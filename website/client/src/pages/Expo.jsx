import { useState, useEffect, useRef } from 'react';
import axios from 'axios';
import { BACKEND_URL } from '../App';
import '../styles/expo.css';

const ALITAPTAP_API = import.meta.env.VITE_ALITAPTAP_API_URL || 'http://127.0.0.1:8000/api/v1';

export default function Expo({ user }) {
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [selectedPost, setSelectedPost] = useState(null);
  const [fundAmount, setFundAmount] = useState('');
  const [comment, setComment] = useState('');
  const [comments, setComments] = useState([]);
  const [loadingComments, setLoadingComments] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [form, setForm] = useState({
    title: '', abstract: '', problem_solved: '',
    sdg_tags: '', funding_goal: '',
  });
  const [menuOpenId, setMenuOpenId] = useState(null);
  const [editPost, setEditPost] = useState(null);
  const [editForm, setEditForm] = useState({});
  const menuRef = useRef({});

  useEffect(() => { fetchPosts(); }, []);
  useEffect(() => {
    const handler = (e) => {
      const openMenu = menuRef.current[menuOpenId];
      if (openMenu && !openMenu.contains(e.target)) {
        setMenuOpenId(null);
      }
    };
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, [menuOpenId]);

  const fetchPosts = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${ALITAPTAP_API}/posts`);
      setPosts(res.data);
    } catch {
      setPosts([]);
    } finally {
      setLoading(false);
    }
  };

  const openPost = async (post) => {
    setSelectedPost(post);
    setLoadingComments(true);
    try {
      const res = await axios.get(`${ALITAPTAP_API}/posts/${post.post_id}/comments`);
      setComments(res.data);
    } catch { setComments([]); }
    setLoadingComments(false);
  };

  const handleLike = async (postId) => {
    if (!user) return;
    try {
      const res = await axios.post(`${ALITAPTAP_API}/posts/${postId}/like`, {
        user_id: user.id?.toString() || user.email,
      });
      setPosts(prev => prev.map(p => p.post_id === postId ? res.data : p));
      if (selectedPost?.post_id === postId) setSelectedPost(res.data);
    } catch {}
  };

  const handleFund = async () => {
    if (!user || !fundAmount || !selectedPost) return;
    const amount = parseFloat(fundAmount);
    if (isNaN(amount) || amount <= 0) return;
    setSubmitting(true);
    try {
      const res = await axios.post(`${ALITAPTAP_API}/posts/${selectedPost.post_id}/fund`, {
        user_id: user.id?.toString() || user.email,
        amount,
      });
      setPosts(prev => prev.map(p => p.post_id === selectedPost.post_id ? res.data : p));
      setSelectedPost(res.data);
      setFundAmount('');
    } catch {}
    setSubmitting(false);
  };

  const handleComment = async () => {
    if (!user || !comment.trim() || !selectedPost) return;
    setSubmitting(true);
    try {
      const res = await axios.post(`${ALITAPTAP_API}/posts/${selectedPost.post_id}/comments`, {
        author_id: user.id?.toString() || user.email,
        author_email: user.email,
        text: comment.trim(),
      });
      setComments(prev => [...prev, res.data]);
      setComment('');
    } catch {}
    setSubmitting(false);
  };

  const handleDeletePost = async (postId) => {
    if (!window.confirm('Delete this post?')) return;
    try {
      await axios.delete(`${ALITAPTAP_API}/posts/${postId}`);
      setPosts(prev => prev.filter(p => p.post_id !== postId));
      if (selectedPost?.post_id === postId) setSelectedPost(null);
    } catch {}
    setMenuOpenId(null);
  };

  const openEditPost = (post) => {
    setEditPost(post);
    setEditForm({
      title: post.title,
      abstract: post.abstract,
      problem_solved: post.problem_solved,
      sdg_tags: post.sdg_tags?.join(', ') || '',
      funding_goal: post.funding_goal || '',
    });
    setMenuOpenId(null);
  };

  const handleEditSubmit = async (e) => {
    e.preventDefault();
    setSubmitting(true);
    try {
      const res = await axios.put(`${ALITAPTAP_API}/posts/${editPost.post_id}`, {
        title: editForm.title,
        abstract: editForm.abstract,
        problem_solved: editForm.problem_solved,
        sdg_tags: editForm.sdg_tags.split(',').map(s => s.trim()).filter(Boolean),
        funding_goal: parseFloat(editForm.funding_goal) || 0,
      });
      setPosts(prev => prev.map(p => p.post_id === editPost.post_id ? res.data : p));
      if (selectedPost?.post_id === editPost.post_id) setSelectedPost(res.data);
      setEditPost(null);
    } catch {}
    setSubmitting(false);
  };

  const handleSubmitPost = async (e) => {
    e.preventDefault();
    if (!user) return;
    setSubmitting(true);
    try {
      await axios.post(`${ALITAPTAP_API}/posts`, {
        author_id: user.id?.toString() || user.email,
        author_email: user.email,
        title: form.title,
        abstract: form.abstract,
        problem_solved: form.problem_solved,
        sdg_tags: form.sdg_tags.split(',').map(s => s.trim()).filter(Boolean),
        funding_goal: parseFloat(form.funding_goal) || 0,
      });
      setForm({ title: '', abstract: '', problem_solved: '', sdg_tags: '', funding_goal: '' });
      setShowForm(false);
      fetchPosts();
    } catch {}
    setSubmitting(false);
  };

  const fundingPercent = (post) => {
    if (!post.funding_goal || post.funding_goal === 0) return 0;
    return Math.min(100, Math.round((post.funding_raised / post.funding_goal) * 100));
  };

  return (
    <div className="expo-layout">
      <aside className="expo-sidebar">
        <div className="expo-sidebar-logo">● ALITAPTAP</div>
        <nav className="expo-sidebar-nav">
          <a href="/home" className="expo-nav-item">🏠 Home</a>
          <a href="/dashboard" className="expo-nav-item">🗺️ Ideas</a>
          <a href="/research" className="expo-nav-item">✍️ Research</a>
          <a href="/expo" className="expo-nav-item expo-nav-item--active">🚀 Expo</a>
        </nav>
        <button className="expo-signout" onClick={() => {
          localStorage.removeItem('token');
          delete axios.defaults.headers.common['Authorization'];
          window.location.href = '/';
        }}>Sign Out</button>
      </aside>
      <div className="expo-main">
        {/* Header */}
        <div className="expo-header">
          <div className="expo-header-left">
            <div className="expo-header-icon">🚀</div>
            <div>
              <h1 className="expo-title">Innovation Funding Expo</h1>
              <p className="expo-subtitle">Discover student research. Fund the future.</p>
            </div>
          </div>
          {user && (
            <button className="expo-post-btn" onClick={() => setShowForm(true)}>
              + Post Research
            </button>
          )}
        </div>

        {/* Post Form Modal */}
        {showForm && (
          <div className="expo-modal-overlay" onClick={() => setShowForm(false)}>
            <div className="expo-modal" onClick={e => e.stopPropagation()}>
              <div className="expo-modal-header">
                <h2>Share Your Research</h2>
                <button className="expo-modal-close" onClick={() => setShowForm(false)}>✕</button>
              </div>
              <form onSubmit={handleSubmitPost} className="expo-form">
                <div className="expo-form-group">
                  <label>Research Title *</label>
                  <input required value={form.title}
                    onChange={e => setForm(p => ({ ...p, title: e.target.value }))}
                    placeholder="e.g. Low-cost flood warning system for urban barangays" />
                </div>
                <div className="expo-form-group">
                  <label>Abstract *</label>
                  <textarea required rows={4} value={form.abstract}
                    onChange={e => setForm(p => ({ ...p, abstract: e.target.value }))}
                    placeholder="Summarize your research, methodology, and findings..." />
                </div>
                <div className="expo-form-group">
                  <label>Problem Solved *</label>
                  <textarea required rows={2} value={form.problem_solved}
                    onChange={e => setForm(p => ({ ...p, problem_solved: e.target.value }))}
                    placeholder="What community problem does this research address?" />
                </div>
                <div className="expo-form-row">
                  <div className="expo-form-group">
                    <label>SDG Tags (comma separated)</label>
                    <input value={form.sdg_tags}
                      onChange={e => setForm(p => ({ ...p, sdg_tags: e.target.value }))}
                      placeholder="SDG 11, SDG 13, SDG 6" />
                  </div>
                  <div className="expo-form-group">
                    <label>Funding Goal (₱)</label>
                    <input type="number" min="0" value={form.funding_goal}
                      onChange={e => setForm(p => ({ ...p, funding_goal: e.target.value }))}
                      placeholder="50000" />
                  </div>
                </div>
                <div className="expo-form-actions">
                  <button type="button" className="expo-btn-cancel" onClick={() => setShowForm(false)}>Cancel</button>
                  <button type="submit" className="expo-btn-submit" disabled={submitting}>
                    {submitting ? 'Posting...' : 'Publish Research'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Feed */}
        {loading ? (
          <div className="expo-loading">
            <div className="expo-spinner" />
            <p>Loading research posts...</p>
          </div>
        ) : posts.length === 0 ? (
          <div className="expo-empty">
            <div className="expo-empty-icon">🔬</div>
            <h3>No research posted yet</h3>
            <p>Be the first to share your research with the community.</p>
          </div>
        ) : (
          <div className="expo-feed">
            {posts.map(post => (
              <div key={post.post_id} className="expo-card">
                <div className="expo-card-header">
                  <div className="expo-card-avatar">
                    {post.author_email?.[0]?.toUpperCase() || 'R'}
                  </div>
                  <div className="expo-card-meta">
                    <span className="expo-card-author">{post.author_email?.split('@')[0]}</span>
                    <span className="expo-card-date">{post.created_at?.split('T')[0]}</span>
                  </div>
                  <div className="expo-post-menu" ref={el => menuRef.current[post.post_id] = el} onClick={e => e.stopPropagation()}>
                    <button className="expo-menu-btn" onClick={() => setMenuOpenId(menuOpenId === post.post_id ? null : post.post_id)}>⋯</button>
                    {menuOpenId === post.post_id && (
                      <div className="expo-menu-dropdown">
                        <button onClick={() => openEditPost(post)}>✏️ Edit Post</button>
                        <button className="expo-menu-delete" onClick={() => handleDeletePost(post.post_id)}>🗑️ Delete Post</button>
                      </div>
                    )}
                  </div>
                </div>

                <div className="expo-card-body" onClick={() => openPost(post)}>
                <h3 className="expo-card-title">{post.title}</h3>
                <p className="expo-card-abstract">{post.abstract}</p>

                {post.sdg_tags?.length > 0 && (
                  <div className="expo-card-tags">
                    {post.sdg_tags.map(tag => (
                      <span key={tag} className="expo-tag">{tag}</span>
                    ))}
                  </div>
                )}

                {post.funding_goal > 0 && (
                  <div className="expo-funding-bar-wrap">
                    <div className="expo-funding-bar-track">
                      <div className="expo-funding-bar-fill"
                        style={{ width: `${fundingPercent(post)}%` }} />
                    </div>
                    <div className="expo-funding-stats">
                      <span className="expo-funding-raised">₱{post.funding_raised?.toLocaleString()}</span>
                      <span className="expo-funding-goal">of ₱{post.funding_goal?.toLocaleString()} goal · {fundingPercent(post)}%</span>
                    </div>
                  </div>
                )}

                </div>
                <div className="expo-card-actions" onClick={e => e.stopPropagation()}>
                  <button className="expo-action-btn" onClick={() => handleLike(post.post_id)}>
                    ❤️ {post.likes || 0}
                  </button>
                  <button className="expo-action-btn" onClick={() => openPost(post)}>
                    💬 Comment
                  </button>
                  {post.funding_goal > 0 && (
                    <button className="expo-action-btn expo-fund-btn"
                      onClick={() => openPost(post)}>
                      💰 Fund
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Edit Post Modal */}
        {editPost && (
          <div className="expo-modal-overlay" onClick={() => setEditPost(null)}>
            <div className="expo-modal" onClick={e => e.stopPropagation()}>
              <div className="expo-modal-header">
                <h2>Edit Post</h2>
                <button className="expo-modal-close" onClick={() => setEditPost(null)}>✕</button>
              </div>
              <form onSubmit={handleEditSubmit} className="expo-form">
                <div className="expo-form-group">
                  <label>Research Title *</label>
                  <input required value={editForm.title} onChange={e => setEditForm(p => ({ ...p, title: e.target.value }))} />
                </div>
                <div className="expo-form-group">
                  <label>Abstract *</label>
                  <textarea required rows={4} value={editForm.abstract} onChange={e => setEditForm(p => ({ ...p, abstract: e.target.value }))} />
                </div>
                <div className="expo-form-group">
                  <label>Problem Solved *</label>
                  <textarea required rows={2} value={editForm.problem_solved} onChange={e => setEditForm(p => ({ ...p, problem_solved: e.target.value }))} />
                </div>
                <div className="expo-form-row">
                  <div className="expo-form-group">
                    <label>SDG Tags (comma separated)</label>
                    <input value={editForm.sdg_tags} onChange={e => setEditForm(p => ({ ...p, sdg_tags: e.target.value }))} />
                  </div>
                  <div className="expo-form-group">
                    <label>Funding Goal (₱)</label>
                    <input type="number" min="0" value={editForm.funding_goal} onChange={e => setEditForm(p => ({ ...p, funding_goal: e.target.value }))} />
                  </div>
                </div>
                <div className="expo-form-actions">
                  <button type="button" className="expo-btn-cancel" onClick={() => setEditPost(null)}>Cancel</button>
                  <button type="submit" className="expo-btn-submit" disabled={submitting}>{submitting ? 'Saving...' : 'Save Changes'}</button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Post Detail Modal */}
        {selectedPost && (
          <div className="expo-modal-overlay" onClick={() => setSelectedPost(null)}>
            <div className="expo-modal expo-detail-modal" onClick={e => e.stopPropagation()}>
              <div className="expo-modal-header">
                <h2>{selectedPost.title}</h2>
                <button className="expo-modal-close" onClick={() => setSelectedPost(null)}>✕</button>
              </div>

              <div className="expo-detail-body">
                <div className="expo-detail-author">
                  <div className="expo-card-avatar">
                    {selectedPost.author_email?.[0]?.toUpperCase()}
                  </div>
                  <div>
                    <span className="expo-card-author">{selectedPost.author_email?.split('@')[0]}</span>
                    <span className="expo-card-date"> · {selectedPost.created_at?.split('T')[0]}</span>
                  </div>
                </div>

                <div className="expo-detail-section">
                  <h4>Abstract</h4>
                  <p>{selectedPost.abstract}</p>
                </div>

                <div className="expo-detail-section">
                  <h4>Problem Solved</h4>
                  <p>{selectedPost.problem_solved}</p>
                </div>

                {selectedPost.sdg_tags?.length > 0 && (
                  <div className="expo-detail-section">
                    <h4>SDG Alignment</h4>
                    <div className="expo-card-tags">
                      {selectedPost.sdg_tags.map(tag => (
                        <span key={tag} className="expo-tag">{tag}</span>
                      ))}
                    </div>
                  </div>
                )}

                {selectedPost.funding_goal > 0 && (
                  <div className="expo-detail-section">
                    <h4>Funding Progress</h4>
                    <div className="expo-funding-bar-track">
                      <div className="expo-funding-bar-fill"
                        style={{ width: `${fundingPercent(selectedPost)}%` }} />
                    </div>
                    <div className="expo-funding-stats">
                      <span className="expo-funding-raised">₱{selectedPost.funding_raised?.toLocaleString()}</span>
                      <span className="expo-funding-goal"> of ₱{selectedPost.funding_goal?.toLocaleString()} · {fundingPercent(selectedPost)}%</span>
                    </div>
                    {user && (
                      <div className="expo-fund-input-row">
                        <input type="number" min="1" placeholder="Enter amount (₱)"
                          value={fundAmount}
                          onChange={e => setFundAmount(e.target.value)} />
                        <button className="expo-btn-submit" onClick={handleFund} disabled={submitting}>
                          {submitting ? '...' : '💰 Fund This'}
                        </button>
                      </div>
                    )}
                  </div>
                )}

                <div className="expo-detail-section">
                  <div className="expo-detail-likes">
                    <button className="expo-action-btn" onClick={() => handleLike(selectedPost.post_id)}>
                      ❤️ {selectedPost.likes || 0} Likes
                    </button>
                  </div>
                </div>

                {/* Comments */}
                <div className="expo-detail-section">
                  <h4>Discussion</h4>
                  {loadingComments ? (
                    <p className="expo-subtle">Loading comments...</p>
                  ) : comments.length === 0 ? (
                    <p className="expo-subtle">No comments yet. Start the discussion!</p>
                  ) : (
                    <div className="expo-comments">
                      {comments.map(c => (
                        <div key={c.comment_id} className="expo-comment">
                          <div className="expo-comment-avatar">
                            {c.author_email?.[0]?.toUpperCase()}
                          </div>
                          <div className="expo-comment-body">
                            <span className="expo-comment-author">{c.author_email?.split('@')[0]}</span>
                            <span className="expo-comment-date"> · {c.created_at?.split('T')[0]}</span>
                            <p>{c.text}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {user && (
                    <div className="expo-comment-input-row">
                      <input placeholder="Write a comment..."
                        value={comment}
                        onChange={e => setComment(e.target.value)}
                        onKeyDown={e => e.key === 'Enter' && handleComment()} />
                      <button className="expo-btn-submit" onClick={handleComment} disabled={submitting}>
                        Send
                      </button>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
