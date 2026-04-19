"""Mapper service — semantic matching of student ideas to community problems.

Uses a Hugging Face sentence-transformers model (loaded locally, no API key)
to encode text and compute cosine similarity between a student's research
idea and all validated community issues in Firestore.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import TYPE_CHECKING

import numpy as np
from sentence_transformers import SentenceTransformer

from app.core.config import settings
from app.core.firebase import get_db

if TYPE_CHECKING:
    from google.cloud.firestore_v1.client import Client

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Data classes
# ---------------------------------------------------------------------------

@dataclass
class MatchItem:
    """A single match between a student idea and a community issue."""
    issue_id: str
    score: float
    reason: str


# ---------------------------------------------------------------------------
# Service
# ---------------------------------------------------------------------------

class MapperService:
    """Encapsulates the semantic-matching pipeline.

    The sentence-transformers model is loaded lazily on the first call.
    Subsequent calls reuse the cached model instance.
    """

    _model: SentenceTransformer | None = None

    # -- model management ----------------------------------------------------

    @classmethod
    def _get_model(cls) -> SentenceTransformer:
        """Return the shared SentenceTransformer, loading on first use."""
        if cls._model is None:
            model_name = settings.huggingface_model_name
            logger.info('Loading sentence-transformers model: %s', model_name)
            cls._model = SentenceTransformer(model_name)
            logger.info('Model loaded successfully.')
        return cls._model

    # -- public API -----------------------------------------------------------

    def match_idea(
        self,
        student_id: str,
        idea_text: str,
        max_results: int = 5,
    ) -> tuple[str, list[MatchItem]]:
        """Match *idea_text* against validated issues.

        Returns:
            A tuple of (run_id, list[MatchItem]) sorted by descending score.

        Raises:
            ValueError:  If there are no validated issues to match against.
            RuntimeError: If Firebase is not initialised.
        """
        db: Client = get_db()

        # 1. Fetch validated issues ----------------------------------------
        docs = (
            db.collection('issues')
            .where('status', '==', 'validated')
            .stream()
        )

        issues: list[dict] = []
        for doc in docs:
            data = doc.to_dict()
            data['_id'] = doc.id
            issues.append(data)

        if not issues:
            raise ValueError(
                'No validated community issues available for matching. '
                'An admin must validate at least one issue first.'
            )

        # 2. Build corpus texts --------------------------------------------
        corpus_texts = [
            f"{issue.get('title', '')}. {issue.get('description', '')}"
            for issue in issues
        ]

        # 3. Encode with HuggingFace model ---------------------------------
        model = self._get_model()

        idea_embedding = model.encode(idea_text, normalize_embeddings=True)
        corpus_embeddings = model.encode(corpus_texts, normalize_embeddings=True)

        # 4. Cosine similarity (embeddings are already L2-normalised) ------
        scores = np.dot(corpus_embeddings, idea_embedding).tolist()

        # 5. Rank and take top-N -------------------------------------------
        ranked_indices = sorted(
            range(len(scores)),
            key=lambda i: scores[i],
            reverse=True,
        )[:max_results]

        matches: list[MatchItem] = []
        for rank, idx in enumerate(ranked_indices, start=1):
            issue = issues[idx]
            score = float(scores[idx])

            # Clamp to [0, 1] — cosine can occasionally be slightly > 1 due
            # to float precision when embeddings are normalised.
            score = max(0.0, min(1.0, score))

            reason = _build_reason(
                rank=rank,
                idea_text=idea_text,
                issue_title=issue.get('title', ''),
                issue_description=issue.get('description', ''),
                score=score,
            )

            matches.append(MatchItem(
                issue_id=issue['_id'],
                score=round(score, 4),
                reason=reason,
            ))

        # 6. Persist mapper run to Firestore --------------------------------
        run_doc = {
            'student_id': student_id,
            'idea_text': idea_text,
            'matches': [
                {
                    'issue_id': m.issue_id,
                    'score': m.score,
                    'reason': m.reason,
                }
                for m in matches
            ],
            'created_at': datetime.now(timezone.utc),
        }
        _, ref = db.collection('mapper_runs').add(run_doc)
        run_id = ref.id

        logger.info(
            'Mapper run %s: matched %d issues for student %s',
            run_id,
            len(matches),
            student_id,
        )

        return run_id, matches


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _build_reason(
    *,
    rank: int,
    idea_text: str,
    issue_title: str,
    issue_description: str,
    score: float,
) -> str:
    """Generate a human-readable explanation of why the issue matched.

    Uses simple keyword overlap to highlight shared themes.  A more
    sophisticated approach (e.g. LLM-generated explanations) could be
    swapped in later without changing the public API.
    """
    # Tokenise and find shared keywords (case-insensitive).
    idea_words = set(idea_text.lower().split())
    issue_words = set(
        f"{issue_title} {issue_description}".lower().split()
    )

    # Remove very common stop-words to surface meaningful overlap.
    stop = {
        'the', 'a', 'an', 'is', 'are', 'was', 'were', 'and', 'or', 'but',
        'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'as',
        'it', 'its', 'this', 'that', 'be', 'been', 'being', 'have', 'has',
        'had', 'do', 'does', 'did', 'not', 'no', 'so', 'if', 'will', 'can',
        'may', 'about', 'up', 'out', 'than', 'then', 'also', 'very', 'just',
        'into', 'over', 'such', 'some', 'any', 'each', 'which', 'their',
        'there', 'when', 'what', 'how', 'all', 'would', 'could', 'should',
    }
    shared = (idea_words & issue_words) - stop
    shared_display = sorted(shared)[:6]  # keep it concise

    # Strength label
    if score >= 0.70:
        strength = 'Strong'
    elif score >= 0.45:
        strength = 'Moderate'
    else:
        strength = 'Weak'

    parts: list[str] = [
        f'{strength} semantic match ({score:.0%}) with "{issue_title}".'
    ]

    if shared_display:
        parts.append(
            f"Shared themes: {', '.join(shared_display)}."
        )
    else:
        parts.append(
            'The match is based on overall meaning similarity rather than '
            'specific keyword overlap.'
        )

    return ' '.join(parts)
