import React from 'react';
import { useNavigate } from 'react-router-dom';
import { BACKEND_URL } from '../App';
import { Swiper, SwiperSlide } from 'swiper/react';
import { Pagination, Autoplay } from 'swiper/modules';
import 'swiper/css';
import 'swiper/css/pagination';
import '../styles/landingpage.css';
import '../styles/FeatureCarousel.css';
import Navbar from '../components/Navbar';
import FloatingLines from '../components/FloatingLines';
import imgSourceValidation from '../images/card-source.svg';
import imgHighlight from '../images/card-factcheck.svg';
import imgScore from '../images/card-credibility.svg';
import imgClarity from '../images/card-clarity.svg';
import imgNavigate from '../images/card-navigate.svg';

const CARDS = [
  { title: 'Source Validation',  description: 'Checks if sources are peer-reviewed, authoritative, and recent.', gradient: 'linear-gradient(135deg, #6366f1 0%, #0ea5e9 100%)', img: imgSourceValidation },
  { title: 'Fact Cross-Check',   description: 'Compares claims with verified datasets and academic papers.',       gradient: 'linear-gradient(135deg, #4f46e5 0%, #a855f7 100%)', img: imgHighlight },
  { title: 'Credibility Scoring',description: 'Analyzes language patterns and potential biases in real-time.',     gradient: 'linear-gradient(135deg, #06b6d4 0%, #3b82f6 100%)', img: imgScore },
  { title: 'Clarity Score',      description: 'Rates how clearly and logically an argument is structured.',        gradient: 'linear-gradient(135deg, #0F766E 0%, #14B8A6 100%)', img: imgClarity },
];

function GoogleIcon() {
  return (
    <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
      <path d="M19.6 10.23c0-.68-.06-1.36-.18-2H10v3.79h5.48a4.7 4.7 0 0 1-2.04 3.08v2.56h3.3c1.93-1.78 3.06-4.4 3.06-7.43z" fill="#4285F4"/>
      <path d="M10 20c2.7 0 4.97-.89 6.63-2.41l-3.3-2.56c-.92.62-2.1.99-3.33.99-2.56 0-4.73-1.73-5.5-4.07H1.1v2.6A10 10 0 0 0 10 20z" fill="#34A853"/>
      <path d="M4.5 12.95A5.99 5.99 0 0 1 4.06 10c0-.51.09-1.01.14-1.49V5.91H1.1A10 10 0 0 0 0 10c0 1.56.37 3.03 1.1 4.09l3.4-1.14z" fill="#FBBC05"/>
      <path d="M10 4.01c1.47 0 2.78.51 3.81 1.51l2.85-2.85C14.97 1.13 12.7.01 10 .01A10 10 0 0 0 1.1 5.91l3.4 2.6C5.27 5.74 7.44 4.01 10 4.01z" fill="#EA4335"/>
    </svg>
  );
}

