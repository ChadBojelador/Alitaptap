# Domain Model (MVP)

## Collections

### users
- `id`
- `role` (`community`, `student`, `admin`)
- `display_name`
- `created_at`

### issues
- `id`
- `reporter_id`
- `title`
- `description`
- `location.lat`
- `location.lng`
- `image_url`
- `status` (`pending`, `validated`, `rejected`)
- `created_at`
- `updated_at`

### mapper_runs
- `id`
- `student_id`
- `idea_text`
- `matches` (array of `{ issue_id, score, reason }`)
- `created_at`

### title_suggestions
- `id`
- `issue_id`
- `suggestions` (string[])
- `model_version`
- `created_at`

## Relationships
- One `user` can create many `issues`.
- One `student` can create many `mapper_runs`.
- One `issue` can have many `title_suggestions` versions.
