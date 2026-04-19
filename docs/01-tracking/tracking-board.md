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
| T-03 | Map validated issues in app | Civic Intelligence | M2 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-02 | Mapbox pins render from API data, submit form works | apps/mobile_flutter/lib/features/civic_intelligence/ |
| T-04 | Build idea match API | Neural Mapper | M3 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-01 | POST /mapper/match returns ranked list | services/api_fastapi/app/services/mapper_service.py |
| T-05 | Add student idea input UI | Neural Mapper | M3 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-04 | Student sees ranked problem matches | apps/mobile_flutter/lib/features/neural_mapper/ |
| T-06 | Problem title suggestion API | Neural Mapper | M4 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-04 | Suggestions returned for selected issue | services/api_fastapi/app/api/routes/issues.py |
| T-07 | Show title suggestions in problem detail | Neural Mapper | M4 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-06 | At least 3 suggestions visible | apps/mobile_flutter/lib/features/civic_intelligence/presentation/issue_detail_page.dart |
| T-08 | Execute M5 QA checklist | QA | M5 | Team | P0 | Backlog | 2026-04-19 | 2026-04-20 | T-02, T-03, T-04, T-05, T-06, T-07 | End-to-end flow validated and evidence captured | docs/01-tracking/m5-qa-demo-checklist.md |
| T-09 | Finalize and rehearse demo script | Product | M5 | Team | P0 | Backlog | 2026-04-19 | 2026-04-20 | T-08 | Demo can be delivered in 5-7 minutes | docs/05-product/demo-script.md |

## Kanban
### Backlog
- T-08, T-09

### Ready
- (move IDs here)

### In Progress
- (move IDs here)

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