function LandingPage() {
  const navigate = useNavigate();

  const handleGoogleSignup = () => {
    window.location.href = `${BACKEND_URL}/auth/google`;
  };

  return (
    <div className="App">
      <Navbar />
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}>
        <FloatingLines enabledWaves={['top', 'middle', 'bottom']} lineCount={5} lineDistance={5} bendRadius={5} bendStrength={-0.5} interactive={true} parallax={true} />
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>

      <main className="main-content">
        <h1 className="main-heading">Think deeper. We'll help<br /> you make sense of it all.</h1>
        <p className="main-description">
          Work with IThink—your AI partner in identifying truth,<br />
          exposing inaccuracies, and navigating knowledge with<br />
          clarity and confidence.
        </p>

        <div className="signup-buttons">
          <button className="signup-free-btn" onClick={() => navigate('/login')}>Sign up for free</button>
          <button className="signup-google-btn" onClick={handleGoogleSignup}>
            <GoogleIcon /> Sign up with Google
          </button>
        </div>

        <p className="legal-text">
          By signing up, you agree to the <a href="/terms">Terms and Conditions and Privacy Policy</a>.<br />
          Learn how we assist you in our <a href="/how-it-works">Help Center</a>.
        </p>

        <div className="carousel-container">
          <Swiper
            modules={[Pagination, Autoplay]}
            spaceBetween={20}
            slidesPerView={1.2}
            centeredSlides={true}
            loop={true}
            loopAdditionalSlides={4}
            pagination={{ clickable: true }}
            autoplay={{ delay: 3000 }}
            breakpoints={{
              640: { slidesPerView: 1.5 },
              1024: { slidesPerView: 2.2 }
            }}
          >
            {CARDS.map((card, i) => (
              <SwiperSlide key={i}>
                <div className="feature-card">
                  <div className="card-img" style={{ backgroundImage: `url(${card.img})` }} />
                  <div className="card-content">
                    <h2>{card.title}</h2>
                    <p>{card.description}</p>
                  </div>
                </div>
              </SwiperSlide>
            ))}
          </Swiper>
        </div>
      </main>

      <section className="feature-row">
        <div className="feature-text">
          <h1>Identify truth, cut through the noise</h1>
          <p>Detect real claims from your RRL and separate facts from misleading information in seconds.</p>
        </div>
        <div className="feature-visual"><img src={imgSourceValidation} alt="Source Validation" /></div>
      </section>

      <section className="feature-row reverse">
        <div className="feature-text">
          <h1>Highlight inaccuracies, verify every source</h1>
          <p>Check if information is credible, peer-reviewed, and up-to-date.</p>
        </div>
        <div className="feature-visual"><img src={imgHighlight} alt="Highlight Inaccuracies" /></div>
      </section>

      <section className="feature-row">
        <div className="feature-text">
          <h1>Navigate knowledge, with confidence</h1>
          <p>Cross-check facts across reliable sources and ensure accuracy in every detail.</p>
        </div>
        <div className="feature-visual"><img src={imgNavigate} alt="AI Chatbot" /></div>
      </section>

      <section className="feature-row reverse">
        <div className="feature-text">
          <h1>Understand credibility, instantly</h1>
          <p>Get clear ratings like High Credibility, Needs Verification, or Likely False—so decisions are easier.</p>
        </div>
        <div className="feature-visual"><img src={imgScore} alt="Credibility Score" /></div>
      </section>

      <section className="cta-full-width">
        <div className="cta-content">
          <h2>IThink is your AI truth partner</h2>
          <p>Love the clarity IThink gives you in identifying truth? IThink brings that same confidence to every claim, source, and piece of information, with tools and insights designed to help you think smarter and make decisions you can trust.</p>
          <button className="learn-more-btn">Learn more</button>
        </div>
      </section>

      <section className="final-signup">
        <div className="brand-logo-large">
          <div className="logo-icon">i</div>
          <span className="logo-text-large">think.</span>
        </div>
        <h2>Truth powers better decisions</h2>
        <p>Rely on IThink to highlight inaccuracies, verify sources, and navigate knowledge with ease.</p>
        <div className="btn-group">
          <button className="signup-free" onClick={() => navigate('/login')}>Sign up for free</button>
          <button className="signup-google" onClick={handleGoogleSignup}>
            <GoogleIcon /> Sign up with Google
          </button>
        </div>
        <p className="legal-footer-text">
          By signing up, you agree to the <a href="/terms" style={{ color: '#fff', fontWeight: 600 }}>Terms and Conditions and Privacy Policy</a>.<br />
          Learn how we assist you in our <a href="/how-it-works" style={{ color: '#fff', fontWeight: 600 }}>Help Center</a>.
        </p>
      </section>

      <div className="purple-banner">
        <div className="banner-logo">IThink</div>
        <p>Identify <b>T</b>ruth. <b>H</b>ighlight <b>I</b>naccuracies. <b>N</b>avigate <b>K</b>nowledge.</p>
      </div>

      <footer className="main-footer">
        <div className="footer-grid">
          <div className="footer-col about">
            <h3>About Us</h3>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
            <a href="#">Learn More</a>
          </div>
          <div className="footer-col">
            <h3>Features</h3>
            <ul>
              <li>Claim Detection</li>
              <li>Source Validation</li>
              <li>Fact Cross-Verification</li>
              <li>Credibility Scoring</li>
            </ul>
          </div>
          <div className="footer-col">
            <h3>Quick Links</h3>
            <div className="link-double-grid">
              <a href="#">Link</a><a href="#">Link</a>
              <a href="#">Link</a><a href="#">Link</a>
              <a href="#">Link</a><a href="#">Link</a>
            </div>
          </div>
          <div className="footer-col">
            <h3>Connect</h3>
            <div className="social-links">
              <span className="social-item"><div className="dot-social blue"></div> Facebook</span>
              <span className="social-item"><div className="dot-social blue"></div> Instagram</span>
              <span className="social-item"><div className="dot-social blue"></div> X</span>
              <span className="social-item"><div className="dot-social blue"></div> TikTok</span>
              <span className="social-item"><div className="dot-social blue"></div> Gmail</span>
            </div>
          </div>
        </div>
        <div className="copyright">2026 IThink. All Right Reserved.</div>
      </footer>
      </div>
    </div>
  );
}

export default LandingPage;