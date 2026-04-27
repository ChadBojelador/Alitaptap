"""MongoDB client initialization."""

from pymongo import MongoClient
from pymongo.database import Database

from app.core.config import settings

_client: MongoClient | None = None
_db: Database | None = None


def init_mongodb() -> None:
    global _client, _db
    _client = MongoClient(settings.mongodb_uri)
    _db = _client[settings.mongodb_db_name]


def close_mongodb() -> None:
    global _client, _db
    if _client is not None:
        _client.close()
        _client = None
        _db = None


def get_db() -> Database:
    if _db is None:
        raise RuntimeError("MongoDB not initialized. Call init_mongodb() at startup.")
    return _db
