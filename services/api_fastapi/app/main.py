from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import settings
from app.core.firebase import init_firebase


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: initialize services on startup."""
    init_firebase()
    yield


def create_app() -> FastAPI:
    application = FastAPI(title=settings.app_name, lifespan=lifespan)
    application.include_router(api_router)
    return application


app = create_app()
