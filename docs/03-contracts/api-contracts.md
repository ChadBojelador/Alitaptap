# API Contracts (v1)

## POST /api/v1/issues
Create a community problem report.

Request
- `reporter_id`: string
- `title`: string
- `description`: string
- `lat`: number
- `lng`: number
- `image_url`: string | null

Response
- `issue_id`: string
- `status`: `pending` | `validated` | `rejected`
- `created_at`: string

## GET /api/v1/issues?status=validated
List map-ready issues.

Response item
- `issue_id`: string
- `title`: string
- `lat`: number
- `lng`: number
- `tags`: string[]

## POST /api/v1/mapper/match
Match a student idea to mapped problems.

Request
- `student_id`: string
- `idea_text`: string
- `max_results`: number

Response
- `matches`: array of
  - `issue_id`: string
  - `score`: number
  - `reason`: string

## GET /api/v1/issues/{issue_id}/title-suggestions
Get research title suggestions for a selected problem.

Response
- `issue_id`: string
- `suggestions`: string[]
- `generated_at`: string
