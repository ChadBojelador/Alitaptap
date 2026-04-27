import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import '../styles/home_feed.css';
import '../styles/platform.css';

const ALITAPTAP_API = import.meta.env.VITE_ALITAPTAP_API_URL || 'http://127.0.0.1:8000/api/v1';

export default function Home({ user }) {
  const navigate = useNavigate();
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeStory, setActiveStory] = useState(null);
  const [isDarkMode, setIsDarkMode] = useState(true);


  useEffect(() => {
    fetchPosts();
  }, []);

  const fetchPosts = async () => {
    setLoading(true);
    try {
      const res = await axios.get(`${ALITAPTAP_API}/posts`);
      setPosts(res.data);
    } catch {
      setPosts([]);
    }
    setLoading(false);
  };

  const stories = [
    { label: 'SDG 3', icon: '❤️', color: '#EF5350' },
    { label: 'SDG 13', icon: '🍃', color: '#66BB6A' },
    { label: 'SDG 4', icon: '🎓', color: '#42A5F5' },
    { label: 'SDG 11', icon: '🏙️', color: '#AB47BC' },
    { label: 'SDG 6', icon: '💧', color: '#26C6DA' },
  ];

  const displayName = user?.name || user?.email?.split('@')[0] || 'there';

  return (
    <div className={`hf-root ${!isDarkMode ? 'light-mode' : ''}`}>

      {/* App Sidebar */}
      <aside className="plat-sidebar">
        <div className="plat-sidebar-logo">
          <span className="plat-logo-dot">●</span>
          <span>ALITAPTAP</span>
        </div>
        <nav className="plat-sidebar-nav">
          <div className="plat-nav-item plat-nav-item--active" onClick={() => navigate('/home')}>
            <span>🏠</span> Home
          </div>
          <div className="plat-nav-item" onClick={() => navigate('/dashboard')}>
            <span>🗺️</span> Ideas
          </div>
          <div className="plat-nav-item" onClick={() => navigate('/research')}>
            <span>✍️</span> Research
          </div>
          <div className="plat-nav-item" onClick={() => navigate('/expo')}>
            <span>🚀</span> Expo
          </div>
        </nav>
      </aside>

      <main className="hf-main">
        <header className="hf-web-header">
          <div className="hf-header-left-group">
            <h2 className="hf-logo-text">ALITAPTAP</h2>
            <div className="hf-header-search">
              <svg style={{ color: 'var(--c-yellow)', marginRight: '8px' }} width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
                <circle cx="11" cy="11" r="8"></circle>
                <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
              </svg>
              <input type="text" placeholder="Search research, SDGs, or people..." />
            </div>
          </div>
          <div className="hf-header-icons">
            <div className="hf-icon-btn">
              <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                <path d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05 1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/>
              </svg>
            </div>
            <div className="hf-icon-btn">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
                <path d="M20 2H4c-1.1 0-2 .9-2 2v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/>
              </svg>
            </div>
            <div className="hf-icon-btn hf-theme-btn" onClick={() => setIsDarkMode(!isDarkMode)}>
              {isDarkMode ? (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1zM5.99 4.58c-.39-.39-1.03-.39-1.41 0s-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41L5.99 4.58zm12.37 12.37c-.39-.39-1.03-.39-1.41 0s-.39 1.03 0 1.41l1.06 1.06c.39.39 1.03.39 1.41 0s.39-1.03 0-1.41l-1.06-1.06zm1.06-12.37c-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06c.39-.39.39-1.03 0-1.41zm-12.37 12.37c-.39-.39-1.03-.39-1.41 0l-1.06 1.06c-.39.39-.39 1.03 0 1.41s1.03.39 1.41 0l1.06-1.06c.39-.39.39-1.03 0-1.41z"/>
                </svg>
              ) : (
                <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                  <path d="M12 3c-4.97 0-9 4.03-9 9s4.03 9 9 9 9-4.03 9-9c0-.46-.04-.92-.1-1.36-.98 1.37-2.58 2.26-4.4 2.26-2.98 0-5.4-2.42-5.4-5.4 0-1.81.89-3.42 2.26-4.4-.44-.06-.9-.1-1.36-.1z"/>
                </svg>
              )}
            </div>
          </div>
        </header>

        <div className="hf-feed-column">
          {/* Stories Row - Mobile Clone */}
          <section className="hf-stories-container">
            <div className="hf-stories-scroll">
              <div className="hf-story">
                <div className="hf-story-ring add">
                  <div className="hf-story-inner">
                    <span style={{ fontSize: '20px', color: '#FFD60A' }}>+</span>
                  </div>
                </div>
                <span className="hf-story-label">Your Story</span>
              </div>
              {stories.map((s, i) => (
                <div key={i} className="hf-story" onClick={() => setActiveStory(s)}>
                  <div className="hf-story-ring" style={{ background: `linear-gradient(45deg, ${s.color}, #FFD60A)` }}>
                    <div className="hf-story-inner">
                      <div className="hf-story-avatar">{s.icon}</div>
                    </div>
                  </div>
                  <span className="hf-story-label">{s.label}</span>
                </div>
              ))}
            </div>
          </section>

          {/* Story Viewer Modal */}
          {activeStory && (
            <div className="hf-story-modal" onClick={() => setActiveStory(null)}>
              <div className="hf-story-content" onClick={e => e.stopPropagation()} style={{ background: `linear-gradient(180deg, ${activeStory.color}, var(--c-bg))` }}>
                <button className="hf-story-close" onClick={() => setActiveStory(null)}>✕</button>
                <div className="hf-story-view-inner">
                  <div className="hf-story-viewer-avatar">{activeStory.icon}</div>
                  <h2 className="hf-story-view-title">{activeStory.label} Intelligence</h2>
                  <p className="hf-story-view-desc">
                    Viewing real-time research updates for {activeStory.label}.
                    A new community problem was recently pinned in Batangas City matching this goal.
                  </p>
                  <button className="hf-story-action-btn" onClick={() => { setActiveStory(null); navigate('/dashboard'); }}>
                    See Related Map Pins
                  </button>
                </div>
                <div className="hf-story-progress">
                  <div className="hf-story-progress-fill" />
                </div>
              </div>
            </div>
          )}


          {/* Create Post Bar - Mobile Clone */}
          <section className="hf-create-bar">
            <div className="hf-create-input-row">
              <div className="hf-mini-avatar">{displayName[0].toUpperCase()}</div>
              <div className="hf-fake-input" onClick={() => navigate('/expo')}>
                What's on your research mind?
              </div>
            </div>
            <div className="hf-create-actions">
              <div className="hf-create-btn"><span>🖼️</span> Photo</div>
              <div className="hf-create-btn"><span>🔬</span> Research</div>
              <div className="hf-create-btn"><span>💰</span> Fund</div>
            </div>
          </section>

          {/* Feed - Mobile Clone */}
          <section className="hf-feed">
            {loading ? (
              <div className="plat-spinner" style={{ margin: '40px auto' }} />
            ) : posts.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px', color: '#757575' }}>
                <p>📭 No research posts yet.</p>
              </div>
            ) : (
              posts.map(post => (
                <article key={post.post_id} className="hf-post-card">
                  <div className="hf-post-header">
                    <div className="hf-mini-avatar" style={{ backgroundColor: '#34495e', color: '#FFF' }}>
                      {post.author_email?.[0]?.toUpperCase() || 'R'}
                    </div>
                    <div className="hf-post-author">
                      <span className="hf-post-name">{post.author_email?.split('@')[0]}</span>
                      <span className="hf-post-time">Just now · 🌎</span>
                    </div>
                  </div>

                  <div className="hf-post-content">
                    <h3 className="hf-post-title">{post.title}</h3>
                    <p className="hf-post-abstract">{post.abstract}</p>
                  </div>

                  {post.sdg_tags?.length > 0 && (
                    <div className="hf-post-tags">
                      {post.sdg_tags.map(tag => (
                        <span key={tag} className="hf-tag">{tag}</span>
                      ))}
                    </div>
                  )}

                  <div className="hf-post-actions">
                    <div className="hf-action">❤️ Like</div>
                    <div className="hf-action">💬 Comment</div>
                    <div className="hf-action">🏹 Share</div>
                  </div>
                </article>
              ))
            )}
          </section>
        </div>

        {/* Right Sidebar - Web Specific Widgets */}
        <aside className="hf-right-sidebar">
          <div className="hf-widget">
            <h3 className="hf-widget-title">SDG Pulse</h3>
            <div className="hf-sdg-stat">
              <span className="hf-stat-label">Active Research</span>
              <span className="hf-stat-value">24</span>
            </div>
            <div className="hf-sdg-stat">
              <span className="hf-stat-label">Communities Impacted</span>
              <span className="hf-stat-value">12</span>
            </div>
            <div className="hf-sdg-stat">
              <span className="hf-stat-label">SDG Target Met</span>
              <span className="hf-stat-value">SDG 11</span>
            </div>
          </div>

          <div className="hf-widget">
            <h3 className="hf-widget-title">Top Researchers</h3>
            {[
              { name: 'Dr. Jane Smith', rank: 'Platinum' },
              { name: 'Engr. Mike Doe', rank: 'Gold' },
              { name: 'Batangas Team', rank: 'Silver' },
            ].map((c, i) => (
              <div key={i} className="hf-contributor">
                <div className="hf-mini-avatar" style={{ opacity: 0.8, backgroundColor: '#444' }}>{c.name[0]}</div>
                <div>
                  <div className="hf-contrib-name">{c.name}</div>
                  <div className="hf-contrib-rank">{c.rank}</div>
                </div>
              </div>
            ))}
          </div>
        </aside>
      </main>
    </div>
  );
}
