import { createElement } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  FiArrowRight,
  FiArrowUpRight,
  FiCode,
  FiCompass,
  FiFileText,
  FiLayers,
  FiMap,
  FiSmartphone,
  FiZap,
} from 'react-icons/fi';
import '../styles/landing.css';

const steps = [
  { number: '01', icon: FiSmartphone, title: 'Notice what matters', description: 'Save a community challenge from the Alitaptap mobile app when the idea is still fresh.' },
  { number: '02', icon: FiCompass, title: 'Bring it into focus', description: 'Open your saved ideas on desktop and choose the one you are ready to explore.' },
  { number: '03', icon: FiZap, title: 'Make a way forward', description: 'Turn a promising thought into a structured project plan with clear next steps.' },
];

const features = [
  { icon: FiLayers, title: 'Project framing', description: 'Scope your idea into clear goals, deliverables, and a practical starting point.' },
  { icon: FiCode, title: 'Build-ready stack', description: 'See recommended tools and technologies shaped around the problem you chose.' },
  { icon: FiMap, title: 'Guided roadmap', description: 'Move through a thoughtful sequence from research and validation to launch.' },
  { icon: FiFileText, title: 'Structured output', description: 'Keep project details, starter code, and documentation together in one place.' },
];

function CubeField() {
  return <div className="land-cube-field" aria-hidden="true">{Array.from({ length: 24 }, (_, index) => <span key={index} />)}</div>;
}

export default function LandingPage() {
  const navigate = useNavigate();

  return (
    <main className="land-root">
      <div className="land-grid-overlay" aria-hidden="true" />
      <div className="land-aurora land-aurora-one" aria-hidden="true" />
      <div className="land-aurora land-aurora-two" aria-hidden="true" />

      <nav className="land-nav" aria-label="Main navigation">
        <a className="land-brand" href="#top" aria-label="Alitaptap home"><span className="land-brand-mark"><i /><i /><i /></span><span>ALITAPTAP</span></a>
        <div className="land-nav-links"><a href="#how">How it works</a><a href="#toolkit">Toolkit</a></div>
        <button className="land-nav-cta" onClick={() => navigate('/login')}>Start a project <FiArrowUpRight aria-hidden="true" /></button>
      </nav>

      <section className="land-hero" id="top">
        <div className="land-hero-copy">
          <p className="land-kicker"><span /> Community ideas, made actionable</p>
          <h1>Make room for<br /><em>bright</em> local ideas<span className="land-pixel-word"> now</span>.</h1>
          <p className="land-hero-description">Alitaptap turns the problems you notice into research projects with a clear, confident path from first spark to real-world impact.</p>
          <div className="land-hero-actions">
            <button className="land-btn-primary" onClick={() => navigate('/login')}>Begin with an idea <FiArrowRight aria-hidden="true" /></button>
            <a href="#how" className="land-text-link">Explore the process <FiArrowRight aria-hidden="true" /></a>
          </div>
          <div className="land-trust-row"><span className="land-trust-spark">+</span><p>Built around the problems your community already knows.</p></div>
        </div>

        <div className="land-project-window" aria-label="An example Alitaptap project plan">
          <div className="land-window-topline"><span>LIVE PROJECT VIEW</span><span>01 / 04</span></div>
          <div className="land-window-title-row"><div><p>Saved community signal</p><h2>Flood-ready<br /><em>barangays.</em></h2></div><span className="land-sun-token">*</span></div>
          <div className="land-window-flow">
            <article className="land-window-card land-window-card-idea"><span className="land-card-tag">THE START</span><p>Low-cost flood alerts for areas that need more time to respond.</p></article>
            <div className="land-flow-rail"><span /></div>
            <article className="land-window-card land-window-card-plan"><span className="land-card-tag">THE PLAN</span><ul><li><b>01</b> Community context</li><li><b>02</b> Practical tech stack</li><li><b>03</b> Starter implementation</li></ul><span className="land-card-status">Ready to shape</span></article>
          </div>
          <CubeField />
        </div>
      </section>

      <section className="land-intro" aria-label="Alitaptap introduction">
        <div className="land-intro-label">ALITAPTAP / FIELD NOTES</div>
        <p>The <em>real world</em> is already full of meaningful prompts. We help you <span>carry them forward</span> with care.</p>
        <div className="land-dots" aria-hidden="true" />
      </section>

      <section className="land-how" id="how">
        <div className="land-section-heading"><p className="land-kicker"><span /> An intentional process</p><h2>One small signal.<br /><em>A project with direction.</em></h2><p>From a saved observation to a shareable plan, the path stays simple and visible.</p></div>
        <div className="land-steps">
          {steps.map(({ number, icon: Icon, title, description }) => <article className="land-step" key={number}><div className="land-step-top"><span>{number}</span>{createElement(Icon, { 'aria-hidden': true })}</div><h3>{title}</h3><p>{description}</p><div className="land-step-line" /></article>)}
        </div>
        <CubeField />
      </section>

      <section className="land-toolkit" id="toolkit">
        <div className="land-toolkit-copy"><p className="land-kicker"><span /> The research toolkit</p><h2>Thoughtful tools for <em>making</em> momentum.</h2><p>Everything is designed to help a local concern become a grounded, buildable response.</p><button className="land-btn-secondary" onClick={() => navigate('/login')}>Open Alitaptap <FiArrowUpRight aria-hidden="true" /></button></div>
        <div className="land-features-grid">
          {features.map(({ icon: Icon, title, description }) => <article className="land-feature-card" key={title}><span className="land-feature-icon">{createElement(Icon, { 'aria-hidden': true })}</span><h3>{title}</h3><p>{description}</p><FiArrowUpRight className="land-feature-arrow" aria-hidden="true" /></article>)}
        </div>
      </section>

      <section className="land-cta">
        <div className="land-cta-aurora" aria-hidden="true" /><CubeField />
        <p className="land-kicker"><span /> A place to begin</p><h2>Let the next <em>useful</em><br /> idea find its form.</h2><p className="land-cta-copy">Start with a problem worth noticing. We will help you map what comes next.</p>
        <button className="land-btn-primary land-btn-large" onClick={() => navigate('/login')}>Start building <FiArrowRight aria-hidden="true" /></button>
      </section>

      <footer className="land-footer"><a className="land-brand" href="#top"><span className="land-brand-mark"><i /><i /><i /></span><span>ALITAPTAP</span></a><p>Community problems, student research, real impact.</p><span>2026</span></footer>
    </main>
  );
}
