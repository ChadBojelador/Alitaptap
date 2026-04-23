from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from app.api.router import api_router
from app.core.config import settings
from app.core.mongodb import init_mongodb


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan: initialize services on startup."""
    try:
        init_mongodb()
    except Exception as e:
        print(f"Warning: MongoDB initialization failed: {e}")
    yield


def create_app() -> FastAPI:
    application = FastAPI(title=settings.app_name, lifespan=lifespan)

    # Allow Flutter web (Chrome) to call the API from localhost.
    application.add_middleware(
        CORSMiddleware,
        allow_origins=['*'],
        allow_credentials=False,
        allow_methods=['*'],
        allow_headers=['*'],
    )

    # Serve local images from scripts/images folder
    images_path = Path(__file__).parent.parent / "scripts" / "images"
    if images_path.exists():
        application.mount("/images", StaticFiles(directory=str(images_path)), name="images")

    application.include_router(api_router)
    return application


app = create_app()
