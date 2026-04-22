import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/landingpage.css';
import logo from '../images/darkmode-logo.png';

export default function Navbar() {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);

  return (
    <header className="header">
      <div className="logo-container">
        <img src={logo} alt="Alitaptap" className="nav-logo-img" />
      </div>

      <nav className={`nav${open ? ' nav--open' : ''}`}>
        <a href="/" onClick={() => setOpen(false)}>Home</a>
        <a href="/features" onClick={() => setOpen(false)}>Features</a>
        <a href="/how-it-works" onClick={() => setOpen(false)}>How it Works</a>
        <a href="/terms" onClick={() => setOpen(false)}>Terms & Privacy</a>
        <a href="/about" onClick={() => setOpen(false)}>About</a>
        <button className="get-started-btn nav-mobile-cta" onClick={() => { setOpen(false); navigate('/login'); }}>Get Started</button>
      </nav>

      <div className="header-actions">
        <button className="get-started-btn" onClick={() => navigate('/login')}>Get Started</button>
        <button className="hamburger" onClick={() => setOpen(o => !o)} aria-label="Toggle menu">
          <span className={`bar${open ? ' bar--open' : ''}`}></span>
          <span className={`bar${open ? ' bar--open' : ''}`}></span>
          <span className={`bar${open ? ' bar--open' : ''}`}></span>
        </button>
      </div>

      {open && <div className="nav-overlay" onClick={() => setOpen(false)} />}
    </header>
  );
}
