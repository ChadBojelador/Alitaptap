"""Issue Validator Service — AI quality check for submitted community problems.

## Current State (STUB)
The `validate()` method always returns `ValidationResult(is_valid=True)`.
All submitted issues are auto-approved until this service is wired in.

## Integration Plan
Wire into `issues.py` `create_issue()` before saving to Firestore:
    from app.services.issue_validator_service import IssueValidatorService
    result = IssueValidatorService().validate(
        title=payload.title,
        description=payload.description,
    )
    status = 'validated' if result.is_valid else 'rejected'
    # Optionally store result.reason in the issue document.

## Validation Criteria
A valid community issue should:
    1. Describe a real, observable problem (not spam or test data)
    2. Be specific enough to be researchable
    3. Be relevant to a Philippine community context
    4. Have a minimum description length (already enforced by API schema)
    5. Not be a duplicate of an existing issue (future: embedding similarity check)

## AI Options (choose one when integrating)
Option A — OpenAI GPT moderation + classification:
    Use GPT to score the issue on relevance, specificity, and authenticity.

Option B — HuggingFace text classification:
    Fine-tune or use a zero-shot model to classify as valid/invalid.

Option C — Rule-based heuristics (no AI, immediate):
    Check minimum word count, banned keywords, etc.
    Already partially implemented in `_rule_based_check()` below.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)

# Minimum description word count to be considered a valid issue.
_MIN_DESCRIPTION_WORDS = 10

# Keywords that suggest spam or test submissions.
_SPAM_KEYWORDS = {'test', 'asdf', 'lorem', 'ipsum', 'hello world', '123'}


@dataclass
class ValidationResult:
    """Result of an issue validation check."""
    is_valid: bool
    reason: str = ''
    confidence: float = 1.0  # 0.0 – 1.0, for AI-based validation


class IssueValidatorService:
    """Validates a submitted community issue for quality and relevance.

    Currently auto-approves everything (stub).
    See module docstring for integration options.
    """

    def validate(self, *, title: str, description: str) -> ValidationResult:
        """Check whether a submitted issue is valid.

        Args:
            title:       Issue title from the submission.
            description: Issue description from the submission.

        Returns:
            ValidationResult with is_valid=True/False and a reason string.
        """
        # TODO: Replace with AI-based validation.
        # For now always returns valid — all issues are auto-approved.
        # Uncomment below to enable rule-based checks immediately:
        # return self._rule_based_check(title, description)
        return ValidationResult(is_valid=True, reason='Auto-approved (stub)')

    def _rule_based_check(self, title: str, description: str) -> ValidationResult:
        """Simple rule-based validation — no AI required.

        Can be enabled immediately as a baseline before AI is integrated.
        """
        combined = f'{title} {description}'.lower().strip()

        # Check for spam keywords.
        for spam in _SPAM_KEYWORDS:
            if spam in combined:
                return ValidationResult(
                    is_valid=False,
                    reason=f'Submission appears to be a test or spam (detected: "{spam}").',
                )

        # Check minimum description length.
        word_count = len(description.split())
        if word_count < _MIN_DESCRIPTION_WORDS:
            return ValidationResult(
                is_valid=False,
                reason=(
                    f'Description too short ({word_count} words). '
                    f'Please provide at least {_MIN_DESCRIPTION_WORDS} words.'
                ),
            )

        return ValidationResult(
            is_valid=True,
            reason='Passed rule-based validation.',
            confidence=0.8,
        )
