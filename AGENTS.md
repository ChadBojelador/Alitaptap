# AGENTS.md — ALITAPTAP

> Instructions for AI coding agents working in this repository.
> Read this file in full before writing any code.

---

## 1 · Project Overview

**ALITAPTAP** is a social-impact platform that bridges community-reported problems with student-driven academic research, aligned to the UN Sustainable Development Goals (SDGs).

### Core Loop

```
Community reports local problem (with geolocation)
  → Problem pinned on a live map
    → Student enters a research idea
      → System semantically matches idea to mapped problems
        → Student selects a match
          → AI generates research title suggestions for that problem
```

### Key Feature Modules

| Module                     | Purpose                                                                 |
|----------------------------|-------------------------------------------------------------------------|
| **Civic Intelligence**     | Community problem intake, admin validation, map pin visualization       |
| **SDG Neural Mapper**      | Semantic matching of student ideas → community problems → SDG alignment |
| **Impact Prediction Engine** | Forecasts social, environmental, economic impact of proposed solutions |
| **Innovation Funding Expo** | Project showcase, ratings, feedback, donations                         |

### User Roles

| Role         | Capabilities                                           |
|-------------|-------------------------------------------------------|
| `community` | Submit local problems with location data               |
| `student`   | Submit research ideas, browse matched problems         |
| `admin`     | Validate/reject community reports, manage platform     |

Role defaults to `student` if unassigned. Stored in Firestore `users/{uid}.role`.

---

## 2 · Repository Structure

```
Alitaptap/
├── apps/
│   └── mobile_flutter/          # Flutter mobile app (Android/iOS)
│       └── lib/
│           ├── main.dart         # Entry point, Firebase init
│           ├── app/
│           │   └── app.dart      # Root widget, role-based routing
│           ├── core/
│           │   └── models/       # Shared domain models (AppRole, etc.)
│           ├── features/
│           │   ├── auth/         # Authentication screens
│           │   └── home/         # Role-specific home pages
│           └── services/
│               └── auth_service.dart   # Firebase Auth + Firestore role lookup
│
├── services/
│   └── api_fastapi/             # FastAPI backend service
│       ├── app/
│       │   ├── main.py           # App factory
│       │   ├── api/
│       │   │   ├── router.py     # Versioned router (/api/v1)
│       │   │   └── routes/
│       │   │       ├── auth.py       # POST /auth/role
│       │   │       ├── health.py     # GET /health
│       │   │       ├── issues.py     # POST /issues
│       │   │       └── mapper.py     # POST /mapper/match
│       │   └── core/
│       │       └── config.py     # Pydantic settings (.env)
│       ├── requirements.txt
│       └── .env.example
│
├── docs/                        # Planning & architecture docs
│   ├── 00-governance/           # Auth model, Firebase setup
│   ├── 01-tracking/             # Roadmap, tracking board, checklists
│   ├── 02-architecture/         # System context diagrams
│   ├── 03-contracts/            # API contract specs
│   ├── 04-data-model/           # Firestore domain model
│   └── 05-product/              # MVP scope
│
├── readme.md
└── AGENTS.md                    # ← You are here
```

---

## 3 · Tech Stack

| Layer            | Technology                                         |
|------------------|----------------------------------------------------|
| **Mobile App**   | Flutter (Dart) — Android & iOS                     |
| **Backend API**  | FastAPI (Python 3.12+)                             |
| **Database**     | Firebase Firestore (real-time), Realtime Database  |
| **Auth**         | Firebase Auth (anonymous for prototype)            |
| **Storage**      | Firebase Storage                                   |
| **AI/ML**        | OpenAI API / open-source LLMs, Sentence Transformers, scikit-learn |
| **Maps**         | Mapbox (preferred) or Google Maps                  |
| **Payments**     | Stripe API (future, out of MVP scope)              |
| **Deployment**   | Render or Railway (backend), Firebase (data/auth)  |

---

## 4 · Architecture & Conventions

### 4.1 Flutter App (`apps/mobile_flutter/`)

