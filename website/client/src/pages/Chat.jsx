import React, { useState, useRef, useEffect, useCallback } from 'react';
import '../styles/workspace.css';
import '../styles/gradient-icon.css';
import { FaQuestionCircle, FaUserCircle, FaPaperPlane, FaPlus, FaTrashAlt } from 'react-icons/fa';
import { Link, useLocation } from 'react-router-dom';
import axios from 'axios';
import AlitaptapLogo from '../AlitaptapLogo';
import { useTheme } from '../ThemeContext';
import Sidebar from '../components/Sidebar';
import ThemeToggle from '../components/ThemeToggle';
import HelpModal from '../components/HelpModal';
import Toast from '../components/Toast';

import { BACKEND_URL as API } from '../App';

function genId() {
  return Math.random().toString(36).slice(2) + Date.now().toString(36);
}

function parseReply(text) {
  const idx = text.indexOf('Sources:');
  if (idx === -1) return { answer: text, sources: [] };
  const answer = text.slice(0, idx).trim();
  const sources = text.slice(idx + 8).trim()
    .split('\n')
    .map(l => l.replace(/^[\-\*\d\.\s]+/, '').trim())
    .filter(l => l.startsWith('http'));
  return { answer, sources };
}

const WELCOME = { role: 'bot', text: "Hi! I'm Alitaptap's research assistant. Ask me anything about fact-checking, source verification, or credibility analysis." };

