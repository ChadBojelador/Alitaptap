import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { BACKEND_URL } from '../App';
import '../styles/account.css';

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
    <div className="acc-root">
      {/* Sidebar */}
      <aside className="acc-sidebar">
        <div className="acc-sidebar-logo">● ALITAPTAP</div>
        <nav className="acc-sidebar-nav">
          <a href="/dashboard" className="acc-nav-item">🗺️ Ideas</a>
          <a href="/research" className="acc-nav-item">✍️ Research</a>
          <a href="/expo" className="acc-nav-item">🚀 Expo</a>
        </nav>
        <button className="acc-signout" onClick={() => {
          localStorage.removeItem('token');
          window.location.href = '/';
        }}>Sign Out</button>
      </aside>

      {/* Main */}
      <div className="acc-main">
        <div className="acc-header">
          <h1>Account Settings</h1>
          <p>Manage your profile, security, and login options</p>
        </div>

        {/* Tabs */}
        <div className="acc-tabs">
          {[
            { id: 'profile', label: '👤 Profile' },
            { id: 'qr', label: '📱 QR Login' },
            { id: 'security', label: '🔒 Security' },
          ].map(t => (
            <button key={t.id}
              className={`acc-tab ${activeTab === t.id ? 'acc-tab--active' : ''}`}
              onClick={() => setActiveTab(t.id)}>
              {t.label}
            </button>
          ))}
        </div>

        {/* ── Profile Tab ─────────────────────────────────────────────── */}
        {activeTab === 'profile' && (
          <div className="acc-section">
            {/* Avatar */}
            <div className="acc-avatar-section">
              <div className="acc-avatar" onClick={() => fileRef.current?.click()}>
                {form.avatarUrl
                  ? <img src={form.avatarUrl} alt="avatar" />
                  : <span>{initials}</span>}
                <div className="acc-avatar-overlay">📷</div>
              </div>
              <input ref={fileRef} type="file" accept="image/*"
                style={{ display: 'none' }} onChange={handleAvatarFile} />
              <div className="acc-avatar-info">
                <h3>{form.displayName || user?.email?.split('@')[0]}</h3>
                <p>{user?.email}</p>
                <button className="acc-btn-ghost" onClick={() => fileRef.current?.click()}>
                  Change Photo
                </button>
              </div>
            </div>

            {/* Form */}
            <div className="acc-form">
              <div className="acc-form-row">
                <div className="acc-form-group">
                  <label>Display Name</label>
                  <input value={form.displayName}
                    onChange={e => setForm(p => ({ ...p, displayName: e.target.value }))}
                    placeholder="Your full name" />
                </div>
                <div className="acc-form-group">
                  <label>Institution / School</label>
                  <input value={form.institution}
                    onChange={e => setForm(p => ({ ...p, institution: e.target.value }))}
                    placeholder="e.g. University of the Philippines" />
                </div>
              </div>
              <div className="acc-form-group">
                <label>Location</label>
                <input value={form.location}
                  onChange={e => setForm(p => ({ ...p, location: e.target.value }))}
                  placeholder="e.g. Manila, Philippines" />
              </div>
              <div className="acc-form-group">
                <label>Bio</label>
                <textarea rows={4} value={form.bio}
                  onChange={e => setForm(p => ({ ...p, bio: e.target.value }))}
                  placeholder="Tell the community about your research interests..." />
              </div>
              <div className="acc-form-actions">
                <button className="acc-btn-save" onClick={saveProfile} disabled={saving}>
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
    </div>
  );
}
