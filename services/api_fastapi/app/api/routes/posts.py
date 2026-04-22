"""Research Posts API — Innovation Funding Expo."""

from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.core.firebase import get_db

router = APIRouter(prefix='/posts', tags=['posts'])


class PostCreate(BaseModel):
    author_id: str
    author_email: str
    title: str
    abstract: str
    problem_solved: str
    image_url: Optional[str] = None
    image_urls: list[str] = []
    caption: Optional[str] = None
    sdg_tags: list[str] = []
    funding_goal: float = 0.0


class PostResponse(BaseModel):
    post_id: str
    author_id: str
    author_email: str
    title: str
    abstract: str
    problem_solved: str
    image_url: Optional[str] = None
    image_urls: list[str]
    caption: Optional[str] = None
    sdg_tags: list[str]
    funding_goal: float
    funding_raised: float
    likes: int
    liked_by: list[str]
    created_at: str


class LikeRequest(BaseModel):
    user_id: str


class FundRequest(BaseModel):
    user_id: str
    amount: float


class CommentCreate(BaseModel):
    author_id: str
    author_email: str
    text: str


class CommentResponse(BaseModel):
    comment_id: str
    author_id: str
    author_email: str
    text: str
    created_at: str


def _doc_to_post(doc_id: str, data: dict) -> dict:
    created = data.get('created_at')
    image_urls = data.get('image_urls') or []
    image_url = data.get('image_url')
    if image_url and image_url not in image_urls:
        image_urls = [image_url, *image_urls]
    if not image_url and image_urls:
        image_url = image_urls[0]
    return {
        'post_id': doc_id,
        'author_id': data.get('author_id', ''),
        'author_email': data.get('author_email', ''),
        'title': data.get('title', ''),
        'abstract': data.get('abstract', ''),
        'problem_solved': data.get('problem_solved', ''),
        'image_url': image_url,
        'image_urls': image_urls,
        'caption': data.get('caption'),
        'sdg_tags': data.get('sdg_tags', []),
        'funding_goal': data.get('funding_goal', 0.0),
        'funding_raised': data.get('funding_raised', 0.0),
        'likes': data.get('likes', 0),
        'liked_by': data.get('liked_by', []),
        'created_at': created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
    }


@router.post('', response_model=PostResponse)
def create_post(payload: PostCreate) -> PostResponse:
    db = get_db()
    now = datetime.now(timezone.utc)
    image_urls = list(dict.fromkeys(payload.image_urls or []))
    if payload.image_url and payload.image_url not in image_urls:
        image_urls = [payload.image_url, *image_urls]
    image_url = payload.image_url or (image_urls[0] if image_urls else None)

    data = {
        'author_id': payload.author_id,
        'author_email': payload.author_email,
        'title': payload.title,
        'abstract': payload.abstract,
        'problem_solved': payload.problem_solved,
        'image_url': image_url,
        'image_urls': image_urls,
        'caption': payload.caption,
        'sdg_tags': payload.sdg_tags,
        'funding_goal': payload.funding_goal,
        'funding_raised': 0.0,
        'likes': 0,
        'liked_by': [],
        'created_at': now,
    }
    _, ref = db.collection('research_posts').add(data)
    return PostResponse(**_doc_to_post(ref.id, data))


@router.get('', response_model=list[PostResponse])
def list_posts() -> list[PostResponse]:
    db = get_db()
    docs = db.collection('research_posts').order_by(
        'created_at', direction='DESCENDING'
    ).stream()
    return [PostResponse(**_doc_to_post(d.id, d.to_dict())) for d in docs]


@router.post('/{post_id}/like', response_model=PostResponse)
def toggle_like(post_id: str, payload: LikeRequest) -> PostResponse:
    db = get_db()
    ref = db.collection('research_posts').document(post_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail='Post not found')
    data = doc.to_dict()
    liked_by: list = data.get('liked_by', [])
    if payload.user_id in liked_by:
        liked_by.remove(payload.user_id)
    else:
        liked_by.append(payload.user_id)
    ref.update({'liked_by': liked_by, 'likes': len(liked_by)})
    data['liked_by'] = liked_by
    data['likes'] = len(liked_by)
    return PostResponse(**_doc_to_post(post_id, data))


@router.post('/{post_id}/fund', response_model=PostResponse)
def fund_post(post_id: str, payload: FundRequest) -> PostResponse:
    db = get_db()
    ref = db.collection('research_posts').document(post_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail='Post not found')
    data = doc.to_dict()
    new_raised = data.get('funding_raised', 0.0) + payload.amount
    ref.update({'funding_raised': new_raised})
    # Log the funding transaction
    db.collection('funding_transactions').add({
        'post_id': post_id,
        'user_id': payload.user_id,
        'amount': payload.amount,
        'created_at': datetime.now(timezone.utc),
    })
    data['funding_raised'] = new_raised
    return PostResponse(**_doc_to_post(post_id, data))


@router.post('/{post_id}/comments', response_model=CommentResponse)
def add_comment(post_id: str, payload: CommentCreate) -> CommentResponse:
    db = get_db()
    if not db.collection('research_posts').document(post_id).get().exists:
        raise HTTPException(status_code=404, detail='Post not found')
    now = datetime.now(timezone.utc)
    data = {
        'author_id': payload.author_id,
        'author_email': payload.author_email,
        'text': payload.text,
        'created_at': now,
    }
    _, ref = db.collection('research_posts').document(post_id).collection('comments').add(data)
    return CommentResponse(
        comment_id=ref.id,
        author_id=payload.author_id,
        author_email=payload.author_email,
        text=payload.text,
        created_at=now.isoformat(),
    )


@router.get('/{post_id}/comments', response_model=list[CommentResponse])
def get_comments(post_id: str) -> list[CommentResponse]:
    db = get_db()
    docs = db.collection('research_posts').document(post_id).collection('comments').stream()
    result = []
    for d in docs:
        data = d.to_dict()
        created = data.get('created_at')
        result.append(CommentResponse(
            comment_id=d.id,
            author_id=data.get('author_id', ''),
            author_email=data.get('author_email', ''),
            text=data.get('text', ''),
            created_at=created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
        ))
    return result
