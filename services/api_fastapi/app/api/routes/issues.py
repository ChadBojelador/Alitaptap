from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix='/issues', tags=['issues'])


class IssueCreate(BaseModel):
    reporter_id: str
    title: str
    description: str
    lat: float
    lng: float


@router.post('')
def create_issue(payload: IssueCreate) -> dict:
    return {
        'message': 'M1 skeleton ready',
        'payload': payload.model_dump(),
    }
