# Auth and Role Model (M1 Decision)

## Roles
- `community`: submits local problems
- `student`: submits research idea and browses matches

> **Note:** The `admin` role was removed from the sign-in flow.
> Issue validation is now handled automatically by the backend (AI-assisted).
> Submitted issues are immediately set to `validated` status so they appear
> on the map without requiring manual admin review.
> See `docs/06-bypasses/android-firebase-bypasses.md` and
> `services/api_fastapi/app/api/routes/issues.py` for implementation details.

## Source of Truth
- Firebase Auth for identity (anonymous sign-in for MVP)
- Role selected in-memory from sign-in screen (Firestore persistence bypassed — see bypass docs)

## Access Policy (M1)
- Anonymous sign-in allowed for rapid prototype
- Role defaults to `student` if not yet assigned
- Only `community` and `student` roles are exposed in the UI

## AI Validation Flow
1. Community member submits a problem via `POST /api/v1/issues`
2. Backend immediately sets `status = validated`
3. Issue appears as a pin on the map for students to discover
4. No manual admin review required

## M2 Hardening Plan
- Replace anonymous with email/password or OAuth
- Add Firestore security rules by role
- Consider AI quality scoring before auto-validation
  (e.g. reject spam, duplicate detection, SDG tagging)
