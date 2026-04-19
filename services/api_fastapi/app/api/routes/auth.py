from enum import Enum

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix='/auth', tags=['auth'])


class Role(str, Enum):
    community = 'community'
    student = 'student'
    admin = 'admin'


class RoleDecision(BaseModel):
    user_id: str
    role: Role


@router.post('/role', response_model=RoleDecision)
def set_user_role(payload: RoleDecision) -> RoleDecision:
    # M1 skeleton: persistence to Firestore will be implemented in M2.
    return payload
