import React, { useState } from 'react';
import Toast from '../components/Toast';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import { FaUserCircle } from 'react-icons/fa';
import { useLocation, useNavigate } from 'react-router-dom';
import AlitaptapLogo from '../AlitaptapLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';

import { BACKEND_URL } from '../App';
<<<<<<< HEAD
import '../styles/account.css';
// import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import { FaUserCircle, FaQuestionCircle, FaArrowLeft } from 'react-icons/fa';
=======
>>>>>>> 6fc21a23771319b9a26fef2c7cf86a18d092d2d6

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
<<<<<<< HEAD
    <div className="ws2-root" style={{ background: 'linear-gradient(120deg, #181818 0%, #ffd60a 100%)', minHeight: '100vh' }}>
      <main className="ws2-main">
        <header className="ws2-header" style={{ boxShadow: '0 2px 12px rgba(0,0,0,0.10)', background: '#181818', borderRadius: '0 0 18px 18px', color: '#ffd60a' }}>
          <button
            className="acc-back-btn"
            style={{
              background: 'none', border: 'none', color: '#1976d2', fontSize: '1.2rem', display: 'flex', alignItems: 'center', gap: '0.5rem', cursor: 'pointer', fontWeight: 600, marginRight: 16
            }}
            onClick={() => window.location.href = '/dashboard'}
            title="Back to Dashboard"
          >
            <FaArrowLeft /> Back
          </button>
          <div className="ws2-header-title" style={{ color: '#ffd60a', fontWeight: 700 }}>Account Settings</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <FaQuestionCircle size={20} className="ws2-header-icon" style={{ cursor: 'pointer', color: '#ffd60a' }} title="Help & About" />
            <FaUserCircle size={18} className="ws2-avatar" title="Account" style={{ color: '#ffd60a' }} />
          </div>
        </header>

        <div className="acc-main" style={{ boxShadow: '0 6px 32px rgba(0,0,0,0.13)', borderRadius: 18, background: '#181818', marginTop: 32, maxWidth: 540, marginLeft: 'auto', marginRight: 'auto', padding: '2.5rem 2rem', color: '#fff', overflow: 'hidden' }}>
          {/* Tabs */}
          <div className="acc-tabs" style={{ marginBottom: 32, justifyContent: 'center', display: 'flex', gap: '1.2rem' }}>
            {[
              { id: 'profile', label: '👤 Profile' },
              { id: 'qr', label: '📱 QR Login' },
              { id: 'security', label: '🔒 Security' },
            ].map(t => (
              <button
                key={t.id}
                className={`acc-tab ${activeTab === t.id ? 'acc-tab--active' : ''}`}
                style={{
                  background: activeTab === t.id ? '#ffd60a' : 'none',
                  color: activeTab === t.id ? '#181818' : '#ffd60a',
                  borderBottom: activeTab === t.id ? '2px solid #ffd60a' : '2px solid transparent',
                  fontWeight: 700,
                  fontSize: '1.1rem',
                  borderRadius: '7px 7px 0 0',
                  padding: '0.7rem 1.5rem',
                  cursor: 'pointer',
                  transition: 'background 0.2s, color 0.2s',
                  minWidth: 120
                }}
                onClick={() => setActiveTab(t.id)}
              >
                {t.label}
              </button>
            ))}
          </div>

          {/* ── Profile Tab ─────────────────────────────────────────────── */}
          {activeTab === 'profile' && (
            <div className="acc-section" style={{ width: '100%', padding: '2.5rem 0', boxSizing: 'border-box', overflow: 'hidden' }}>
              {/* Avatar */}
              <div className="acc-avatar-section" style={{ display: 'flex', alignItems: 'center', gap: '2.5rem', marginBottom: '2.2rem', flexWrap: 'wrap' }}>
                <div className="acc-avatar" style={{ width: 110, height: 110, borderRadius: '50%', background: '#ffd60a', border: '3px solid #181818', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '2.5rem', fontWeight: 700, color: '#181818', position: 'relative', overflow: 'hidden', cursor: 'pointer', transition: 'box-shadow 0.2s' }} onClick={() => fileRef.current?.click()}>
                  {form.avatarUrl
                    ? <img src={form.avatarUrl} alt="avatar" style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '50%' }} />
                    : <span>{initials}</span>}
                  <div className="acc-avatar-overlay" style={{ position: 'absolute', bottom: 0, left: 0, width: '100%', background: 'rgba(24,24,24,0.85)', color: '#ffd60a', fontSize: '1.1rem', textAlign: 'center', padding: '0.3rem 0', opacity: 0, transition: 'opacity 0.2s', borderRadius: '0 0 50% 50%' }}>📷</div>
                </div>
                <input ref={fileRef} type="file" accept="image/*" style={{ display: 'none' }} onChange={handleAvatarFile} />
                <div className="acc-avatar-info">
                  <h3 style={{ fontSize: '1.35rem', fontWeight: 700, marginBottom: '0.2rem', color: '#ffd60a' }}>{form.displayName || user?.email?.split('@')[0]}</h3>
                  <p style={{ fontSize: '1rem', color: '#fff', marginBottom: '0.5rem' }}>{user?.email}</p>
                  <button className="acc-btn-ghost" style={{ background: 'none', border: '1.5px solid #ffd60a', color: '#ffd60a', borderRadius: 7, padding: '0.5rem 1.2rem', fontSize: '1rem', cursor: 'pointer', transition: 'background 0.2s, color 0.2s' }} onClick={() => fileRef.current?.click()}>
                    Change Photo
                  </button>
                </div>
              </div>

              {/* Form */}
              <div className="acc-form" style={{ width: '100%', marginTop: '1.2rem' }}>
                <div className="acc-form-row" style={{ display: 'flex', gap: '1.5rem', flexWrap: 'wrap' }}>
                  <div className="acc-form-group" style={{ flex: 1, display: 'flex', flexDirection: 'column', marginBottom: '1.2rem', minWidth: 0 }}>
                    <label style={{ fontSize: '1rem', fontWeight: 600, color: '#ffd60a', marginBottom: '0.4rem' }}>Display Name</label>
                    <input value={form.displayName}
                      onChange={e => setForm(p => ({ ...p, displayName: e.target.value }))}
                      placeholder="Your full name"
                      style={{ padding: '0.85rem 1rem', border: '1.5px solid #ffd60a', borderRadius: 8, fontSize: '1rem', background: '#232323', color: '#ffd60a', transition: 'border 0.2s', width: '100%' }}
                    />
                  </div>
                  <div className="acc-form-group" style={{ flex: 1, display: 'flex', flexDirection: 'column', marginBottom: '1.2rem', minWidth: 0 }}>
                    <label style={{ fontSize: '1rem', fontWeight: 600, color: '#ffd60a', marginBottom: '0.4rem' }}>Institution / School</label>
                    <input value={form.institution}
                      onChange={e => setForm(p => ({ ...p, institution: e.target.value }))}
                      placeholder="e.g. University of the Philippines"
                      style={{ padding: '0.85rem 1rem', border: '1.5px solid #ffd60a', borderRadius: 8, fontSize: '1rem', background: '#232323', color: '#ffd60a', transition: 'border 0.2s', width: '100%' }}
                    />
                  </div>
                </div>
                <div className="acc-form-group" style={{ marginBottom: '1.2rem' }}>
                  <label style={{ fontSize: '1rem', fontWeight: 600, color: '#ffd60a', marginBottom: '0.4rem' }}>Location</label>
                  <input value={form.location}
                    onChange={e => setForm(p => ({ ...p, location: e.target.value }))}
                    placeholder="e.g. Manila, Philippines"
                    style={{ padding: '0.85rem 1rem', border: '1.5px solid #ffd60a', borderRadius: 8, fontSize: '1rem', background: '#232323', color: '#ffd60a', transition: 'border 0.2s', width: '100%' }}
                  />
                </div>
                <div className="acc-form-group" style={{ marginBottom: '1.2rem' }}>
                  <label style={{ fontSize: '1rem', fontWeight: 600, color: '#ffd60a', marginBottom: '0.4rem' }}>Bio</label>
                  <textarea rows={4} value={form.bio}
                    onChange={e => setForm(p => ({ ...p, bio: e.target.value }))}
                    placeholder="Tell the community about your research interests..."
                    style={{ padding: '0.85rem 1rem', border: '1.5px solid #ffd60a', borderRadius: 8, fontSize: '1rem', background: '#232323', color: '#ffd60a', transition: 'border 0.2s', resize: 'none', width: '100%' }}
                  />
                </div>
                <div className="acc-form-actions" style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '1.2rem' }}>
                  <button className="acc-btn-save" style={{ padding: '0.9rem 2.2rem', background: 'linear-gradient(90deg, #ffd60a 60%, #181818 100%)', color: '#181818', border: 'none', borderRadius: 8, fontSize: '1.1rem', fontWeight: 700, cursor: 'pointer', transition: 'background 0.2s, box-shadow 0.2s', boxShadow: '0 2px 8px rgba(0,0,0,0.10)' }} onClick={saveProfile} disabled={saving}>
                    {saving ? 'Saving...' : saved ? '✓ Saved!' : 'Save Changes'}
                  </button>
                </div>
              </div>
            </div>
          )}

        {/* ── QR Login Tab ─────────────────────────────────────────────── */}
        {activeTab === 'qr' && (
          <div className="acc-section acc-qr-section">
            <div className="acc-qr-info">
              <h3>📱 QR Code Login</h3>
              <p>Generate a QR code to instantly log in on another device — no password needed. The code expires in 5 minutes.</p>
              <ol>
                <li>Click <strong>Generate QR Code</strong> below</li>
                <li>Open the camera on your phone or another device</li>
                <li>Scan the QR code to log in instantly</li>
              </ol>
            </div>

            <div className="acc-qr-box">
              {!qrData ? (
                <div className="acc-qr-placeholder">
                  <div className="acc-qr-icon">📱</div>
                  <p>No QR code generated yet</p>
                  <button className="acc-btn-yellow" onClick={generateQR} disabled={qrLoading}>
                    {qrLoading ? 'Generating...' : '⚡ Generate QR Code'}
                  </button>
                </div>
              ) : (
                <div className="acc-qr-active">
                  <img src={qrData.img} alt="QR Login Code" className="acc-qr-img" />
                  <div className="acc-qr-timer">
                    <div className="acc-qr-timer-bar"
                      style={{ width: `${(qrExpiry / 300) * 100}%` }} />
                  </div>
                  <p className="acc-qr-expiry">
                    Expires in <strong>{Math.floor(qrExpiry / 60)}:{String(qrExpiry % 60).padStart(2, '0')}</strong>
                  </p>
                  <button className="acc-btn-ghost" onClick={generateQR}>
                    🔄 Regenerate
                  </button>
                </div>
              )}
            </div>
          </div>
        )}

        {/* ── Security Tab ─────────────────────────────────────────────── */}
        {activeTab === 'security' && (
          <div className="acc-section">
            <div className="acc-security-card">
              <h3>Account Info</h3>
              <div className="acc-info-row">
                <span>Email</span>
                <strong>{user?.email}</strong>
              </div>
              <div className="acc-info-row">
                <span>Login method</span>
                <strong>{user?.googleId ? 'Google OAuth' : 'Email & Password'}</strong>
              </div>
              <div className="acc-info-row">
                <span>Account ID</span>
                <strong>#{user?.id}</strong>
              </div>
            </div>

            <div className="acc-danger-card">
              <h3>⚠️ Danger Zone</h3>
              <p>Permanently delete your account and all associated data. This cannot be undone.</p>
              <button className="acc-btn-danger" onClick={() => setConfirmDelete(true)}>
                Delete Account
              </button>
            </div>
          </div>
        )}
        </div>

        {/* Delete confirm modal */}
        {confirmDelete && (
          <div className="acc-modal-overlay" onClick={() => setConfirmDelete(false)}>
            <div className="acc-modal" onClick={e => e.stopPropagation()}>
              <h3>Delete Account?</h3>
              <p>This will permanently delete your account, all drafts, and research posts. This cannot be undone.</p>
              <div className="acc-modal-actions">
                <button className="acc-btn-ghost" onClick={() => setConfirmDelete(false)}>Cancel</button>
                <button className="acc-btn-danger" onClick={deleteAccount} disabled={deleting}>
                  {deleting ? 'Deleting...' : 'Yes, Delete'}
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
=======
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
>>>>>>> 6fc21a23771319b9a26fef2c7cf86a18d092d2d6
    </div>
  );
}
