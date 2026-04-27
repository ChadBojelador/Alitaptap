"""Research Posts API — Innovation Funding Expo."""

import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from bson import ObjectId
from bson.errors import InvalidId
from fastapi import APIRouter, HTTPException, UploadFile, File, Request
from pydantic import BaseModel
from app.core.mongodb import get_db
from app.core.config import settings

router = APIRouter(prefix='/posts', tags=['posts'])

_UPLOAD_DIR = Path(__file__).parent.parent.parent.parent / "uploads"
_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

_ALLOWED_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.gif', '.webp'}


def _parse_object_id(id_str: str) -> ObjectId:
    try:
        return ObjectId(id_str)
    except (InvalidId, Exception):
        raise HTTPException(status_code=400, detail='Invalid ID format')


@router.post('/upload')
async def upload_image(request: Request, file: UploadFile = File(...)):
    """Upload an image and return its URL."""
    try:
        original_name = file.filename or 'upload'
        ext = Path(original_name).suffix.lower()
        if ext not in _ALLOWED_EXTENSIONS:
            raise HTTPException(status_code=400, detail='Invalid file type. Only jpg, jpeg, png, gif, webp are allowed.')

        # Use only a UUID as filename — never trust user-supplied name
        filename = f"{uuid.uuid4()}{ext}"
        filepath = _UPLOAD_DIR / filename

        with open(filepath, "wb") as buffer:
            content = await file.read()
            buffer.write(content)

        base_url = str(request.base_url).rstrip('/')
        image_url = f"{base_url}/uploads/{filename}"

        return {"image_url": image_url}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Upload failed: {str(e)}")


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


