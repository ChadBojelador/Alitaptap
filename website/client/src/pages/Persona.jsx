import React, { useState } from 'react';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import { FaUserCircle, FaGraduationCap, FaFlask, FaBriefcase, FaCheck, FaQuestionCircle } from 'react-icons/fa';
import { Link, useLocation } from 'react-router-dom';
import AlitaptapLogo from '../AlitaptapLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import HelpModal from '../components/HelpModal';

import { BACKEND_URL } from '../App';

const PERSONAS = [
  {
    val: '1',
    label: 'High School Student',
    icon: FaGraduationCap,
    desc: 'Simplified fact-checking tailored for academic research and school projects.',
    features: ['Easy-to-understand source ratings', 'Homework & essay research support', 'Credibility basics explained simply', 'Safe and curated source suggestions'],
  },
  {
    val: '2',
    label: 'College Student',
    icon: FaFlask,
    desc: 'In-depth analysis tools for academic papers, thesis research, and critical thinking.',
    features: ['Academic journal verification', 'Citation credibility scoring', 'Cross-source contradiction detection', 'Research bias analysis'],
  },
  {
    val: '3',
    label: 'Professional',
    icon: FaBriefcase,
    desc: 'Advanced verification suite for journalists, researchers, and industry experts.',
    features: ['Deep source investigation', 'Real-time misinformation alerts', 'Expert-level credibility metrics', 'Exportable fact-check reports'],
  },
];

export default function Persona({ user, setUser }) {
  const [usage, setUsage] = useState(user?.persona || '1');
  const [helpOpen, setHelpOpen] = useState(false);
  const { pathname } = useLocation();

  const handlePersonaChange = async (val) => {
    setUsage(val);
    await fetch(`${BACKEND_URL}/api/user/persona`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('token')}` },
      body: JSON.stringify({ persona: val })
    });
    setUser(prev => ({ ...prev, persona: val }));
  };

  const active = PERSONAS.find(p => p.val === usage);

  return (
    <div className="ws2-root">
      <Sidebar />

      <main className="ws2-main">
        <header className="ws2-header">
          <div className="ws2-header-title">Persona</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <FaQuestionCircle size={20} className="ws2-header-icon" style={{ cursor: 'pointer' }} onClick={() => setHelpOpen(true)} title="Help & About" />
            <Link to="/dashboard/account" className="ws2-avatar" title="Account"><FaUserCircle size={18} /></Link>
          </div>
        </header>

        <div className="persona-page">
          <div className="persona-selector">
            {PERSONAS.map(({ val, label, icon: Icon }) => (
              <div
                key={val}
                className={`persona-option${usage === val ? ' persona-option--active' : ''}`}
                onClick={() => handlePersonaChange(val)}
              >
                <div className="persona-option-icon"><Icon size={32} /></div>
                <span>{label}</span>
                {usage === val && <FaCheck size={12} className="persona-option-check" />}
              </div>
            ))}
          </div>

          <div className="persona-detail">
            <div className="persona-detail-header">
              <div className="persona-detail-icon">{active && <active.icon size={40} />}</div>
              <div>
                <div className="persona-detail-title">{active?.label}</div>
                <div className="persona-detail-desc">{active?.desc}</div>
              </div>
            </div>
            <div className="persona-features">
              {active?.features.map((f, i) => (
                <div key={i} className="persona-feature-item">
                  <FaCheck size={11} className="persona-feature-check" />
                  {f}
                </div>
              ))}
            </div>
          </div>
        </div>
      </main>
      {helpOpen && <HelpModal onClose={() => setHelpOpen(false)} />}
    </div>
  );
}
