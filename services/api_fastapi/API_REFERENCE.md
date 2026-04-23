# Quick Reference - CRUD Endpoints

## Issues CRUD (Community Reports)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/issues` | Create new issue |
| GET | `/api/v1/issues` | List all issues (with optional status filter) |
| GET | `/api/v1/issues/{issue_id}` | Get single issue |
| PUT | `/api/v1/issues/{issue_id}` | Update issue |
| DELETE | `/api/v1/issues/{issue_id}` | Delete issue |
| PATCH | `/api/v1/issues/{issue_id}/status` | Update issue status |
| GET | `/api/v1/issues/{issue_id}/title-suggestions` | Get AI title suggestions |
| GET | `/api/v1/issues/expo/validated` | Get validated issues for expo |

## Research Posts CRUD (Innovation Funding)

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/posts` | Create new research post |
| GET | `/api/v1/posts` | List all posts |
| GET | `/api/v1/posts/{post_id}` | Get single post |
| PUT | `/api/v1/posts/{post_id}` | Update post |
| DELETE | `/api/v1/posts/{post_id}` | Delete post |
| POST | `/api/v1/posts/{post_id}/like` | Toggle like on post |
| POST | `/api/v1/posts/{post_id}/fund` | Fund a post |
| POST | `/api/v1/posts/{post_id}/comments` | Add comment |
| GET | `/api/v1/posts/{post_id}/comments` | Get comments |

## Example Requests

### Create Issue
```json
POST /api/v1/issues
{
  "reporter_id": "user_123",
  "reporter_name": "John Doe",
  "title": "Road Damage",
  "description": "Potholes on main street",
  "lat": 14.5995,
  "lng": 120.9842
}
```

### Update Issue
```json
PUT /api/v1/issues/{issue_id}
{
  "title": "Updated Title",
  "description": "Updated description"
}
```

### Create Research Post
```json
POST /api/v1/posts
{
  "author_id": "researcher_123",
  "author_email": "researcher@example.com",
  "title": "Smart Flood Detection System",
  "abstract": "IoT-based flood monitoring",
  "problem_solved": "Early flood warning",
  "sdg_tags": ["SDG 11"],
  "funding_goal": 50000.0
}
```

### Update Research Post
```json
PUT /api/v1/posts/{post_id}
{
  "title": "Updated Research Title",
  "funding_goal": 75000.0
}
```

## Status Codes

- `200` - Success
- `201` - Created
- `404` - Not Found
- `422` - Validation Error
- `500` - Server Error

## MongoDB Collections

- `issues` - Community problem reports
- `research_posts` - Research posts for funding
- `post_comments` - Comments on posts
- `funding_transactions` - Funding records
- `title_suggestions` - AI-generated suggestions
