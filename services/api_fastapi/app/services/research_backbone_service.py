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
    community_impact_level: str  # low, medium, high


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
        impact = self._estimate_impact(problem, approach)

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

    def _estimate_impact(self, problem: str, approach: str) -> str:
        """Estimate expected community impact level."""
        # Heuristic: assess based on problem severity and approach scope
        problem_lower = problem.lower()
        approach_lower = approach.lower()

        # Check for high-impact indicators
        high_impact_keywords = [
            "scalable",
            "sustainable",
            "systemic",
            "community-wide",
            "policy",
            "infrastructure",
        ]
        medium_impact_keywords = [
            "pilot",
            "local",
            "targeted",
            "intervention",
        ]

        if any(word in approach_lower for word in high_impact_keywords):
            return "High"
        elif any(word in approach_lower for word in medium_impact_keywords):
            return "Medium"
        else:
            return "Medium"
