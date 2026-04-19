from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix='/mapper', tags=['mapper'])


class IdeaMatchRequest(BaseModel):
    student_id: str
    idea_text: str
    max_results: int = 5


@router.post('/match')
def match_idea(payload: IdeaMatchRequest) -> dict:
    return {
        'message': 'M1 skeleton ready',
        'matches': [],
        'input': payload.model_dump(),
    }
