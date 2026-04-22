import React, { useState, useRef, useEffect } from 'react';
import Toast from '../components/Toast';
import '../styles/workspace.css';
import '../styles/draft.css';
import '../styles/gradient-icon.css';
import { Link, useParams, useNavigate } from 'react-router-dom';
import html2pdf from 'html2pdf.js';
import { Document, Packer, Paragraph, TextRun } from 'docx';
import mammoth from 'mammoth';

import { BACKEND_URL } from '../App';

function saveToDevice(title, html) {
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  const text = tmp.innerText;
  const blob = new Blob([text], { type: 'text/plain' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `${title || 'document'}.txt`;
  a.click();
  URL.revokeObjectURL(a.href);
}

async function saveAsPDF(title, html) {
  const container = document.createElement('div');
  container.innerHTML = html;
  container.style.cssText = 'font-family:Georgia,serif;font-size:14px;line-height:1.6;color:#222;padding:32px;max-width:700px;';
  document.body.appendChild(container);
  await html2pdf().set({
    margin: [15, 15, 15, 15],
    filename: `${title || 'document'}.pdf`,
    image: { type: 'jpeg', quality: 0.98 },
    html2canvas: { scale: 2, useCORS: true },
    jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
  }).from(container).save();
  document.body.removeChild(container);
}

async function saveAsWord(title, html) {
  const tmp = document.createElement('div');
  tmp.innerHTML = html;
  const lines = (tmp.innerText || '').split('\n').filter(l => l.trim());
  const doc = new Document({
    sections: [{
      properties: {},
      children: lines.map(line => new Paragraph({
        children: [new TextRun({ text: line, size: 24, font: 'Calibri' })],
        spacing: { after: 160 },
      }))
    }]
  });
  const blob = await Packer.toBlob(doc);
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = `${title || 'document'}.docx`;
  a.click();
  URL.revokeObjectURL(a.href);
}

function Draft({ user }) {
  const { id } = useParams();
  const navigate = useNavigate();
  const [analysis, setAnalysis] = useState(null);
  const [sidebarTab, setSidebarTab] = useState('analysis');
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [isChecking, setIsChecking] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [draftId, setDraftId] = useState(null);
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [textColor, setTextColor] = useState('#000000');
  const [bgColor, setBgColor] = useState('#ffff00');
  const [fontSize, setFontSize] = useState('');
  const [wordCount, setWordCount] = useState(0);
  const [isDirty, setIsDirty] = useState(false);
  const [exitPrompt, setExitPrompt] = useState(null);
  const [toast, setToast] = useState(null);
  const [downloadOpen, setDownloadOpen] = useState(false);
  const fileInputRef = useRef(null);
  const savedRangeRef = useRef(null);
  const editorRef = useRef(null);
  const wrongFindingsRef = useRef([]);
  const tooltipRef = useRef(null);
  const PERSONA_NAMES = { '1': 'High School Student', '2': 'College Student', '3': 'Professional' };

  useEffect(() => {
    contentLoadedRef.current = false;
    if (id) {
      fetch(`${BACKEND_URL}/api/drafts/${id}`, {
        headers: { 'Authorization': `Bearer ${localStorage.getItem('token')}` }
      })
        .then(r => {
          if (r.status === 401) { navigate('/login'); return null; }
          return r.json();
        })
        .then(draft => {
          if (!draft) return;
          setDraftId(draft.id);
          setTitle(draft.title);
          setContent(draft.content);
          if (draft.analysis) setAnalysis(draft.analysis);
        })
        .catch(() => {});
    } else {
      if (editorRef.current) editorRef.current.innerHTML = '';
    }
  }, [id]);

  // Set editor HTML only when content loads from server
  const contentLoadedRef = useRef(false);
  useEffect(() => {
    if (editorRef.current && content && !contentLoadedRef.current) {
      editorRef.current.innerHTML = content;
      contentLoadedRef.current = true;
      const text = editorRef.current.innerText || '';
      setWordCount(text.trim().split(/\s+/).filter(w => w.length > 0).length);
    }
  }, [content]);

  const saveDraft = async (e, afterSave) => {
    if (e) e.preventDefault();
    const currentContent = editorRef.current?.innerHTML || '';
    const currentTitle = title || 'Untitled Document';
    setIsSaving(true);
    try {
      const method = draftId ? 'PUT' : 'POST';
      const url = draftId
        ? `${BACKEND_URL}/api/drafts/${draftId}`
        : `${BACKEND_URL}/api/drafts`;
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('token')}` },
        body: JSON.stringify({ title: currentTitle, content: currentContent, analysis })
      });
      if (!res.ok) throw new Error('Server error');
      setIsDirty(false);
      if (afterSave) afterSave();
      else navigate('/dashboard');
    } catch (err) {
      setToast({ message: 'Failed to save draft. Please try again.', type: 'error' });
    } finally {
      setIsSaving(false);
    }
  };

  const handleOpenFile = async (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const ext = file.name.split('.').pop().toLowerCase();
    const fileTitle = file.name.replace(/\.[^.]+$/, '');

    try {
      if (ext === 'docx') {
        const arrayBuffer = await file.arrayBuffer();
        const result = await mammoth.convertToHtml({ arrayBuffer });
        if (editorRef.current) {
          editorRef.current.innerHTML = result.value;
          const text = editorRef.current.innerText || '';
          setWordCount(text.trim().split(/\s+/).filter(w => w.length > 0).length);
          setIsDirty(true);
        }
      } else if (ext === 'pdf') {
        const arrayBuffer = await file.arrayBuffer();
        const pdfjsLib = await import('pdfjs-dist');
        pdfjsLib.GlobalWorkerOptions.workerSrc = new URL('pdfjs-dist/build/pdf.worker.min.mjs', import.meta.url).toString();
        const pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
        let fullText = '';
        for (let i = 1; i <= pdf.numPages; i++) {
          const page = await pdf.getPage(i);
          const textContent = await page.getTextContent();
          const pageText = textContent.items.map(item => item.str).join(' ');
          fullText += pageText + '\n\n';
        }
        if (editorRef.current) {
          editorRef.current.innerText = fullText.trim();
          const words = fullText.trim().split(/\s+/).filter(w => w.length > 0);
          setWordCount(words.length);
          setIsDirty(true);
        }
      } else {
        // plain text
        const reader = new FileReader();
        reader.onload = (ev) => {
          const text = ev.target.result;
          if (editorRef.current) {
            editorRef.current.innerText = text;
            setWordCount(text.trim().split(/\s+/).filter(w => w.length > 0).length);
            setIsDirty(true);
          }
        };
        reader.readAsText(file);
      }
      if (!title) setTitle(fileTitle);
    } catch (err) {
      setToast({ message: 'Failed to open file. Please try a different file.', type: 'error' });
    }
    e.target.value = '';
  };

  const tryNavigate = (dest) => {
    if (isDirty) { setExitPrompt(dest); }
    else navigate(dest);
  };

  const formatText = (formatType, formatValue = null) => {
    const editor = editorRef.current;
    if (!editor) return;
    editor.focus();

    switch (formatType) {
      case 'bold': document.execCommand('bold', false, null); break;
      case 'italic': document.execCommand('italic', false, null); break;
      case 'underline': document.execCommand('underline', false, null); break;
      case 'h1': document.execCommand('formatBlock', false, 'h1'); break;
      case 'h2': document.execCommand('formatBlock', false, 'h2'); break;
      case 'list': document.execCommand('insertUnorderedList', false, null); break;
      case 'textColor':
        document.execCommand('foreColor', false, formatValue);
        break;
      case 'bgColor':
        document.execCommand('hiliteColor', false, formatValue);
        break;
      case 'fontSize': {
        const sel = window.getSelection();
        if (savedRangeRef.current) {
          sel.removeAllRanges();
          sel.addRange(savedRangeRef.current);
        }
        if (!sel.rangeCount || sel.isCollapsed) break;
        const range = sel.getRangeAt(0);
        const marker = `fs-${Date.now()}`;
        document.execCommand('styleWithCSS', false, false);
        document.execCommand('fontSize', false, '7');
        editor.querySelectorAll('font[size="7"]').forEach(font => {
          if (font.dataset.marker) return;
          font.dataset.marker = marker;
        });
        editor.querySelectorAll(`font[data-marker="${marker}"]`).forEach(font => {
          const span = document.createElement('span');
          span.style.fontSize = formatValue;
          while (font.firstChild) span.appendChild(font.firstChild);
          font.replaceWith(span);
        });
        break;
      }
      case 'link': {
        const url = prompt('Enter the URL:');
        if (url) document.execCommand('createLink', false, url);
        break;
      }
      default: return;
    }
  };

  const handleInput = () => {
    const text = editorRef.current?.innerText || '';
    const words = text.trim().split(/\s+/).filter(w => w.length > 0);
    setWordCount(words.length);
    setIsDirty(true);
  };

  const clearHighlights = () => {
    const editor = editorRef.current;
    if (!editor) return;
    editor.querySelectorAll('mark.claim-highlight').forEach(mark => {
      const parent = mark.parentNode;
      if (!parent) return;
      const frag = document.createDocumentFragment();
      while (mark.firstChild) frag.appendChild(mark.firstChild);
      parent.replaceChild(frag, mark);
      parent.normalize();
    });
  };

  const highlightClaims = (findings) => {
    const editor = editorRef.current;
    if (!editor || !findings?.length) return;
    clearHighlights();

    const wrongFindings = findings.filter(f => (f.accuracy_percentage ?? f.accuracy ?? 100) < 70);
    wrongFindingsRef.current = wrongFindings;
    if (!wrongFindings.length) return;

    const getTextNodes = () => {
      const walker = document.createTreeWalker(editor, NodeFilter.SHOW_TEXT);
      const nodes = [];
      let n;
      while ((n = walker.nextNode())) {
        if (!n.parentNode) continue;
        if (n.parentNode.closest('mark.claim-highlight')) continue;
        nodes.push(n);
      }
      return nodes;
    };

    const wrapTextNode = (textNode, localStart, localEnd, findingIndex) => {
      const text = textNode.nodeValue;
      const parent = textNode.parentNode;
      if (!parent) return;
      const mark = document.createElement('mark');
      mark.className = 'claim-highlight';
      mark.dataset.findingIndex = String(findingIndex);
      mark.textContent = text.slice(localStart, localEnd);
      const after = document.createTextNode(text.slice(localEnd));
      const before = document.createTextNode(text.slice(0, localStart));
      parent.replaceChild(after, textNode);
      parent.insertBefore(mark, after);
      parent.insertBefore(before, mark);
    };

    wrongFindings.forEach((finding, findingIndex) => {
      const claim = (finding.claim || finding.text || '').trim();
      if (!claim) return;

      // Get fresh text nodes each time (DOM changed by previous highlight)
      const nodes = getTextNodes();
      // Build full plain text with per-char node mapping
      let fullText = '';
      const charMap = []; // charMap[i] = { node, localIndex }
      for (const node of nodes) {
        for (let i = 0; i < node.nodeValue.length; i++) {
          charMap.push({ node, localIndex: i });
          fullText += node.nodeValue[i];
        }
      }

      const fullLower = fullText.toLowerCase();
      const claimLower = claim.toLowerCase();

      // Try exact match first
      let matchStart = fullLower.indexOf(claimLower);
      let matchLen = claim.length;

      // Fallback: try longest keyword sequence
      if (matchStart === -1) {
        const words = claimLower.split(/\s+/).map(w => w.replace(/[^a-z0-9]/g, '')).filter(w => w.length >= 4);
        for (let len = words.length; len >= 2; len--) {
          for (let s = 0; s <= words.length - len; s++) {
            const phrase = words.slice(s, s + len).join(' ');
            const idx = fullLower.indexOf(phrase);
            if (idx !== -1) { matchStart = idx; matchLen = phrase.length; break; }
          }
          if (matchStart !== -1) break;
        }
      }
      if (matchStart === -1) return;

      // Find which text node the match starts in
      const startEntry = charMap[matchStart];
      const endEntry = charMap[Math.min(matchStart + matchLen - 1, charMap.length - 1)];
      if (!startEntry || !endEntry) return;

      // If match is within a single text node
      if (startEntry.node === endEntry.node) {
        wrapTextNode(startEntry.node, startEntry.localIndex, endEntry.localIndex + 1, findingIndex);
      } else {
        // Wrap just the portion in the starting node
        wrapTextNode(startEntry.node, startEntry.localIndex, startEntry.node.nodeValue.length, findingIndex);
      }
    });
  };

  // Tooltip for highlighted claims
  useEffect(() => {
    const tip = document.createElement('div');
    tip.className = 'claim-tooltip';
    document.body.appendChild(tip);
    tooltipRef.current = tip;

    const onOver = (e) => {
      const mark = e.target.closest('mark.claim-highlight');
      if (!mark) { tip.style.display = 'none'; return; }
      const idx = parseInt(mark.dataset.findingIndex, 10);
      const finding = wrongFindingsRef.current[idx];
      if (!finding) { tip.style.display = 'none'; return; }
      tip.innerHTML = `<strong>⚠ ${finding.accuracy_percentage ?? finding.accuracy ?? 0}% accurate</strong><br/>${finding.analysis || finding.reasoning || ''}`;
      tip.style.display = 'block';
      tip.style.left = `${e.pageX + 14}px`;
      tip.style.top = `${e.pageY + 14}px`;
    };
    const onOut = (e) => {
      if (!e.relatedTarget?.closest('mark.claim-highlight')) tip.style.display = 'none';
    };
    const onMove = (e) => {
      if (tip.style.display === 'block') {
        tip.style.left = `${e.pageX + 14}px`;
        tip.style.top = `${e.pageY + 14}px`;
      }
    };

    document.addEventListener('mouseover', onOver);
    document.addEventListener('mouseout', onOut);
    document.addEventListener('mousemove', onMove);
    return () => {
      document.removeEventListener('mouseover', onOver);
      document.removeEventListener('mouseout', onOut);
      document.removeEventListener('mousemove', onMove);
      tip.remove();
    };
  }, []);

  const fetchCredibility = async () => {
    const saved = savedRangeRef.current;
    const sel = window.getSelection();
    const selectedText = saved && !saved.collapsed ? saved.toString().trim() : (sel && !sel.isCollapsed ? sel.toString().trim() : null);
    const content = selectedText || editorRef.current?.innerText.trim();
    if (!content) {
      setToast({ message: 'Please type something before checking credibility.', type: 'info' });
      return;
    }

    setIsChecking(true);
    setAnalysis(null);
    clearHighlights(); 

    try {
      const response = await fetch(`${BACKEND_URL}/api/credibility`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${localStorage.getItem('token')}` },
        body: JSON.stringify({ text: content, persona: user?.persona || '1' }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Server Error' }));
        throw new Error(errorData.error || `Status ${response.status}`);
      }

      const data = await response.json();
      if (data.error) {
        setAnalysis({ _tooLong: true });
        setSidebarTab('analysis');
        return;
      }
      setAnalysis(data);
      setSidebarTab('analysis');
      setSidebarOpen(true);
      highlightClaims(data.findings || data.details || []);
    } catch (error) {
      setAnalysis({ _tooLong: true });
      setSidebarTab('analysis');
      setSidebarOpen(true);
    } finally {
      setIsChecking(false);
    }
  };



  return (
    <div className="editor-container">
      <header className="navbar">
        <div className="nav-left">
          <button
            className="nav-link"
            style={{ background: 'none', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6, color: 'inherit', font: 'inherit', padding: 0 }}
            onClick={() => tryNavigate('/dashboard')}
          >
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <polyline points="15 18 9 12 15 6" />
            </svg>
            <span>Back</span>
          </button>
        </div>
        <div className="nav-center">
          <input
            className="title-input"
            value={title}
            onChange={e => { setTitle(e.target.value); setIsDirty(true); }}
            placeholder="Untitled Document"
            spellCheck={false}
          />
        </div>
        <div className="nav-right">
          {/* Open file */}
          <input
            ref={fileInputRef}
            type="file"
            accept=".txt,.text,.pdf,.docx"
            style={{ display: 'none' }}
            onChange={handleOpenFile}
          />
          <button
            className="nav-file-btn"
            onClick={() => fileInputRef.current?.click()}
            title="Open file"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z"/>
            </svg>
            <span>Open</span>
          </button>
          {/* Save to device dropdown */}
          <div style={{ position: 'relative' }}>
            <button
              className="nav-file-btn"
              onClick={() => setDownloadOpen(o => !o)}
              title="Download"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
                <polyline points="7 10 12 15 17 10"/>
                <line x1="12" y1="15" x2="12" y2="3"/>
              </svg>
              <span>Download</span>
            </button>
            {downloadOpen && (
              <>
                <div style={{ position: 'fixed', inset: 0, zIndex: 98 }} onClick={() => setDownloadOpen(false)} />
                <div className="download-menu">
                  <button className="download-menu-item" onClick={() => { saveAsPDF(title, editorRef.current?.innerHTML || ''); setDownloadOpen(false); }}>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    Download as PDF
                  </button>
                  <button className="download-menu-item" onClick={() => { saveAsWord(title, editorRef.current?.innerHTML || ''); setDownloadOpen(false); }}>
                    <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
                    Download as Word
                  </button>
                </div>
              </>
            )}
          </div>
          <div
            className={`action-circle purple ${isChecking ? 'loading' : ''}`}
            onMouseDown={() => {
              const sel = window.getSelection();
              if (sel && !sel.isCollapsed) savedRangeRef.current = sel.getRangeAt(0).cloneRange();
            }}
            onClick={fetchCredibility}
            title="Check credibility"
          >
            {isChecking ? (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ animation: 'spin 1s linear infinite' }}>
                <path d="M21 12a9 9 0 1 1-6.219-8.56" />
              </svg>
            ) : (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
              </svg>
            )}
          </div>
          {analysis && (
            <button
              className={`draft-panel-toggle${sidebarOpen ? ' active' : ''}`}
              onClick={() => setSidebarOpen(o => !o)}
              title="Toggle analysis panel"
            >
              Results {sidebarOpen ? '▲' : '▼'}
            </button>
          )}
        </div>
      </header>

      {/* Analysis panel — fixed right on desktop, dropdown on mobile */}
      {analysis && (
        <div className={`draft-panel${sidebarOpen ? ' draft-panel--open' : ''}`}>
          <div className="draft-panel-tabs">
            <button className={`draft-panel-tab${sidebarTab === 'analysis' ? ' active' : ''}`} onClick={() => setSidebarTab('analysis')}>Analysis</button>
            <button className={`draft-panel-tab${sidebarTab === 'suggestion' ? ' active' : ''}`} onClick={() => setSidebarTab('suggestion')}>Suggestion</button>
            <button className="draft-panel-close" onClick={() => setSidebarOpen(false)}>✕</button>
          </div>
          <div className="draft-panel-body">
            {sidebarTab === 'analysis' ? (
              !analysis ? (
                <div style={{ textAlign: 'center', padding: '32px 16px', color: '#aaa' }}>
                  <div style={{ fontSize: '2rem', marginBottom: '12px' }}>🛡️</div>
                  <p style={{ fontSize: '0.9rem', lineHeight: '1.6' }}>Click the shield button to check credibility.</p>
                </div>
              ) : analysis._tooLong ? (
                <div style={{ textAlign: 'center', padding: '20px' }}>
                  <div style={{ fontSize: '2rem', marginBottom: '12px' }}>✂️</div>
                  <p style={{ fontWeight: '700', color: '#d97706', marginBottom: '8px' }}>Text is too long to analyze</p>
                  <p style={{ color: '#666', fontSize: '0.9rem', lineHeight: '1.6' }}>Please <strong>highlight</strong> a specific sentence or claim, then click the shield button.</p>
                </div>
              ) : (
                <div>
                  <div style={{ fontSize: '1.1rem', fontWeight: 'bold', color: '#6a11cb', marginBottom: '12px' }}>
                    Score: {analysis.overall_credibility_score || analysis.score || '0'}%
                  </div>
                  <p style={{ margin: '0 0 16px', lineHeight: '1.5', color: '#333', fontSize: '0.9rem' }}>{analysis.summary || analysis.result}</p>
                  {(analysis.findings || analysis.details || []).map((item, i) => (
                    <div key={i} className="analysis-card" style={{ background: '#f9f9f9', padding: '14px', borderRadius: '8px', marginBottom: '12px', borderLeft: '4px solid #6a11cb' }}>
                      <p style={{ fontWeight: 'bold', marginBottom: '4px', color: '#000', fontSize: '0.9rem' }}>Claim: {item.claim || item.text}</p>
                      <div style={{ fontSize: '0.82rem', color: (item.accuracy_percentage || item.accuracy) > 70 ? 'green' : '#d97706', marginBottom: '8px', fontWeight: 'bold' }}>
                        Accuracy: {item.accuracy_percentage || item.accuracy || '0'}%
                      </div>
                      <p style={{ fontSize: '0.85rem', color: '#444', lineHeight: '1.5', margin: '0 0 8px' }}>{item.analysis || item.reasoning}</p>
                      {(item.source_url || item.url) && (item.source_url || item.url) !== 'null' && (item.source_url || item.url).startsWith('http') && (
                        <a href={item.source_url || item.url} target="_blank" rel="noreferrer" style={{ fontSize: '0.8rem', color: '#2563eb', textDecoration: 'underline' }}>🔗 View Source</a>
                      )}
                    </div>
                  ))}
                </div>
              )
            ) : (
              !analysis ? (
                <div style={{ textAlign: 'center', padding: '32px 16px', color: '#aaa' }}>
                  <div style={{ fontSize: '2rem', marginBottom: '12px' }}>💡</div>
                  <p style={{ fontSize: '0.9rem', lineHeight: '1.6' }}>Run a credibility check to get suggestions.</p>
                </div>
              ) : analysis?.suggestions?.length > 0 ? (
                <div>
                  <div className="analysis-card" style={{ background: '#f9f9f9', padding: '14px', borderRadius: '8px', marginBottom: '12px', borderLeft: '4px solid #00b894' }}>
                    <p style={{ fontSize: '0.75rem', fontWeight: '700', color: '#00b894', marginBottom: '8px', textTransform: 'uppercase' }}>💡 Suggestions</p>
                    {analysis.suggestions.map((s, i) => (
                      <p key={i} style={{ fontSize: '0.88rem', color: '#333', lineHeight: '1.6', margin: '0 0 6px' }}>{i + 1}. {s.text || s}</p>
                    ))}
                  </div>
                  {(analysis.apa_summary || analysis.summary_with_citations) && (
                    <div className="analysis-card" style={{ background: '#f5f0ff', padding: '14px', borderRadius: '8px', marginBottom: '12px', borderLeft: '4px solid #6a11cb' }}>
                      <p style={{ fontSize: '0.75rem', fontWeight: '700', color: '#6a11cb', marginBottom: '8px', textTransform: 'uppercase' }}>📝 APA Summary</p>
                      <p style={{ fontSize: '0.88rem', color: '#333', lineHeight: '1.6', margin: 0, whiteSpace: 'pre-wrap' }}>{analysis.apa_summary || analysis.summary_with_citations}</p>
                    </div>
                  )}
                </div>
              ) : (
                <div style={{ textAlign: 'center', padding: '20px', color: '#888', fontSize: '0.9rem' }}>Run a credibility check to get suggestions.</div>
              )
            )}
          </div>
        </div>
      )}

      <main className="editor-layout">
        <aside className="toolbar-left">
          <button className="tool-btn bold" onClick={() => formatText('bold')}>B</button>
          <button className="tool-btn italic" onClick={() => formatText('italic')}>I</button>
          <button className="tool-btn underline" onClick={() => formatText('underline')}>U</button>
          <button className="tool-btn" onClick={() => formatText('h1')}>H₁</button>
          <button className="tool-btn" onClick={() => formatText('h2')}>H₂</button>
          <button className="tool-btn" onClick={() => formatText('list')}>≡</button>

          <select className="tool-select"
            value={fontSize}
            onMouseDown={() => {
              const sel = window.getSelection();
              if (sel.rangeCount) savedRangeRef.current = sel.getRangeAt(0).cloneRange();
            }}
            onChange={e => {
              setFontSize(e.target.value);
              formatText('fontSize', e.target.value);
            }}>
            <option value="" disabled>{fontSize ? fontSize.replace('px','') : 'Sz'}</option>
            <option value="12px">12</option>
            <option value="14px">14</option>
            <option value="16px">16</option>
            <option value="18px">18</option>
            <option value="24px">24</option>
            <option value="32px">32</option>
            <option value="48px">48</option>
          </select>

          <div className="tool-color-group">
            <span className="tool-color-label">A</span>
            <div className="tool-color-swatch" style={{ background: textColor }} />
            <input type="color" className="tool-color-input" value={textColor}
              onChange={e => { setTextColor(e.target.value); formatText('textColor', e.target.value); }}
            />
          </div>

          <div className="tool-color-group">
            <span className="tool-color-label">BG</span>
            <div className="tool-color-swatch" style={{ background: bgColor }} />
            <input type="color" className="tool-color-input" value={bgColor}
              onChange={e => { setBgColor(e.target.value); formatText('bgColor', e.target.value); }}
            />
          </div>
        </aside>

        <section className="writing-area">
          <div
            ref={editorRef}
            className="editor"
            contentEditable
            onInput={handleInput}
            suppressContentEditableWarning={true}
          />
          <div className="editor-save-bar">
            <span className="word-count">{wordCount} {wordCount === 1 ? 'word' : 'words'}</span>
            <button className="save-btn" onClick={saveDraft} disabled={isSaving}>
              {isSaving ? '💾 Saving...' : '💾 Save'}
            </button>
          </div>
        </section>
      </main>

      {exitPrompt && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.6)', zIndex: 999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ background: 'var(--card-bg, #2e2e2e)', border: '1px solid rgba(255,255,255,0.1)', borderRadius: 16, padding: 28, maxWidth: 360, width: '90%', display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ fontSize: '1.1rem', fontWeight: 700, color: 'var(--text-main, #fff)' }}>Unsaved Changes</div>
            <div style={{ fontSize: '0.9rem', color: 'var(--text-muted, #888)', lineHeight: 1.6 }}>Do you want to save your document before leaving?</div>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
              <button onClick={() => setExitPrompt(null)} style={{ padding: '8px 16px', borderRadius: 8, border: '1px solid var(--border-color, #3a3a3a)', background: 'transparent', color: 'var(--text-main, #fff)', cursor: 'pointer', fontFamily: 'inherit' }}>Cancel</button>
              <button onClick={() => { setIsDirty(false); navigate(exitPrompt); }} style={{ padding: '8px 16px', borderRadius: 8, border: '1px solid #ff6b6b', background: 'transparent', color: '#ff6b6b', cursor: 'pointer', fontFamily: 'inherit' }}>Don't Save</button>
              <button onClick={() => saveDraft(null, () => navigate(exitPrompt))} disabled={isSaving} style={{ padding: '8px 16px', borderRadius: 8, border: 'none', background: 'var(--accent-teal, #5ce1e6)', color: '#1a6d70', fontWeight: 700, cursor: 'pointer', fontFamily: 'inherit' }}>{isSaving ? 'Saving...' : 'Save'}</button>
            </div>
          </div>
        </div>
      )}
      {toast && <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />}
    </div>
  );
}

export default Draft;