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

## Web Auth Troubleshooting

If browser console shows errors like:

`Failed to load resource: theidentitytoolkit.googleapis.com/v1/accounts:signUp`

check these in order:

1. **Anonymous Auth enabled** in Firebase Console → Authentication → Sign-in method.
2. **Authorized domains** include:
	- `localhost`
	- `127.0.0.1`
3. **API key restrictions** in Google Cloud Console allow Identity Toolkit calls from your local referrer.
4. Browser extensions (ad/tracker blockers) are not blocking `googleapis.com` requests.

## Firestore Permission Denied Troubleshooting

If you see `cloud_firestore/permission-denied`, your Firestore security rules are blocking client reads/writes.

For MVP testing with anonymous sign-in, use this ruleset in Firebase Console → Firestore Database → Rules:

```text
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		function isSignedIn() {
			return request.auth != null;
		}

		// users/{uid}: allow signed-in users to read their own profile.
		match /users/{uid} {
			allow read: if isSignedIn() && request.auth.uid == uid;
			// User profile writes should come from backend/admin flow.
			allow write: if false;
		}

		// issues and title_suggestions are served by FastAPI in this MVP.
		match /issues/{docId} {
			allow read, write: if false;
		}

		match /title_suggestions/{docId} {
			allow read, write: if false;
		}

		match /mapper_runs/{docId} {
			allow read, write: if false;
		}
	}
}
```

After publishing rules, reload the app and ensure anonymous sign-in succeeds first.
