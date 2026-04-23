# MongoDB CRUD Operations - Complete Implementation

## Overview
The Alitaptap API now has **full CRUD operations** using **MongoDB** instead of Firebase.

## Collections Used
- `issues` - Community problem reports
- `research_posts` - Innovation funding expo posts
- `post_comments` - Comments on research posts
- `funding_transactions` - Funding transactions
- `title_suggestions` - AI-generated title suggestions

## Issues API - Full CRUD

### CREATE - Post New Issue
```http
POST /api/v1/issues
Content-Type: application/json

{
  "reporter_id": "user_123",
  "reporter_name": "John Doe",
  "title": "Flooding in Market Street",
  "description": "Heavy flooding during rain",
  "lat": 14.5995,
  "lng": 120.9842,
  "image_urls": ["http://example.com/image.jpg"],
  "caption": "Flood damage"
}
```

### READ - Get Single Issue
```http
GET /api/v1/issues/{issue_id}
```

### READ - List All Issues
```http
GET /api/v1/issues
GET /api/v1/issues?status=validated
GET /api/v1/issues?status=pending
```

### UPDATE - Update Issue
```http
PUT /api/v1/issues/{issue_id}
Content-Type: application/json

{
  "title": "Updated Title",
  "description": "Updated description",
  "lat": 14.6000,
  "lng": 120.9850,
  "caption": "Updated caption"
}
```

### DELETE - Delete Issue
```http
DELETE /api/v1/issues/{issue_id}
```

### PATCH - Update Status
```http
PATCH /api/v1/issues/{issue_id}/status
Content-Type: application/json

{
  "status": "validated"
}
```

## Research Posts API - Full CRUD

### CREATE - Post New Research
```http
POST /api/v1/posts
Content-Type: application/json

{
  "author_id": "researcher_123",
  "author_email": "researcher@example.com",
  "title": "Research Title",
  "abstract": "Research abstract",
  "problem_solved": "Problem description",
  "sdg_tags": ["SDG 11"],
  "funding_goal": 50000.0
}
```

### READ - Get Single Post
```http
GET /api/v1/posts/{post_id}
```

### READ - List All Posts
```http
GET /api/v1/posts
```

### UPDATE - Update Post
```http
PUT /api/v1/posts/{post_id}
Content-Type: application/json

{
  "title": "Updated Title",
  "abstract": "Updated abstract",
  "funding_goal": 75000.0
}
```

### DELETE - Delete Post
```http
DELETE /api/v1/posts/{post_id}
```

### Additional Post Operations
```http
POST /api/v1/posts/{post_id}/like
POST /api/v1/posts/{post_id}/fund
POST /api/v1/posts/{post_id}/comments
GET /api/v1/posts/{post_id}/comments
```

## MongoDB Configuration

### Connection String
Set in `.env` file:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/?appName=Cluster0
MONGODB_DB_NAME=alitaptap
```

### Local Development
For local MongoDB:
```env
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=alitaptap
```

## Testing CRUD Operations

### Run the test script:
```bash
cd services/api_fastapi
python test_crud.py
```

### Manual testing with curl:

**Create:**
```bash
curl -X POST http://localhost:8000/api/v1/issues \
  -H "Content-Type: application/json" \
  -d '{"reporter_id":"test","title":"Test","description":"Test issue","lat":14.5,"lng":120.9}'
```

**Read:**
```bash
curl http://localhost:8000/api/v1/issues/{issue_id}
```

**Update:**
```bash
curl -X PUT http://localhost:8000/api/v1/issues/{issue_id} \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Title"}'
```

**Delete:**
```bash
curl -X DELETE http://localhost:8000/api/v1/issues/{issue_id}
```

## Database Schema

### Issues Collection
```json
{
  "_id": ObjectId,
  "reporter_id": "string",
  "reporter_name": "string",
  "title": "string",
  "description": "string",
  "location": {
    "lat": 14.5995,
    "lng": 120.9842
  },
  "image_url": "string",
  "image_urls": ["string"],
  "caption": "string",
  "status": "validated|pending|rejected",
  "tags": ["string"],
  "ai_summary": "string",
  "ai_sdg_tag": "string",
  "validation_reason": "string",
  "created_at": ISODate,
  "updated_at": ISODate
}
```

### Research Posts Collection
```json
{
  "_id": ObjectId,
  "author_id": "string",
  "author_email": "string",
  "title": "string",
  "abstract": "string",
  "problem_solved": "string",
  "image_url": "string",
  "image_urls": ["string"],
  "caption": "string",
  "sdg_tags": ["string"],
  "funding_goal": 0.0,
  "funding_raised": 0.0,
  "likes": 0,
  "liked_by": ["string"],
  "created_at": ISODate
}
```

## Running the API

```bash
cd services/api_fastapi
uvicorn app.main:app --reload --port 8000
```

API will be available at: http://localhost:8000
API docs: http://localhost:8000/docs

## Summary

✅ **CREATE** - POST endpoints for issues and posts
✅ **READ** - GET endpoints for single items and lists
✅ **UPDATE** - PUT endpoints for full updates
✅ **DELETE** - DELETE endpoints for removal
✅ **MongoDB** - Fully integrated, Firebase removed
✅ **Validation** - AI validation on create
✅ **Status Management** - PATCH endpoint for status updates
