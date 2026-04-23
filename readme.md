<div align="center">
  <img src="ALITAPTAP LOGO2.png" alt="ALITAPTAP Logo" width="200"/>
  
  # ALITAPTAP
  
  ### Turning Community Problems into Student-Led Solutions
  
  *What if research didn't start in the classroom, but in the community?*
  
  [![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
  [![FastAPI](https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white)](https://fastapi.tiangolo.com)
  [![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
  [![React](https://img.shields.io/badge/React-61DAFB?style=for-the-badge&logo=react&logoColor=black)](https://react.dev)
  
</div>

---

## 🌟 Overview

ALITAPTAP is a social media platform that bridges the gap between community needs and student research. We empower students to build meaningful research around real-world problems, align their work with UN Sustainable Development Goals (SDGs), and transform academic projects into measurable social impact.

### 🎯 The Problem We Solve

Traditional research often:
- Starts with abstract theories disconnected from real needs
- Lacks community validation and relevance
- Struggles to measure actual impact
- Misses opportunities for SDG alignment

### 💡 Our Solution

ALITAPTAP creates a data-driven ecosystem where:
1. **Communities** report real problems with location data
2. **Students** discover research opportunities from validated issues
3. **AI** matches problems with research ideas and SDGs
4. **Platform** facilitates collaboration, funding, and impact tracking

---

## 🚀 Core Workflow

```
📱 Community Reports → 🗺️ Mapped & Validated → 🎓 Student Browses 
→ 🤖 AI Generates Plan → ✍️ Research & Development → 🚀 Innovation Expo 
→ 💰 Funding & Implementation
```

1. **Community Problem Mining** - Civilians upload issues with GPS coordinates
2. **Live Problem Map** - Each report appears as a pinpoint, creating a multi-problem community map
3. **Idea Matching** - Students enter research ideas, system finds semantically related problems
4. **AI-Assisted Planning** - Platform suggests research titles, methodology, and SDG alignment
5. **Research Development** - Rich text editor with RRL generation and export tools
6. **Innovation Expo** - Showcase projects, get feedback, and secure funding

---

## ✨ Key Features

### 📲 Mobile App (Flutter)

#### For Community Members:
- 📍 **Report Issues** - Upload problems with photos, GPS location, and descriptions
- 🗺️ **Interactive Map** - View all community problems in real-time
- ✅ **Validation System** - Vote and verify reported issues
- 📊 **Impact Tracking** - See how problems are being addressed

#### For Students:
- 🔍 **Browse Problems** - Explore validated community issues
- 🎯 **SDG Alignment** - See which problems match specific SDGs
- 📱 **Mobile Research** - Access research tools on-the-go
- 🔔 **Notifications** - Get updates on problem status and research opportunities

### 💻 Web Platform (React)

#### Ideas Tab (Dashboard):
- 🗺️ **Community Problems Feed** - Browse validated issues from mobile app
- 🤖 **AI Project Planner** - Generate complete project plans with:
  - Implementation roadmap (4-step plan)
  - Tech stack recommendations
  - Feature breakdown
  - Folder structure
  - Starter code
  - SDG alignment
- 💬 **Interactive Chat** - Modify plans with AI assistance
- 📋 **Export Options** - Copy full plan or generate research documents

#### Research Tab:
- ✍️ **Rich Text Editor** - Write research papers with formatting tools
- 📚 **Auto-Generated RRL** - AI creates Review of Related Literature with:
  - 12+ academic references across 4 categories
  - Detailed summaries for each source
  - Proper citations (APA format)
- 📥 **Import from Mobile** - Pull problem data directly into research
- 📤 **Export** - Download as PDF or Word (.docx)
- 💾 **Auto-Save** - Never lose your work

#### Innovation Expo:
- 🚀 **Project Showcase** - Display completed research and prototypes
- ❤️ **Social Features** - Likes, comments, and discussions
- 💰 **Crowdfunding** - Set funding goals and track contributions
- 📊 **Progress Tracking** - Visual funding progress bars
- 🏆 **Leaderboards** - Highlight top projects and contributors

### 🤖 AI-Powered Intelligence

#### 1. Civic Intelligence Engine
- **Problem Clustering** - Groups similar issues using NLP
- **SDG Mapping** - Automatically tags problems with relevant SDGs
- **Trend Analysis** - Identifies emerging community needs
- **Priority Scoring** - Ranks problems by urgency and impact potential

#### 2. Research Assistant
- **Title Generation** - Suggests research titles based on problems
- **Methodology Planning** - Recommends research approaches
- **Literature Review** - Generates RRL with academic sources
- **Feasibility Analysis** - Estimates cost, time, and data requirements

#### 3. Impact Prediction
- **Outcome Forecasting** - Predicts social, environmental, and economic impact
- **Scalability Assessment** - Evaluates replication potential
- **Risk Analysis** - Identifies implementation challenges

#### 4. Research Heatmap
- **Topic Saturation** - Shows overused vs. underserved problems
- **SDG Coverage** - Visualizes which goals need more attention
- **Geographic Distribution** - Maps research activity by location
- **Trend Tracking** - Monitors research patterns over time

---

## 🛠️ Tech Stack

### Mobile App (Flutter)
```yaml
Framework: Flutter 3.x (Dart)
State Management: Provider / Riverpod
Maps: maplibre_gl + OpenFreeMap
Charts: fl_chart
Animations: lottie, flutter_animate
HTTP: dio
Storage: shared_preferences
```

### Web Platform (React)
```json
Framework: React 18 + Vite
Routing: React Router v6
HTTP: Axios
Editor: ContentEditable API
Export: html2pdf.js, docx
Styling: Custom CSS
```

### Backend (FastAPI)
```python
Framework: FastAPI (Python 3.10+)
AI/ML: OpenAI API, Sentence Transformers
Data Processing: Pandas, NumPy
Clustering: Scikit-learn
Validation: Pydantic
Auth: JWT tokens
```

### Database & Services
```
Database: Firebase Firestore / MongoDB Atlas
Authentication: Firebase Auth
Storage: Firebase Storage / Cloudinary
Real-time: Firebase Realtime Database
Payments: Stripe API (optional)
```

### Deployment
```
Backend: Railway / Render / Fly.io
Web Frontend: Vercel / Netlify
Mobile: Google Play Store / App Store
Database: Firebase / MongoDB Atlas
```

---

## 📁 Project Structure

```
ALITAPTAP/
├── apps/
│   └── mobile_flutter/          # Flutter mobile app
│       ├── lib/
│       │   ├── screens/         # UI screens
│       │   ├── widgets/         # Reusable components
│       │   ├── services/        # API calls
│       │   └── models/          # Data models
│       └── assets/              # Images, fonts
│
├── website/
│   ├── client/                  # React web app
│   │   ├── src/
│   │   │   ├── pages/          # Dashboard, Research, Expo
│   │   │   ├── components/     # Reusable UI components
│   │   │   ├── styles/         # CSS files
│   │   │   └── api/            # API integration
│   │   └── public/             # Static assets
│   │
│   └── server/                  # Node.js server (IThink)
│       ├── models/             # Database models
│       ├── credibility_checker/ # Python AI integration
│       └── server.js           # Express server
│
├── services/
│   └── api_fastapi/            # FastAPI backend
│       ├── app/
│       │   ├── routers/        # API endpoints
│       │   ├── models/         # Pydantic models
│       │   ├── services/       # Business logic
│       │   └── utils/          # Helper functions
│       ├── scripts/            # Data seeding
│       └── tests/              # Unit tests
│
└── docs/                       # Documentation
    ├── 00-governance/          # Setup guides
    ├── 01-tracking/            # Project management
    ├── 02-architecture/        # System design
    ├── 03-contracts/           # API specs
    └── 04-data-model/          # Database schemas
```

---

## 🚦 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Node.js 18+
- Python 3.10+
- Firebase account
- Git

### Quick Start

#### 1. Clone Repository
```bash
git clone https://github.com/yourusername/alitaptap.git
cd alitaptap
```

#### 2. Setup Mobile App
```bash
cd apps/mobile_flutter
flutter pub get
flutter run
```

#### 3. Setup Web Platform
```bash
cd website/client
npm install
npm run dev
```

#### 4. Setup Backend
```bash
cd services/api_fastapi
pip install -r requirements.txt
uvicorn app.main:app --reload
```

#### 5. Setup Node Server (IThink)
```bash
cd website/server
npm install
node server.js
```

### Environment Variables

Create `.env` files in respective directories:

**Backend (.env)**
```env
MONGODB_URI=your_mongodb_connection_string
OPENAI_API_KEY=your_openai_key
JWT_SECRET=your_jwt_secret
```

**Web Client (.env)**
```env
VITE_ALITAPTAP_API_URL=http://localhost:8000/api/v1
VITE_BACKEND_URL=http://localhost:3000
```

---

## 📊 System Architecture

```
┌─────────────────┐         ┌──────────────────┐
│  Flutter App    │◄────────┤  FastAPI Backend │
│  (Mobile)       │         │  (AI Engine)     │
└────────┬────────┘         └────────┬─────────┘
         │                           │
         │                           │
         ▼                           ▼
┌─────────────────┐         ┌──────────────────┐
│  React Web      │◄────────┤  Firebase/MongoDB│
│  (Dashboard)    │         │  (Database)      │
└─────────────────┘         └──────────────────┘
```

---

## 🎓 Use Cases

### For Students:
1. **Find Research Topics** - Browse real community problems
2. **Generate Project Plans** - AI creates complete roadmaps
3. **Write Research Papers** - Use rich text editor with auto-generated RRL
4. **Get Funding** - Showcase projects on Innovation Expo
5. **Track Impact** - Measure real-world outcomes

### For Communities:
1. **Report Problems** - Easy mobile app submission
2. **Track Solutions** - See which issues are being addressed
3. **Validate Issues** - Vote on problem severity
4. **Support Projects** - Fund promising student solutions

### For Institutions:
1. **Monitor Research** - Dashboard shows all student projects
2. **SDG Alignment** - Track institutional SDG contributions
3. **Impact Metrics** - Measure community engagement
4. **Resource Allocation** - Identify priority areas

---

## 💰 Cost Breakdown

### FREE Tier (Recommended for MVP)
- ✅ Firebase (Spark Plan) - FREE
- ✅ MongoDB Atlas - FREE (512MB)
- ✅ Vercel/Netlify - FREE
- ✅ Railway/Render - FREE tier
- ✅ Cloudinary - FREE (25GB)

**Total: $0/month** ✨

### With AI Features
- OpenAI API - ~$50-100/month (moderate usage)
- Google Maps API - $200 FREE credits/month
- Stripe - 2.9% + $0.30 per transaction

**Total: $50-100/month** (with AI)

### Scaling (1000+ users)
- Firebase Blaze Plan - ~$25-50/month
- MongoDB Atlas - ~$57/month (M10 cluster)
- Backend hosting - ~$20/month

**Total: ~$100-200/month** (at scale)

---

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📝 Documentation

Detailed documentation available in `/docs`:
- [Firebase Setup](docs/00-governance/firebase-setup.md)
- [API Contracts](docs/03-contracts/api-contracts.md)
- [System Architecture](docs/02-architecture/system-context.md)
- [Data Models](docs/04-data-model/domain-model.md)
- [Roadmap](docs/01-tracking/roadmap-milestones.md)

---

## 🏆 Milestones

- [x] M1: Foundation Setup (Flutter + FastAPI + Firebase)
- [x] M2: Mobile Problem Reporting
- [x] M3: Web Dashboard with AI Planning
- [x] M4: Research Editor with RRL Generation
- [x] M5: Innovation Expo with Funding
- [ ] M6: Impact Tracking Dashboard
- [ ] M7: Advanced Analytics & Heatmaps
- [ ] M8: Multi-language Support

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👥 Team

Built with ❤️ by students, for students.

---

## 📧 Contact

For questions, suggestions, or partnerships:
- 📧 Email: contact@alitaptap.com
- 🐦 Twitter: [@alitaptap](https://twitter.com/alitaptap)
- 💬 Discord: [Join our community](https://discord.gg/alitaptap)

---

<div align="center">
  
  ### 🌟 Star us on GitHub if you find this project useful!
  
  Made with 💡 by the ALITAPTAP Team
  
</div>
