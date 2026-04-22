# Domain Model (MVP)

> **Schema Status: LOCKED for M4** — Do not add or rename fields without updating this doc and api-contracts.md first.

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
- `image_urls` (string[] — optional gallery, first item should match `image_url`)
- `status` (`pending`, `validated`, `rejected`)
- `tags` (string[] — for SDG tagging in M3, default empty)
- `created_at`
- `updated_at`

### research_posts
- `id`
- `author_id`
- `author_email`
- `title`
- `abstract`
- `problem_solved`
- `image_url`
- `image_urls` (string[] — optional gallery, first item should match `image_url`)
- `sdg_tags` (string[])
- `funding_goal`
- `funding_raised`
- `likes`
- `liked_by` (string[])
- `created_at`

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
