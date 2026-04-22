import React, { useEffect } from 'react';
import Navbar from '../components/Navbar';
import FloatingLines from '../components/FloatingLines';
import '../styles/HowItWorks.css';
import '../styles/landingpage.css';
import imgAccount from '../images/step-account.svg';
import imgPaste from '../images/step-paste.svg';
import imgAnalyze from '../images/card-credibility.svg';
import imgResults from '../images/step-results.svg';
import imgExport from '../images/card-export.svg';
import imgImprove from '../images/card-improve.svg';

const steps = [
  { id: 1, title: "Create an Account", text: "Sign up for free using your email or Google account. Your Alitaptap workspace is ready in seconds.", img: imgAccount },
  { id: 2, title: "Paste Your Text", text: "Copy and paste any article, claim, research excerpt, or statement into the Alitaptap editor.", img: imgPaste },
  { id: 3, title: "Run a Credibility Check", text: "Click Analyze and let Alitaptap scan your text for source quality, factual accuracy, and potential bias.", img: imgAnalyze },
  { id: 4, title: "Review the Results", text: "Alitaptap returns a detailed credibility score with highlighted inaccuracies and source validation notes.", img: imgResults },
  { id: 5, title: "Save or Export", text: "Save your analysis as a draft, export it as a report, or share it directly with your team or classmates.", img: imgExport },
  { id: 6, title: "Keep Improving", text: "Use Alitaptap regularly to sharpen your critical thinking and build a habit of verifying information before acting on it.", img: imgImprove },
];

const HowItWorks = () => {
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
    <div className="how-it-works-page">
      <Navbar />
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}>
        <FloatingLines enabledWaves={['top', 'middle', 'bottom']} lineCount={5} lineDistance={5} bendRadius={5} bendStrength={-0.5} interactive={true} parallax={true} />
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>
      <section className="how-header animate-in fade-up">
        <div className="how-header-text">
          <h1>How to use Alitaptap?</h1>
          <p>Follow these steps to identify truth and spot inaccuracies:</p>
        </div>
        <div className="how-header-step">
          <div className="step-text-content">
            <h3>{steps[0].title}</h3>
            <p>{steps[0].text}</p>
          </div>
          <div className="step-visual-box"><img src={steps[0].img} alt={steps[0].title} /></div>
        </div>
      </section>

      <div className="steps-container">
        {steps.slice(1).map((step) => (
          <div key={step.id} className={`step-item animate-in ${step.id % 2 === 0 ? 'fade-left' : 'fade-up'}`}>
            <div className="step-text-content">
              <h3>{step.title}</h3>
              <p>{step.text}</p>
            </div>
            <div className="step-visual-box"><img src={step.img} alt={step.title} /></div>
          </div>
        ))}
      </div>

      <section className="how-cta gradient-mesh animate-in fade-up">
        <h2>Alitaptap is your AI truth partner</h2>
        <p>Love the clarity Alitaptap gives you in identifying truth? Alitaptap brings that same confidence to every claim, source, and piece of information.</p>
        <button className="white-btn">Learn more</button>
      </section>

      <div className="branding-strip animate-in fade-up">
        <p className="cta-this-is">This is</p>
        <h2 className="cta-tagline"><span className="blue-it">IT</span>hink</h2>
        <p>Identify <b>Truth</b>. Highlight <b>Inaccuracies</b>. Navigate <b>Knowledge</b>.</p>
      </div>

      <footer className="footer-v2">
        <div className="footer-grid">
          <div className="footer-main-info">
            <h4>About Us</h4>
            <p>Alitaptap was built to help you think smarter. We combine AI with credibility research to give you tools that verify sources, detect bias, and score information accuracy.</p>
            <a href="#" className="learn-link">Learn More</a>
            <p className="footer-subtext">Review how we handle your data in our <br/> <b>Terms & Privacy Policy</b>. <br/> Learn how we assist you in our <b>Help Center</b>.</p>
          </div>
          <div className="footer-nav">
            <h4>Features</h4>
            <ul>
              <li>Claim Detection</li>
              <li>Source Validation</li>
              <li>Fact Cross-Verification</li>
              <li>Credibility Scoring</li>
            </ul>
          </div>
          <div className="footer-nav">
            <h4>Quick Links</h4>
            <div className="links-grid">
              <a href="#">Link</a><a href="#">Link</a>
              <a href="#">Link</a><a href="#">Link</a>
              <a href="#">Link</a><a href="#">Link</a>
              <a href="#">Link</a><a href="#">Link</a>
            </div>
          </div>
          <div className="footer-nav">
            <h4>Connect</h4>
            <ul className="social-list">
              <li><span className="dot fb"></span> Facebook</li>
              <li><span className="dot ig"></span> Instagram</li>
              <li><span className="dot x"></span> X</li>
              <li><span className="dot tk"></span> TikTok</li>
              <li><span className="dot gm"></span> Gmail</li>
            </ul>
          </div>
        </div>
        <p className="copyright-bar">2026 Alitaptap. All Rights Reserved.</p>
      </footer>
      </div>
    </div>
  );
};

export default HowItWorks;
