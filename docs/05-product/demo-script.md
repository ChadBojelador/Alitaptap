# Demo Script (M5)

## Duration
Target: 5–7 minutes

## Demo Objective
Show that ALITAPTAP connects real community problems to student research ideas and generates actionable research titles.

## Setup Before Demo
- Backend API running and reachable
- Mobile app running (Android/Web/Windows)
- Firebase project connected
- At least 1 validated issue available on map
- Presenter account signed in as `student`

## Talk Track + Steps

### 1) Opening (30–45s)
- "ALITAPTAP bridges community-reported problems and student-led research aligned with SDGs."
- "We will run one full flow from problem data to research title suggestions."

### 2) Community Problem Context (45–60s)
- Open map view.
- Show validated issues list and pin distribution.
- Highlight one issue briefly (title + location).

### 3) Student Idea Matching (90–120s)
- Open "Match Your Idea" screen.
- Enter a research idea (example: low-cost flood warning for urban neighborhoods).
- Submit and show ranked matches with scores/reasons.

### 4) Problem Detail + Title Suggestions (90–120s)
- Open top matched issue detail.
- Show issue summary and tags.
- Show generated title suggestions.
- Click regenerate once to show history-producing behavior.

### 5) Technical Credibility (45–60s)
- Mention backend endpoints involved:
  - `/api/v1/issues`
  - `/api/v1/mapper/match`
  - `/api/v1/issues/{issue_id}/title-suggestions`
- Mention Firestore collections used:
  - `issues`, `mapper_runs`, `title_suggestions`

### 6) Close (30–45s)
- "This workflow ensures research starts from real local needs."
- "Next phase expands QA, impact prediction, and deployment hardening."

## Backup Plan (if live API/network fails)
- Use cached screenshots for map, matches, and suggestions.
- Show API contract docs and explain expected payloads/responses.
- Continue narrative as a guided walkthrough.

## Suggested Demo Data
- Issue title: "Frequent Flooding in Riverside Barangay"
- Idea text: "Affordable early-warning and drainage monitoring system"
- Expected result: flooding-related issue appears near top rank with at least 3 title suggestions.
