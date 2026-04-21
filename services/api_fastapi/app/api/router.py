from fastapi import APIRouter

from .routes.auth import router as auth_router
from .routes.health import router as health_router
from .routes.issues import router as issues_router
from .routes.mapper import router as mapper_router
from .routes.posts import router as posts_router

api_router = APIRouter(prefix='/api/v1')
api_router.include_router(health_router)
api_router.include_router(auth_router)
api_router.include_router(issues_router)
api_router.include_router(mapper_router)
api_router.include_router(posts_router)
