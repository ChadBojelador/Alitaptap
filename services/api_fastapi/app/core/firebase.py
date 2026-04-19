"""Firebase Admin SDK initialization."""

import firebase_admin
from firebase_admin import credentials, firestore
from google.cloud.firestore_v1.client import Client

from app.core.config import settings

_db: Client | None = None


def init_firebase() -> None:
    """Initialize Firebase Admin SDK. Call once at app startup."""
    global _db
    if firebase_admin._apps:
        # Already initialized.
        _db = firestore.client()
        return

    if settings.firebase_service_account_path:
        cred = credentials.Certificate(settings.firebase_service_account_path)
        firebase_admin.initialize_app(cred, {
            'projectId': settings.firebase_project_id,
        })
    else:
        # Fall back to Application Default Credentials (e.g. on Cloud Run).
        firebase_admin.initialize_app()

    _db = firestore.client()


def get_db() -> Client:
    """Return the Firestore client. Raises if Firebase not initialized."""
    if _db is None:
        raise RuntimeError(
            'Firebase not initialized. Call init_firebase() at startup.'
        )
    return _db
