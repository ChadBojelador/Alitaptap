# Vercel Deployment

Deploy `website/` as the Vercel project root. This project builds the Vite client from `client/` and serves the Express API as a Vercel Function from `api/[...route].js`; do not set `VITE_API_URL` for this single-origin setup.

In Vercel **Project Settings > Environment Variables**, add `DATABASE_URL`, `DB_SSL=true`, `JWT_SECRET`, `SESSION_SECRET`, `APP_URL`, `FRONTEND_URL`, and `GROQ_API_KEY`. Set `APP_URL` and `FRONTEND_URL` to the exact Vercel production URL, without a trailing slash. `SERPER_API_KEY` is optional and enables source search for credibility checks.

Use a managed MySQL-compatible database (for example, one connected through the Vercel Marketplace) because Vercel Functions have no persistent local filesystem. Do not use the repository's SQLite file in production.

For Google sign-in, add `https://your-project.vercel.app/auth/google/callback` to Google Cloud Console's authorized redirect URIs, then set the three `GOOGLE_*` variables. Redeploy after changing environment variables. Test `POST /api/chat` after signing in; it should return a live Groq response without contacting Railway or Render.
