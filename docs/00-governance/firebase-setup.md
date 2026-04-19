# Firebase Setup (M1)

## Services Enabled
- Authentication
- Firestore Database
- Storage

## Required Local Config
1. Create a Firebase project.
2. Enable Anonymous Auth for prototype testing.
3. Create Firestore in native mode.
4. Download service account JSON for backend and place in `services/api_fastapi/secrets/`.
5. Add env values from `services/api_fastapi/.env.example`.
6. Configure Flutter Android/iOS app and add generated platform Firebase config files.

## Initial Collections
- `users`
- `issues`
- `mapper_runs`
- `title_suggestions`
