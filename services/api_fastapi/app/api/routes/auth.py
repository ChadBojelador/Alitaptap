"""Auth API — authentication and role management."""

from enum import Enum
import hashlib
import secrets

import bcrypt
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

from app.core.mongodb import get_db

router = APIRouter(prefix='/auth', tags=['auth'])


class Role(str, Enum):
    student = 'student'
    admin = 'admin'


class RoleDecision(BaseModel):
    user_id: str
    role: Role


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    role: Role


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class AuthResponse(BaseModel):
    user_id: str
    email: str
    role: str


def hash_password(password: str) -> str:
    """Hash password with bcrypt."""
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(password: str, hashed: str) -> bool:
    """Verify password against bcrypt hash or legacy SHA-256 hex hash."""
    if hashed.startswith('$2b$') or hashed.startswith('$2a$'):
        # Standard bcrypt hash
        return bcrypt.checkpw(password.encode(), hashed.encode())
    # Legacy SHA-256 hex hash (64-char hex string)
    if len(hashed) == 64:
        return hashlib.sha256(password.encode()).hexdigest() == hashed
    return False


class SocialLoginRequest(BaseModel):
    email: EmailStr
    provider: str  # 'google' | 'facebook'
    provider_id: str
    display_name: str = ''
    role: Role = Role.student


@router.post('/social', response_model=AuthResponse)
def social_login(payload: SocialLoginRequest) -> AuthResponse:
    """Sign in or register via Google / Facebook."""
    db = get_db()
    user = db['users'].find_one({'email': payload.email})
    if user:
        stored_role = user.get('role', 'student')
        return AuthResponse(
            user_id=user['user_id'],
            email=user['email'],
            role=stored_role,
        )
    user_id = secrets.token_urlsafe(16)
    db['users'].insert_one({
        'user_id': user_id,
        'email': payload.email,
        'display_name': payload.display_name,
        'provider': payload.provider,
        'provider_id': payload.provider_id,
        'role': payload.role.value,
    })
    return AuthResponse(user_id=user_id, email=payload.email, role=payload.role.value)


@router.post('/register', response_model=AuthResponse)
def register(payload: RegisterRequest) -> AuthResponse:
    """Register a new user."""
    db = get_db()
    
    # Check if user already exists
    existing = db['users'].find_one({'email': payload.email})
    if existing:
        raise HTTPException(status_code=400, detail='Email already registered')
    
    # Hash password
    hashed_password = hash_password(payload.password)

    # Generate user_id
    user_id = secrets.token_urlsafe(16)

    # Create user
    user_doc = {
        'user_id': user_id,
        'email': payload.email,
        'password_hash': hashed_password,
        'role': payload.role.value,
    }
    db['users'].insert_one(user_doc)
    
    return AuthResponse(
        user_id=user_id,
        email=payload.email,
        role=payload.role.value,
    )


@router.post('/login', response_model=AuthResponse)
def login(payload: LoginRequest) -> AuthResponse:
    """Login user."""
    db = get_db()
    user = db['users'].find_one({'email': payload.email})
    if not user:
        raise HTTPException(status_code=401, detail='Invalid email or password')
    # Social-only accounts have no password
    if not user.get('password_hash'):
        raise HTTPException(status_code=401, detail='This account uses Google sign-in. Please use Continue with Google.')
    if not verify_password(payload.password, user['password_hash']):
        raise HTTPException(status_code=401, detail='Invalid email or password')

    # Auto-upgrade legacy SHA-256 hashes to bcrypt on successful login
    stored_hash = user['password_hash']
    if not (stored_hash.startswith('$2b$') or stored_hash.startswith('$2a$')):
        new_hash = hash_password(payload.password)
        db['users'].update_one(
            {'_id': user['_id']},
            {'$set': {'password_hash': new_hash}},
        )

    role = user.get('role', 'student')
    return AuthResponse(
        user_id=user['user_id'],
        email=user['email'],
        role=role,
    )


@router.post('/role', response_model=RoleDecision)
def set_user_role(payload: RoleDecision) -> RoleDecision:
    """Set or update a user's role in MongoDB."""
    db = get_db()
    db['users'].update_one(
        {'user_id': payload.user_id},
        {'$set': {'user_id': payload.user_id, 'role': payload.role.value}},
        upsert=True,
    )
    return payload


@router.get('/role/{user_id}')
def get_user_role(user_id: str) -> dict:
    """Get a user's role from MongoDB."""
    db = get_db()
    doc = db['users'].find_one({'user_id': user_id})
    if not doc:
        raise HTTPException(status_code=404, detail='User not found')
    role = doc.get('role', 'student')
    return {'user_id': user_id, 'role': role}