- **Layer boundaries** — Follow `UI → application → domain → adapters`. Do not import adapter code directly from UI widgets.
- **Feature-first organization** — Each feature lives in `lib/features/<feature_name>/` with sub-folders:
  - `presentation/` — Pages, widgets
  - `application/` — Use cases, state management
  - `domain/` — Entities, value objects, repository interfaces
  - `data/` — Repository implementations, DTOs
- **State management** — Use `provider` or `riverpod`. Do not mix state approaches.
- **Models** — Shared cross-feature models live in `lib/core/models/`.
- **Services** — External service wrappers (Firebase, API client) live in `lib/services/`.
- **Naming** — Files use `snake_case`. Classes use `PascalCase`. Enums use `camelCase` values.
- **Material 3** — The app uses `useMaterial3: true`. Keep all widgets consistent with Material 3 design.

### 4.2 FastAPI Backend (`services/api_fastapi/`)

- **App factory pattern** — App is created via `create_app()` in `app/main.py`. Never instantiate `FastAPI()` elsewhere.
- **Versioned routing** — All API routes are prefixed with `/api/v1`. Register new routers in `app/api/router.py`.
- **Route organization** — One file per domain in `app/api/routes/`. Group related endpoints.
- **Pydantic models** — All request/response schemas must be Pydantic `BaseModel` subclasses.
- **Settings** — Use `app/core/config.py` (Pydantic Settings). Load all secrets from environment variables or `.env`, never hard-code them.
- **Naming** — Files use `snake_case`. Classes use `PascalCase`. Endpoints use lowercase kebab-style paths.

### 4.3 Firebase (Firestore)

- **Collections**: `users`, `issues`, `mapper_runs`, `title_suggestions`
- **Relationships**:
  - One `user` → many `issues`
  - One `student` → many `mapper_runs`
  - One `issue` → many `title_suggestions` versions
- Refer to [docs/04-data-model/domain-model.md](docs/04-data-model/domain-model.md) for the canonical field list.
- Any schema change must be reflected in both the domain model doc and the API contracts doc first (contract-first).

### 4.4 API Contracts

Canonical contracts are documented in [docs/03-contracts/api-contracts.md](docs/03-contracts/api-contracts.md).

| Endpoint                                 | Method | Purpose                                    |
|------------------------------------------|--------|--------------------------------------------|
| `/api/v1/health`                         | GET    | Health check                               |
| `/api/v1/auth/role`                      | POST   | Set user role                              |
| `/api/v1/issues`                         | POST   | Create community problem report            |
| `/api/v1/issues?status=validated`        | GET    | List map-ready issues                      |
| `/api/v1/mapper/match`                   | POST   | Match student idea to community problems   |
| `/api/v1/issues/{issue_id}/title-suggestions` | GET | AI-generated research title suggestions |

**Rule**: Update the contracts doc *before* changing any endpoint signature.

---

## 5 · Development Workflow

### 5.1 Running Locally

**Backend (FastAPI)**:
```bash
cd services/api_fastapi
pip install -r requirements.txt
# copy .env.example to .env and fill values
uvicorn app.main:app --reload --port 8000
# Swagger UI: http://127.0.0.1:8000/docs
```

**Mobile App (Flutter)**:
```bash
cd apps/mobile_flutter
flutter pub get
flutter run
```

### 5.2 Environment Variables

| Variable                         | Purpose                          |
|----------------------------------|----------------------------------|
| `APP_NAME`                       | API display name                 |
| `APP_ENV`                        | Environment (`dev`, `prod`)      |
| `APP_PORT`                       | API port (default: 8000)         |
| `FIREBASE_PROJECT_ID`            | Firebase project ID              |
| `FIREBASE_SERVICE_ACCOUNT_PATH`  | Path to service account JSON     |

Never commit `.env` or `secrets/` to version control.

### 5.3 Git Practices

- Commit messages should be clear and descriptive.
- Reference tracking board IDs (e.g., `T-02`) in commit messages when applicable.
- Keep commits focused — one logical change per commit.

---

## 6 · Milestone Roadmap

