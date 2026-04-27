"""Research Backbone API — AI-guided research structure generation."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.research_backbone_service import ResearchBackboneService

router = APIRouter(prefix="/research", tags=["research"])


class ResearchBackboneRequest(BaseModel):
    """Request to generate research backbone."""

    student_id: str = Field(min_length=1, max_length=128)
    problem: str = Field(min_length=10, max_length=2000, description="Community problem")
    sdg_or_idea: str = Field(
        min_length=5, max_length=1000, description="SDG focus or research idea"
    )
    approach: str = Field(
        min_length=10, max_length=2000, description="Proposed approach/methodology"
    )


class FeasibilityScore(BaseModel):
    """Feasibility assessment."""

    cost: str
    time: str
    data_availability: str


class CommunityImpact(BaseModel):
    """Community impact assessment."""
    
    social: float
    environmental: float
    economic: float
    overall: float
    summary: str


class ResearchBackboneResponse(BaseModel):
    """Generated research backbone."""

    research_title: str
    methodology: str
    sdg_alignment: list[str]
    feasibility_score: FeasibilityScore
    community_impact_level: CommunityImpact


_service = ResearchBackboneService()


@router.post("/backbone/generate", response_model=ResearchBackboneResponse)
def generate_research_backbone(payload: ResearchBackboneRequest) -> ResearchBackboneResponse:
    """Generate AI-guided research backbone.

    Takes problem, SDG/idea, and approach as input.
    Returns structured backbone that users can edit.

    All fields are editable by the user to leverage their own skills.
    """
    try:
        backbone = _service.generate(
            problem=payload.problem.strip(),
            sdg_or_idea=payload.sdg_or_idea.strip(),
            approach=payload.approach.strip(),
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except RuntimeError as error:
        raise HTTPException(status_code=500, detail="Service error") from error

    return ResearchBackboneResponse(
        research_title=backbone.research_title,
        methodology=backbone.methodology,
        sdg_alignment=backbone.sdg_alignment,
        feasibility_score=FeasibilityScore(
            cost=backbone.feasibility_score["cost"],
            time=backbone.feasibility_score["time"],
            data_availability=backbone.feasibility_score["data_availability"],
        ),
        community_impact_level=backbone.community_impact_level,
    )
