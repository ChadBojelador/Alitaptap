import React, { useEffect } from 'react';
import Navbar from '../components/Navbar';
import IconSet from '../components/IconSet';
import FloatingLines from '../components/FloatingLines';
import '../styles/Features.css';
import '../styles/landingpage.css';
import imgSource from '../images/card-source.svg';
import imgFactcheck from '../images/card-factcheck.svg';
import imgClarity from '../images/card-chat.svg';
import imgCredibility from '../images/card-credibility.svg';

const FeaturesPage = () => {
  useEffect(() => {
    const els = document.querySelectorAll('.animate-in');
    const observer = new IntersectionObserver(
      entries => entries.forEach(e => e.isIntersecting ? e.target.classList.add('visible') : e.target.classList.remove('visible')),
      { threshold: 0.15 }
    );
    els.forEach(el => observer.observe(el));
    return () => observer.disconnect();
  }, []);

  return (
    <div className="features-container">
      <Navbar />
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}>
        <FloatingLines enabledWaves={['top', 'middle', 'bottom']} lineCount={5} lineDistance={5} bendRadius={5} bendStrength={-0.5} interactive={true} parallax={true} />
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>
      <header className="features-header animate-in fade-up">
        <h1>Features</h1>
        <p className="intro-text">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor 
          incididunt ut labore et dolore magna aliqua. Ut enim ad mini.
        </p>

        <IconSet />

        <p className="sub-text">
          Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor 
          incididunt ut labore et dolore magna aliqua. Ut enim ad mini. Lorem ipsum dolor sit amet, 
          consectetur adipiscing elit.
        </p>
      </header>

      <section className="feature-block blue-bg animate-in fade-up">
        <div className="feature-content">
          <h2>Source Validation</h2>
          <p>Alitaptap checks whether your sources are peer-reviewed, authoritative, and up-to-date — so you only cite what's credible.</p>
        </div>
        <div className="feature-placeholder"><img src={imgSource} alt="Source Validation" /></div>
      </section>

      <section className="feature-block white-bg reverse animate-in fade-left">
        <div className="feature-content">
          <h2>Fact Cross-Verification</h2>
          <p>Compare claims against verified datasets and academic papers to confirm accuracy before you publish or share.</p>
        </div>
        <div className="feature-placeholder"><img src={imgFactcheck} alt="Fact Cross-Verification" /></div>
      </section>

      <section className="feature-block blue-bg animate-in fade-up">
        <div className="feature-content">
          <h2>AI Chat Assistant</h2>
          <p>Ask Alitaptap anything. Our built-in AI chatbot helps you dig deeper into claims, get instant explanations, and explore topics with guided, intelligent conversation — all in real time.</p>
        </div>
        <div className="feature-placeholder"><img src={imgClarity} alt="AI Chat Assistant" /></div>
      </section>

      <section className="feature-block white-bg reverse animate-in fade-left">
        <div className="feature-content">
          <h2>Credibility Scoring</h2>
          <p>Get instant ratings — High Credibility, Needs Verification, or Likely False — so you can make informed decisions with confidence.</p>
        </div>
        <div className="feature-placeholder"><img src={imgCredibility} alt="Credibility Scoring" /></div>
      </section>

      <section className="cta-section animate-in fade-up">
        <h2>Alitaptap is your AI truth partner</h2>
        <p>Love the clarity Alitaptap gives you in identifying truth? Alitaptap brings that same 
           confidence to every claim, source, and piece of information.</p>
        <button className="cta-btn">Learn more</button>
        <p className="cta-this-is">This is</p>
        <h2 className="cta-tagline"><span className="blue-it">IT</span>hink</h2>

        <div className="brand-logo-footer">               
          <p>Identify <b>Truth</b>. Highlight <b>Inaccuracies</b>. Navigate <b>Knowledge</b>.</p>
        </div>
      </section>

      <footer className="footer-main">
        <div className="footer-grid">
          <div className="footer-col">
            <h4>About Us</h4>
            <p>Alitaptap was built to help you think smarter. We combine AI with credibility research to give you tools that verify sources, detect bias, and score information accuracy.</p>
            <a href="#" className="footer-link-bold">Learn More</a>
          </div>
          <div className="footer-col">
            <h4>Features</h4>
            <ul>
              <li>Claim Detection</li>
              <li>Source Validation</li>
              <li>Fact Cross-Verification</li>
              <li>Credibility Scoring</li>
            </ul>
          </div>
          <div className="footer-col">
            <h4>Quick Links</h4>
            <div className="links-double">
              <span>Link</span><span>Link</span>
              <span>Link</span><span>Link</span>
              <span>Link</span><span>Link</span>
            </div>
          </div>
          <div className="footer-col">
            <h4>Connect</h4>
            <div className="socials">
              <span className="social-row"><div className="dot"></div> Facebook</span>
              <span className="social-row"><div className="dot"></div> Instagram</span>
              <span className="social-row"><div className="dot"></div> X</span>
              <span className="social-row"><div className="dot"></div> Gmail</span>
            </div>
          </div>
        </div>
        <p className="copyright">2026 Alitaptap. All Right Reserved.</p>
      </footer>
      </div>
    </div>
  );
};

export default FeaturesPage;
