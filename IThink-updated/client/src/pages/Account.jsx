import React, { useState } from 'react';
import Toast from '../components/Toast';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import { FaUserCircle } from 'react-icons/fa';
import { useLocation, useNavigate } from 'react-router-dom';
import IThinkLogo from '../IThinkLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';

import { BACKEND_URL } from '../App';

export default function Account({ user, setUser }) {
  const [usage, setUsage] = useState(user?.persona || '1');
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [toast, setToast] = useState(null);
  const { pathname } = useLocation();
  const { theme } = useTheme();
  const navigate = useNavigate();

  const handleDeleteAccount = async () => {
    setDeleting(true);
    try {
      const res = await fetch(`${BACKEND_URL}/api/user`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
      });
      if (!res.ok) throw new Error();
      localStorage.removeItem('token');
      setUser(null);
      navigate('/login');
    } catch {
      setToast({ message: 'Failed to delete account. Please try again.', type: 'error' });
      setDeleting(false);
    }
  };

  const handlePersonaChange = async (val) => {
    setUsage(val);
    await fetch(`${BACKEND_URL}/api/user/persona`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('token')}` },
      body: JSON.stringify({ persona: val })
    });
    setUser(prev => ({ ...prev, persona: val }));
  };
  return (
    <div className="ws2-root">
      <Sidebar />

      <main className="ws2-main">
        <header className="ws2-header">
          <div className="ws2-header-title">Account</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <div className="ws2-avatar ws2-avatar--active" title="Account"><FaUserCircle size={18} /></div>
          </div>
        </header>

        <div className="account-page">
          {/* Profile Card */}
          <div className="account-card">
            <div className="account-avatar-large"><FaUserCircle size={48} /></div>
            <div className="account-card-info">
              <div className="account-card-name">{user?.displayName || user?.name || 'N/A'}</div>
              <div className="account-card-email">{user?.email || 'N/A'}</div>
            </div>
          </div>

          {/* Danger Card */}
          <div className="account-card account-card--danger">
            <div className="account-card-title" style={{ color: '#ff6b6b' }}>Delete Account</div>
            <div className="account-card-desc">Permanently removes all your data. This cannot be undone.</div>
            <button className="account-delete-btn" onClick={() => setConfirmDelete(true)}>Delete Account</button>
          </div>
        </div>
      </main>

      {confirmDelete && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ background: 'var(--card-bg)', border: '1px solid rgba(255,107,107,0.3)', borderRadius: 16, padding: 28, maxWidth: 360, width: '90%', display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ fontSize: '1.1rem', fontWeight: 700, color: '#ff6b6b' }}>Delete Account?</div>
            <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', lineHeight: 1.6 }}>This will permanently delete your account, all drafts, and chat history. This cannot be undone.</div>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button onClick={() => setConfirmDelete(false)} style={{ padding: '8px 18px', borderRadius: 8, border: '1px solid var(--border-color)', background: 'transparent', color: 'var(--text-main)', cursor: 'pointer', fontFamily: 'inherit' }}>Cancel</button>
              <button onClick={handleDeleteAccount} disabled={deleting} style={{ padding: '8px 18px', borderRadius: 8, border: 'none', background: '#ff6b6b', color: '#fff', fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit' }}>{deleting ? 'Deleting...' : 'Yes, Delete'}</button>
            </div>
          </div>
        </div>
      )}
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
