"""Title Suggestion Service — AI-generated research title suggestions.

## Current State (STUB)
The `generate()` method is a placeholder that raises NotImplementedError.
The heuristic fallback in `issues.py` (`_build_title_suggestions`) is still
active until this service is wired in.

## Integration Plan
Replace the heuristic in `issues.py` with a call to `TitleSuggestionService.generate()`.

## AI Options (choose one when integrating)
Option A — OpenAI GPT (requires OPENAI_API_KEY in .env):
    from openai import OpenAI
    client = OpenAI(api_key=settings.openai_api_key)
    response = client.chat.completions.create(
        model='gpt-4o-mini',
        messages=[{'role': 'user', 'content': prompt}],
    )

Option B — Local LLM via Ollama (no API key, runs on machine):
    import requests
    response = requests.post('http://localhost:11434/api/generate', json={
        'model': 'llama3',
        'prompt': prompt,
        'stream': False,
    })

Option C — HuggingFace Inference API (free tier available):
    import requests
    response = requests.post(
        'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.2',
        headers={'Authorization': f'Bearer {settings.huggingface_api_key}'},
        json={'inputs': prompt},
    )

## How to Wire In
1. Choose an option above and implement `generate()`.
2. In `issues.py`, replace `_build_title_suggestions(issue_data)` with:
       from app.services.title_suggestion_service import TitleSuggestionService
       suggestions = TitleSuggestionService().generate(
           title=issue_data.get('title', ''),
           description=issue_data.get('description', ''),
           tags=issue_data.get('tags', []),
       )
3. Add the required API key to `.env` and `config.py`.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)


class TitleSuggestionService:
    """Generates AI-powered research title suggestions for a community issue.

    Currently stubbed — see module docstring for integration options.
    """

    def generate(
        self,
        *,
        title: str,
        description: str,
        tags: list[str],
        limit: int = 3,
    ) -> list[str]:
        """Generate research title suggestions for a community issue.

        Args:
            title:       Issue title from Firestore.
            description: Issue description from Firestore.
            tags:        SDG tags assigned to the issue.
            limit:       Number of suggestions to return.

        Returns:
            List of research title strings.

        Raises:
            NotImplementedError: Until an AI backend is wired in.
        """
        # TODO: Replace this stub with a real LLM call.
        # See module docstring for integration options (OpenAI, Ollama, HuggingFace).
        raise NotImplementedError(
            'TitleSuggestionService.generate() is not yet implemented. '
            'See services/ai/title_suggestion_service.py for integration options.'
        )

    def _build_prompt(
        self,
        title: str,
        description: str,
        tags: list[str],
        limit: int,
    ) -> str:
        """Build the LLM prompt for title generation.

        This prompt is ready to use — just pass it to whichever LLM you choose.
        """
        sdg_context = f'SDG tags: {", ".join(tags)}' if tags else 'No SDG tags assigned yet.'
        return (
            f'You are a research advisor helping Filipino students turn community '
            f'problems into academic research titles.\n\n'
            f'Community Problem:\n'
            f'Title: {title}\n'
            f'Description: {description}\n'
            f'{sdg_context}\n\n'
            f'Generate exactly {limit} specific, academic research titles that a '
            f'student could use to address this community problem. '
            f'Each title should be actionable, measurable, and suitable for a '
            f'undergraduate or graduate thesis in the Philippines.\n\n'
            f'Return only the titles, one per line, no numbering or extra text.'
        )
