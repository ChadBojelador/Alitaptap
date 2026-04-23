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

  useEffect(() => { fetchIssues(); }, []);

  const fetchIssues = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${ALITAPTAP_API}/issues?status=validated`);
      setIssues(res.data);
    } catch { setIssues([]); }
    setLoading(false);
  };

  const generatePlan = async () => {
    if (!selected) return;
    setPlan_generating(true);
    setPlan(null);
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
    setPlan_generating(false);
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
                <p>AI is analyzing the problem and building your project plan...</p>
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
                </div>

                {/* Start Project CTA */}
                <div className="plat-start-project">
                  <div>
                    <h4>Ready to build?</h4>
                    <p>Your project plan is ready. Start executing now.</p>
                  </div>
                  <button className="plat-start-btn"
                    onClick={() => navigator.clipboard.writeText(JSON.stringify(plan, null, 2))}>
                    📋 Copy Full Plan
                  </button>
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}
