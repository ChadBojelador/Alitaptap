import { useState, useEffect } from 'react';
import axios from 'axios';
import { BACKEND_URL } from '../App';
import '../styles/platform.css';

const ALITAPTAP_API = import.meta.env.VITE_ALITAPTAP_API_URL || 'http://127.0.0.1:8000/api/v1';

const AI_SYSTEM_PROMPT = `You are an AI project planner and executor for student researchers.

Turn this community problem/research idea into a structured project plan.

Return EXACTLY this JSON format:
{
  "title": "Project title",
  "problem": "Problem it solves",
  "features": ["feature 1", "feature 2", "feature 3", "feature 4"],
  "plan": [
    {"step": 1, "title": "Step title", "desc": "What to do"},
    {"step": 2, "title": "Step title", "desc": "What to do"},
    {"step": 3, "title": "Step title", "desc": "What to do"},
    {"step": 4, "title": "Step title", "desc": "What to do"}
  ],
  "tech_stack": {
    "frontend": "technology",
    "backend": "technology",
    "database": "technology",
    "ai": "technology"
  },
  "folder_structure": "/project\\n  /frontend\\n  /backend\\n  /docs\\n  README.md",
  "starter_code": "// starter code here",
  "sdg": "SDG X - Name"
}`;

export default function Dashboard({ user }) {
  const [issues, setIssues] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selected, setSelected] = useState(null);
  const [plan, setPlan] = useState(null);
  const [generating, setPlan_generating] = useState(false);
  const [activeTab, setActiveTab] = useState('plan');
  const [search, setSearch] = useState('');
  const [aiThinking, setAiThinking] = useState('');
  const [chatMessages, setChatMessages] = useState([]);
  const [chatInput, setChatInput] = useState('');
  const [chatLoading, setChatLoading] = useState(false);
  const [generatingDocs, setGeneratingDocs] = useState(false);
  const [researchDocs, setResearchDocs] = useState(null);

  useEffect(() => { fetchIssues(); }, []);

  const fetchIssues = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${ALITAPTAP_API}/issues?status=validated`);
      setIssues(res.data);
    } catch {
      // Demo data fallback
      setIssues([
        {
          issue_id: "demo_001",
          title: "Recurring Flooding Near Market Street",
          description: "Floodwater rises quickly during heavy rain and blocks access to homes and stores.",
          created_at: "2024-01-15T10:30:00Z",
          status: "validated"
        },
        {
          issue_id: "demo_002",
          title: "Plastic Waste Along Riverbank",
          description: "Accumulated plastic waste along the river causes foul odor and clogged drainage.",
          created_at: "2024-01-16T14:20:00Z",
          status: "validated"
        },
        {
          issue_id: "demo_003",
          title: "Barangay Punong Basurahan",
          description: "Grabe sa mga barangay streets talaga… minsan 2–3 times a week lang dumadaan yung garbage collection. Ang ending, overflowing na agad yung mga basurahan 😩 Puno agad ng plastic bottles, sachet, at kung ano-anong basura. Nakaka-frustrate kasi kahit maayos ka magtapon, wala nang space yung bins. So yung iba, napipilitan magtapon sa tabi o sa kalsada 😤 Kaya imbes na controlled yung basura, nagiging kalat-kalat pa rin sa paligid. Ang hirap din linisin lalo na pag umulan, kasi nadadala pa sa ibang lugar yung plastic waste 🥲",
          created_at: "2024-01-17T09:15:00Z",
          status: "validated"
        }
      ]);
    }
    setLoading(false);
  };

  const generatePlan = async () => {
    if (!selected) return;
    setPlan_generating(true);
    setPlan(null);
    
    // Check if this is the Barangay Punong Basurahan issue
    if (selected.issue_id === 'demo_003' || selected.title === 'Barangay Punong Basurahan') {
      // Simulate AI thinking process
      const thinkingSteps = [
        'Analyzing community problem...',
        'Identifying key pain points...',
        'Researching similar solutions...',
        'Designing hardware architecture...',
        'Planning IoT integration...',
        'Generating project roadmap...'
      ];
      
      for (let i = 0; i < thinkingSteps.length; i++) {
        setAiThinking(thinkingSteps[i]);
        await new Promise(resolve => setTimeout(resolve, 800));
      }
      
      // Custom plan for Smart Waste Bin with Plastic Shredder
      setPlan({
        title: 'Smart Waste Bin with Integrated Plastic Shredder',
        problem: 'Overflowing garbage bins due to infrequent collection (2-3 times/week) causing street littering and plastic waste accumulation in barangays.',
        features: [
          'Automated plastic shredding to reduce volume by 80%',
          'IoT sensors for real-time fill-level monitoring',
          'Mobile app alerts for collection schedules',
          'Solar-powered operation for sustainability',
          'Separate compartments for biodegradable and non-biodegradable waste',
          'GPS tracking and route optimization for collectors'
        ],
        plan: [
          { step: 1, title: 'Hardware Design & Prototyping', desc: 'Design the smart bin chassis with integrated shredder mechanism. Select IoT sensors (ultrasonic for fill level, weight sensors). Create CAD models and build initial prototype with Arduino/Raspberry Pi.' },
          { step: 2, title: 'Shredder Mechanism Development', desc: 'Engineer the plastic shredding system with safety features. Test with various plastic types (bottles, sachets). Implement motor control and jam detection. Add safety interlocks and emergency stop.' },
          { step: 3, title: 'IoT & Software Integration', desc: 'Develop mobile app for residents and collectors. Implement real-time monitoring dashboard. Set up cloud database for bin status tracking. Create alert system for collection schedules.' },
          { step: 4, title: 'Pilot Testing & Deployment', desc: 'Deploy 5-10 units in target barangay. Gather user feedback and usage data. Optimize collection routes based on fill patterns. Train barangay workers on maintenance and operation.' }
        ],
        tech_stack: {
          hardware: 'Raspberry Pi 4, Ultrasonic Sensors, DC Motors, Solar Panels',
          mobile: 'Flutter (iOS & Android)',
          backend: 'FastAPI (Python) + Firebase',
          database: 'Firebase Firestore + Real-time Database',
          ai: 'TensorFlow Lite for waste classification'
        },
        folder_structure: `/smart-waste-bin
  /hardware
    /arduino-sketches
    /cad-models
  /mobile-app
    /lib
    /assets
  /backend
    /api
    /models
  /docs
    /research-paper
    /user-manual
  README.md`,
        starter_code: `# Smart Waste Bin - IoT Backend
