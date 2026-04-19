# API Service (FastAPI) - M4 Ready

## Included
- App factory and versioned router (`/api/v1`)
- Health endpoint (`GET /health`)
- Role endpoint (`POST /auth/role`)
- Civic Intelligence issue endpoints (`POST/GET /issues`, `GET /issues/{id}`, `PATCH /issues/{id}/status`)
- Neural Mapper endpoint (`POST /mapper/match`) with ranked semantic matching
- Title Suggestions endpoint (`GET /issues/{issue_id}/title-suggestions`)

## Neural Mapper Notes
- Uses `sentence-transformers/all-MiniLM-L6-v2` by default.
- Matches only issues with `status = validated`.
- Persists each mapper run to Firestore `mapper_runs`.
- Returns `run_id` plus ranked `matches` (with `issue_id`, `score`, `reason`).

## Title Suggestions Notes
- Generates at least 3 research title suggestions per request.
- Persists each generation to Firestore `title_suggestions`.
- Returns `issue_id`, `suggestions`, and `generated_at`.

## Run (after Python setup)
1. Install dependencies: `pip install -r requirements.txt`
2. Start API: `uvicorn app.main:app --reload --port 8000`
3. Open docs: `http://127.0.0.1:8000/docs`
