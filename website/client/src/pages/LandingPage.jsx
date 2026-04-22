import { useNavigate } from 'react-router-dom';
import { BACKEND_URL } from '../App';
import '../styles/landing.css';

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <div className="land-root">
      {/* Nav */}
      <nav className="land-nav">
        <div className="land-nav-logo">
          <span className="land-logo-dot">●</span> ALITAPTAP
        </div>
        <div className="land-nav-links">
          <a href="#how">How it works</a>
          <a href="#features">Features</a>
        </div>
        <button className="land-nav-cta" onClick={() => navigate('/login')}>
          Get Started
        </button>
      </nav>

      {/* Hero */}
      <section className="land-hero">
        <div className="land-hero-glow land-hero-glow--1" />
        <div className="land-hero-glow land-hero-glow--2" />
        <div className="land-hero-content">
          <div className="land-hero-badge">🚀 AI Execution Platform</div>
          <h1 className="land-hero-title">
            From community problem<br />
            <span className="land-hero-accent">to executed project.</span>
          </h1>
          <p className="land-hero-desc">
            Save research ideas on mobile. Come to desktop and let AI turn them
            into a full project plan, tech stack, and starter code — instantly.
          </p>
          <div className="land-hero-actions">
            <button className="land-btn-primary" onClick={() => navigate('/login')}>
              Start Building Free
            </button>
            <a href="#how" className="land-btn-ghost">See how it works →</a>
          </div>
          <p className="land-hero-sub">
            Connected to the Alitaptap mobile app · No credit card required
          </p>
        </div>

        {/* Mock UI preview */}
        <div className="land-hero-preview">
          <div className="land-preview-card">
            <div className="land-preview-header">
              <span className="land-preview-dot red" />
              <span className="land-preview-dot yellow" />
              <span className="land-preview-dot green" />
              <span className="land-preview-title">AI Project Planner</span>
            </div>
            <div className="land-preview-body">
              <div className="land-preview-idea">
                <span className="land-preview-label">💡 Saved Idea</span>
                <p>Low-cost flood warning system for urban barangays</p>
              </div>
              <div className="land-preview-arrow">↓ Generate Plan with AI</div>
              <div className="land-preview-output">
                <div className="land-preview-line land-preview-line--yellow">📋 Project Breakdown</div>
                <div className="land-preview-line">⚙️ Tech Stack: React, FastAPI, Firebase</div>
                <div className="land-preview-line">📁 Folder Structure Generated</div>
                <div className="land-preview-line land-preview-line--green">✅ Starter Code Ready</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="land-how" id="how">
        <h2 className="land-section-title">How it works</h2>
        <p className="land-section-sub">Three steps from idea to execution</p>
        <div className="land-steps">
          {[
            { num: '01', icon: '📲', title: 'Save on Mobile', desc: 'Browse community problems on the Alitaptap app. Bookmark the ones you want to solve.' },
            { num: '02', icon: '💻', title: 'Open on Desktop', desc: 'Log in with the same account. Your saved ideas sync automatically.' },
            { num: '03', icon: '🤖', title: 'AI Builds the Plan', desc: 'Click "Generate Plan". AI returns a full project breakdown, tech stack, and starter code.' },
          ].map(s => (
            <div key={s.num} className="land-step">
              <div className="land-step-num">{s.num}</div>
              <div className="land-step-icon">{s.icon}</div>
              <h3>{s.title}</h3>
              <p>{s.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Features */}
      <section className="land-features" id="features">
        <h2 className="land-section-title">What AI generates for you</h2>
        <div className="land-features-grid">
          {[
            { icon: '📋', title: 'Project Breakdown', desc: 'Clear scope, goals, and deliverables for your research idea.' },
            { icon: '⚙️', title: 'Tech Stack', desc: 'Recommended tools, frameworks, and libraries based on your problem.' },
            { icon: '🗺️', title: 'Step-by-Step Plan', desc: 'A development roadmap from setup to deployment.' },
            { icon: '📁', title: 'Folder Structure', desc: 'Ready-to-use project scaffold with frontend, backend, and README.' },
            { icon: '💻', title: 'Starter Code', desc: 'Basic working code to get you running in minutes, not days.' },
            { icon: '🌍', title: 'SDG Alignment', desc: 'Maps your project to the UN Sustainable Development Goals.' },
          ].map(f => (
            <div key={f.title} className="land-feature-card">
              <div className="land-feature-icon">{f.icon}</div>
              <h3>{f.title}</h3>
              <p>{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* CTA */}
      <section className="land-cta">
        <div className="land-cta-glow" />
        <h2>Your idea is waiting to be built.</h2>
        <p>Log in, pick a saved problem, and let AI do the heavy lifting.</p>
        <button className="land-btn-primary land-btn-large" onClick={() => navigate('/login')}>
          Start Building Now →
        </button>
      </section>

      {/* Footer */}
      <footer className="land-footer">
        <div className="land-footer-logo">
          <span className="land-logo-dot">●</span> ALITAPTAP
        </div>
        <p>Community problems → Student research → Real impact.</p>
        <p className="land-footer-copy">© 2026 Alitaptap. All rights reserved.</p>
      </footer>
    </div>
  );
}
