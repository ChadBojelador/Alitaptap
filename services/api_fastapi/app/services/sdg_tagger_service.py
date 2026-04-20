"""SDG Tagger Service — classifies community issues into UN SDG categories.

## Current State (STUB)
The `tag()` method is a placeholder that returns an empty list.
Issues are currently stored with `tags: []` until this service is wired in.

## Integration Plan
Wire into `issues.py` `create_issue()` after the issue is saved:
    from app.services.sdg_tagger_service import SdgTaggerService
    tags = SdgTaggerService().tag(
        title=payload.title,
        description=payload.description,
    )
    doc_ref.update({'tags': tags})

## SDG Categories (UN 2030 Agenda)
The 17 SDGs relevant to Philippine community problems:
    SDG-1:  No Poverty
    SDG-2:  Zero Hunger
    SDG-3:  Good Health and Well-being
    SDG-4:  Quality Education
    SDG-5:  Gender Equality
    SDG-6:  Clean Water and Sanitation
    SDG-7:  Affordable and Clean Energy
    SDG-8:  Decent Work and Economic Growth
    SDG-9:  Industry, Innovation and Infrastructure
    SDG-10: Reduced Inequalities
    SDG-11: Sustainable Cities and Communities
    SDG-12: Responsible Consumption and Production
    SDG-13: Climate Action
    SDG-14: Life Below Water
    SDG-15: Life on Land
    SDG-16: Peace, Justice and Strong Institutions
    SDG-17: Partnerships for the Goals

## AI Options (choose one when integrating)
Option A — Zero-shot classification with HuggingFace:
    from transformers import pipeline
    classifier = pipeline('zero-shot-classification',
                          model='facebook/bart-large-mnli')
    result = classifier(text, candidate_labels=SDG_LABELS)

Option B — OpenAI GPT with structured output:
    Ask GPT to return a JSON list of matching SDG codes.

Option C — Keyword-based fallback (no AI, fast):
    Map keywords to SDGs using a predefined dictionary.
    Already partially implemented in `_keyword_fallback()` below.
"""

from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# SDG label list for zero-shot classification or LLM prompting.
SDG_LABELS = [
    'SDG-1: No Poverty',
    'SDG-2: Zero Hunger',
    'SDG-3: Good Health and Well-being',
    'SDG-4: Quality Education',
    'SDG-5: Gender Equality',
    'SDG-6: Clean Water and Sanitation',
    'SDG-7: Affordable and Clean Energy',
    'SDG-8: Decent Work and Economic Growth',
    'SDG-9: Industry, Innovation and Infrastructure',
    'SDG-10: Reduced Inequalities',
    'SDG-11: Sustainable Cities and Communities',
    'SDG-12: Responsible Consumption and Production',
    'SDG-13: Climate Action',
    'SDG-14: Life Below Water',
    'SDG-15: Life on Land',
    'SDG-16: Peace, Justice and Strong Institutions',
    'SDG-17: Partnerships for the Goals',
]

# Keyword → SDG mapping for the keyword fallback.
_KEYWORD_MAP: dict[str, str] = {
    'flood': 'SDG-11', 'flooding': 'SDG-11', 'drainage': 'SDG-11',
    'water': 'SDG-6', 'sanitation': 'SDG-6', 'sewage': 'SDG-6',
    'waste': 'SDG-12', 'garbage': 'SDG-12', 'plastic': 'SDG-12',
    'health': 'SDG-3', 'hospital': 'SDG-3', 'disease': 'SDG-3',
    'school': 'SDG-4', 'education': 'SDG-4', 'literacy': 'SDG-4',
    'poverty': 'SDG-1', 'poor': 'SDG-1', 'livelihood': 'SDG-1',
    'hunger': 'SDG-2', 'food': 'SDG-2', 'nutrition': 'SDG-2',
    'energy': 'SDG-7', 'electricity': 'SDG-7', 'solar': 'SDG-7',
    'road': 'SDG-9', 'infrastructure': 'SDG-9', 'bridge': 'SDG-9',
    'climate': 'SDG-13', 'pollution': 'SDG-13', 'carbon': 'SDG-13',
    'gender': 'SDG-5', 'women': 'SDG-5', 'violence': 'SDG-16',
    'crime': 'SDG-16', 'corruption': 'SDG-16', 'justice': 'SDG-16',
}


class SdgTaggerService:
    """Classifies a community issue into relevant UN SDG categories.

    Currently returns empty list (stub). See module docstring for options.
    """

    def tag(self, *, title: str, description: str) -> list[str]:
        """Return a list of SDG codes relevant to the issue.

        Args:
            title:       Issue title.
            description: Issue description.

        Returns:
            List of SDG codes e.g. ['SDG-11', 'SDG-6'].
            Returns empty list until implemented.
        """
        # TODO: Replace with AI-based classification.
        # For now returns empty list — issues stored with tags: [].
        # Uncomment below to enable keyword fallback immediately:
        # return self._keyword_fallback(title, description)
        return []

    def _keyword_fallback(self, title: str, description: str) -> list[str]:
        """Simple keyword-based SDG tagging — no AI required.

        Can be enabled immediately as a baseline before AI is integrated.
        """
        text = f'{title} {description}'.lower()
        matched: set[str] = set()
        for keyword, sdg in _KEYWORD_MAP.items():
            if keyword in text:
                matched.add(sdg)
        return sorted(matched)
