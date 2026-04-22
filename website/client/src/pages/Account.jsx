import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { BACKEND_URL } from '../App';
import '../styles/account.css';
// import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import { FaUserCircle, FaQuestionCircle, FaArrowLeft } from 'react-icons/fa';

export default function Account({ user, setUser }) {
  const navigate = useNavigate();
  const fileRef = useRef(null);

  const [form, setForm] = useState({
    displayName: user?.displayName || '',
    bio: user?.bio || '',
    institution: user?.institution || '',
    location: user?.location || '',
    avatarUrl: user?.avatarUrl || '',
  });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [activeTab, setActiveTab] = useState('profile');
  const [qrData, setQrData] = useState(null);
  const [qrLoading, setQrLoading] = useState(false);
  const [qrExpiry, setQrExpiry] = useState(0);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [pwForm, setPwForm] = useState({ current: '', next: '', confirm: '' });
  const [pwMsg, setPwMsg] = useState('');

  // QR countdown
  useEffect(() => {
    if (!qrExpiry) return;
    const t = setInterval(() => {
      setQrExpiry(e => {
        if (e <= 1) { clearInterval(t); setQrData(null); return 0; }
        return e - 1;
      });
    }, 1000);
    return () => clearInterval(t);
  }, [qrExpiry]);

  const handleAvatarFile = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => setForm(p => ({ ...p, avatarUrl: ev.target.result }));
    reader.readAsDataURL(file);
  };

  const saveProfile = async () => {
    setSaving(true);
    try {
      const res = await axios.put(`${BACKEND_URL}/api/user/profile`, form, {
        headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
      });
      setUser(prev => ({ ...prev, ...res.data.user }));
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {}
    setSaving(false);
  };

  const generateQR = async () => {
    setQrLoading(true);
    try {
      const res = await axios.get(`${BACKEND_URL}/api/user/qr-token`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
      });
      // Build QR URL — points to login page with token pre-filled
      const qrUrl = `${window.location.origin}/login?qr=${res.data.qrToken}`;
      // Use QR Server API to generate QR image
      const qrImg = `https://api.qrserver.com/v1/create-qr-code/?size=220x220&data=${encodeURIComponent(qrUrl)}&bgcolor=0a0a0a&color=ffd60a&margin=10`;
      setQrData({ img: qrImg, token: res.data.qrToken, url: qrUrl });
      setQrExpiry(res.data.expiresIn);
    } catch {}
    setQrLoading(false);
  };

  const deleteAccount = async () => {
    setDeleting(true);
    try {
      await axios.delete(`${BACKEND_URL}/api/user`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
      });
      localStorage.removeItem('token');
      setUser(null);
      navigate('/login');
    } catch { setDeleting(false); }
  };

  const initials = (form.displayName || user?.email || 'U')[0].toUpperCase();

  return (
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
    </div>
  );
}