def _doc_to_post(doc: dict) -> dict:
    image_urls = doc.get('image_urls') or []
    image_url = doc.get('image_url')
    if image_url and image_url not in image_urls:
        image_urls = [image_url, *image_urls]
    if not image_url and image_urls:
        image_url = image_urls[0]
    created = doc.get('created_at')
    return {
        'post_id': str(doc['_id']),
        'author_id': doc.get('author_id', ''),
        'author_email': doc.get('author_email', ''),
        'title': doc.get('title', ''),
        'abstract': doc.get('abstract', ''),
        'problem_solved': doc.get('problem_solved', ''),
        'image_url': image_url,
        'image_urls': image_urls,
        'caption': doc.get('caption'),
        'sdg_tags': doc.get('sdg_tags', []),
        'funding_goal': doc.get('funding_goal', 0.0),
        'funding_raised': doc.get('funding_raised', 0.0),
        'likes': doc.get('likes', 0),
        'liked_by': doc.get('liked_by', []),
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
    result = db['research_posts'].insert_one(data)
    data['_id'] = result.inserted_id
    return PostResponse(**_doc_to_post(data))


@router.get('', response_model=list[PostResponse])
def list_posts() -> list[PostResponse]:
    db = get_db()
    docs = db['research_posts'].find().sort('created_at', -1)
    return [PostResponse(**_doc_to_post(d)) for d in docs]


@router.post('/{post_id}/like', response_model=PostResponse)
def toggle_like(post_id: str, payload: LikeRequest) -> PostResponse:
    db = get_db()
    doc = db['research_posts'].find_one({'_id': _parse_object_id(post_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Post not found')
    liked_by: list = doc.get('liked_by', [])
    if payload.user_id in liked_by:
        liked_by.remove(payload.user_id)
    else:
        liked_by.append(payload.user_id)
    db['research_posts'].update_one(
        {'_id': ObjectId(post_id)},
        {'$set': {'liked_by': liked_by, 'likes': len(liked_by)}},
    )
    doc['liked_by'] = liked_by
    doc['likes'] = len(liked_by)
    return PostResponse(**_doc_to_post(doc))


@router.post('/{post_id}/fund', response_model=PostResponse)
def fund_post(post_id: str, payload: FundRequest) -> PostResponse:
    db = get_db()
    doc = db['research_posts'].find_one({'_id': _parse_object_id(post_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Post not found')
    new_raised = doc.get('funding_raised', 0.0) + payload.amount
    db['research_posts'].update_one(
        {'_id': ObjectId(post_id)},
        {'$set': {'funding_raised': new_raised}},
    )
    db['funding_transactions'].insert_one({
        'post_id': post_id,
        'user_id': payload.user_id,
        'amount': payload.amount,
        'created_at': datetime.now(timezone.utc),
    })
    doc['funding_raised'] = new_raised
    return PostResponse(**_doc_to_post(doc))


@router.post('/{post_id}/comments', response_model=CommentResponse)
def add_comment(post_id: str, payload: CommentCreate) -> CommentResponse:
    db = get_db()
    if not db['research_posts'].find_one({'_id': _parse_object_id(post_id)}):
        raise HTTPException(status_code=404, detail='Post not found')
    now = datetime.now(timezone.utc)
    data = {
        'post_id': post_id,
        'author_id': payload.author_id,
        'author_email': payload.author_email,
        'text': payload.text,
        'created_at': now,
    }
    result = db['post_comments'].insert_one(data)
    return CommentResponse(
        comment_id=str(result.inserted_id),
        author_id=payload.author_id,
        author_email=payload.author_email,
        text=payload.text,
        created_at=now.isoformat(),
    )


@router.get('/{post_id}/comments', response_model=list[CommentResponse])
def get_comments(post_id: str) -> list[CommentResponse]:
    _parse_object_id(post_id)  # validate format
    db = get_db()
    docs = db['post_comments'].find({'post_id': post_id}).sort('created_at', -1)
    result = []
    for d in docs:
        created = d.get('created_at')
        result.append(CommentResponse(
            comment_id=str(d['_id']),
            author_id=d.get('author_id', ''),
            author_email=d.get('author_email', ''),
            text=d.get('text', ''),
            created_at=created.isoformat() if hasattr(created, 'isoformat') else str(created or ''),
        ))
    return result


class PostUpdate(BaseModel):
    title: Optional[str] = None
    abstract: Optional[str] = None
    problem_solved: Optional[str] = None
    image_url: Optional[str] = None
    image_urls: Optional[list[str]] = None
    caption: Optional[str] = None
    sdg_tags: Optional[list[str]] = None
    funding_goal: Optional[float] = None


@router.get('/{post_id}', response_model=PostResponse)
def get_post(post_id: str) -> PostResponse:
    db = get_db()
    doc = db['research_posts'].find_one({'_id': _parse_object_id(post_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Post not found')
    return PostResponse(**_doc_to_post(doc))


@router.put('/{post_id}', response_model=PostResponse)
def update_post(post_id: str, payload: PostUpdate) -> PostResponse:
    db = get_db()
    doc = db['research_posts'].find_one({'_id': _parse_object_id(post_id)})
    if not doc:
        raise HTTPException(status_code=404, detail='Post not found')
    
    update_data = {}
    if payload.title is not None:
        update_data['title'] = payload.title
    if payload.abstract is not None:
        update_data['abstract'] = payload.abstract
    if payload.problem_solved is not None:
        update_data['problem_solved'] = payload.problem_solved
    if payload.image_url is not None:
        update_data['image_url'] = payload.image_url
    if payload.image_urls is not None:
        update_data['image_urls'] = payload.image_urls
    if payload.caption is not None:
        update_data['caption'] = payload.caption
    if payload.sdg_tags is not None:
        update_data['sdg_tags'] = payload.sdg_tags
    if payload.funding_goal is not None:
        update_data['funding_goal'] = payload.funding_goal
    
    oid = _parse_object_id(post_id)
    if update_data:
        db['research_posts'].update_one({'_id': oid}, {'$set': update_data})
        doc = db['research_posts'].find_one({'_id': oid})

    return PostResponse(**_doc_to_post(doc))


@router.delete('/{post_id}')
def delete_post(post_id: str) -> dict:
    db = get_db()
    result = db['research_posts'].delete_one({'_id': _parse_object_id(post_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail='Post not found')
    
    # Also delete associated comments
    db['post_comments'].delete_many({'post_id': post_id})
    
    return {'message': 'Post deleted successfully', 'post_id': post_id}
