"""AI Validator Service — automated issue validation, summarization, and SDG tagging."""

import json
import html
import logging
from typing import Optional

from openai import OpenAI

from app.core.config import settings

logger = logging.getLogger(__name__)


class AIValidationResult:
    """Result of AI validation."""

    def __init__(
        self,
        is_valid: bool,
        reason: str,
        ai_summary: str,
        auto_sdg_tag: str,
        standardized_title: str,
    ):
        self.is_valid = is_valid
        self.reason = reason
        self.ai_summary = ai_summary
        self.auto_sdg_tag = auto_sdg_tag
        self.standardized_title = standardized_title


class AIValidator:
    """Validates issues, generates summaries, assigns SDG tags, and standardizes titles."""

    def __init__(self):
        self.client = OpenAI(api_key=settings.openai_api_key) if settings.openai_api_key else None

    def validate_and_process(
        self,
        title: str,
        description: str,
    ) -> AIValidationResult:
        """
        Validate issue content, generate summary, assign SDG tag, and standardize title.

        Returns AIValidationResult with validation status and processed fields.
        """
        if not self.client or not settings.ai_issue_validation_enabled:
            return self._fallback_validation(title, description)

        try:
            prompt = self._build_validation_prompt(title, description)
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {
                        "role": "system",
                        "content": self._get_system_instructions(),
                    },
                    {"role": "user", "content": prompt},
                ],
                temperature=0.3,
                max_tokens=1000,
            )

            result_text = response.choices[0].message.content
            return self._parse_validation_response(result_text)

        except Exception as e:
            logger.error(f"AI validation failed: {e}. Falling back to heuristic validation.")
            return self._fallback_validation(title, description)

    def _get_system_instructions(self) -> str:
        """System instructions for AI validator."""
        return """You are an AI Admin for ALITAPTAP, a platform connecting community problems with student research.

Your role:
1. Validate content for spam, safety, and relevance
2. Summarize descriptions into professional "Research Problem Statements"
3. Assign the most relevant UN SDG tag
4. Standardize titles for better semantic matching

Output ONLY valid JSON with these fields:
{
  "is_valid": boolean,
  "reason": "brief explanation",
  "ai_summary": "professional research problem statement (2-3 sentences)",
  "auto_sdg_tag": "SDG-X: Goal Name",
  "standardized_title": "improved title for semantic matching"
}

SDG Tags (use exact format):
- SDG-1: No Poverty
- SDG-2: Zero Hunger
- SDG-3: Good Health and Well-being
- SDG-4: Quality Education
- SDG-5: Gender Equality
- SDG-6: Clean Water and Sanitation
- SDG-7: Affordable and Clean Energy
- SDG-8: Decent Work and Economic Growth
- SDG-9: Industry, Innovation and Infrastructure
- SDG-10: Reduced Inequalities
- SDG-11: Sustainable Cities and Communities
- SDG-12: Responsible Consumption and Production
- SDG-13: Climate Action
- SDG-14: Life Below Water
- SDG-15: Life on Land
- SDG-16: Peace, Justice and Strong Institutions
- SDG-17: Partnerships for the Goals

Reject if: spam, offensive, off-topic, or unsafe."""

    def _build_validation_prompt(self, title: str, description: str) -> str:
        """Build validation prompt."""
        safe_title = html.escape(title[:200])
        safe_description = html.escape(description[:2000])
        return f"""Validate and process this community problem report:

Title: {safe_title}
Description: {safe_description}

Respond with ONLY the JSON object, no additional text."""

    def _parse_validation_response(self, response_text: str) -> AIValidationResult:
        """Parse AI response and return AIValidationResult."""
        try:
            data = json.loads(response_text)
            return AIValidationResult(
                is_valid=data.get("is_valid", True),
                reason=data.get("reason", ""),
                ai_summary=data.get("ai_summary", ""),
                auto_sdg_tag=data.get("auto_sdg_tag", "SDG-11: Sustainable Cities and Communities"),
                standardized_title=data.get("standardized_title", ""),
            )
        except json.JSONDecodeError:
            logger.error(f"Failed to parse AI response: {response_text}")
            return self._fallback_validation("", "")

    def _heuristic_sdg_tag(self, text: str) -> str:
        """Assign an SDG tag based on keywords in the text."""
        text = text.lower()
        if any(kw in text for kw in ['water', 'flood', 'sanitation', 'sewer', 'pipe', 'drain']):
            return "SDG-6: Clean Water and Sanitation"
        if any(kw in text for kw in ['health', 'disease', 'medical', 'hospital', 'doctor', 'clinic', 'medicine']):
            return "SDG-3: Good Health and Well-being"
        if any(kw in text for kw in ['education', 'school', 'learning', 'student', 'teacher', 'classroom']):
            return "SDG-4: Quality Education"
        if any(kw in text for kw in ['poverty', 'poor', 'income', 'money', 'financial', 'hungry', 'food']):
            return "SDG-1: No Poverty"
        if any(kw in text for kw in ['waste', 'garbage', 'trash', 'recycle', 'pollution', 'plastic']):
            return "SDG-12: Responsible Consumption and Production"
        if any(kw in text for kw in ['climate', 'environment', 'nature', 'warming', 'weather']):
            return "SDG-13: Climate Action"
        if any(kw in text for kw in ['road', 'bridge', 'traffic', 'transport', 'building', 'internet', 'electricity']):
            return "SDG-9: Industry, Innovation and Infrastructure"
        return "SDG-11: Sustainable Cities and Communities"

    def _fallback_validation(self, title: str, description: str) -> AIValidationResult:
        """Fallback heuristic validation when AI is unavailable."""
        is_valid = self._heuristic_check(title, description)
        combined_text = f"{title} {description}"
        return AIValidationResult(
            is_valid=is_valid,
            reason="Heuristic validation (AI unavailable)" if is_valid else "Failed heuristic checks",
            ai_summary=description[:200] if description else "Community problem report",
            auto_sdg_tag=self._heuristic_sdg_tag(combined_text),
            standardized_title=title,
        )

    def _heuristic_check(self, title: str, description: str) -> bool:
        """Basic heuristic validation."""
        if not title or len(title.strip()) < 1:
            return False
        if not description or len(description.strip()) < 1:
            return False
        if len(title) > 200 or len(description) > 5000:
            return False
        spam_keywords = [
            'viagra', 'casino', 'lottery', 'click here', 'buy now',
            'free money', 'make money fast', 'work from home', 'earn cash',
            'weight loss', 'diet pills', 'crypto investment', 'bitcoin',
            'xxx', 'porn', 'sex', 'nude', 'naked',
            'hack', 'crack', 'pirate', 'warez', 'keygen',
            'nigger', 'faggot', 'retard', 'kys', 'kill yourself',
        ]
        combined = (title + " " + description).lower()
        if any(keyword in combined for keyword in spam_keywords):
            return False
        return True


# Singleton instance
_validator: Optional[AIValidator] = None


def get_ai_validator() -> AIValidator:
    """Get or create AI validator instance."""
    global _validator
    if _validator is None:
        _validator = AIValidator()
    return _validator
