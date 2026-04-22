import React, { useEffect } from 'react';

export default function Toast({ message, type = 'error', onClose }) {
  useEffect(() => {
    const t = setTimeout(onClose, 3500);
    return () => clearTimeout(t);
  }, [onClose]);

  const colors = {
    error:   { bg: 'rgba(239,68,68,0.15)',   border: 'rgba(239,68,68,0.4)',   text: '#f87171' },
    success: { bg: 'rgba(16,185,129,0.15)',  border: 'rgba(16,185,129,0.4)',  text: '#34d399' },
    info:    { bg: 'rgba(99,102,241,0.15)',  border: 'rgba(99,102,241,0.4)',  text: '#a78bfa' },
  };
  const c = colors[type] || colors.error;

  return (
    <div style={{
      position: 'fixed', bottom: 24, right: 24, zIndex: 9999,
      background: c.bg, border: `1px solid ${c.border}`,
      borderRadius: 12, padding: '12px 18px',
      display: 'flex', alignItems: 'center', gap: 12,
      backdropFilter: 'blur(12px)', boxShadow: '0 4px 24px rgba(0,0,0,0.4)',
      maxWidth: 360, animation: 'toast-in 0.25s ease',
    }}>
      <span style={{ color: c.text, fontSize: '0.9rem', lineHeight: 1.5, flex: 1 }}>{message}</span>
      <button onClick={onClose} style={{
        background: 'none', border: 'none', color: c.text,
        cursor: 'pointer', fontSize: '1rem', padding: 0, lineHeight: 1
      }}>✕</button>
      <style>{`@keyframes toast-in { from { opacity:0; transform:translateY(12px); } to { opacity:1; transform:translateY(0); } }`}</style>
    </div>
  );
}
