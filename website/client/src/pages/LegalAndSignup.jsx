import React from 'react';
import Navbar from '../components/Navbar';
import { useNavigate } from 'react-router-dom';
import logo from '../images/logo.png';
import '../styles/LegalAndSignup.css';
import '../styles/HowItWorks.css';
import { BACKEND_URL } from '../App';
import FloatingLines from '../components/FloatingLines';

const LegalAndSignup = () => {
  const navigate = useNavigate();

  const handleGoogleSignup = () => {
    window.location.href = `${BACKEND_URL}/auth/google`;
  };

  return (
    <div className="legal-page-container">
      <Navbar />
      <div style={{ position: 'fixed', inset: 0, zIndex: 0, pointerEvents: 'none' }}>
        <FloatingLines enabledWaves={['top', 'middle', 'bottom']} lineCount={5} lineDistance={5} bendRadius={5} bendStrength={-0.5} interactive={true} parallax={true} />
      </div>
      <div style={{ position: 'relative', zIndex: 1 }}>

      <section className="legal-content">
        <div className="legal-block">
          <h2>Terms and Conditions</h2>
          <p>Last updated: January 1, 2026. Please read these Terms and Conditions carefully before using the Alitaptap platform. By accessing or using Alitaptap, you confirm that you are at least 13 years of age, that you have read and understood these terms, and that you agree to be bound by them. If you do not agree, you must discontinue use of the platform immediately.</p>

          <h3>1. Acceptance of Terms</h3>
          <p>By creating an account or using any part of the Alitaptap service, you enter into a legally binding agreement with Alitaptap. These terms apply to all users, including visitors, registered users, researchers, students, and professionals. Alitaptap reserves the right to update or modify these terms at any time. Continued use of the platform after changes are posted constitutes your acceptance of the revised terms. We recommend reviewing these terms periodically to stay informed of any updates.</p>

          <h3>2. Use of the Platform</h3>
          <p>Alitaptap grants you a limited, non-exclusive, non-transferable license to access and use the platform for personal, educational, or professional purposes. You agree not to use Alitaptap to generate, distribute, or promote false, misleading, or harmful content. You may not attempt to reverse-engineer, scrape, or exploit the platform's AI systems. Any automated access, data harvesting, or unauthorized API usage is strictly prohibited and may result in immediate account termination without refund.</p>

          <h3>3. User Accounts</h3>
          <p>You are responsible for maintaining the confidentiality of your account credentials. You agree to notify Alitaptap immediately of any unauthorized use of your account. Alitaptap is not liable for any loss or damage arising from your failure to protect your login information. Each user may only maintain one active account. Creating multiple accounts to circumvent restrictions or bans is a violation of these terms and may result in permanent suspension of all associated accounts.</p>

          <h3>4. Intellectual Property</h3>
          <p>All content, features, and functionality on Alitaptap — including but not limited to text, graphics, logos, AI models, and software — are the exclusive property of Alitaptap and are protected by applicable intellectual property laws. You may not copy, reproduce, distribute, or create derivative works from any part of the platform without prior written consent from Alitaptap. Content you create using Alitaptap remains yours, but you grant Alitaptap a non-exclusive, royalty-free license to use it for improving our services and training our models.</p>

          <h3>5. Prohibited Conduct</h3>
          <p>You agree not to engage in any conduct that violates any applicable law or regulation, infringes on the rights of others, transmits spam, malware, or harmful code, impersonates any person or entity, or interferes with the proper functioning of the platform. You may not attempt to gain unauthorized access to any part of Alitaptap's systems, databases, or infrastructure. Violations may result in immediate suspension or permanent termination of your account without notice or liability to Alitaptap.</p>

          <h3>6. AI-Generated Content Disclaimer</h3>
          <p>Alitaptap uses artificial intelligence to assist users in analyzing claims, validating sources, and scoring credibility. While we strive for accuracy, AI-generated analysis is not infallible and should not be treated as definitive legal, medical, scientific, or professional advice. Users are responsible for independently verifying critical information through authoritative sources before making decisions based on Alitaptap's output. Alitaptap disclaims all liability for decisions made based solely on AI-generated results.</p>

          <h3>7. Disclaimer of Warranties</h3>
          <p>Alitaptap is provided on an "as is" and "as available" basis without warranties of any kind, either express or implied. We do not warrant that the platform will be uninterrupted, error-free, or completely accurate at all times. We make no guarantees regarding the reliability, timeliness, or completeness of any content or analysis provided through the platform. Your use of Alitaptap is entirely at your own risk.</p>

          <h3>8. Limitation of Liability</h3>
          <p>To the fullest extent permitted by law, Alitaptap shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising from your use of or inability to use the platform. This includes loss of data, loss of profits, reputational harm, or any other tangible or intangible losses, even if Alitaptap has been advised of the possibility of such damages. Our total liability to you for any claim shall not exceed the amount you paid to Alitaptap in the twelve months preceding the claim.</p>

          <h3>9. Termination</h3>
          <p>Alitaptap reserves the right to suspend or terminate your access to the platform at any time, with or without cause, and with or without notice. Upon termination, your right to use the platform ceases immediately and any data associated with your account may be deleted. Provisions of these terms that by their nature should survive termination shall survive, including ownership provisions, warranty disclaimers, indemnification obligations, and limitations of liability.</p>

          <h3>10. Governing Law</h3>
          <p>These Terms and Conditions shall be governed by and construed in accordance with the laws of the jurisdiction in which Alitaptap operates, without regard to its conflict of law provisions. Any disputes arising under these terms shall first be attempted to be resolved through good-faith negotiation. If unresolved, disputes shall be submitted to binding arbitration or the courts of the applicable jurisdiction, and you waive any right to a jury trial in connection with such disputes.</p>
        </div>

        <div className="legal-block">
          <h2>Privacy Policy</h2>
          <p>Last updated: January 1, 2026. Your privacy is important to us. This Privacy Policy explains how Alitaptap collects, uses, stores, and protects your personal information when you use our platform. By using Alitaptap, you consent to the data practices described in this policy. We are committed to being transparent about how we handle your data and giving you meaningful control over your information.</p>

          <h3>1. Information We Collect</h3>
          <p>We collect information you provide directly, such as your name, email address, and profile details when you register. We also collect usage data including the pages you visit, features you use, the content you analyze, and the time spent on each section. When you sign in with Google, we receive basic profile information as permitted by your Google account settings. We may also collect device information, IP addresses, browser type, and operating system for security and analytics purposes. We collect only what is necessary to deliver and improve our services.</p>

          <h3>2. How We Use Your Information</h3>
          <p>We use your information to provide, maintain, and improve the Alitaptap platform. This includes personalizing your experience, processing your analyses, sending important service notifications, and responding to your support requests. We may use aggregated, anonymized data to improve our AI models and platform features. We will never use your personal data to make automated decisions that significantly affect you without your knowledge, and we will never sell your data to advertisers or data brokers.</p>

          <h3>3. Data Storage and Security</h3>
          <p>Your data is stored on secure servers using industry-standard encryption protocols including TLS/SSL for data in transit and AES-256 for data at rest. We implement strict access controls, role-based permissions, regular security audits, and intrusion detection systems to protect your information. Our team undergoes regular security training and only authorized personnel have access to user data. While we take every reasonable precaution, no system is completely immune to security risks, and we encourage you to use a strong, unique password.</p>

          <h3>4. Data Sharing and Third Parties</h3>
          <p>Alitaptap does not sell, rent, or trade your personal information to third parties under any circumstances. We may share data with trusted service providers who assist us in operating the platform — such as cloud hosting providers, analytics tools, and customer support systems — under strict confidentiality and data processing agreements. These providers are only permitted to use your data as necessary to perform services on our behalf. We may disclose your information if required by law, court order, or governmental authority, or if we believe disclosure is necessary to protect the rights, property, or safety of Alitaptap, our users, or the public.</p>

          <h3>5. Cookies and Tracking Technologies</h3>
          <p>Alitaptap uses cookies and similar tracking technologies to enhance your experience, remember your preferences, maintain your session, and analyze platform usage patterns. We use both session cookies, which expire when you close your browser, and persistent cookies, which remain on your device for a set period to remember your settings. You can control cookie settings through your browser preferences, though disabling certain cookies may affect the functionality of the platform. We do not use cookies to track your activity across third-party websites.</p>

          <h3>6. Your Rights and Choices</h3>
          <p>You have the right to access, correct, or delete your personal data at any time through your account settings. You may also request a portable copy of the data we hold about you, ask us to restrict how we process it, or object to certain types of processing. If you wish to permanently delete your account and all associated data, you can do so from the Account Settings page. We will process deletion requests within 30 days, subject to any legal obligations to retain certain records such as billing history or compliance logs.</p>

          <h3>7. Data Retention</h3>
          <p>We retain your personal data for as long as your account is active or as needed to provide you with our services. If you delete your account, we will delete or anonymize your personal data within 30 days, except where we are required by law to retain it longer. Anonymized, aggregated data that cannot be used to identify you may be retained indefinitely for research and platform improvement purposes. Backup copies of deleted data may persist in our systems for up to 90 days before being permanently purged.</p>

          <h3>8. Children's Privacy</h3>
          <p>Alitaptap is not directed at children under the age of 13, and we do not knowingly collect personal information from children. If we become aware that a child under 13 has provided us with personal data without verifiable parental consent, we will take immediate steps to delete that information from our systems. Parents or guardians who believe their child has submitted personal information to Alitaptap should contact us at privacy@Alitaptap.ai so we can address the situation promptly.</p>

          <h3>9. Changes to This Policy</h3>
          <p>We may update this Privacy Policy from time to time to reflect changes in our practices, technology, legal requirements, or other factors. We will notify you of significant changes by posting a prominent notice on the platform or sending an email to your registered address at least 14 days before the changes take effect. Your continued use of Alitaptap after changes are posted constitutes your acceptance of the updated policy. We encourage you to review this policy periodically to stay informed.</p>

          <h3>10. Contact Us</h3>
          <p>If you have any questions, concerns, or requests regarding this Privacy Policy or how we handle your data, please contact our Privacy Team at privacy@Alitaptap.ai. We are committed to resolving any concerns promptly and transparently. You also have the right to lodge a complaint with your local data protection authority if you believe we have not handled your data in accordance with applicable law.</p>
        </div>
      </section>

      <section className="signup-cta-section">
        <div className="signup-header">
          <div className="logo-icon-large">
            <img src={logo} alt="Alitaptap Logo" className="Alitaptap-logo-img" />
          </div>
          <h1>Truth powers better decisions</h1>
          <p>Rely on Alitaptap to highlight inaccuracies, verify sources, and navigate knowledge with ease.</p>
        </div>

        <div className="button-group-horizontal">
          <button className="btn-primary-blue" onClick={() => navigate('/login')}>Sign up for free</button>
          <button className="btn-google-outline" onClick={handleGoogleSignup}>
            <svg width="20" height="20" viewBox="0 0 20 20" fill="none" xmlns="http://www.w3.org/2000/svg">
              <path d="M19.6 10.23c0-.68-.06-1.36-.18-2H10v3.79h5.48a4.7 4.7 0 0 1-2.04 3.08v2.56h3.3c1.93-1.78 3.06-4.4 3.06-7.43z" fill="#4285F4"/>
              <path d="M10 20c2.7 0 4.97-.89 6.63-2.41l-3.3-2.56c-.92.62-2.1.99-3.33.99-2.56 0-4.73-1.73-5.5-4.07H1.1v2.6A10 10 0 0 0 10 20z" fill="#34A853"/>
              <path d="M4.5 12.95A5.99 5.99 0 0 1 4.06 10c0-.51.09-1.01.14-1.49V5.91H1.1A10 10 0 0 0 0 10c0 1.56.37 3.03 1.1 4.09l3.4-1.14z" fill="#FBBC05"/>
              <path d="M10 4.01c1.47 0 2.78.51 3.81 1.51l2.85-2.85C14.97 1.13 12.7.01 10 .01A10 10 0 0 0 1.1 5.91l3.4 2.6C5.27 5.74 7.44 4.01 10 4.01z" fill="#EA4335"/>
            </svg>
            Sign up with Google
          </button>
        </div>

        <p className="legal-disclaimer">
          By signing up, you agree to the <a href="/terms">Terms and Conditions and Privacy Policy</a>.
          Learn how we assist you in our <a href="/how-it-works">Help Center</a>.
        </p>
      </section>

      <div className="tagline-strip-purple">
        <div className="branding-center">
          <p className="cta-this-is">This is</p>
          <h2 className="cta-tagline"><span className="blue-it">IT</span>hink</h2>
          <p>Identify <b>Truth</b>. Highlight <b>Inaccuracies</b>. Navigate <b>Knowledge</b>.</p>
        </div>
      </div>

      <footer className="footer-v2">
        <div className="footer-grid">
          <div className="footer-main-info">
            <h4>About Us</h4>
            <p>Alitaptap was built to help you think smarter. We combine AI with credibility research to give you tools that verify sources, detect bias, and score information accuracy.</p>
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

export default LegalAndSignup;
