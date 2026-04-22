# Alitaptap Website Workspace

This folder contains the web stack for Alitaptap:

- `frontend/` - React + Vite client
- `backend/` - Express API

## Run apps

From this `website/` folder:

```bash
npm run dev
```

That runs both frontend and backend concurrently.

## Individual commands

```bash
npm run dev:frontend
npm run dev:backend
```

## Backend API check

Once backend is running:

- GET `http://localhost:4000/api/health`
