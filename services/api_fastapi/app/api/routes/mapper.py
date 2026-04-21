"""Mapper API – semantic matching of student ideas to community problems."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from app.services.mapper_service import MapperService

router = APIRouter(prefix='/mapper', tags=['mapper'])


class IdeaMatchRequest(BaseModel):
    student_id: str = Field(min_length=1, max_length=128)
    idea_text: str = Field(min_length=5, max_length=3000)
    max_results: int = Field(default=5, ge=1, le=20)


class MatchResult(BaseModel):
    issue_id: str
    score: float
    reason: str


class IdeaMatchResponse(BaseModel):
    run_id: str
    matches: list[MatchResult]


class NearestIssuesRequest(BaseModel):
    lat: float = Field(ge=-90, le=90)
    lng: float = Field(ge=-180, le=180)
    max_results: int = Field(default=5, ge=1, le=20)


class NearestIssuesResponse(BaseModel):
    matches: list[MatchResult]


_mapper_service = MapperService()


@router.post('/match', response_model=IdeaMatchResponse)
def match_idea(payload: IdeaMatchRequest) -> IdeaMatchResponse:
    """Match a student idea against validated issues and return ranked matches."""
    try:
        run_id, matches = _mapper_service.match_idea(
            student_id=payload.student_id.strip(),
            idea_text=payload.idea_text.strip(),
            max_results=payload.max_results,
        )
    except ValueError as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except RuntimeError as error:
        raise HTTPException(
            status_code=500,
            detail='Database not initialized',
        ) from error

    return IdeaMatchResponse(
        run_id=run_id,
        matches=[
            MatchResult(issue_id=item.issue_id, score=item.score, reason=item.reason)
            for item in matches
        ],
    )


@router.post('/nearest', response_model=NearestIssuesResponse)
def find_nearest_issues(payload: NearestIssuesRequest) -> NearestIssuesResponse:
    """Find validated issues nearest to the given location."""
    try:
        matches = _mapper_service.find_nearest_issues(
            lat=payload.lat,
            lng=payload.lng,
            max_results=payload.max_results,
        )
    except RuntimeError as error:
        raise HTTPException(
            status_code=500,
            detail='Database not initialized',
        ) from error

    return NearestIssuesResponse(
        matches=[
            MatchResult(issue_id=item.issue_id, score=item.score, reason=item.reason)
            for item in matches
        ],
    )
