# API Contracts (v1)

## POST /api/v1/auth/role
Set or update a user's role.

Request
- `user_id`: string (required)
- `role`: `community` | `student` | `admin` (required)

Response
- `user_id`: string
- `role`: string

---

## GET /api/v1/health
Health check.

Response
- `status`: `ok`

---

## POST /api/v1/issues
Create a community problem report.

Request
- `reporter_id`: string (required)
- `title`: string (required)
- `description`: string (required)
- `lat`: number (required)
- `lng`: number (required)
- `image_url`: string | null (optional)
- `image_urls`: string[] (optional)

Response
- `issue_id`: string
- `status`: `pending`
- `created_at`: string (ISO 8601)

---

## GET /api/v1/issues
List issues with optional status filter.

Query Parameters
- `status`: `pending` | `validated` | `rejected` (optional, defaults to all)

Response (array)
- `issue_id`: string
- `reporter_id`: string
- `title`: string
- `description`: string
- `lat`: number
- `lng`: number
- `image_url`: string | null
- `image_urls`: string[]
- `status`: string
- `tags`: string[]
- `created_at`: string

---

## GET /api/v1/issues/{issue_id}
Get a single issue by ID.

Response
- `issue_id`: string
- `reporter_id`: string
- `title`: string
- `description`: string
- `lat`: number
- `lng`: number
- `image_url`: string | null
- `image_urls`: string[]
- `status`: string
- `tags`: string[]
- `created_at`: string
- `updated_at`: string | null

---

## PATCH /api/v1/issues/{issue_id}/status
Admin validate or reject an issue.

Request
- `status`: `validated` | `rejected` (required)

Response
- `issue_id`: string
- `status`: string
- `updated_at`: string (ISO 8601)

---

## POST /api/v1/mapper/match
Match a student idea to mapped problems.

Request
- `student_id`: string (required)
- `idea_text`: string (required)
- `max_results`: number (optional, default 5)

Response
- `run_id`: string
- `matches`: array of
  - `issue_id`: string
  - `score`: number
  - `reason`: string

---

## GET /api/v1/issues/{issue_id}/title-suggestions
Get research title suggestions for a selected problem.

Response
- `issue_id`: string
- `suggestions`: string[]
- `generated_at`: string
