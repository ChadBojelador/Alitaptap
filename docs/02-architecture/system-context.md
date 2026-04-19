# System Context

## Actors
- Community User: submits local problems
- Student User: submits research ideas and explores matched problems
- Admin: validates or rejects reports

## Core Flow
1. Community user submits issue with geolocation.
2. Backend stores issue and marks status.
3. Validated issue appears as map pin.
4. Student submits research idea text.
5. Matching service ranks closest problems.
6. Student opens a problem and receives research title suggestions.

## Components
- Flutter App: input forms, map UI, student discovery
- FastAPI Service: issue APIs, matching APIs, title suggestion APIs
- Firebase: Auth, Firestore, Storage
- AI Layer: embeddings + title generation
