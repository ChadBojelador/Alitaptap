import { useState, useRef, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import axios from 'axios';
import html2pdf from 'html2pdf.js';
import { Document, Packer, Paragraph, TextRun, HeadingLevel } from 'docx';
import { BACKEND_URL } from '../App';
import '../styles/research-draft.css';

const ALITAPTAP_API = import.meta.env.VITE_ALITAPTAP_API_URL || 'http://127.0.0.1:8000/api/v1';

export default function ResearchDraft({ user }) {
  const { id } = useParams();
  const navigate = useNavigate();
  const editorRef = useRef(null);

  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [draftId, setDraftId] = useState(null);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [wordCount, setWordCount] = useState(0);
  const [exportOpen, setExportOpen] = useState(false);
  const [postOpen, setPostOpen] = useState(false);
  const [posting, setPosting] = useState(false);
  const [ideas, setIdeas] = useState([]);
  const [showIdeas, setShowIdeas] = useState(false);
  const [postForm, setPostForm] = useState({ abstract: '', problem_solved: '', sdg_tags: '', funding_goal: '' });

  // Load draft if editing existing
  useEffect(() => {
    if (id) {
      fetch(`${BACKEND_URL}/api/drafts/${id}`, {
        headers: { Authorization: `Bearer ${localStorage.getItem('token')}` }
      }).then(r => r.json()).then(d => {
        setDraftId(d.id);
        setTitle(d.title || '');
        if (editorRef.current) editorRef.current.innerHTML = d.content || '';
        updateWordCount(d.content || '');
      }).catch(() => {});
    } else {
      // Check for generated research docs from Dashboard
      const generatedDocs = localStorage.getItem('generatedResearchDocs');
      if (generatedDocs) {
        try {
          const docs = JSON.parse(generatedDocs);
          setTitle(docs.title);
          
          // Format the research document as HTML
          let html = `<h1>I. INTRODUCTION</h1>`;
          html += `<p>${docs.introduction.replace(/\n\n/g, '</p><p>')}</p>`;
          
          html += `<h1>II. REVIEW OF RELATED LITERATURE</h1>`;
          docs.rrl.forEach(section => {
            html += `<h2>${section.category}</h2>`;
            section.references.forEach((ref, idx) => {
              html += `<p><strong>${idx + 1}. ${ref.citation}</strong></p>`;
              html += `<p style="margin-left: 20px; text-align: justify;">${ref.summary}</p>`;
            });
          });
          
          html += `<h1>III. METHODOLOGY</h1>`;
          html += `<p>${docs.methodology.replace(/\n\n/g, '</p><p>')}</p>`;
          
          html += `<h1>IV. EXPECTED OUTCOMES</h1>`;
          html += `<ul>`;
          docs.expectedOutcomes.forEach(outcome => {
            html += `<li>${outcome}</li>`;
          });
          html += `</ul>`;
          
          if (editorRef.current) editorRef.current.innerHTML = html;
          updateWordCount(html);
          
          // Clear the localStorage after loading
          localStorage.removeItem('generatedResearchDocs');
        } catch (e) {
          console.error('Failed to load generated docs:', e);
        }
      }
    }
  }, [id]);

  // Load mobile ideas
  useEffect(() => {
    axios.get(`${ALITAPTAP_API}/issues?status=validated`)
      .then(r => setIdeas(r.data))
      .catch(() => {});
  }, []);

  const updateWordCount = (html) => {
    const tmp = document.createElement('div');
    tmp.innerHTML = html;
    const words = (tmp.innerText || '').trim().split(/\s+/).filter(w => w.length > 0);
    setWordCount(words.length);
  };

  const handleInput = () => {
    updateWordCount(editorRef.current?.innerHTML || '');
    setSaved(false);
  };

  const format = (cmd, val = null) => {
    editorRef.current?.focus();
    document.execCommand(cmd, false, val);
  };

  const insertIdea = (idea) => {
    const html = `<h2>${idea.title}</h2><p><strong>Problem:</strong> ${idea.description}</p><p><strong>Location:</strong> ${idea.lat.toFixed(4)}, ${idea.lng.toFixed(4)}</p><hr/>`;
    if (editorRef.current) {
      editorRef.current.focus();
      document.execCommand('insertHTML', false, html);
    }
    if (!title) setTitle(idea.title);
    setShowIdeas(false);
  };

  const save = async () => {
    const currentContent = editorRef.current?.innerHTML || '';
    setSaving(true);
    try {
      const method = draftId ? 'PUT' : 'POST';
      const url = draftId ? `${BACKEND_URL}/api/drafts/${draftId}` : `${BACKEND_URL}/api/drafts`;
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${localStorage.getItem('token')}` },
        body: JSON.stringify({ title: title || 'Untitled Research', content: currentContent }),
      });
      const data = await res.json();
      if (!draftId) setDraftId(data.id);
      setSaved(true);
    } catch {}
    setSaving(false);
  };

  const exportPDF = async () => {
    const container = document.createElement('div');
    container.innerHTML = `<h1>${title || 'Research Draft'}</h1>${editorRef.current?.innerHTML || ''}`;
    container.style.cssText = 'font-family:Georgia,serif;font-size:14px;line-height:1.8;color:#111;padding:40px;max-width:700px;';
    document.body.appendChild(container);
    await html2pdf().set({
      margin: [20, 20, 20, 20],
      filename: `${title || 'research'}.pdf`,
      html2canvas: { scale: 2 },
      jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
    }).from(container).save();
    document.body.removeChild(container);
    setExportOpen(false);
  };

  const exportWord = async () => {
    const tmp = document.createElement('div');
    tmp.innerHTML = editorRef.current?.innerHTML || '';
    const lines = (tmp.innerText || '').split('\n').filter(l => l.trim());
    const doc = new Document({
      sections: [{
        children: [
          new Paragraph({ text: title || 'Research Draft', heading: HeadingLevel.HEADING_1 }),
          ...lines.map(line => new Paragraph({
            children: [new TextRun({ text: line, size: 24, font: 'Calibri' })],
            spacing: { after: 160 },
          }))
        ]
      }]
    });
    const blob = await Packer.toBlob(doc);
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `${title || 'research'}.docx`;
    a.click();
    URL.revokeObjectURL(a.href);
    setExportOpen(false);
  };

  const postToExpo = async () => {
    if (!user) return;
    setPosting(true);
    try {
      await axios.post(`${ALITAPTAP_API}/posts`, {
        author_id: user.id?.toString() || user.email,
        author_email: user.email,
        title: title || 'Research Draft',
        abstract: postForm.abstract || editorRef.current?.innerText?.slice(0, 300) || '',
        problem_solved: postForm.problem_solved,
        sdg_tags: postForm.sdg_tags.split(',').map(s => s.trim()).filter(Boolean),
        funding_goal: parseFloat(postForm.funding_goal) || 0,
      });
      setPostOpen(false);
      navigate('/expo');
    } catch {}
    setPosting(false);
  };

  return (
    <div className="rd-root">
      {/* Top bar */}
      <header className="rd-header">
        <div className="rd-header-left">
          <button className="rd-back" onClick={() => navigate('/home')}>
            ← Back
          </button>
          <input
            className="rd-title-input"
            value={title}
            onChange={e => { setTitle(e.target.value); setSaved(false); }}
            placeholder="Research Title..."
          />
        </div>
        <div className="rd-header-right">
          <span className="rd-wordcount">{wordCount} words</span>
          <button className="rd-btn-ghost" onClick={() => setShowIdeas(v => !v)}>
            📲 Import Idea
          </button>
          <div className="rd-export-wrap">
            <button className="rd-btn-ghost" onClick={() => setExportOpen(v => !v)}>
              ⬇ Export
            </button>
            {exportOpen && (
              <>
                <div className="rd-overlay" onClick={() => setExportOpen(false)} />
                <div className="rd-dropdown">
                  <button onClick={exportPDF}>📄 Export as PDF</button>
                  <button onClick={exportWord}>📝 Export as Word (.docx)</button>
                </div>
              </>
            )}
          </div>
          <button className="rd-btn-post" onClick={() => setPostOpen(true)}>
            🚀 Post to Expo
          </button>
          <button className="rd-btn-save" onClick={save} disabled={saving}>
            {saving ? 'Saving...' : saved ? '✓ Saved' : '💾 Save'}
          </button>
        </div>
      </header>

      {/* Import ideas panel */}
      {showIdeas && (
        <div className="rd-ideas-panel">
          <div className="rd-ideas-header">
            <span>📲 Import from Mobile App</span>
            <button onClick={() => setShowIdeas(false)}>✕</button>
          </div>
          <div className="rd-ideas-list">
            {ideas.length === 0 ? (
              <p className="rd-empty">No validated problems yet from the mobile app.</p>
            ) : ideas.map(idea => (
              <div key={idea.issue_id} className="rd-idea-item" onClick={() => insertIdea(idea)}>
                <strong>{idea.title}</strong>
                <p>{idea.description}</p>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Toolbar */}
      <div className="rd-toolbar">
        <button onClick={() => format('bold')}><b>B</b></button>
        <button onClick={() => format('italic')}><i>I</i></button>
        <button onClick={() => format('underline')}><u>U</u></button>
        <button onClick={() => format('formatBlock', 'h1')}>H1</button>
        <button onClick={() => format('formatBlock', 'h2')}>H2</button>
        <button onClick={() => format('formatBlock', 'h3')}>H3</button>
        <button onClick={() => format('insertUnorderedList')}>• List</button>
        <button onClick={() => format('insertOrderedList')}>1. List</button>
        <button onClick={() => format('formatBlock', 'blockquote')}>❝ Quote</button>
        <button onClick={() => format('removeFormat')}>Clear</button>
      </div>

      {/* Editor */}
      <div className="rd-editor-wrap">
        <div
          ref={editorRef}
          className="rd-editor"
          contentEditable
          onInput={handleInput}
          suppressContentEditableWarning
          data-placeholder="Start writing your research here... or import an idea from the mobile app above."
        />
      </div>

      {/* Post to Expo Modal */}
      {postOpen && (
        <div className="rd-modal-overlay" onClick={() => setPostOpen(false)}>
          <div className="rd-modal" onClick={e => e.stopPropagation()}>
            <div className="rd-modal-header">
              <h3>🚀 Post to Innovation Expo</h3>
              <button onClick={() => setPostOpen(false)}>✕</button>
            </div>
            <div className="rd-modal-body">
              <label>Abstract *</label>
              <textarea rows={4} placeholder="Summarize your research..."
                value={postForm.abstract}
                onChange={e => setPostForm(p => ({ ...p, abstract: e.target.value }))} />
              <label>Problem Solved *</label>
              <textarea rows={2} placeholder="What community problem does this solve?"
                value={postForm.problem_solved}
                onChange={e => setPostForm(p => ({ ...p, problem_solved: e.target.value }))} />
              <label>SDG Tags (comma separated)</label>
              <input placeholder="SDG 11, SDG 13"
                value={postForm.sdg_tags}
                onChange={e => setPostForm(p => ({ ...p, sdg_tags: e.target.value }))} />
              <label>Funding Goal (₱)</label>
              <input type="number" placeholder="50000"
                value={postForm.funding_goal}
                onChange={e => setPostForm(p => ({ ...p, funding_goal: e.target.value }))} />
            </div>
            <div className="rd-modal-footer">
              <button className="rd-btn-ghost" onClick={() => setPostOpen(false)}>Cancel</button>
              <button className="rd-btn-post" onClick={postToExpo} disabled={posting}>
                {posting ? 'Posting...' : '🚀 Publish to Expo'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
