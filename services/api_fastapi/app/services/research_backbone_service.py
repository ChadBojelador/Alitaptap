"""Research Backbone Generation Service — AI-guided research structure.

Generates the backbone of a research project:
- Research title
- Methodology
- Relevant SDG alignment
- Feasibility score (cost, time, data availability)
- Expected community impact level

Users can edit all generated fields to leverage their own skills.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class ResearchBackbone:
    """Generated research backbone structure."""

    research_title: str
    methodology: str
    sdg_alignment: list[str]
    feasibility_score: dict[str, str]  # cost, time, data_availability
    community_impact_level: dict  # {social, environmental, economic, overall, summary}


class ResearchBackboneService:
    """Generates AI-powered research backbone for student projects.

    Takes problem, SDG/idea, and approach as input.
    Returns structured backbone that users can edit.
    """

    def generate(
        self,
        *,
        problem: str,
        sdg_or_idea: str,
        approach: str,
    ) -> ResearchBackbone:
        """Generate research backbone from problem, idea, and approach.

        Args:
            problem: Community problem description.
            sdg_or_idea: SDG focus or research idea.
            approach: Proposed approach/methodology.

        Returns:
            ResearchBackbone with all fields ready for user editing.
        """
        # TODO: Replace with real LLM call (OpenAI, Ollama, or HuggingFace)
        # For now, return structured heuristic-based backbone

        title = self._generate_title(problem, sdg_or_idea)
        methodology = self._generate_methodology(approach)
        sdg_tags = self._extract_sdg_tags(sdg_or_idea, problem)
        feasibility = self._assess_feasibility(approach)
        impact = self._estimate_impact(problem, approach, sdg_or_idea)

        return ResearchBackbone(
            research_title=title,
            methodology=methodology,
            sdg_alignment=sdg_tags,
            feasibility_score=feasibility,
            community_impact_level=impact,
        )

    def _generate_title(self, problem: str, sdg_or_idea: str) -> str:
        """Generate research title from problem and idea."""
        # Heuristic: combine problem and idea into academic title
        problem_key = problem.split()[0].lower()
        idea_key = sdg_or_idea.split()[0].lower()
        return f"Addressing {problem_key} through {idea_key}: A Community-Centered Research Initiative"

    def _generate_methodology(self, approach: str) -> str:
        """Generate methodology from approach description."""
        # Heuristic: structure approach into research methodology
        return (
            f"Mixed-methods approach combining qualitative and quantitative analysis. "
            f"Primary methods: {approach}. "
            f"Data collection through community engagement, surveys, and field observations. "
            f"Analysis using thematic coding and statistical validation."
        )

    def _extract_sdg_tags(self, sdg_or_idea: str, problem: str) -> list[str]:
        """Extract or infer SDG tags from idea and problem."""
        # Heuristic: map keywords to SDGs
        sdg_map = {
            "water": "SDG 6 (Clean Water and Sanitation)",
            "health": "SDG 3 (Good Health and Well-being)",
            "education": "SDG 4 (Quality Education)",
            "climate": "SDG 13 (Climate Action)",
            "poverty": "SDG 1 (No Poverty)",
            "hunger": "SDG 2 (Zero Hunger)",
            "energy": "SDG 7 (Affordable and Clean Energy)",
            "work": "SDG 8 (Decent Work and Economic Growth)",
            "innovation": "SDG 9 (Industry, Innovation, Infrastructure)",
            "inequality": "SDG 10 (Reduced Inequalities)",
            "cities": "SDG 11 (Sustainable Cities and Communities)",
            "consumption": "SDG 12 (Responsible Consumption and Production)",
            "peace": "SDG 16 (Peace, Justice, Strong Institutions)",
            "partnership": "SDG 17 (Partnerships for the Goals)",
        }

        combined_text = f"{sdg_or_idea} {problem}".lower()
        tags = []
        for keyword, sdg in sdg_map.items():
            if keyword in combined_text and sdg not in tags:
                tags.append(sdg)

        return tags if tags else ["SDG 17 (Partnerships for the Goals)"]

    def _assess_feasibility(self, approach: str) -> dict[str, str]:
        """Assess feasibility: cost, time, data availability."""
        # Heuristic: estimate based on approach keywords
        approach_lower = approach.lower()

        cost = "Medium"
        if any(word in approach_lower for word in ["iot", "sensor", "technology", "hardware"]):
            cost = "High"
        elif any(word in approach_lower for word in ["survey", "interview", "observation"]):
            cost = "Low"

        time = "6-12 months"
        if any(word in approach_lower for word in ["quick", "rapid", "pilot"]):
            time = "3-6 months"
        elif any(word in approach_lower for word in ["longitudinal", "long-term", "sustained"]):
            time = "12+ months"

        data_availability = "Moderate"
        if any(word in approach_lower for word in ["existing", "secondary", "database"]):
            data_availability = "High"
        elif any(word in approach_lower for word in ["new", "primary", "collection"]):
            data_availability = "Low"

        return {
            "cost": cost,
            "time": time,
            "data_availability": data_availability,
        }

    def _estimate_impact(
        self, problem: str, approach: str, sdg_or_idea: str
    ) -> dict:
        """Estimate multi-dimensional community impact with percentages.

        Returns a dict with social, environmental, economic scores (0-100),
        an overall score, and a human-readable summary.
        """
        combined = f"{problem} {approach} {sdg_or_idea}".lower()

        # ── Social impact keywords ──────────────────────────────────
        social_keywords = {
            "community": 12, "people": 10, "health": 14, "education": 13,
            "poverty": 15, "welfare": 12, "equity": 11, "access": 10,
            "inclusion": 13, "vulnerable": 14, "youth": 11, "women": 12,
            "children": 13, "safety": 10, "rights": 11, "hunger": 14,
            "well-being": 12, "social": 10, "livelihood": 13, "housing": 11,
        }

        # ── Environmental impact keywords ───────────────────────────
        env_keywords = {
            "climate": 14, "water": 13, "pollution": 15, "waste": 14,
            "biodiversity": 12, "ecosystem": 13, "deforestation": 15,
            "sustainability": 12, "emission": 14, "renewable": 13,
            "conservation": 12, "flood": 13, "drought": 12, "soil": 10,
            "ocean": 11, "energy": 10, "green": 10, "carbon": 13,
            "recycle": 12, "environment": 11,
        }

        # ── Economic impact keywords ────────────────────────────────
        econ_keywords = {
            "economic": 12, "income": 13, "employment": 14, "business": 12,
            "market": 11, "productivity": 13, "growth": 12, "trade": 10,
            "cost": 10, "investment": 13, "infrastructure": 14,
            "agriculture": 12, "industry": 11, "tourism": 12,
            "innovation": 13, "technology": 12, "scalable": 14,
            "funding": 11, "revenue": 12, "supply": 10,
        }

        def _score(keywords: dict[str, int]) -> float:
            base = 35.0
            for kw, weight in keywords.items():
                if kw in combined:
                    base += weight
            return min(base, 98.0)

        social = round(_score(social_keywords), 1)
        environmental = round(_score(env_keywords), 1)
        economic = round(_score(econ_keywords), 1)
        overall = round(social * 0.40 + environmental * 0.30 + economic * 0.30, 1)

        # Determine dominant dimension
        dims = {"Social": social, "Environmental": environmental, "Economic": economic}
        dominant = max(dims, key=dims.get)

        summary = (
            f"Strongest impact in {dominant.lower()} dimension ({dims[dominant]:.0f}%). "
            f"Overall projected community impact: {overall:.0f}%."
        )

        return {
            "social": social,
            "environmental": environmental,
            "economic": economic,
            "overall": overall,
            "summary": summary,
        }

