import React, { useEffect } from 'react';
import Navbar from '../components/Navbar';
import { useNavigate } from 'react-router-dom';
import logo from '../images/logo.png';
import FloatingLines from '../components/FloatingLines';
import '../styles/About.css';
import '../styles/HowItWorks.css';
import '../styles/landingpage.css';
import { BACKEND_URL } from '../App';
import imgVision from '../images/about-vision.svg';
import imgMission from '../images/about-mission.svg';
import imgTeam from '../images/about-team.svg';
import imgDifferent from '../images/about-different.svg';

const AboutPage = () => {
  const navigate = useNavigate();
  const handleGoogleSignup = () => {
    window.location.href = `${BACKEND_URL}/auth/google`;
  };

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
    <div className="about-container">
      <Navbar />
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}>
        <FloatingLines enabledWaves={['top', 'middle', 'bottom']} lineCount={5} lineDistance={5} bendRadius={5} bendStrength={-0.5} interactive={true} parallax={true} />
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>

      <section className="about-hero animate-in fade-up">
        <h1>About Us</h1>
        <p className="hero-subtext">
          Alitaptap is an AI-powered platform built by students, for students. We created this tool to help learners like us verify information, detect bias, and navigate knowledge with clarity and confidence. In a world flooded with misinformation and unverified claims, we built Alitaptap to be a trusted partner in critical thinking — giving you the tools to question what you read, validate what you share, and make decisions grounded in verified facts.
        </p>
      </section>

      <section className="about-split vision animate-in fade-up">
        <div className="split-visual"><img src={imgVision} alt="Our Vision" style={{ width:'100%', height:'100%', objectFit:'cover', borderRadius:20 }} /></div>
        <div className="split-text">
          <h2>Our Vision</h2>
          <p>
            We envision a world where every student — regardless of background or technical expertise — has access to accurate, verified information. A world where misinformation cannot thrive because the tools to expose it are freely available and easy to use. As students ourselves, we built Alitaptap to be the platform we wished we had — one that empowers learners to think critically, question sources, and make decisions grounded in truth.
          </p>
          <p style={{ marginTop: '16px' }}>
            We see a future where students submit research backed by verified sources and can confidently distinguish fact from fiction in their feeds and readings. Alitaptap is building toward that future — one analysis at a time. Our vision is not just a product goal; it is a commitment to helping students like us access better information.
          </p>
        </div>
      </section>

      <section className="about-split mission reverse animate-in fade-left">
        <div className="split-visual"><img src={imgMission} alt="Our Mission" style={{ width:'100%', height:'100%', objectFit:'cover', borderRadius:20 }} /></div>
        <div className="split-text">
          <h2>Our Mission</h2>
          <p>
            Our mission is to make truth accessible to every student. We build intelligent tools that analyze claims, validate sources, and score credibility — so you can trust what you read, share, and cite in your work. Every feature we develop is guided by a single question: does this help students get closer to the truth? From source validation to credibility scoring, every tool in Alitaptap is designed with that purpose at its core.
          </p>
          <p style={{ marginTop: '16px' }}>
            We are students who got tired of not knowing whether the sources we were using were actually reliable. So we built something about it. Alitaptap does not just tell you whether something is true or false — it shows you why, walks you through the evidence, and empowers you to reach your own informed conclusions. Our mission is to be a partner in your thinking process, not a replacement for it.
          </p>
        </div>
      </section>

      <section className="mission-banner animate-in fade-up">
        <div className="banner-content">
          <h2>Our mission is to help you <br/> make sense of it all.</h2>
          <p>Identify <b>Truth</b>. Highlight <b>Inaccuracies</b>. Navigate <b>Knowledge</b>.</p>
        </div>
      </section>

      <section className="about-split animate-in fade-up">
        <div className="split-visual"><img src={imgTeam} alt="Who We Are" style={{ width:'100%', height:'100%', objectFit:'cover', borderRadius:20 }} /></div>
        <div className="split-text">
          <h2>Who We Are</h2>
          <p>
            Alitaptap was built by a group of students who were frustrated by the growing spread of misinformation and the lack of simple, accessible tools to verify what they were reading. We are college students from different fields — computer science, communications, and information technology — united by a shared frustration: why is it so hard to know if something is actually true?
          </p>
          <p style={{ marginTop: '16px' }}>
            Our team is small but driven. We built Alitaptap as a school project that grew into something we genuinely believe can help other students like us. We are not a big tech company — we are students who care about getting the right information and wanted to make that easier for everyone. Every feature in Alitaptap was built with one person in mind: a student trying to do their best work with reliable sources.
          </p>
        </div>
      </section>

      <section className="about-split reverse animate-in fade-left">
        <div className="split-visual"><img src={imgDifferent} alt="What Makes Alitaptap Different" style={{ width:'100%', height:'100%', objectFit:'cover', borderRadius:20 }} /></div>
        <div className="split-text">
          <h2>What Makes Alitaptap Different</h2>
          <p>
            Unlike generic AI assistants, Alitaptap is purpose-built for credibility analysis. We designed it specifically to help students evaluate sources, cross-check claims, and understand why something is or is not reliable — not just get a yes or no answer. This focus means Alitaptap actively evaluates the reliability of information against verified standards rather than just generating plausible-sounding responses.
          </p>
          <p style={{ marginTop: '16px' }}>
            We also believe in explainability. When Alitaptap flags a claim or rates a source, it tells you exactly why — so you can learn from it, not just copy it. As students, we know the difference between a tool that does your thinking for you and one that makes you a better thinker. Alitaptap is built to be the second kind. That is what makes it different, and that is why we built it.
          </p>
        </div>
      </section>

      <section className="about-cta animate-in fade-up">
        <div className="cta-logo">
          <img src={logo} alt="Alitaptap Logo" className="about-logo-img" />
        </div>
        <h3>Truth powers better decisions</h3>
        <p>Rely on Alitaptap to highlight inaccuracies, verify sources, and navigate knowledge with ease.</p>
        <div className="cta-buttons">
          <button className="btn-signup" onClick={() => navigate('/login')}>Sign up for free</button>
          <button className="btn-google" onClick={handleGoogleSignup}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M19.6 10.23c0-.68-.06-1.36-.18-2H10v3.79h5.48a4.7 4.7 0 0 1-2.04 3.08v2.56h3.3c1.93-1.78 3.06-4.4 3.06-7.43z" fill="#4285F4"/>
              <path d="M10 20c2.7 0 4.97-.89 6.63-2.41l-3.3-2.56c-.92.62-2.1.99-3.33.99-2.56 0-4.73-1.73-5.5-4.07H1.1v2.6A10 10 0 0 0 10 20z" fill="#34A853"/>
              <path d="M4.5 12.95A5.99 5.99 0 0 1 4.06 10c0-.51.09-1.01.14-1.49V5.91H1.1A10 10 0 0 0 0 10c0 1.56.37 3.03 1.1 4.09l3.4-1.14z" fill="#FBBC05"/>
              <path d="M10 4.01c1.47 0 2.78.51 3.81 1.51l2.85-2.85C14.97 1.13 12.7.01 10 .01A10 10 0 0 0 1.1 5.91l3.4 2.6C5.27 5.74 7.44 4.01 10 4.01z" fill="#EA4335"/>
            </svg>
            Sign up with Google
          </button>
        </div>
        <p className="about-legal">By signing up, you agree to the <a href="/terms" style={{ color: '#fff' }}><b>Terms and Conditions and Privacy Policy</b></a>.<br/> Learn how we assist you in our <a href="/how-it-works" style={{ color: '#fff' }}><b>Help Center</b></a>.</p>
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
            <p>Alitaptap was built by a team passionate about truth and technology. We combine AI with credibility research to give you a smarter way to verify information and navigate knowledge.</p>
            <a href="#" className="learn-link">Learn More</a>
            <p className="footer-subtext">Review how we handle your data in our <br/> <b>Terms &amp; Privacy Policy</b>. <br/> Learn how we assist you in our <b>Help Center</b>.</p>
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

export default AboutPage;
