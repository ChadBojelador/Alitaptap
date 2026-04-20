# Tracking Board (Hybrid: Table + Kanban)

## Master Table
| ID | Work Item | Track | Milestone | Owner | Priority | Status | Start | Due | Dependencies | Acceptance Criteria | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|
| T-00 | Scaffold Flutter app shell | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | App runs with role-based shell pages | apps/mobile_flutter/ |
| T-00A | Scaffold FastAPI skeleton | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | `/api/v1` routes available for health/auth/issues/mapper | services/api_fastapi/ |
| T-00B | Document Firebase setup | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | Setup steps and env requirements documented | docs/00-governance/firebase-setup.md |
| T-00C | Finalize role/auth decisions | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-00A | Roles and source of truth documented | docs/00-governance/auth-role-model.md |
| T-01 | Define issue schema | Civic Intelligence | M0 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | Fields finalized and locked | docs/04-data-model/domain-model.md |
| T-02 | Implement issue submit API | Civic Intelligence | M2 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-01 | POST /issues writes to Firestore, GET reads back | services/api_fastapi/app/api/routes/issues.py |
| T-03 | Map validated issues in app | Civic Intelligence | M2 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-02 | OpenFreeMap pins render from API data, submit form works | apps/mobile_flutter/lib/features/civic_intelligence/ |
| T-04 | Build idea match API | Neural Mapper | M3 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-01 | POST /mapper/match returns ranked list | services/api_fastapi/app/services/mapper_service.py |
| T-05 | Add student idea input UI | Neural Mapper | M3 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-04 | Student sees ranked problem matches | apps/mobile_flutter/lib/features/neural_mapper/ |
| T-06 | Problem title suggestion API | Neural Mapper | M4 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-04 | Suggestions returned for selected issue | services/api_fastapi/app/api/routes/issues.py |
| T-07 | Show title suggestions in problem detail | Neural Mapper | M4 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-06 | At least 3 suggestions visible | apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_detail_page.dart |
| T-08 | Execute M5 QA checklist | QA | M5 | Team | P0 | In Progress | 2026-04-19 | 2026-04-20 | T-02, T-03, T-04, T-05, T-06, T-07 | End-to-end flow validated and evidence captured | docs/01-tracking/m5-qa-demo-checklist.md |
| T-09 | Finalize and rehearse demo script | Product | M5 | Team | P0 | Backlog | 2026-04-19 | 2026-04-20 | T-08 | Demo can be delivered in 5-7 minutes | docs/05-product/demo-script.md |
| T-10 | Add titled map pin overlays + demo issue generator | Civic Intelligence | M5 | Team | P1 | Done | 2026-04-21 | 2026-04-21 | T-03 | Each issue renders as one tappable pinpoint with title label; quick demo data generation at user location | apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_map_page.dart |
| T-11 | Apply feature-layered Flutter architecture | Platform | M5 | Team | P1 | Done | 2026-04-21 | 2026-04-21 | T-03, T-05 | Features expose repository + use case layers and UI consumes use cases | apps/mobile_flutter/lib/features/ |
| T-12 | Add backend + mobile automated tests | QA | M5 | Team | P1 | Done | 2026-04-21 | 2026-04-21 | T-11 | FastAPI route/helper tests and Flutter model/use-case tests added | services/api_fastapi/tests/ |
| T-13 | Add CI workflows for app and API | Platform | M5 | Team | P1 | Done | 2026-04-21 | 2026-04-21 | T-12 | PR/push triggers run Flutter analyze/tests and FastAPI pytest | .github/workflows/ |
| T-14 | Auto-connect idea to best problem match | Neural Mapper | M5 | Team | P1 | Done | 2026-04-21 | 2026-04-21 | T-05 | After idea matching, app connects user to top-ranked problem detail automatically | apps/mobile_flutter/lib/features/neural_mapper/presentation/idea_match_page.dart |

## Kanban
### Backlog
- T-09

### Ready
- (move IDs here)

### In Progress
- T-08

### Review
- (move IDs here)

### Blocked
- (move IDs here + blocker reason)

### Done
- T-00 (apps/mobile_flutter/)
- T-00A (services/api_fastapi/)
- T-00B (docs/00-governance/firebase-setup.md)
- T-00C (docs/00-governance/auth-role-model.md)
- T-01 (docs/04-data-model/domain-model.md)
- T-02 (services/api_fastapi/app/api/routes/issues.py)
- T-03 (apps/mobile_flutter/lib/features/civic_intelligence/)
- T-04 (services/api_fastapi/app/services/mapper_service.py)
- T-05 (apps/mobile_flutter/lib/features/neural_mapper/)
- T-06 (services/api_fastapi/app/api/routes/issues.py)
- T-07 (apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_detail_page.dart)
- T-10 (apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_map_page.dart)
- T-11 (apps/mobile_flutter/lib/features/)
- T-12 (services/api_fastapi/tests/)
- T-13 (.github/workflows/)
- T-14 (apps/mobile_flutter/lib/features/neural_mapper/presentation/idea_match_page.dart)
