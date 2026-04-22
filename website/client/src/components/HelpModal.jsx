import React, { useState } from 'react';
import AlitaptapLogo from '../AlitaptapLogo';

export default function HelpModal({ onClose }) {
  const [helpTab, setHelpTab] = useState('about');
  return (
    <div className="help-overlay" onClick={onClose}>
      <div className="help-modal" onClick={e => e.stopPropagation()}>
        <button className="help-close" onClick={onClose}>✕</button>
        <div className="help-tabs">
          <button className={`help-tab${helpTab === 'about' ? ' active' : ''}`} onClick={() => setHelpTab('about')}>About</button>
          <button className={`help-tab${helpTab === 'help' ? ' active' : ''}`} onClick={() => setHelpTab('help')}>Help</button>
        </div>
        {helpTab === 'about' ? (
          <div className="help-body">
            <div className="help-logo-row">
              <AlitaptapLogo size={48} />
              <div>
                <div className="help-brand">Alitaptap</div>
                <div className="help-tagline">Think smarter. Write with confidence.</div>
              </div>
            </div>
            <p className="help-desc">Alitaptap is an AI-powered writing and fact-checking platform that helps students and professionals verify claims, analyze credibility, and write with confidence.</p>
            <div className="help-features">
              <div className="help-feature"><span className="help-feature-icon">🛡️</span><div><strong>Credibility Check</strong><p>Analyze any text or selected claim for accuracy using AI and real sources.</p></div></div>
              <div className="help-feature"><span className="help-feature-icon">💬</span><div><strong>AI Chat</strong><p>Ask Alitaptap anything about fact-checking, sources, or writing tips.</p></div></div>
              <div className="help-feature"><span className="help-feature-icon">📝</span><div><strong>Smart Editor</strong><p>Write documents with inline highlights showing inaccurate claims.</p></div></div>
              <div className="help-feature"><span className="help-feature-icon">🎓</span><div><strong>Personas</strong><p>Tailor analysis depth for High School, College, or Professional level.</p></div></div>
            </div>
            <div className="help-version">Version 1.0.0 · Built with ❤️ by the Alitaptap Team</div>
          </div>
        ) : (
          <div className="help-body">
            <div className="help-section-title">Getting Started</div>
            <div className="help-steps">
              <div className="help-step"><div className="help-step-num">1</div><div><strong>Create a document</strong> — Click "New Document" on the dashboard to open the editor.</div></div>
              <div className="help-step"><div className="help-step-num">2</div><div><strong>Write your content</strong> — Type or paste your text into the editor.</div></div>
              <div className="help-step"><div className="help-step-num">3</div><div><strong>Check credibility</strong> — Click the 🛡️ shield button to analyze your full text, or highlight a specific claim first.</div></div>
              <div className="help-step"><div className="help-step-num">4</div><div><strong>Review results</strong> — Click "Results ▼" to see the analysis panel with accuracy scores and suggestions.</div></div>
              <div className="help-step"><div className="help-step-num">5</div><div><strong>Save your work</strong> — Hit 💾 Save. You'll be asked to save if you try to leave with unsaved changes.</div></div>
            </div>
            <div className="help-section-title" style={{ marginTop: 20 }}>Tips</div>
            <ul className="help-tips">
              <li>Highlight a specific sentence before clicking the shield to check just that claim.</li>
              <li>Hover over red-highlighted text in the editor to see why it was flagged.</li>
              <li>Switch your Persona in the sidebar to get analysis tuned to your level.</li>
              <li>Use the Chat page to ask follow-up questions about any flagged claims.</li>
              <li>Deleted documents go to Trash and can be restored within 30 days.</li>
            </ul>
          </div>
        )}
      </div>
    </div>
  );
}
