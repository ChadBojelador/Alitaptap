import { useEffect, useState } from 'react';
import '../styles/loading.css';

const PHRASES = [
  'Verifying your session...',
  'Loading your workspace...',
  'Almost there...',
];

export default function LoadingScreen() {
  const [phrase, setPhrase] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setPhrase(p => (p + 1) % PHRASES.length), 1400);
    return () => clearInterval(t);
  }, []);

  return (
    <div className="ls-root">
      <div className="ls-bg" />

      {/* Floating orbs */}
      <div className="ls-orb ls-orb--1" />
      <div className="ls-orb ls-orb--2" />
      <div className="ls-orb ls-orb--3" />

      <div className="ls-center">
        {/* Logo mark */}
        <div className="ls-logo-wrap">
          <div className="ls-logo-ring" />
          <div className="ls-logo-ring ls-logo-ring--2" />
          <div className="ls-logo-core">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#1A1A1A" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
              <path d="M12 2a7 7 0 0 1 7 7c0 3.5-2.5 6-4 7.5V18a1 1 0 0 1-1 1h-4a1 1 0 0 1-1-1v-1.5C7.5 15 5 12.5 5 9a7 7 0 0 1 7-7z"/>
              <line x1="9" y1="21" x2="15" y2="21"/>
              <line x1="10" y1="23" x2="14" y2="23"/>
            </svg>
          </div>
        </div>

        {/* Brand name */}
        <div className="ls-brand">Alitaptap</div>

        {/* Animated bar */}
        <div className="ls-bar-track">
          <div className="ls-bar-fill" />
        </div>

        {/* Dots */}
        <div className="ls-dots">
          <span /><span /><span />
        </div>

        {/* Phrase */}
        <div className="ls-phrase" key={phrase}>{PHRASES[phrase]}</div>
      </div>
    </div>
  );
}
