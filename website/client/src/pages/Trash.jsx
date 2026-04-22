import React, { useState, useEffect } from 'react';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import { FaQuestionCircle, FaUserCircle, FaSearch, FaExclamationTriangle, FaUndo, FaTrashAlt, FaTrash } from 'react-icons/fa';
import { Link, useLocation } from 'react-router-dom';
import axios from 'axios';
import AlitaptapLogo from '../AlitaptapLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import HelpModal from '../components/HelpModal';

import { BACKEND_URL } from '../App';

export default function Trash() {
  const [deletedDocs, setDeletedDocs] = useState([]);
  const [query, setQuery] = useState('');
  const [helpOpen, setHelpOpen] = useState(false);
  const { pathname } = useLocation();
  const { sidebarExpanded } = useTheme();

  useEffect(() => {
    axios.get(`${BACKEND_URL}/api/drafts/trash`, { withCredentials: true })
      .then(res => setDeletedDocs(res.data))
      .catch(() => {});
  }, []);

  const handleRestore = async (docId) => {
    await axios.post(`${BACKEND_URL}/api/drafts/${docId}/restore`, {}, { withCredentials: true });
    setDeletedDocs(prev => prev.filter(d => d.id !== docId));
  };

  const handlePermanentDelete = async (docId) => {
    if (!window.confirm('Permanently delete? This cannot be undone.')) return;
    await axios.delete(`${BACKEND_URL}/api/drafts/${docId}/permanent`, { withCredentials: true });
    setDeletedDocs(prev => prev.filter(d => d.id !== docId));
  };
  return (
    <div className="ws2-root">
      <Sidebar />

      <main className="ws2-main">
        <header className="ws2-header">
          <div className="ws2-header-title">Trash</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <FaQuestionCircle size={20} className="ws2-header-icon" style={{ cursor: 'pointer' }} onClick={() => setHelpOpen(true)} title="Help & About" />
            <Link to="/dashboard/account" className="ws2-avatar" title="Account"><FaUserCircle size={18} /></Link>
          </div>
        </header>

        <div className="trash-search-bar">
          <FaSearch className="trash-search-icon" />
          <input className="trash-search-input" placeholder="Search deleted documents..." value={query} onChange={e => setQuery(e.target.value)} />
        </div>
        <div className="trash-warning">
          <FaExclamationTriangle className="trash-warning-icon" />
          <span>Files in the trash will be permanently removed after 30 days.</span>
        </div>
        <div className="trash-recent-label">Deleted Documents</div>
        {(() => {
          const filtered = deletedDocs.filter(d => d.title?.toLowerCase().includes(query.toLowerCase()));
          return filtered.length === 0 ? (
            <div className="ws2-empty">
              <FaTrash style={{ fontSize: '3rem', opacity: 0.4, marginBottom: '16px' }} />
              <div className="ws2-empty-title">Trash is empty</div>
              <div className="ws2-empty-desc">Deleted documents will appear here.</div>
            </div>
          ) : (
            <div className="trash-docs-list">
              {filtered.map(doc => (
                <div key={doc.id} className="trash-doc-item">
                  <div className="trash-doc-info">
                    <div className="trash-doc-title">{doc.title}</div>
                    <div className="trash-doc-meta">Last edited {new Date(doc.updatedAt).toLocaleDateString()} • Deleted {new Date(doc.deletedAt).toLocaleDateString()}</div>
                  </div>
                  <div className="trash-doc-actions">
                    <button className="trash-action-btn restore-btn" onClick={() => handleRestore(doc.id)}><FaUndo /> Restore</button>
                    <button className="trash-action-btn delete-btn" onClick={() => handlePermanentDelete(doc.id)}><FaTrashAlt /> Delete</button>
                  </div>
                </div>
              ))}
            </div>
          );
        })()}
      </main>
      {helpOpen && <HelpModal onClose={() => setHelpOpen(false)} />}
    </div>
  );
}
