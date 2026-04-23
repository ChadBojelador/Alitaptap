"""Issues API — community problem reports CRUD."""

from datetime import datetime, timezone
from enum import Enum
import re
from typing import Optional

import logging
from bson import ObjectId
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.core.mongodb import get_db
from app.services.ai_validator import get_ai_validator

router = APIRouter(prefix='/issues', tags=['issues'])
logger = logging.getLogger(__name__)


class IssueStatus(str, Enum):
    pending = 'pending'
    validated = 'validated'
    rejected = 'rejected'


class IssueCreate(BaseModel):
    reporter_id: str
    title: str
    description: str
    lat: float
    lng: float
    image_url: Optional[str] = None
    image_urls: list[str] = []
    caption: Optional[str] = None
    reporter_name: Optional[str] = None


class IssueCreateResponse(BaseModel):
    issue_id: str
    status: str
    created_at: str


class IssueListItem(BaseModel):
    issue_id: str
    reporter_id: str
    reporter_name: Optional[str] = None
    title: str
    description: str
    lat: float
    lng: float
    image_url: Optional[str] = None
    image_urls: list[str] = []
    caption: Optional[str] = None
    status: str
    tags: list[str] = []
    ai_summary: Optional[str] = None
    ai_sdg_tag: Optional[str] = None
    created_at: str


class IssueDetail(IssueListItem):
    updated_at: Optional[str] = None


class StatusUpdate(BaseModel):
    status: IssueStatus


class StatusUpdateResponse(BaseModel):
    issue_id: str
    status: str
    updated_at: str


class IssueUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    image_url: Optional[str] = None
    image_urls: Optional[list[str]] = None
    caption: Optional[str] = None


class TitleSuggestionsResponse(BaseModel):
    issue_id: str
    suggestions: list[str]
    generated_at: str


def _doc_to_issue(doc: dict) -> dict:
    image_urls = doc.get('image_urls') or []
    image_url = doc.get('image_url')
    if image_url and image_url not in image_urls:
        image_urls = [image_url, *image_urls]
    if not image_url and image_urls:
        image_url = image_urls[0]
    location = doc.get('location', {})
    created = doc.get('created_at')
    updated = doc.get('updated_at')
    return {
        'issue_id': str(doc['_id']),
        'reporter_id': doc.get('reporter_id', ''),
        'reporter_name': doc.get('reporter_name'),
        'title': doc.get('title', ''),
        'description': doc.get('description', ''),
        'lat': location.get('lat', 0.0),
        'lng': location.get('lng', 0.0),
        'image_url': image_url,
        'image_urls': image_urls,
        'caption': doc.get('caption'),
        'status': doc.get('status', 'pending'),
        'tags': doc.get('tags', []),
        'ai_summary': doc.get('ai_summary'),
        'ai_sdg_tag': doc.get('ai_sdg_tag'),
        'created_at': created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
        'updated_at': updated.isoformat() if hasattr(updated, 'isoformat') else (str(updated) if updated else None),
    }


def _build_title_suggestions(issue: dict, limit: int = 3) -> list[str]:
    title = (issue.get('title') or '').strip()
    description = (issue.get('description') or '').strip()
    tags: list[str] = issue.get('tags') or []

    if not title:
        title = 'Community Problem'

    short_title = re.sub(r'\s+', ' ', title)[:90].strip()
    context_phrase = 'Local Communities'
    if description:
        parts = re.sub(r'\s+', ' ', description).split('.')
        context_phrase = parts[0][:80].strip() or 'Local Communities'

    sdg_tag = tags[0] if tags else 'SDG-Aligned'

    candidates = [
        f'Assessing {short_title}: A Community-Based Study in {context_phrase}',
        f'Design and Evaluation of an {sdg_tag} Intervention for {short_title}',
        f'From Problem to Prototype: A Research Framework Addressing {short_title}',
        f'Evidence-Driven Strategies to Mitigate {short_title} in Urban Barangays',
        f'Participatory Approaches for Sustainable Solutions to {short_title}',
    ]

    seen: set[str] = set()
    suggestions: list[str] = []
    for c in candidates:
        if c.lower() not in seen:
            seen.add(c.lower())
            suggestions.append(c)
        if len(suggestions) >= limit:
            break
    return suggestions


