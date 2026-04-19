# ALITAPTAP

What if research didn’t start in the classroom, but in the community?

ALITAPTAP is a platform that helps students build research around real community problems, align ideas with the UN Sustainable Development Goals (SDGs), and turn projects into measurable social impact.

Project planning and execution tracking are documented in [docs/README.md](docs/README.md).

## Core Workflow (Main Idea)

1. Civilians upload community problems with location data.
2. Each report appears as a pinpoint on the map, creating a live, multi-problem community map.
3. A student enters a research idea.
4. The system finds and ranks the mapped problems most semantically related to that idea.
5. The student clicks a matched problem.
6. The platform suggests possible research titles focused on solving that specific problem.

In short: **community-reported map problems → student idea matching → problem-specific research title suggestions**.

## Key Features

### 1) Civic Intelligence

#### Community Side: Problem Mining
Community members report local issues such as:
- Recurring flooding affecting households and infrastructure
- Increasing plastic waste in rivers and waterways
- Limited access to health education in underserved areas

These reports are transformed into structured, research-ready insights. AI then processes and clusters submissions into SDG-related categories.

#### Student Side: Research Discovery
Students browse validated community problems, then receive AI-assisted suggestions for:
- Research title
- Methodology
- Relevant SDG alignment
- Feasibility score (cost, time, and data availability)
- Expected community impact

#### Research Heatmap
A visual dashboard highlights:
- Overused topics
- Underserved problems
- Research trends
- Missing SDGs
- Most active SDGs

---

### 2) SDG Neural Mapper
Students input ideas or research concepts, and the system matches them with real community issues across locations. It links issues to relevant SDGs and suggests possible research directions.

This creates a data-driven bridge between student innovation and actual community needs.

---

### 3) Impact Prediction Engine
A data-driven engine estimates potential outcomes of proposed solutions before implementation. It uses community problem data, intervention details, and historical patterns to forecast:
- Social impact
- Environmental impact
- Economic impact

This helps teams prioritize ideas with stronger effectiveness, scalability, and sustainability.

---

### 4) Innovation Funding Expo
A collaborative digital expo where projects are showcased, evaluated, and supported. Users can:
- Rate projects
- Give feedback
- Join discussions
- Donate or fund promising ideas

This turns strong concepts into actionable, community-backed projects.

## Tech Stack (Flutter-Based)

### Frontend (Mobile App)
- Flutter (Dart) for Android and iOS
- Smooth animations and modern UI for dashboards, maps, and insights

Recommended packages:
- `flutter_map` + OpenStreetMap tiles (interactive maps)
- `lottie` (animations)
- `fl_chart` (graphs and dashboards)
- `provider` or `riverpod` (state management)
- `flutter_animate` (UI transitions)

### Map System (Core Feature)
**Recommended:** OpenStreetMap via `flutter_map`
- Open-source map tiles
- No vendor lock-in
- Simple marker-based community mapping

**Alternative:** Google Maps
- Rich ecosystem
- API key and billing considerations

### Backend (Core Engine)
- FastAPI (Python)

Handles:
- Civic Intelligence processing
- SDG mapping logic
- Impact prediction
- Research suggestion API

### AI / Intelligence Layer
- OpenAI API or open-source LLMs (e.g., Llama)
	- Problem-to-SDG matching
	- Research title generation
	- Solution recommendations
- Sentence Transformers
	- Semantic matching (idea ↔ community problem)
- Scikit-learn
	- Clustering and trend detection
- Pandas / NumPy
	- Data processing

### Database
- Firebase Firestore (real-time data)
- Firebase Auth (student and community accounts)
- Firebase Storage (uploads)
- Firebase Realtime Database (live votes, comments, ratings)

### Funding Layer
- Stripe API (optional for donations)
- Cloud Functions (secure funding workflows)

### Analytics
- `fl_chart` for SDG distribution, trend lines, and impact metrics
- Backend-generated feasibility and alignment scores

### Deployment
- Backend: Render or Railway
- Database/Auth/Storage: Firebase
- Optional web dashboard: Flutter Web or React

## System Flow

Flutter App (Map UI, Problem Feed, Research Suggestions, Funding Expo)

↓

FastAPI Backend (AI Processing, SDG Matching, Impact Prediction)

↓

Firebase (Real-time Data Storage and Sync)
