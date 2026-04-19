# Auth and Role Model (M1 Decision)

## Roles
- `community`: submits local problems
- `student`: submits research idea and browses matches
- `admin`: validates/rejects reports

## Source of Truth
- Firebase Auth for identity
- Firestore `users/{uid}.role` for app role

## Access Policy (M1)
- Anonymous sign-in allowed for rapid prototype
- Role defaults to `student` if not yet assigned
- Admin role assignment controlled by backend endpoint: `POST /api/v1/auth/role`

## M2 Hardening Plan
- Replace anonymous with email/password or OAuth
- Add admin-only authorization checks in API
- Add Firestore security rules by role
