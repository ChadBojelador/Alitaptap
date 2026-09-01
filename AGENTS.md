# Repository Guidelines

## Project Structure & Module Organization

The Flutter app is in `apps/mobile_flutter/`: feature code belongs in `lib/features/<feature>/` with `presentation`, `application`, `domain`, and `data` layers. Shared models and external wrappers live in `lib/core/` and `lib/services/`; tests and assets are `test/` and `assets/`.

The FastAPI service is `services/api_fastapi/`: endpoints are in `app/api/routes/`, business logic in `app/services/`, and configuration in `app/core/config.py`; tests are in `tests/`. The Vite/React site is `website/client/` (`src/pages`, `src/components`, `src/api`, `src/styles`); its Node server is `website/server/`. Documentation is under `docs/`.

## Build, Test, and Development Commands

- `cd apps/mobile_flutter && flutter pub get && flutter run` - install and run the mobile app.
- `cd apps/mobile_flutter && flutter analyze && flutter test` - lint and test Flutter.
- `cd services/api_fastapi && pip install -r requirements-dev.txt && pytest -q` - install and test the API.
- `cd services/api_fastapi && uvicorn app.main:app --reload --port 8000` - run the API.
- `cd website/client && npm ci && npm run dev` - run React; use `npm run lint` and `npm run build` before UI PRs.
- `cd website/server && npm ci && npm run dev` - run the Node service.

## Coding Style & Naming Conventions

Use four spaces in Python and Dart and follow the existing local style. Dart files use `snake_case`, classes use `PascalCase`, and enum values use `camelCase`; keep Material 3 UI in the presentation layer. Python files and functions use `snake_case`, Pydantic models use `PascalCase`, and API paths are lowercase kebab-style. React components use `PascalCase` filenames (for example, `Dashboard.jsx`); keep related CSS in `src/styles/`. Flutter uses `flutter_lints` with `prefer_single_quotes` and `avoid_print`; React uses ESLint.

## Testing Guidelines

Add focused tests with behavior changes. Flutter uses `flutter_test` and mirrors source paths (for example, `test/core/models/issue_test.dart`); FastAPI uses pytest and TestClient under `services/api_fastapi/tests/`. Run relevant checks before a PR. CI runs Flutter analysis/tests and FastAPI pytest; no coverage threshold is configured.

## Contracts, Security, and Pull Requests

Do not commit `.env`, credentials, or service-account files; start from each `.env.example`. Update `docs/03-contracts/api-contracts.md` before changing an API signature, and update `docs/04-data-model/domain-model.md` before changing Firestore fields. Preserve role checks through `users/{uid}.role`.

Commit history uses concise Conventional Commit-style subjects, such as `feat: add story upload` or `fix: handle legacy password hashes`; reference tracking IDs like `T-08` when applicable. PRs should explain the user-visible change, list validation performed, link the tracking item, and include screenshots for UI changes.
