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


@router.get('/role/{user_id}')
def get_user_role(user_id: str) -> dict:
    """Get a user's role from Firestore."""
    db = get_db()
    doc = db.collection('users').document(user_id).get()
    if not doc.exists:
        return {'user_id': user_id, 'role': 'student'}
    return {'user_id': user_id, 'role': doc.to_dict().get('role', 'student')}
