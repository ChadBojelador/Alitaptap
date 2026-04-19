# M5 QA + Demo Checklist

## Goal
Prepare a stable, testable MVP demo that proves the full ALITAPTAP flow:
community report → validated map pin → student idea match → title suggestions.

## QA Checklist

### A) Backend API Validation
- [ ] `GET /api/v1/health` returns `status=ok`
- [ ] `POST /api/v1/issues` creates a pending issue
- [ ] `PATCH /api/v1/issues/{issue_id}/status` can validate/reject issue
- [ ] `GET /api/v1/issues?status=validated` returns map-ready issues
- [ ] `POST /api/v1/mapper/match` returns ranked matches with `run_id`
- [ ] `GET /api/v1/issues/{issue_id}/title-suggestions` returns at least 3 suggestions

### B) Firestore Data Validation
- [ ] `issues` documents include required fields and valid status values
- [ ] `mapper_runs` documents are created after each mapper request
- [ ] `title_suggestions` documents are created after each suggestion request
- [ ] Timestamp fields are populated (`created_at`, `updated_at` when applicable)

### C) Mobile UX Validation
- [ ] Community user can submit issue form successfully
- [ ] Student can open map and see validated issue pins/list
- [ ] Student can submit idea text and get ranked matches
- [ ] Student can open issue detail from match result
- [ ] Student can view and regenerate title suggestions
- [ ] Basic error states are visible (network/API error)

### D) Performance/Readiness
- [ ] Mapper response is acceptable for demo dataset (target median < 3s)
- [ ] No blocking runtime errors during end-to-end flow
- [ ] Demo accounts and sample issues are prepared

## Demo Readiness Evidence
- [ ] API screenshots (Swagger/UI responses)
- [ ] App screenshots (map, matcher, detail, title suggestions)
- [ ] Sample Firestore records (`issues`, `mapper_runs`, `title_suggestions`)
- [ ] Final demo script rehearsed at least once

## Exit Criteria (M5 Done)
- [ ] One complete end-to-end run executed without manual patching
- [ ] All P0 defects fixed or documented with workaround
- [ ] Demo can be presented in under 7 minutes
