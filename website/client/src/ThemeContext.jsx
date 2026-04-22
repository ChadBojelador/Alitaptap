import { createContext, useContext, useEffect, useState } from 'react';

const ThemeContext = createContext();

export function ThemeProvider({ children }) {
  const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'dark');
  const [sidebarExpanded, setSidebarExpanded] = useState(() => localStorage.getItem('sidebarExpanded') === 'true');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme === 'light' ? 'light' : '');
    localStorage.setItem('theme', theme);
  }, [theme]);

  useEffect(() => {
    localStorage.setItem('sidebarExpanded', sidebarExpanded.toString());
  }, [sidebarExpanded]);

  const toggle = () => setTheme(t => t === 'dark' ? 'light' : 'dark');

  const toggleSidebar = () => setSidebarExpanded(e => !e);

  return (
    <ThemeContext.Provider value={{ theme, toggle, sidebarExpanded, toggleSidebar }}>
      {children}
    </ThemeContext.Provider>
  );
}

export const useTheme = () => useContext(ThemeContext);
