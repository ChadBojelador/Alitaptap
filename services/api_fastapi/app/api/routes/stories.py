"""Stories API — SDG story bubbles for the Expo feed."""

from datetime import datetime, timezone
from typing import Optional
from bson import ObjectId
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.mongodb import get_db

router = APIRouter(prefix='/stories', tags=['stories'])


class StoryResponse(BaseModel):
    story_id: str
    bubble_label: str
    title: str
    description: str
    sdg_label: str
    sdg_name: str
    image_url: Optional[str] = None
    created_at: str


class StoryCreate(BaseModel):
    bubble_label: str
    title: str
    description: str
    sdg_label: str
    sdg_name: str
    image_url: Optional[str] = None


def _doc_to_story(doc: dict) -> dict:
    created = doc.get('created_at')
    return {
        'story_id': str(doc['_id']),
        'bubble_label': doc.get('bubble_label', ''),
        'title': doc.get('title', ''),
        'description': doc.get('description', ''),
        'sdg_label': doc.get('sdg_label', ''),
        'sdg_name': doc.get('sdg_name', ''),
        'image_url': doc.get('image_url'),
        'created_at': created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
    }


@router.get('', response_model=list[StoryResponse])
def list_stories() -> list[StoryResponse]:
    db = get_db()
    docs = db['stories'].find().sort('created_at', 1)
    return [StoryResponse(**_doc_to_story(d)) for d in docs]


@router.post('', response_model=StoryResponse)
def create_story(payload: StoryCreate) -> StoryResponse:
    db = get_db()
    now = datetime.now(timezone.utc)
    data = {
        'bubble_label': payload.bubble_label,
        'title': payload.title,
        'description': payload.description,
        'sdg_label': payload.sdg_label,
        'sdg_name': payload.sdg_name,
        'image_url': payload.image_url,
        'created_at': now,
    }
    result = db['stories'].insert_one(data)
    data['_id'] = result.inserted_id
    return StoryResponse(**_doc_to_story(data))


@router.delete('/{story_id}')
def delete_story(story_id: str) -> dict:
    db = get_db()
    result = db['stories'].delete_one({'_id': ObjectId(story_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='Story not found')
    return {'message': 'Story deleted', 'story_id': story_id}
