"""Auth API — role management."""

from enum import Enum

from fastapi import APIRouter
from pydantic import BaseModel

from app.core.firebase import get_db

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
    """Set or update a user's role in Firestore."""
    db = get_db()
    db.collection('users').document(payload.user_id).set(
        {'role': payload.role.value},
        merge=True,
    )
    return payload
