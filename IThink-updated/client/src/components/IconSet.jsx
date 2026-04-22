import React, { useEffect } from 'react';
import '../styles/IconSet.css';
import '../styles/landingpage.css';

const SearchSVG = () => (
  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="svg-icon svg-search">
    <circle cx="11" cy="11" r="8"></circle>
    <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
  </svg>
);

const IdeaSVG = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="svg-icon svg-idea">
    <path d="M12 2C8.13 2 5 5.13 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.87-3.13-7-7-7zM9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1z"></path>
  </svg>
);

const CheckSVG = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="svg-icon svg-check">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"></path>
  </svg>
);

const TargetSVG = () => (
  <svg viewBox="0 0 24 24" fill="currentColor" className="svg-icon svg-target">
    <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 18c-4.41 0-8-3.59-8-8s3.59-8 8-8 8 3.59 8 8-3.59 8-8 8zm0-13c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zm0 8c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3z"></path>
  </svg>
);

const iconData = [
  { Svg: SearchSVG, label: "Validate",  style: "icon-white" },
  { Svg: IdeaSVG,   label: "Innovate",  style: "icon-colored" },
  { Svg: CheckSVG,  label: "Confirm",   style: "icon-colored" },
  { Svg: TargetSVG, label: "Target",    style: "icon-colored" },
];

export default function IconSet() {
  useEffect(() => {
    const els = document.querySelectorAll('.icon-wrapper.animate-in');
    const observer = new IntersectionObserver(
      entries => entries.forEach(e => e.isIntersecting ? e.target.classList.add('visible') : e.target.classList.remove('visible')),
      { threshold: 0.15 }
    );
    els.forEach(el => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  return (
    <div className="icon-set-container">
      {iconData.map((icon, index) => (
        <div key={index} className="icon-wrapper animate-in fade-up" style={{ transitionDelay: `${index * 0.1}s` }}>
          <div className={`icon-box ${icon.style}`}>
            <icon.Svg />
          </div>
          <span className="icon-label">{icon.label}</span>
        </div>
      ))}
    </div>
  );
}
