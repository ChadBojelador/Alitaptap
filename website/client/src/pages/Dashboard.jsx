import React, { useState, useEffect } from 'react';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import '../styles/draft.css';
import { FaQuestionCircle, FaUserCircle, FaPlus, FaFileAlt, FaTrash } from 'react-icons/fa';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import axios from 'axios';
import AlitaptapLogo from '../AlitaptapLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import HelpModal from '../components/HelpModal';

import { BACKEND_URL } from '../App';

export default function Workspace() {
  const { theme, toggle } = useTheme();
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const [drafts, setDrafts] = useState([]);
  const [helpOpen, setHelpOpen] = useState(false);

  useEffect(() => {
    axios.get(`${BACKEND_URL}/api/drafts`, { withCredentials: true })
      .then(res => setDrafts(res.data))
      .catch(() => {});
  }, []);

  const handleDelete = async (e, draftId) => {
    e.preventDefault();
    e.stopPropagation();
    await axios.delete(`${BACKEND_URL}/api/drafts/${draftId}`, { withCredentials: true });
    setDrafts(prev => prev.filter(d => d.id !== draftId));
  };

  return (
<<<<<<< HEAD
    <div className="plat-root">
      {/* Sidebar */}
      <aside className="plat-sidebar">
        <div className="plat-sidebar-logo">
          <span className="plat-logo-dot">●</span>
          <span>ALITAPTAP</span>
        </div>
        <nav className="plat-sidebar-nav">
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
        <div className="plat-sidebar-user" style={{ cursor: 'pointer' }} onClick={() => window.location.href = '/dashboard/account'}>
          <div className="plat-user-avatar">
            {user?.email?.[0]?.toUpperCase() || 'U'}
          </div>
          <div className="plat-user-info">
            <span className="plat-user-name">{user?.email?.split('@')[0] || 'User'}</span>
            <span className="plat-user-role">Researcher</span>
          </div>
        </div>
      </aside>
=======
    <div className="ws2-root">
      <Sidebar />
>>>>>>> 6fc21a23771319b9a26fef2c7cf86a18d092d2d6

      {/* Main Content */}
      <main className="ws2-main">
        {/* Header */}
        <header className="ws2-header">
          <div className="ws2-header-title">Documents</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <FaQuestionCircle size={20} className="ws2-header-icon" onClick={() => setHelpOpen(true)} style={{ cursor: 'pointer' }} title="Help & About" />
            <Link to="/dashboard/account" className="ws2-avatar" title="Account"><FaUserCircle size={18} /></Link>
          </div>
        </header>

        {/* Documents */}
        <section>
          <div className="ws2-section-title">Documents</div>
          <div className="ws2-grid">
            <Link to="/draft" className="ws2-card-wrap" style={{ textDecoration: 'none' }}>
              <div className="ws2-card ws2-card--new">
                <FaPlus size={40} className="ws2-card-plus" />
              </div>
              <p className="ws2-card-label">New Document</p>
            </Link>

            {drafts.map(draft => (
              <div key={draft.id} className="ws2-card-wrap">
                <div className="ws2-card">
                  <Link to={`/draft/${draft.id}`} style={{ textDecoration: 'none', width: '100%', height: '100%', display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                    <FaFileAlt size={32} className="ws2-card-file-icon" />
                    <div className="ws2-card-doc-title">{draft.title || 'Untitled Document'}</div>
                    <div className="ws2-card-doc-date">{new Date(draft.updatedAt).toLocaleDateString()}</div>
                  </Link>
                </div>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <p className="ws2-card-label">{draft.title || 'Untitled Document'}</p>
                  <button className="ws2-delete-btn" onClick={(e) => handleDelete(e, draft.id)} title="Move to trash">
                    <FaTrash size={12} />
                  </button>
                </div>
              </div>
            ))}
          </div>

          {drafts.length === 0 && (
            <div className="ws2-empty">
              <div className="ws2-empty-title">Your workspace is empty</div>
              <div className="ws2-empty-desc">Add a document to begin identifying truth and verifying facts.</div>
            </div>
          )}
        </section>

        {/* Floating Chat Button */}
        <Link to="/dashboard/chat" className="ws2-float-chat">
          <div className="ws2-float-chat-bubble">
            <div className="ws2-float-chat-dot"></div>
            <span>Hi! Ask me anything about fact-checking or source verification.</span>
          </div>
          <div className="ws2-float-chat-btn">💬 Chat now</div>
        </Link>

      </main>

      {helpOpen && <HelpModal onClose={() => setHelpOpen(false)} />}
    </div>
  );
}