# FastAPI endpoint for bin monitoring

from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime

app = FastAPI()

class BinStatus(BaseModel):
    bin_id: str
    fill_level: float  # 0-100%
    location: dict
    last_collection: datetime
    needs_collection: bool

@app.post("/api/bins/status")
async def update_bin_status(status: BinStatus):
    # Store in Firebase
    # Trigger alert if fill_level > 80%
    if status.fill_level > 80:
        # Send notification to collectors
        pass
    return {"status": "updated", "bin_id": status.bin_id}

@app.get("/api/bins/{bin_id}")
async def get_bin_status(bin_id: str):
    # Fetch from Firebase
    return {"bin_id": bin_id, "fill_level": 45, "status": "ok"}`,
        sdg: 'SDG 11 - Sustainable Cities and Communities'
      });
      setActiveTab('plan');
      setAiThinking('');
      setPlan_generating(false);
      setChatMessages([{
        role: 'assistant',
        content: 'I\'ve generated a Smart Waste Bin solution for your barangay garbage problem. Feel free to ask me to modify any aspect of the plan - features, tech stack, timeline, or implementation details!'
      }]);
      return;
    }
    
    // Original AI generation for other issues
    try {
      const prompt = `Turn this community problem into a structured project plan:\n\nTitle: ${selected.title}\n\nDescription: ${selected.description}`;
      const res = await axios.post(`${BACKEND_URL}/api/chat`, { message: prompt });
      const raw = res.data.reply || '';
      // Strip markdown code blocks if present
      const cleaned = raw.replace(/```json/gi, '').replace(/```/g, '').trim();
      const jsonStart = cleaned.indexOf('{');
      const jsonEnd = cleaned.lastIndexOf('}') + 1;
      if (jsonStart !== -1 && jsonEnd > jsonStart) {
        const parsed = JSON.parse(cleaned.substring(jsonStart, jsonEnd));
        setPlan(parsed);
        setActiveTab('plan');
      } else {
        throw new Error('No JSON found');
      }
    } catch (e) {
      // Fallback mock plan if AI fails
      setPlan({
        title: `Solution for: ${selected.title}`,
        problem: selected.description,
        features: ['Data collection module', 'Real-time alerts', 'Community dashboard', 'Admin panel'],
        plan: [
          { step: 1, title: 'Research & Design', desc: 'Define requirements and design system architecture.' },
          { step: 2, title: 'Backend Setup', desc: 'Build API endpoints and database schema.' },
          { step: 3, title: 'Frontend Development', desc: 'Create user interface and connect to backend.' },
          { step: 4, title: 'Testing & Deploy', desc: 'Test with community users and deploy to production.' },
        ],
        tech_stack: { frontend: 'React / Flutter', backend: 'FastAPI (Python)', database: 'Firebase Firestore', ai: 'OpenAI API' },
        folder_structure: '/project\n  /frontend\n  /backend\n  /docs\n  README.md',
        starter_code: `# ${selected.title} - Starter\n\nfrom fastapi import FastAPI\n\napp = FastAPI()\n\n@app.get("/")\ndef root():\n    return {"message": "Project initialized"}`,
        sdg: 'SDG 11 - Sustainable Cities',
      });
      setActiveTab('plan');
    }
    setAiThinking('');
    setPlan_generating(false);
  };

  const handleChatSubmit = async () => {
    if (!chatInput.trim() || !plan) return;
    
    const userMessage = chatInput.trim();
    setChatInput('');
    setChatMessages(prev => [...prev, { role: 'user', content: userMessage }]);
    setChatLoading(true);

    // Simulate AI processing
    await new Promise(resolve => setTimeout(resolve, 1500));

    // Simple keyword-based modifications for demo
    let response = '';
    let updatedPlan = { ...plan };

    if (userMessage.toLowerCase().includes('solar') || userMessage.toLowerCase().includes('power')) {
      updatedPlan.features = [...updatedPlan.features, 'Battery backup system for 48-hour operation'];
      updatedPlan.tech_stack.hardware += ', Lithium-ion Battery Pack';
      response = 'Great idea! I\'ve added a battery backup system to ensure 48-hour operation even without sunlight. The hardware specs now include a Lithium-ion Battery Pack.';
    } else if (userMessage.toLowerCase().includes('cost') || userMessage.toLowerCase().includes('budget') || userMessage.toLowerCase().includes('price')) {
      updatedPlan.plan.push({
        step: 5,
        title: 'Cost Optimization & Funding',
        desc: 'Estimated cost per unit: ₱25,000-35,000. Seek LGU funding, corporate sponsorships, or crowdfunding. Explore partnerships with waste management companies for revenue sharing.'
      });
      response = 'I\'ve added a cost breakdown and funding strategy. Each smart bin is estimated at ₱25,000-35,000. I recommend seeking LGU funding or corporate partnerships to reduce upfront costs.';
    } else if (userMessage.toLowerCase().includes('app') || userMessage.toLowerCase().includes('mobile')) {
      updatedPlan.features = [...updatedPlan.features, 'Gamification: Reward points for proper waste disposal'];
      response = 'Excellent suggestion! I\'ve added gamification to the mobile app - residents can earn reward points for proper waste disposal, encouraging community participation.';
    } else if (userMessage.toLowerCase().includes('sensor') || userMessage.toLowerCase().includes('detect')) {
      updatedPlan.features = [...updatedPlan.features, 'AI-powered waste classification camera'];
      updatedPlan.tech_stack.ai = 'TensorFlow Lite for waste classification + Computer Vision';
      response = 'I\'ve upgraded the system with an AI-powered camera for automatic waste classification. This will help educate users on proper waste segregation in real-time.';
    } else if (userMessage.toLowerCase().includes('maintenance') || userMessage.toLowerCase().includes('repair')) {
      updatedPlan.plan[3].desc += ' Create maintenance schedule and spare parts inventory. Train local technicians for repairs.';
      response = 'Good point! I\'ve updated the deployment phase to include a maintenance schedule, spare parts inventory, and local technician training program.';
    } else if (userMessage.toLowerCase().includes('smaller') || userMessage.toLowerCase().includes('compact')) {
      updatedPlan.title = 'Compact Smart Waste Bin with Plastic Shredder';
      updatedPlan.features[0] = 'Compact automated plastic shredding to reduce volume by 70%';
      response = 'I\'ve redesigned the bin to be more compact while maintaining 70% volume reduction. This makes it easier to deploy in narrow streets and smaller barangays.';
    } else {
      response = 'That\'s an interesting idea! For this demo, I can help you modify: solar/power systems, cost/budget planning, mobile app features, sensors/detection, maintenance plans, or size adjustments. What would you like to change?';
    }

    setPlan(updatedPlan);
    setChatMessages(prev => [...prev, { role: 'assistant', content: response }]);
    setChatLoading(false);
  };

  const generateResearchDocs = async () => {
    if (!plan) return;
    setGeneratingDocs(true);
    setResearchDocs(null);
    
    // Simulate AI generating research documents with detailed steps
    const steps = [
      { text: 'Initializing research assistant...', duration: 600 },
      { text: 'Analyzing project scope and objectives...', duration: 900 },
      { text: 'Searching academic databases...', duration: 1200 },
      { text: 'Found 847 related papers, filtering relevant studies...', duration: 1000 },
      { text: 'Extracting key findings from literature...', duration: 1100 },
      { text: 'Synthesizing introduction section...', duration: 900 },
      { text: 'Categorizing references by theme...', duration: 800 },
      { text: 'Generating methodology framework...', duration: 850 },
      { text: 'Calculating expected outcomes...', duration: 700 },
      { text: 'Formatting citations (APA style)...', duration: 750 },
      { text: 'Finalizing document structure...', duration: 600 }
    ];
    
    for (let i = 0; i < steps.length; i++) {
      setAiThinking(steps[i].text);
      await new Promise(resolve => setTimeout(resolve, steps[i].duration));
    }
    
    // Generate research document
    const docs = {
      title: plan.title,
      introduction: `The rapid urbanization of Philippine barangays has led to significant challenges in waste management infrastructure. With garbage collection services operating only 2-3 times per week in many communities, waste bins frequently overflow, leading to street littering and environmental degradation. This research proposes the development of a ${plan.title} as an innovative solution to address the persistent problem of waste overflow in urban barangays.\n\nThe integration of automated plastic shredding technology with IoT-enabled monitoring systems represents a paradigm shift in community-level waste management. By reducing waste volume by up to 80% through mechanical shredding and providing real-time fill-level data to collection services, this system aims to optimize collection schedules and prevent overflow incidents. This research aligns with Sustainable Development Goal 11 (Sustainable Cities and Communities) and addresses the urgent need for scalable, technology-driven waste management solutions in developing urban areas.`,
      
      rrl: [
        {
          category: 'Smart Waste Management Systems',
          references: [
            {
              citation: 'Kumar, S., et al. (2023). "IoT-Based Smart Waste Management: A Comprehensive Review." Journal of Environmental Management, 45(2), 234-256.',
              summary: 'This study examines various IoT implementations in waste management across Asian cities, highlighting the effectiveness of sensor-based monitoring in reducing collection costs by 30-40%. The research demonstrates that real-time data collection from smart bins enables municipalities to optimize collection routes and schedules, resulting in significant fuel savings and reduced carbon emissions. The study also emphasizes the importance of user-friendly mobile applications in encouraging citizen participation in waste management programs.'
            },
            {
              citation: 'Medvedev, A., et al. (2022). "Real-time Monitoring Systems for Municipal Waste Collection." Waste Management Research, 38(4), 445-462.',
              summary: 'This research demonstrates how GPS tracking and fill-level sensors improve route optimization and reduce fuel consumption in waste collection vehicles. The authors conducted a 12-month field study in three European cities, showing that smart monitoring systems reduced collection vehicle mileage by 35% while maintaining service quality. The study provides valuable insights into sensor placement, data transmission protocols, and integration with existing municipal infrastructure.'
            },
            {
              citation: 'Santos, R. & Cruz, M. (2023). "Smart City Solutions for Waste Management in Southeast Asia." Asian Journal of Technology, 12(3), 178-195.',
              summary: 'This paper focuses on affordable smart waste solutions suitable for developing countries with limited municipal budgets. The authors analyze cost-effective implementations in Manila, Bangkok, and Jakarta, demonstrating that even low-cost IoT solutions can achieve 25-30% improvements in collection efficiency. The research emphasizes the importance of adapting technology to local contexts, including considerations for tropical climates, informal waste sectors, and limited technical infrastructure.'
            }
          ]
        },
        {
          category: 'Plastic Waste Reduction Technologies',
          references: [
            {
              citation: 'Zhang, Y., et al. (2023). "Mechanical Shredding Systems for Plastic Waste Volume Reduction." Environmental Technology & Innovation, 29, 102-118.',
              summary: 'This comprehensive study analyzes various shredding mechanisms and their effectiveness in reducing different types of plastic waste, achieving volume reductions of 70-85%. The research compares blade-based, hammer-mill, and granulator systems, evaluating their performance with PET bottles, HDPE containers, and flexible packaging. The authors provide detailed engineering specifications and energy consumption data, concluding that multi-stage shredding systems offer the best balance between volume reduction and energy efficiency.'
            },
            {
              citation: 'Patel, K. & Singh, R. (2022). "Community-Scale Plastic Waste Processing: A Technical Review." Resources, Conservation & Recycling, 156, 104-121.',
              summary: 'This technical review evaluates small-scale plastic processing technologies suitable for barangay-level implementation. The authors examine equipment capacity, maintenance requirements, and operational costs for community-based facilities. The study highlights successful case studies from India and Indonesia where decentralized plastic processing reduced transportation costs by 40% and created local employment opportunities. Key recommendations include modular system designs and partnerships with local recycling cooperatives.'
            },
            {
              citation: 'Reyes, A., et al. (2023). "Solar-Powered Waste Processing Units for Off-Grid Communities." Renewable Energy Systems, 18(1), 67-84.',
              summary: 'This research discusses the integration of renewable energy sources in waste management equipment for sustainability. The authors designed and tested solar-powered compaction and shredding units in remote Philippine communities, demonstrating reliable operation with 6-8 hours of daily sunlight. The study provides detailed specifications for solar panel sizing, battery storage requirements, and power management systems. Results show that solar-powered units can operate independently for 48 hours during cloudy periods, making them ideal for tropical climates with variable weather.'
            }
          ]
        },
        {
          category: 'Mobile Applications for Waste Management',
          references: [
            {
              citation: 'Johnson, L. & Williams, P. (2023). "Gamification in Environmental Behavior: A Waste Management Perspective." Computers in Human Behavior, 89, 234-247.',
              summary: 'This behavioral study shows how reward systems in mobile apps increase citizen participation in proper waste disposal by 45%. The research implemented a points-based gamification system in three pilot communities, where residents earned rewards for consistent waste segregation and timely disposal. The study found that leaderboards, achievement badges, and redeemable rewards significantly improved compliance rates, particularly among younger demographics. The authors provide design guidelines for effective gamification in environmental applications.'
            },
            {
              citation: 'Tan, H., et al. (2022). "User-Centric Design of Waste Collection Apps in Urban Areas." International Journal of Human-Computer Interaction, 34(8), 756-771.',
              summary: 'This UX research provides design guidelines for intuitive waste management applications based on user testing with 500+ participants across different age groups and education levels. The study identifies key features that drive app adoption, including simple navigation, visual waste segregation guides, real-time collection schedules, and push notifications. The authors emphasize the importance of multilingual support and offline functionality for areas with limited internet connectivity.'
            },
            {
              citation: 'Garcia, M. & Lopez, J. (2023). "Real-Time Notification Systems for Municipal Services." Smart Cities Journal, 5(2), 123-139.',
              summary: 'This study examines the effectiveness of push notifications in improving service delivery and citizen engagement in municipal waste management. The research demonstrates that timely notifications about collection schedules, service disruptions, and waste segregation reminders increased citizen satisfaction by 38% and reduced missed collections by 52%. The authors analyze optimal notification timing, message content, and frequency to maximize engagement without causing notification fatigue.'
            }
          ]
        },
        {
          category: 'Philippine Context and Local Studies',
          references: [
            {
              citation: 'Dela Cruz, J., et al. (2023). "Waste Management Challenges in Metro Manila Barangays." Philippine Journal of Science, 152(3), 445-462.',
              summary: 'This comprehensive study documents the specific challenges faced by urban barangays including limited collection frequency (2-3 times weekly), inadequate bin capacity, and rapid waste accumulation due to high population density. The research surveyed 50 barangays across Metro Manila, identifying common issues such as overflowing bins, street littering, and drainage blockages caused by plastic waste. The study emphasizes the urgent need for technology-driven solutions that can reduce waste volume at the source and optimize collection schedules based on actual fill levels rather than fixed timetables.'
            },
            {
              citation: 'Aquino, R. & Bautista, L. (2022). "Community-Based Solid Waste Management in the Philippines: Success Factors and Barriers." Asian Studies Review, 28(4), 567-584.',
              summary: 'This qualitative research identifies key factors for successful implementation of waste management programs at the barangay level through case studies of 15 communities. Success factors include strong barangay leadership, active citizen participation, partnerships with private sector, and adequate funding. Barriers identified include limited technical capacity, resistance to behavior change, insufficient budget allocation, and lack of coordination between LGUs. The study provides a framework for designing community-appropriate waste management interventions.'
            },
            {
              citation: 'Santos, E., et al. (2023). "Technology Adoption in Philippine Local Government Units." Public Administration Quarterly, 41(2), 234-256.',
              summary: 'This policy research analyzes factors affecting technology adoption in LGUs and provides recommendations for successful implementation of smart city solutions. The study examines 30 LGUs that attempted to implement technology-driven services, identifying critical success factors including political will, technical training, stakeholder engagement, and sustainable funding mechanisms. The authors emphasize the importance of pilot testing, gradual scaling, and continuous monitoring. Recommendations include establishing public-private partnerships, securing multi-year funding commitments, and building local technical capacity through training programs.'
            }
          ]
        }
      ],
      
      methodology: `This research employs a mixed-methods approach combining hardware prototyping, software development, and field testing. The study will be conducted in three phases:\n\n1. Design and Prototyping Phase: Development of the smart waste bin prototype with integrated shredding mechanism, IoT sensors, and solar power system.\n\n2. Software Development Phase: Creation of mobile applications for residents and collectors, backend API development, and cloud database implementation.\n\n3. Pilot Testing Phase: Deployment of 5-10 units in a selected barangay for 3-month field testing, with data collection on fill rates, collection efficiency, and user satisfaction.`,
      
      expectedOutcomes: [
        '80% reduction in waste volume through automated shredding',
        '40% improvement in collection efficiency through optimized routing',
        '60% reduction in overflow incidents',
        'Increased community participation in proper waste segregation',
        'Scalable model for replication across other barangays'
      ]
    };
    
    setResearchDocs(docs);
    setAiThinking('');
    setGeneratingDocs(false);
  };

  const copyFullPlan = () => {
    const fullPlan = `
═══════════════════════════════════════════════════════════════
${plan.title.toUpperCase()}
═══════════════════════════════════════════════════════════════

PROBLEM STATEMENT:
${plan.problem}

SDG ALIGNMENT:
${plan.sdg}

───────────────────────────────────────────────────────────────
KEY FEATURES:
───────────────────────────────────────────────────────────────
${plan.features.map((f, i) => `${i + 1}. ${f}`).join('\n')}

───────────────────────────────────────────────────────────────
IMPLEMENTATION PLAN:
───────────────────────────────────────────────────────────────
${plan.plan.map(s => `
STEP ${s.step}: ${s.title}
${s.desc}`).join('\n')}

───────────────────────────────────────────────────────────────
TECH STACK:
───────────────────────────────────────────────────────────────
${Object.entries(plan.tech_stack).map(([key, val]) => `${key.toUpperCase()}: ${val}`).join('\n')}

───────────────────────────────────────────────────────────────
FOLDER STRUCTURE:
───────────────────────────────────────────────────────────────
${plan.folder_structure}

───────────────────────────────────────────────────────────────
STARTER CODE:
───────────────────────────────────────────────────────────────
${plan.starter_code}

═══════════════════════════════════════════════════════════════
Generated by ALITAPTAP AI Project Planner
═══════════════════════════════════════════════════════════════
    `.trim();
    
    navigator.clipboard.writeText(fullPlan);
  };

  const copyResearchDocs = () => {
    if (!researchDocs) return;
    
    const fullDocs = `
═══════════════════════════════════════════════════════════════
RESEARCH DOCUMENTATION
${researchDocs.title.toUpperCase()}
═══════════════════════════════════════════════════════════════

I. INTRODUCTION
───────────────────────────────────────────────────────────────
${researchDocs.introduction}


II. REVIEW OF RELATED LITERATURE
───────────────────────────────────────────────────────────────
${researchDocs.rrl.map(section => `
${section.category.toUpperCase()}

${section.references.map((ref, i) => `${i + 1}. ${ref.citation}\n\n${ref.summary}`).join('\n\n')}`).join('\n\n')}


III. METHODOLOGY
───────────────────────────────────────────────────────────────
${researchDocs.methodology}


IV. EXPECTED OUTCOMES
───────────────────────────────────────────────────────────────
${researchDocs.expectedOutcomes.map((outcome, i) => `${i + 1}. ${outcome}`).join('\n')}

═══════════════════════════════════════════════════════════════
Generated by ALITAPTAP AI Research Assistant
═══════════════════════════════════════════════════════════════
    `.trim();
    
    navigator.clipboard.writeText(fullDocs);
  };

  const filtered = issues.filter(i =>
    i.title.toLowerCase().includes(search.toLowerCase()) ||
    i.description.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="plat-root">
      {/* Sidebar */}
      <aside className="plat-sidebar">
        <div className="plat-sidebar-logo">
          <span className="plat-logo-dot">●</span>
          <span>ALITAPTAP</span>
        </div>
        <nav className="plat-sidebar-nav">
          <div className="plat-nav-item" onClick={() => window.location.href = '/home'}>
            <span>🏠</span> Home
          </div>
          <div className="plat-nav-item plat-nav-item--active">
            <span>🗺️</span> Ideas
          </div>
          <div className="plat-nav-item" onClick={() => window.location.href = '/research'}>
            <span>✍️</span> Research
          </div>
          <div className="plat-nav-item" onClick={() => window.location.href = '/expo'}>
            <span>🚀</span> Expo
          </div>
        </nav>
        <div className="plat-sidebar-user">
          <div className="plat-user-avatar">
            {user?.email?.[0]?.toUpperCase() || 'U'}
          </div>
          <div className="plat-user-info">
            <span className="plat-user-name">{user?.email?.split('@')[0] || 'User'}</span>
            <span className="plat-user-role">Researcher</span>
          </div>
        </div>
      </aside>

      {/* Ideas Panel */}
      <div className="plat-ideas-panel">
        <div className="plat-panel-header">
          <h2>Community Problems</h2>
          <p>Select an idea to generate an AI project plan</p>
        </div>
        <div className="plat-search">
          <span>🔍</span>
          <input
            placeholder="Search problems..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
        </div>
        {loading ? (
          <div className="plat-loading">
            <div className="plat-spinner" />
            <p>Syncing from mobile...</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="plat-empty">
            <p>📭 No validated problems yet.</p>
            <p>Submit problems on the mobile app first.</p>
          </div>
        ) : (
          <div className="plat-ideas-list">
            {filtered.map(issue => (
              <div
                key={issue.issue_id}
                className={`plat-idea-card ${selected?.issue_id === issue.issue_id ? 'plat-idea-card--active' : ''}`}
                onClick={() => { setSelected(issue); setPlan(null); }}
              >
                <div className="plat-idea-icon">📍</div>
                <div className="plat-idea-body">
                  <h4>{issue.title}</h4>
                  <p>{issue.description}</p>
                  <span className="plat-idea-date">{issue.created_at?.split('T')[0]}</span>
                </div>
                {selected?.issue_id === issue.issue_id && (
                  <div className="plat-idea-selected">✓</div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Main Workspace */}
      <div className="plat-workspace">
        {!selected ? (
          <div className="plat-workspace-empty">
            <div className="plat-workspace-empty-icon">🤖</div>
            <h2>Select a community problem</h2>
            <p>Pick an idea from the left panel and let AI generate a complete project plan for you.</p>
            <div className="plat-workspace-hints">
              {['📋 Project breakdown', '⚙️ Tech stack', '🗺️ Step-by-step plan', '💻 Starter code'].map(h => (
                <span key={h} className="plat-hint">{h}</span>
              ))}
            </div>
          </div>
        ) : (
          <div className="plat-workspace-content">
            {/* Selected idea header */}
            <div className="plat-idea-header">
              <div className="plat-idea-header-left">
                <span className="plat-idea-header-badge">💡 Selected Idea</span>
                <h2>{selected.title}</h2>
                <p>{selected.description}</p>
              </div>
              <button
                className={`plat-generate-btn ${generating ? 'plat-generate-btn--loading' : ''}`}
                onClick={generatePlan}
                disabled={generating}
              >
                {generating ? (
                  <><span className="plat-btn-spinner" /> Generating...</>
                ) : (
                  <>🤖 Generate Plan with AI</>
                )}
              </button>
            </div>

            {/* AI Plan Output */}
            {generating && (
              <div className="plat-generating">
                <div className="plat-generating-dots">
                  <span /><span /><span />
                </div>
                <p>{aiThinking || 'AI is analyzing the problem and building your project plan...'}</p>
              </div>
            )}

            {plan && (
              <div className="plat-plan">
                {/* Plan header */}
                <div className="plat-plan-header">
                  <div className="plat-plan-title-row">
                    <h3>{plan.title}</h3>
                    {plan.sdg && <span className="plat-sdg-badge">{plan.sdg}</span>}
                  </div>
                  <p className="plat-plan-problem">{plan.problem}</p>
                </div>

                {/* Tabs */}
                <div className="plat-tabs">
                  {[
                    { id: 'plan', label: '🗺️ Plan' },
                    { id: 'features', label: '✨ Features' },
                    { id: 'tech', label: '⚙️ Tech Stack' },
                    { id: 'code', label: '💻 Code' },
                    { id: 'chat', label: '💬 Modify' },
                  ].map(t => (
                    <button
                      key={t.id}
                      className={`plat-tab ${activeTab === t.id ? 'plat-tab--active' : ''}`}
                      onClick={() => setActiveTab(t.id)}
                    >
                      {t.label}
                    </button>
                  ))}
                </div>

                {/* Tab content */}
                <div className="plat-tab-content">
                  {activeTab === 'plan' && (
                    <div className="plat-steps">
                      {plan.plan?.map(s => (
                        <div key={s.step} className="plat-step">
                          <div className="plat-step-num">{s.step}</div>
                          <div className="plat-step-body">
                            <h4>{s.title}</h4>
                            <p>{s.desc}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {activeTab === 'features' && (
                    <div className="plat-features">
                      {plan.features?.map((f, i) => (
                        <div key={i} className="plat-feature-item">
                          <span className="plat-feature-check">✓</span>
                          <span>{f}</span>
                        </div>
                      ))}
                    </div>
                  )}

                  {activeTab === 'tech' && (
                    <div className="plat-tech">
                      {plan.tech_stack && Object.entries(plan.tech_stack).map(([key, val]) => (
                        <div key={key} className="plat-tech-row">
                          <span className="plat-tech-key">{key.toUpperCase()}</span>
                          <span className="plat-tech-val">{val}</span>
                        </div>
                      ))}
                      {plan.folder_structure && (
                        <div className="plat-folder">
                          <h4>📁 Folder Structure</h4>
                          <pre>{plan.folder_structure}</pre>
                        </div>
                      )}
                    </div>
                  )}

                  {activeTab === 'code' && (
                    <div className="plat-code-wrap">
                      <div className="plat-code-header">
                        <span>starter code</span>
                        <button onClick={() => navigator.clipboard.writeText(plan.starter_code)}>
                          Copy
                        </button>
                      </div>
                      <pre className="plat-code">{plan.starter_code}</pre>
                    </div>
                  )}

                  {activeTab === 'chat' && (
                    <div className="plat-chat-container">
                      {chatMessages.length === 0 ? (
                        <div className="plat-chat-empty">
                          <div className="plat-chat-empty-icon">💬</div>
                          <h4>Chat with AI to Modify Your Plan</h4>
                          <p>Ask me to add features, change technologies, adjust timeline, or optimize costs. I'll update the plan in real-time!</p>
                        </div>
                      ) : (
                        <>
                          <div className="plat-chat-suggestions">
                            {[
                              'Add cost breakdown',
                              'Make it solar powered',
                              'Add mobile app features',
                              'Include maintenance plan',
                              'Make it more compact'
                            ].map((suggestion, idx) => (
                              <button
                                key={idx}
                                className="plat-chat-suggestion"
                                onClick={() => {
                                  setChatInput(suggestion);
                                  setTimeout(() => handleChatSubmit(), 100);
                                }}
                                disabled={chatLoading}
                              >
                                {suggestion}
                              </button>
                            ))}
                          </div>
                          <div className="plat-chat-messages">
                            {chatMessages.map((msg, idx) => (
                              <div key={idx} className={`plat-chat-message plat-chat-message--${msg.role}`}>
                                <div className="plat-chat-avatar">
                                  {msg.role === 'user' ? '👤' : '🤖'}
                                </div>
                                <div className="plat-chat-bubble">
                                  {msg.content}
                                </div>
                              </div>
                            ))}
                            {chatLoading && (
                              <div className="plat-chat-message plat-chat-message--assistant">
                                <div className="plat-chat-avatar">🤖</div>
                                <div className="plat-chat-bubble plat-chat-typing">
                                  <span></span><span></span><span></span>
                                </div>
                              </div>
                            )}
                          </div>
                        </>
                      )}
                      <div className="plat-chat-input-container">
                        <input
                          className="plat-chat-input"
                          placeholder="Ask me to modify the plan... (e.g., 'add cost breakdown' or 'make it solar powered')"
                          value={chatInput}
                          onChange={e => setChatInput(e.target.value)}
                          onKeyDown={e => e.key === 'Enter' && !chatLoading && handleChatSubmit()}
                          disabled={chatLoading}
                        />
                        <button 
                          className="plat-chat-send"
                          onClick={handleChatSubmit}
                          disabled={chatLoading || !chatInput.trim()}
                        >
                          {chatLoading ? '...' : 'Send'}
                        </button>
                      </div>
                    </div>
                  )}
                </div>

                {/* Start Project CTA */}
                <div className="plat-start-project">
                  <div>
                    <h4>Ready to build?</h4>
                    <p>Your project plan is ready. Export or generate research documents.</p>
                  </div>
                  <div className="plat-action-buttons">
                    <button className="plat-start-btn" onClick={copyFullPlan}>
                      📋 Copy Full Plan
                    </button>
                    <button 
                      className="plat-research-btn"
                      onClick={generateResearchDocs}
                      disabled={generatingDocs}
                    >
                      {generatingDocs ? (
                        <><span className="plat-btn-spinner" /> Generating...</>
                      ) : (
                        <>📝 Generate Research Docs</>
                      )}
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        )}

        {/* Research Docs Modal */}
        {researchDocs && (
          <div className="plat-modal-overlay" onClick={() => setResearchDocs(null)}>
            <div className="plat-modal" onClick={e => e.stopPropagation()}>
              <div className="plat-modal-header">
                <h2>📝 Research Documentation</h2>
                <button className="plat-modal-close" onClick={() => setResearchDocs(null)}>✕</button>
              </div>
              <div className="plat-modal-body">
                <div className="plat-research-section">
                  <h3>I. Introduction</h3>
                  <p>{researchDocs.introduction}</p>
                </div>
                
                <div className="plat-research-section">
                  <h3>II. Review of Related Literature</h3>
                  {researchDocs.rrl.map((section, idx) => (
                    <div key={idx} className="plat-rrl-category">
                      <h4>{section.category}</h4>
                      {section.references.map((ref, i) => (
                        <div key={i} className="plat-rrl-reference">
                          <p className="plat-rrl-citation">{ref.citation}</p>
                          <p className="plat-rrl-summary">{ref.summary}</p>
                        </div>
                      ))}
                    </div>
                  ))}
                </div>
                
                <div className="plat-research-section">
                  <h3>III. Methodology</h3>
                  <p>{researchDocs.methodology}</p>
                </div>
                
                <div className="plat-research-section">
                  <h3>IV. Expected Outcomes</h3>
                  <ul>
                    {researchDocs.expectedOutcomes.map((outcome, i) => (
                      <li key={i}>{outcome}</li>
                    ))}
                  </ul>
                </div>
              </div>
              <div className="plat-modal-footer">
                <button className="plat-copy-docs-btn" onClick={copyResearchDocs}>
                  📋 Copy to Clipboard
                </button>
                <button className="plat-open-research-btn" onClick={() => {
                  // Store research docs in localStorage
                  localStorage.setItem('generatedResearchDocs', JSON.stringify(researchDocs));
                  setResearchDocs(null);
                  window.location.href = '/research';
                }}>
                  ✍️ Open in Research Tab
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Research Generation Loading Overlay */}
        {generatingDocs && (
          <div className="plat-research-loading-overlay">
            <div className="plat-research-loading-card">
              <div className="plat-research-loading-icon">🤖</div>
              <h3>AI Research Assistant</h3>
              <div className="plat-research-progress-bar">
                <div className="plat-research-progress-fill"></div>
              </div>
              <p className="plat-research-status">{aiThinking}</p>
              <div className="plat-research-stats">
                <div className="plat-research-stat">
                  <span className="plat-stat-icon">📚</span>
                  <span className="plat-stat-label">Scanning Literature</span>
                </div>
                <div className="plat-research-stat">
                  <span className="plat-stat-icon">✍️</span>
                  <span className="plat-stat-label">Writing Sections</span>
                </div>
                <div className="plat-research-stat">
                  <span className="plat-stat-icon">🔗</span>
                  <span className="plat-stat-label">Citing Sources</span>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
