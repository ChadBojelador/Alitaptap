"""Issues API — community problem reports CRUD."""

from datetime import datetime, timezone
from enum import Enum
import re
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel

from app.core.firebase import get_db

router = APIRouter(prefix='/issues', tags=['issues'])


# ---------------------------------------------------------------------------
# Pydantic schemas
# ---------------------------------------------------------------------------

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


class IssueCreateResponse(BaseModel):
    issue_id: str
    status: str
    created_at: str


class IssueListItem(BaseModel):
    issue_id: str
    reporter_id: str
    title: str
    description: str
    lat: float
    lng: float
    image_url: Optional[str] = None
    status: str
    tags: list[str] = []
    created_at: str


class IssueDetail(IssueListItem):
    updated_at: Optional[str] = None


class StatusUpdate(BaseModel):
    status: IssueStatus


class StatusUpdateResponse(BaseModel):
    issue_id: str
    status: str
    updated_at: str


class TitleSuggestionsResponse(BaseModel):
    issue_id: str
    suggestions: list[str]
    generated_at: str


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _doc_to_issue(doc_id: str, data: dict) -> dict:
    """Convert a Firestore document dict to a flat issue dict."""
    location = data.get('location', {})
    created = data.get('created_at')
    updated = data.get('updated_at')
    return {
        'issue_id': doc_id,
        'reporter_id': data.get('reporter_id', ''),
        'title': data.get('title', ''),
        'description': data.get('description', ''),
        'lat': location.get('lat', 0.0),
        'lng': location.get('lng', 0.0),
        'image_url': data.get('image_url'),
        'status': data.get('status', 'pending'),
        'tags': data.get('tags', []),
        'created_at': created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
        'updated_at': updated.isoformat() if hasattr(updated, 'isoformat') else (str(updated) if updated else None),
    }


def _build_title_suggestions(issue: dict, limit: int = 3) -> list[str]:
    """Generate concise research title suggestions from issue details."""
    title = (issue.get('title') or '').strip()
    description = (issue.get('description') or '').strip()
    tags: list[str] = issue.get('tags') or []

    if not title:
        title = 'Community Problem'

    short_title = re.sub(r'\s+', ' ', title)
    short_title = short_title[:90].strip()

    context_phrase = 'Local Communities'
    if description:
        context_phrase = re.sub(r'\s+', ' ', description).split('.')
        context_phrase = context_phrase[0][:80].strip() or 'Local Communities'

    sdg_tag = tags[0] if tags else 'SDG-Aligned'

    candidates = [
        f'Assessing {short_title}: A Community-Based Study in {context_phrase}',
        f'Design and Evaluation of an {sdg_tag} Intervention for {short_title}',
        f'From Problem to Prototype: A Research Framework Addressing {short_title}',
        f'Evidence-Driven Strategies to Mitigate {short_title} in Urban Barangays',
        f'Participatory Approaches for Sustainable Solutions to {short_title}',
    ]

    # Keep original order while removing duplicates.
    seen: set[str] = set()
    suggestions: list[str] = []
    for candidate in candidates:
        key = candidate.lower()
        if key in seen:
            continue
        seen.add(key)
        suggestions.append(candidate)
        if len(suggestions) >= limit:
            break

    return suggestions


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@router.post('', response_model=IssueCreateResponse)
def create_issue(payload: IssueCreate) -> IssueCreateResponse:
    """Create a new community problem report. Status defaults to pending."""
    db = get_db()
    now = datetime.now(timezone.utc)

    doc_data = {
        'reporter_id': payload.reporter_id,
        'title': payload.title,
        'description': payload.description,
        'location': {
            'lat': payload.lat,
            'lng': payload.lng,
        },
        'image_url': payload.image_url,
        'status': IssueStatus.pending.value,
        'tags': [],
        'created_at': now,
        'updated_at': None,
    }

    _, doc_ref = db.collection('issues').add(doc_data)

    return IssueCreateResponse(
        issue_id=doc_ref.id,
        status=IssueStatus.pending.value,
        created_at=now.isoformat(),
    )


@router.get('', response_model=list[IssueListItem])
def list_issues(
    status: Optional[IssueStatus] = Query(None, description='Filter by status'),
) -> list[IssueListItem]:
    """List issues, optionally filtered by status."""
    db = get_db()
    query = db.collection('issues')

    if status is not None:
        query = query.where('status', '==', status.value)

    query = query.order_by('created_at', direction='DESCENDING')
    docs = query.stream()

    items = []
    for doc in docs:
        data = doc.to_dict()
        items.append(IssueListItem(**_doc_to_issue(doc.id, data)))
    return items


@router.get('/{issue_id}', response_model=IssueDetail)
def get_issue(issue_id: str) -> IssueDetail:
    """Get a single issue by ID."""
    db = get_db()
    doc = db.collection('issues').document(issue_id).get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail='Issue not found')

    return IssueDetail(**_doc_to_issue(doc.id, doc.to_dict()))


@router.patch('/{issue_id}/status', response_model=StatusUpdateResponse)
def update_issue_status(issue_id: str, payload: StatusUpdate) -> StatusUpdateResponse:
    """Admin: validate or reject an issue."""
    db = get_db()
    doc_ref = db.collection('issues').document(issue_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(status_code=404, detail='Issue not found')

    now = datetime.now(timezone.utc)
    doc_ref.update({
        'status': payload.status.value,
        'updated_at': now,
    })

    return StatusUpdateResponse(
        issue_id=issue_id,
        status=payload.status.value,
        updated_at=now.isoformat(),
    )


@router.get('/{issue_id}/title-suggestions', response_model=TitleSuggestionsResponse)
def get_title_suggestions(issue_id: str) -> TitleSuggestionsResponse:
    """Generate and persist research title suggestions for an issue."""
    db = get_db()
    issue_doc = db.collection('issues').document(issue_id).get()

    if not issue_doc.exists:
        raise HTTPException(status_code=404, detail='Issue not found')

    issue_data = issue_doc.to_dict() or {}
    suggestions = _build_title_suggestions(issue_data, limit=3)
    now = datetime.now(timezone.utc)

    db.collection('title_suggestions').add({
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
