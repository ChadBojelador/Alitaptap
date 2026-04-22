import { useEffect, useState } from 'react';
import '../styles/loading.css';

const PHRASES = [
  'Syncing your ideas...',
  'Loading your workspace...',
  'Connecting to community...',
  'Almost ready...',
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
      <div className="ls-orb ls-orb--1" />
      <div className="ls-orb ls-orb--2" />
      <div className="ls-orb ls-orb--3" />

      <div className="ls-center">
        <div className="ls-logo-wrap">
          <div className="ls-logo-ring" />
          <div className="ls-logo-ring ls-logo-ring--2" />
          <div className="ls-logo-core">
            <span className="ls-logo-dot">●</span>
          </div>
        </div>

        <div className="ls-brand">ALITAPTAP</div>
        <div className="ls-tagline">Community · Research · Impact</div>

        <div className="ls-bar-track">
          <div className="ls-bar-fill" />
        </div>

        <div className="ls-dots">
          <span /><span /><span />
        </div>

        <div className="ls-phrase" key={phrase}>{PHRASES[phrase]}</div>
      </div>
    </div>
  );
}