| Milestone | Timeframe    | Focus                                     | Status       |
|-----------|-------------|-------------------------------------------|-------------|
| **M0**    | 0–6h        | Scope lock, entity freeze                 | ✅ Done      |
| **M1**    | 6–24h       | App shell + API skeleton + Firebase setup | ✅ Done      |
| **M2**    | Day 2–3     | Civic Intelligence (issue submit, map)    | 🔲 Backlog   |
| **M3**    | Day 4–6     | Neural Mapper (idea matching)             | 🔲 Backlog   |
| **M4**    | Day 7–8     | Title Suggestions                         | 🔲 Backlog   |
| **M5**    | Day 9–10    | QA + Demo                                 | 🔲 Backlog   |

Refer to [docs/01-tracking/roadmap-milestones.md](docs/01-tracking/roadmap-milestones.md) for details.

---

## 7 · Agent Rules

### 7.1 Before Writing Code

1. **Read this file** and any relevant doc in `docs/` before making changes.
2. **Check the tracking board** ([docs/01-tracking/tracking-board.md](docs/01-tracking/tracking-board.md)) to understand current task status and dependencies.
3. **Check the API contracts** before modifying any endpoint.
4. **Check the domain model** before modifying any Firestore collection or field.

### 7.2 Code Quality

- Preserve all existing comments and docstrings unrelated to your change.
- Follow the existing code style — do not introduce new patterns without justification.
- Every new API route must have a Pydantic request/response model.
- Every new Flutter feature must follow the feature-first folder structure.
- Do not add packages/dependencies without stating the reason.

### 7.3 Documentation

- Update `docs/03-contracts/api-contracts.md` **before** changing any API signature.
- Update `docs/04-data-model/domain-model.md` **before** changing any Firestore schema.
- Update the tracking board after completing a task.
- Keep `readme.md` in sync with major structural changes.

### 7.4 Testing

- Backend: test new endpoints with the FastAPI TestClient or verify via `/docs`.
- Flutter: add widget tests for new screens when feasible.
- End-to-end success criteria: a full flow from community report → map pin → student match → title suggestions.

### 7.5 Things to Never Do

- ❌ Hard-code API keys, secrets, or Firebase credentials in source code.
- ❌ Modify `.env.example` to contain real secret values.
- ❌ Bypass the role system — all role checks go through `users/{uid}.role`.
- ❌ Create new top-level directories without updating this file.
- ❌ Mix feature code across feature folders (e.g., auth logic in home feature).
- ❌ Skip contract-first — never ship an API change without updating docs first.

---

## 8 · Key File Reference

| What                          | Where                                                          |
|-------------------------------|---------------------------------------------------------------|
| Project README                | [readme.md](readme.md)                                        |
| MVP scope                    | [docs/05-product/mvp-scope.md](docs/05-product/mvp-scope.md) |
| System architecture           | [docs/02-architecture/system-context.md](docs/02-architecture/system-context.md) |
| API contracts                 | [docs/03-contracts/api-contracts.md](docs/03-contracts/api-contracts.md) |
| Domain model                  | [docs/04-data-model/domain-model.md](docs/04-data-model/domain-model.md) |
| Auth & roles                  | [docs/00-governance/auth-role-model.md](docs/00-governance/auth-role-model.md) |
| Firebase setup                | [docs/00-governance/firebase-setup.md](docs/00-governance/firebase-setup.md) |
| Roadmap                       | [docs/01-tracking/roadmap-milestones.md](docs/01-tracking/roadmap-milestones.md) |
| Tracking board                | [docs/01-tracking/tracking-board.md](docs/01-tracking/tracking-board.md) |
| Flutter entry point           | [apps/mobile_flutter/lib/main.dart](apps/mobile_flutter/lib/main.dart) |
| FastAPI entry point           | [services/api_fastapi/app/main.py](services/api_fastapi/app/main.py) |
| API router                    | [services/api_fastapi/app/api/router.py](services/api_fastapi/app/api/router.py) |
| Backend config                | [services/api_fastapi/app/core/config.py](services/api_fastapi/app/core/config.py) |