export default function Chat({ user }) {
  const { pathname } = useLocation();
  const { theme } = useTheme();
  const [sessions, setSessions] = useState([]);
  const [activeId, setActiveId] = useState(null);
  const [messages, setMessages] = useState([WELCOME]);
  const [historyOpen, setHistoryOpen] = useState(false);
  const [helpOpen, setHelpOpen] = useState(false);
  const [toast, setToast] = useState(null);
  const hasMessages = messages.length > 1;
  const [input, setInput] = useState('');
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef(null);
  const saveTimer = useRef(null);

  // Load session list on mount
  useEffect(() => {
    axios.get(`${API}/api/chat/sessions`, { withCredentials: true })
      .then(res => setSessions(res.data))
      .catch(() => {});
  }, []);

  // Scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Debounced save — fires 1s after messages stop changing
  const scheduleSave = useCallback((id, msgs) => {
    clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(async () => {
      const userMsg = msgs.find(m => m.role === 'user');
      const title = userMsg ? userMsg.text.slice(0, 40) : 'New Chat';
      try {
        await axios.put(`${API}/api/chat/sessions/${id}`, { messages: msgs, title }, { withCredentials: true });
        setSessions(prev => prev.map(s => s.sessionId === id ? { ...s, title } : s));
      } catch {}
    }, 1000);
  }, []);

  const loadSession = async (sessionId) => {
    try {
      const res = await axios.get(`${API}/api/chat/sessions/${sessionId}`, { withCredentials: true });
      setActiveId(sessionId);
      setMessages(res.data.messages?.length ? res.data.messages : [WELCOME]);
    } catch {}
  };

  const startNewChat = async () => {
    const id = genId();
    try {
      await axios.post(`${API}/api/chat/sessions`, { sessionId: id, title: 'New Chat', messages: [WELCOME] }, { withCredentials: true });
      setSessions(prev => [{ sessionId: id, title: 'New Chat', updatedAt: new Date() }, ...prev]);
      setActiveId(id);
      setMessages([WELCOME]);
    } catch {}
  };

  const deleteSession = async (e, sessionId) => {
    e.stopPropagation();
    try {
      await axios.delete(`${API}/api/chat/sessions/${sessionId}`, { withCredentials: true });
      setSessions(prev => prev.filter(s => s.sessionId !== sessionId));
      if (activeId === sessionId) { setActiveId(null); setMessages([WELCOME]); }
    } catch {}
  };

  const sendMessage = async () => {
    const trimmed = input.trim();
    if (!trimmed || loading) return;

    let currentId = activeId;
    if (!currentId) {
      currentId = genId();
      setActiveId(currentId);
      try {
        await axios.post(`${API}/api/chat/sessions`, { sessionId: currentId, title: trimmed.slice(0, 40), messages: [WELCOME] }, { withCredentials: true });
        setSessions(prev => [{ sessionId: currentId, title: trimmed.slice(0, 40), updatedAt: new Date() }, ...prev]);
      } catch {}
    }

    const newMessages = [...messages, { role: 'user', text: trimmed }];
    setMessages(newMessages);
    setInput('');
    setLoading(true);

    try {
      const res = await axios.post(`${API}/api/chat`, { message: trimmed }, { withCredentials: true });
      const { answer, sources } = parseReply(res.data.reply);
      const final = [...newMessages, { role: 'bot', text: answer, sources }];
      setMessages(final);
      scheduleSave(currentId, final);
    } catch {
      const final = [...newMessages, { role: 'bot', text: 'Something went wrong. Please try again.' }];
      setMessages(final);
      scheduleSave(currentId, final);
    }
    setLoading(false);
  };

  const textareaRef = useRef(null);

  const handleInput = (e) => {
    setInput(e.target.value);
    const el = textareaRef.current;
    if (el) { el.style.height = 'auto'; el.style.height = el.scrollHeight + 'px'; }
  };

  const handleKey = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
      if (textareaRef.current) textareaRef.current.style.height = 'auto';
    }
  };

  const handleSignOut = async () => {
    try {
      await axios.get(`${API}/logout`, { withCredentials: true });
      localStorage.removeItem('token');
      window.location.href = '/login';
    } catch { setToast({ message: 'Failed to log out. Please try again.', type: 'error' }); }
  };

  return (
    <div className="ws2-root">
      <Sidebar />

      <div className="chat-area">
        <header className="ws2-header">
          <div className="ws2-header-title">Chat with Alitaptap</div>
          <div className="ws2-header-controls">
            <ThemeToggle />
            <FaQuestionCircle size={20} className="ws2-header-icon" style={{ cursor: 'pointer' }} onClick={() => setHelpOpen(true)} title="Help & About" />
            <Link to="/dashboard/account" className="ws2-avatar" title="Account"><FaUserCircle size={18} /></Link>
            <button className="chat-history-toggle" onClick={() => setHistoryOpen(o => !o)} title="History">☰</button>
          </div>
        </header>

        {!hasMessages ? (
          <div className="chat-landing">
            <div className="chat-landing-title">What do you want to research?</div>
            <div className="chat-landing-sub">Ask me anything about fact-checking, source verification, or credibility analysis.</div>
            <div className="chat-input-row">
              <textarea
                ref={textareaRef}
                className="chat-input"
                placeholder="Ask a research question..."
                value={input}
                onChange={handleInput}
                onKeyDown={handleKey}
                rows={1}
              />
              <button className="chat-send-btn" onClick={sendMessage} disabled={loading}><FaPaperPlane /></button>
            </div>
          </div>
        ) : (
          <>
            <div className="chat-messages">
              {messages.map((msg, i) => (
                <div key={i} className={`chat-bubble-wrap ${msg.role}`}>
                  <div className={`chat-bubble ${msg.role}`}>
                    <p>{msg.text}</p>
                    {msg.sources?.length > 0 && (
                      <div className="chat-sources">
                        <span>Sources:</span>
                        <ul>{msg.sources.map((src, j) => <li key={j}><a href={src} target="_blank" rel="noreferrer">{src}</a></li>)}</ul>
                      </div>
                    )}
                  </div>
                </div>
              ))}
              {loading && (
                <div className="chat-bubble-wrap bot">
                  <div className="chat-bubble bot chat-typing"><span /><span /><span /></div>
                </div>
              )}
              <div ref={bottomRef} />
            </div>
            <div className="chat-input-row">
              <textarea
                ref={textareaRef}
                className="chat-input"
                placeholder="Ask a research question..."
                value={input}
                onChange={handleInput}
                onKeyDown={handleKey}
                rows={1}
              />
              <button className="chat-send-btn" onClick={sendMessage} disabled={loading}><FaPaperPlane /></button>
            </div>
          </>
        )}
      </div>

      {historyOpen && <div className="ws2-drawer-overlay" onClick={() => setHistoryOpen(false)} />}
      <aside className={`chat-history-sidebar${historyOpen ? ' chat-history-sidebar--open' : ''}`}>
        <div className="chat-history-header">
          <span>History</span>
          <button className="chat-new-btn" onClick={startNewChat} title="New Chat"><FaPlus /></button>
        </div>
        <div className="chat-history-list">
          {sessions.length === 0 && <div className="chat-history-empty">No conversations yet</div>}
          {sessions.map(s => (
            <div
              key={s.sessionId}
              className={`chat-history-item${activeId === s.sessionId ? ' active' : ''}`}
              onClick={() => loadSession(s.sessionId)}
            >
              <span className="chat-history-title">{s.title || 'New Chat'}</span>
              <button className="chat-history-delete" onClick={e => deleteSession(e, s.sessionId)} title="Delete"><FaTrashAlt /></button>
            </div>
          ))}
        </div>
      </aside>
      {helpOpen && <HelpModal onClose={() => setHelpOpen(false)} />}
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}
