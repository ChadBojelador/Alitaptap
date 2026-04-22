import { BrowserRouter as Router, Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { useState, useEffect } from 'react';
import LoadingScreen from './components/LoadingScreen';
import axios from 'axios';
import './styles/auth.css';
import LoginRegister from './pages/LoginRegister';
import Dashboard from './pages/Dashboard';
import Draft from './pages/Draft';
import Account from './pages/Account';
import Persona from './pages/Persona';
import LandingPage from './pages/LandingPage';
import Features from './pages/Features';
import HowItWorks from './pages/HowItWorks';
import LegalAndSignup from './pages/LegalAndSignup';
import AboutPage from './pages/About';
import Chat from './pages/Chat';
import Trash from './pages/Trash';

// Set global axios defaults for the entire app
axios.defaults.withCredentials = true;

// Dynamically resolve API URL based on current origin
const { hostname, port } = window.location;
const isViteDev = port === '5173';
export const BACKEND_URL = import.meta.env.VITE_API_URL
  ? import.meta.env.VITE_API_URL
  : isViteDev
    ? `http://${hostname}:3000`
    : window.location.origin;

function TermsRequired({ user, setUser }) {
  const navigate = useNavigate();

  const handleAgree = async () => {
    await axios.post(`${BACKEND_URL}/api/user/agree-terms`);
    setUser(prev => ({ ...prev, agreedToTerms: true }));
    navigate('/dashboard', { replace: true });
  };

  const handleDecline = () => {
    localStorage.removeItem('token');
    delete axios.defaults.headers.common['Authorization'];
    setUser(null);
    navigate('/login', { replace: true });
  };

  return (
    <div className="terms-modal-overlay">
      <div className="terms-modal">
        <h3>Before you continue</h3>
        <p>
          By using Alitaptap, you agree to our{' '}
          <a href="/terms" target="_blank" rel="noreferrer">Terms and Conditions</a>{' '}and{' '}
          <a href="/terms" target="_blank" rel="noreferrer">Privacy Policy</a>.
          Please read them before proceeding.
        </p>
        <div className="terms-modal-actions">
          <button className="terms-modal-agree" onClick={handleAgree}>I Agree — Continue to Alitaptap</button>
          <button className="terms-modal-decline" onClick={handleDecline}>Decline — Go back to login</button>
        </div>
      </div>
    </div>
  );
}

function OAuthCallback({ setUser }) {
  const navigate = useNavigate();
  const location = useLocation();

  useEffect(() => {
    const token = new URLSearchParams(location.search).get('token');
    if (token) {
      localStorage.setItem('token', token);
      axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
      axios.get(`${BACKEND_URL}/profile`)
        .then(res => {
          const u = res.data.user;
          setUser(u);
          navigate(u.agreedToTerms ? '/dashboard' : '/agree', { replace: true });
        })
        .catch(() => navigate('/login', { replace: true }));
    } else {
      navigate('/login', { replace: true });
    }
  }, []);

  return <LoadingScreen />;
}

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const checkAuth = async () => {
      try {
        const token = localStorage.getItem('token');
        if (!token) { setLoading(false); return; }
        axios.defaults.headers.common['Authorization'] = `Bearer ${token}`;
        const res = await axios.get(`${BACKEND_URL}/profile`);
        setUser(res.data.user);
      } catch (err) {
        localStorage.removeItem('token');
        setUser(null);
      } finally {
        setLoading(false);
      }
    };
    checkAuth();
  }, []);

  if (loading) return <LoadingScreen />;

  return (
    <Router>
      <Routes>
        {/* 1. Root Route: Send to dashboard if logged in, else login */}
        <Route path="/features" element={<Features />} />
        <Route path="/how-it-works" element={<HowItWorks />} />
        <Route path="/terms" element={<LegalAndSignup />} />
        <Route path="/about" element={<AboutPage />} />
        <Route path="/auth/callback" element={<OAuthCallback setUser={setUser} />} />
        <Route path="/" element={
          user ? <Navigate to="/dashboard" replace /> : <LandingPage />
        } />

        {/* 2. Login Route: If already logged in, skip this page */}
        <Route path="/login" element={
          user ? <Navigate to="/dashboard" replace /> : <LoginRegister setUser={setUser} />
        } />

        {/* Terms agreement for Google OAuth first-time users */}
        <Route path="/agree" element={
          !user ? <Navigate to="/login" replace /> :
          user.agreedToTerms ? <Navigate to="/dashboard" replace /> :
          <TermsRequired user={user} setUser={setUser} />
        } />

        {/* 3. Protected Dashboard Route */}
        <Route path="/dashboard" element={<Dashboard user={user} />} />
        <Route path="/draft" element={<Draft user={user} />} />
        <Route path="/draft/:id" element={<Draft user={user} />} />
        <Route path="/dashboard/trash" element={<Trash user={user} />} />
        <Route path="/dashboard/account" element={<Account user={user} setUser={setUser} />} />
        <Route path="/dashboard/persona" element={<Persona user={user} setUser={setUser} />} />
        <Route path="/dashboard/chat" element={<Chat user={user} />} />
        {/* 4. Catch-all: Redirect unknown URLs to login or dashboard */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;