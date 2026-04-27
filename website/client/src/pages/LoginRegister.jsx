import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import '../styles/auth.css';
import { BACKEND_URL } from '../App';

function GoogleGIcon({ size = 20 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 20 20" fill="none">
      <path d="M19.6 10.23c0-.68-.06-1.36-.18-2H10v3.79h5.48a4.7 4.7 0 0 1-2.04 3.08v2.56h3.3c1.93-1.78 3.06-4.4 3.06-7.43z" fill="#4285F4"/>
      <path d="M10 20c2.7 0 4.97-.89 6.63-2.41l-3.3-2.56c-.92.62-2.1.99-3.33.99-2.56 0-4.73-1.73-5.5-4.07H1.1v2.6A10 10 0 0 0 10 20z" fill="#34A853"/>
      <path d="M4.5 12.95A5.99 5.99 0 0 1 4.06 10c0-.51.09-1.01.14-1.49V5.91H1.1A10 10 0 0 0 0 10c0 1.56.37 3.03 1.1 4.09l3.4-1.14z" fill="#FBBC05"/>
      <path d="M10 4.01c1.47 0 2.78.51 3.81 1.51l2.85-2.85C14.97 1.13 12.7.01 10 .01A10 10 0 0 0 1.1 5.91l3.4 2.6C5.27 5.74 7.44 4.01 10 4.01z" fill="#EA4335"/>
    </svg>
  );
}

export default function LoginRegister({ setUser }) {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [displayName, setDisplayName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [agreed, setAgreed] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    setSuccessMsg('');

    if (!isLogin && !displayName.trim()) {
      setError('Display name is required.');
      setLoading(false);
      return;
    }
    if (!isLogin && !agreed) {
      setError('You must agree to the Terms to sign up.');
      setLoading(false);
      return;
    }
    if (!isLogin) {
      if (password.length < 8) return (setError('Password must be at least 8 characters'), setLoading(false));
      if (!/[A-Z]/.test(password)) return (setError('Password must contain an uppercase letter'), setLoading(false));
      if (!/[0-9]/.test(password)) return (setError('Password must contain a number'), setLoading(false));
    }

    const endpoint = isLogin ? '/login' : '/signup';
    try {
      const response = await fetch(`${BACKEND_URL}${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ email, password, displayName }),
      });

      if (response.ok) {
        if (isLogin) {
          const data = await response.json();
          localStorage.setItem('token', data.token);
          axios.defaults.headers.common['Authorization'] = `Bearer ${data.token}`;
          setUser(data.user);
          navigate('/home');
        } else {
          const loginRes = await fetch(`${BACKEND_URL}/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ email, password, displayName }),
          });
          if (loginRes.ok) {
            const data = await loginRes.json();
            localStorage.setItem('token', data.token);
            axios.defaults.headers.common['Authorization'] = `Bearer ${data.token}`;
            setSuccessMsg('Account created! Redirecting...');
            setTimeout(() => { setUser(data.user); navigate('/home'); }, 1200);
          }
        }
      } else {
        const err = await response.json().catch(() => ({}));
        setError(err.error || 'Invalid credentials');
      }
    } catch {
      setError('Cannot connect to server. Is the backend running?');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Left Panel */}
      <div className="left-panel">
        <div className="content-wrapper">
          <div className="brand-logo-mark">●</div>
          <h1 className="brand-title">ALITAPTAP</h1>
          <p className="brand-subtitle">
            Community problems → Student research<br />
            → Real impact. Build with AI.
          </p>
          <button className="learn-more-btn" onClick={() => navigate('/')}>
            Learn more
          </button>
        </div>
      </div>

      {/* Right Panel */}
      <div className="right-panel">
        <div className="login-box">
          <div className="login-brand-top">
            <span className="login-brand-dot">●</span>
            <span className="login-brand-name">ALITAPTAP</span>
          </div>

          <h2 className="login-header">
            {isLogin ? 'Welcome back' : 'Create account'}
          </h2>
          <p className="login-subheader">
            {isLogin ? 'Sign in to your workspace' : 'Join the research community'}
          </p>

          <form className="login-form" onSubmit={handleSubmit} autoComplete="off">
            {!isLogin && (
              <input
                type="text"
                placeholder="Display name"
                className="input-field"
                value={displayName}
                onChange={e => setDisplayName(e.target.value)}
                required={!isLogin}
              />
            )}
            <input
              type="email"
              placeholder="Email address"
              className="input-field"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
            />
            <input
              type="password"
              placeholder="Password"
              className="input-field"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
            />
            {!isLogin && (
              <label className="terms-checkbox-wrap">
                <input type="checkbox" checked={agreed} onChange={e => setAgreed(e.target.checked)} />
                <span>I agree to the Terms and Privacy Policy</span>
              </label>
            )}
            <button type="submit" className="login-submit-btn" disabled={loading || (!isLogin && !agreed)}>
              {loading ? 'Processing...' : (isLogin ? 'Sign In' : 'Create Account')}
            </button>
            {successMsg && <p className="msg-success">{successMsg}</p>}
            {error && <p className="msg-error">{error}</p>}
          </form>

          <div className="divider">
            <span className="line" /><span className="or-text">or</span><span className="line" />
          </div>

          <button className="google-login-btn" type="button"
            onClick={() => window.location.href = `${BACKEND_URL}/auth/google`}>
            <GoogleGIcon />
            {isLogin ? 'Sign in' : 'Sign up'} with Google
          </button>

          <div className="auth-switch">
            {isLogin ? "Don't have an account? " : 'Already have an account? '}
            <button type="button" className="switch-btn"
              onClick={() => { setIsLogin(!isLogin); setAgreed(false); setError(''); setDisplayName(''); }}>
              {isLogin ? 'Sign up' : 'Sign in'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