@router.post('', response_model=IssueCreateResponse)
def create_issue(payload: IssueCreate) -> IssueCreateResponse:
    db = get_db()
    now = datetime.now(timezone.utc)
    validator = get_ai_validator()

    validation_result = validator.validate_and_process(
        title=payload.title,
        description=payload.description,
    )
    status = IssueStatus.validated.value if validation_result.is_valid else IssueStatus.rejected.value

    image_urls = list(dict.fromkeys(payload.image_urls or []))
    if payload.image_url and payload.image_url not in image_urls:
        image_urls = [payload.image_url, *image_urls]
    image_url = payload.image_url or (image_urls[0] if image_urls else None)

    doc_data = {
        'reporter_id': payload.reporter_id,
        'reporter_name': payload.reporter_name,
        'title': payload.title,
        'description': payload.description,
        'location': {'lat': payload.lat, 'lng': payload.lng},
        'image_url': image_url,
        'image_urls': image_urls,
        'caption': payload.caption,
        'status': status,
        'ai_summary': validation_result.ai_summary,
        'ai_sdg_tag': validation_result.auto_sdg_tag,
        'tags': [validation_result.auto_sdg_tag],
        'validation_reason': validation_result.reason,
        'created_at': now,
        'updated_at': now,
    }
    result = db['issues'].insert_one(doc_data)
    return IssueCreateResponse(
        issue_id=str(result.inserted_id),
        status=status,
        created_at=now.isoformat(),
    )


@router.get('/expo/validated', response_model=list[IssueListItem])
def get_expo_issues() -> list[IssueListItem]:
    try:
        db = get_db()
        docs = db['issues'].find({'status': IssueStatus.validated.value}).sort('created_at', -1)
        return [IssueListItem(**_doc_to_issue(d)) for d in docs]
    except Exception as e:
        logger.exception('get_expo_issues failed: %s', e)
        raise


@router.get('', response_model=list[IssueListItem])
def list_issues(
    status: Optional[IssueStatus] = Query(None, description='Filter by status'),
) -> list[IssueListItem]:
    try:
        db = get_db()
        query_filter = {'status': status.value if status else IssueStatus.validated.value}
        docs = db['issues'].find(query_filter).sort('created_at', -1)
        return [IssueListItem(**_doc_to_issue(d)) for d in docs]
    except Exception as e:
        logger.exception('list_issues failed: %s', e)
        raise


@router.get('/{issue_id}', response_model=IssueDetail)
def get_issue(issue_id: str) -> IssueDetail:
    db = get_db()
    doc = db['issues'].find_one({'_id': ObjectId(issue_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Issue not found')
    return IssueDetail(**_doc_to_issue(doc))


@router.patch('/{issue_id}/status', response_model=StatusUpdateResponse)
def update_issue_status(issue_id: str, payload: StatusUpdate) -> StatusUpdateResponse:
    db = get_db()
    now = datetime.now(timezone.utc)
    result = db['issues'].update_one(
        {'_id': ObjectId(issue_id)},
        {'$set': {'status': payload.status.value, 'updated_at': now}},
    )
    if result.matched_count == 0:
        raise HTTPException(status_code=404, detail='Issue not found')
    return StatusUpdateResponse(
        issue_id=issue_id,
        status=payload.status.value,
        updated_at=now.isoformat(),
    )


@router.get('/{issue_id}/title-suggestions', response_model=TitleSuggestionsResponse)
def get_title_suggestions(issue_id: str) -> TitleSuggestionsResponse:
    db = get_db()
    doc = db['issues'].find_one({'_id': ObjectId(issue_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Issue not found')
    suggestions = _build_title_suggestions(doc, limit=3)
    now = datetime.now(timezone.utc)
    db['title_suggestions'].insert_one({
        'issue_id': issue_id,
        'suggestions': suggestions,
        'model_version': 'heuristic-v1',
        'created_at': now,
    })
    return TitleSuggestionsResponse(
        issue_id=issue_id,
        suggestions=suggestions,
        generated_at=now.isoformat(),
    )


@router.put('/{issue_id}', response_model=IssueDetail)
def update_issue(issue_id: str, payload: IssueUpdate) -> IssueDetail:
    db = get_db()
    doc = db['issues'].find_one({'_id': ObjectId(issue_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Issue not found')
    
    update_data = {}
    if payload.title is not None:
        update_data['title'] = payload.title
    if payload.description is not None:
        update_data['description'] = payload.description
    if payload.lat is not None or payload.lng is not None:
        location = doc.get('location', {})
        if payload.lat is not None:
            location['lat'] = payload.lat
        if payload.lng is not None:
            location['lng'] = payload.lng
        update_data['location'] = location
    if payload.image_url is not None:
        update_data['image_url'] = payload.image_url
    if payload.image_urls is not None:
        update_data['image_urls'] = payload.image_urls
    if payload.caption is not None:
        update_data['caption'] = payload.caption
    
    if update_data:
        update_data['updated_at'] = datetime.now(timezone.utc)
        db['issues'].update_one(
            {'_id': ObjectId(issue_id)},
            {'$set': update_data}
        )
        doc = db['issues'].find_one({'_id': ObjectId(issue_id)})
    
    return IssueDetail(**_doc_to_issue(doc))


@router.delete('/{issue_id}')
def delete_issue(issue_id: str) -> dict:
    db = get_db()
    result = db['issues'].delete_one({'_id': ObjectId(issue_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='Issue not found')
    return {'message': 'Issue deleted successfully', 'issue_id': issue_id}
