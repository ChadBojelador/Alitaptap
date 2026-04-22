import { useTheme } from '../ThemeContext';

const MoonIcon = () => (
  <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
    <path d="M21 12.79A9 9 0 1 1 11.21 3a7 7 0 0 0 9.79 9.79z"/>
  </svg>
);

const SunIcon = () => (
  <svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor">
    <circle cx="12" cy="12" r="5"/>
    <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42"
      stroke="currentColor" strokeWidth="2" strokeLinecap="round"/>
  </svg>
);

export default function ThemeToggle() {
  const { theme, toggle } = useTheme();
  return (
    <button className="ws2-theme-toggle" onClick={toggle} title="Toggle theme" aria-label="Toggle theme">
      <span className="ws2-theme-track">
        <span className="ws2-theme-thumb">
          {theme === 'dark' ? <MoonIcon /> : <SunIcon />}
        </span>
      </span>
    </button>
  );
}
