# Tracking Board (Hybrid: Table + Kanban)

## Master Table
| ID | Work Item | Track | Milestone | Owner | Priority | Status | Start | Due | Dependencies | Acceptance Criteria | Evidence |
|---|---|---|---|---|---|---|---|---|---|---|---|
| T-00 | Scaffold Flutter app shell | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | App runs with role-based shell pages | apps/mobile_flutter/ |
| T-00A | Scaffold FastAPI skeleton | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | `/api/v1` routes available for health/auth/issues/mapper | services/api_fastapi/ |
| T-00B | Document Firebase setup | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 |  | Setup steps and env requirements documented | docs/00-governance/firebase-setup.md |
| T-00C | Finalize role/auth decisions | Platform | M1 | Team | P0 | Done | 2026-04-19 | 2026-04-19 | T-00A | Roles and source of truth documented | docs/00-governance/auth-role-model.md |
| T-01 | Define issue schema | Civic Intelligence | M0 | TBD | P0 | Backlog |  |  |  | Fields finalized and approved |  |
| T-02 | Implement issue submit API | Civic Intelligence | M2 | TBD | P0 | Backlog |  |  | T-01 | POST /issues works with validation |  |
| T-03 | Map validated issues in app | Civic Intelligence | M2 | TBD | P0 | Backlog |  |  | T-02 | Pins render from API data |  |
| T-04 | Build idea match API | Neural Mapper | M3 | TBD | P0 | Backlog |  |  | T-01 | POST /mapper/match returns ranked list |  |
| T-05 | Add student idea input UI | Neural Mapper | M3 | TBD | P0 | Backlog |  |  | T-04 | Student sees ranked problem matches |  |
| T-06 | Problem title suggestion API | Neural Mapper | M4 | TBD | P0 | Backlog |  |  | T-04 | Suggestions returned for selected issue |  |
| T-07 | Show title suggestions in problem detail | Neural Mapper | M4 | TBD | P0 | Backlog |  |  | T-06 | At least 3 suggestions visible |  |

## Kanban
### Backlog
- T-01, T-02, T-03, T-04, T-05, T-06, T-07

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
