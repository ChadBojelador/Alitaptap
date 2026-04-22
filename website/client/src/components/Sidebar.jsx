import { useEffect, useState } from 'react';
import { FaFileAlt, FaTrash, FaUserTag, FaSignOutAlt, FaComments, FaPlus, FaBars, FaTimes, FaChevronRight, FaChevronLeft } from 'react-icons/fa';
import { Link, useLocation } from 'react-router-dom';
import axios from 'axios';
import logo from '../images/logo.png';
import darkLogo from '../images/darkmode-logo.png';
import { useTheme } from '../ThemeContext';

const { hostname, port } = window.location;
const BACKEND_URL = port === '5173' ? `http://${hostname}:3000` : window.location.origin;

// Mobile drawer state
const listeners = new Set();
let _open = false;
function setOpen(val) {
  _open = val;
  listeners.forEach(fn => fn(val));
}

export default function Sidebar() {
  const { pathname } = useLocation();
  const [open, setLocalOpen] = useState(false);
  const { theme, sidebarExpanded, toggleSidebar } = useTheme();
  const currentLogo = theme === 'light' ? logo : darkLogo;
  const isExpanded = sidebarExpanded;

  useEffect(() => {
    const fn = (val) => setLocalOpen(val);
    listeners.add(fn);
    return () => listeners.delete(fn);
  }, []);

  const close = () => setOpen(false);

  const handleSignOut = async () => {
    await axios.get(`${BACKEND_URL}/logout`, { withCredentials: true });
    localStorage.removeItem('token');
    window.location.href = '/';
  };

  const links = [
    { to: '/draft',             icon: <FaPlus size={20} />,     label: 'New' },
    { to: '/dashboard',         icon: <FaFileAlt size={20} />,  label: 'Docs' },
    { to: '/dashboard/chat',    icon: <FaComments size={20} />, label: 'Chat' },
    { to: '/dashboard/persona', icon: <FaUserTag size={20} />,  label: 'Persona' },
  ];

  const bottomLinks = [
    { to: '/dashboard/trash', icon: <FaTrash size={20} />, label: 'Trash' },
  ];

  return (
    <>
      {/* Desktop sidebar */}
      <aside
        className={`ws2-sidebar ws2-sidebar--desktop${isExpanded ? ' ws2-sidebar--expanded' : ''}${sidebarExpanded ? ' ws2-sidebar--pinned' : ''}`}
      >
        <div className="ws2-sidebar-top">
          <Link to="/dashboard" className="ws2-sidebar-logo">
            <img src={currentLogo} alt="Alitaptap" />
            <div className={`ws2-sidebar-copy${isExpanded ? ' ws2-sidebar-copy--visible' : ''}`}>
              <span className="ws2-sidebar-brand">Alitaptap</span>
              <span className="ws2-sidebar-subtitle">Workspace</span>
            </div>
          </Link>
          <button
            className="ws2-sidebar-toggle"
            onClick={toggleSidebar}
            title={sidebarExpanded ? 'Collapse sidebar' : 'Pin sidebar open'}
          >
            {sidebarExpanded ? <FaChevronLeft size={12} /> : <FaChevronRight size={12} />}
          </button>
        </div>
        <div className="ws2-sidebar-nav">
          {links.map(l => (
            <Link
              key={l.to}
              to={l.to}
              className={`ws2-sidebar-icon${pathname === l.to ? ' ws2-sidebar-icon--active' : ''}`}
              data-tooltip={l.label}
            >
              <span className="ws2-sidebar-icon-glyph">{l.icon}</span>
              <span className={`ws2-sidebar-label${isExpanded ? ' ws2-sidebar-label--visible' : ''}`}>{l.label}</span>
            </Link>
          ))}
        </div>
        <div className="ws2-sidebar-bottom">
          {bottomLinks.map(l => (
            <Link
              key={l.to}
              to={l.to}
              className={`ws2-sidebar-icon${pathname === l.to ? ' ws2-sidebar-icon--active' : ''}`}
              data-tooltip={l.label}
            >
              <span className="ws2-sidebar-icon-glyph">{l.icon}</span>
              <span className={`ws2-sidebar-label${isExpanded ? ' ws2-sidebar-label--visible' : ''}`}>{l.label}</span>
            </Link>
          ))}
          <button
            type="button"
            className="ws2-sidebar-icon ws2-sidebar-action"
            data-tooltip="Sign Out"
            onClick={handleSignOut}
          >
            <span className="ws2-sidebar-icon-glyph"><FaSignOutAlt size={20} /></span>
            <span className={`ws2-sidebar-label${isExpanded ? ' ws2-sidebar-label--visible' : ''}`}>Sign Out</span>
          </button>
        </div>
      </aside>

      {/* Mobile hamburger button — only visible on mobile via CSS */}
      <button className="ws2-mobile-fab" onClick={() => setOpen(true)} title="Menu">
        <FaBars size={20} />
      </button>

      {/* Mobile drawer */}
      {open && <div className="ws2-drawer-overlay" onClick={close} />}
      <nav className={`ws2-drawer${open ? ' ws2-drawer--open' : ''}`}>
        <button className="ws2-drawer-close" onClick={close}><FaTimes size={20} /></button>
        {[...links, ...bottomLinks].map(l => (
          <Link key={l.to} to={l.to} className={`ws2-drawer-item${pathname === l.to ? ' ws2-drawer-item--active' : ''}`} onClick={close}>
            {l.icon} <span>{l.label}</span>
          </Link>
        ))}
        <button className="ws2-drawer-item ws2-drawer-signout" onClick={handleSignOut}>
          <FaSignOutAlt size={20} /> <span>Sign Out</span>
        </button>
      </nav>
    </>
  );
}
