import React from 'react';

export default function DemoControls({ onReset, onRunBad, onRunFix, loading }) {
  return (
    <div className="card" style={{ background: 'var(--white)', border: 'var(--border)', boxShadow: 'var(--shadow)', padding: '20px', marginBottom: '24px' }}>
      <div className="nav-section-label" style={{ paddingLeft: 0, marginBottom: 12, color: 'var(--black)' }}>
        BẢNG ĐIỀU KHIỂN (CONTROLS)
      </div>
      <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
        <button
          className="btn btn-secondary"
          onClick={onReset}
          disabled={loading}
          style={{ flex: 1, minWidth: '120px' }}
        >
          🔄 RESET
        </button>
        <button
          className="btn btn-magenta"
          onClick={onRunBad}
          disabled={loading}
          style={{ flex: 1, minWidth: '120px', color: 'white' }}
        >
          🚨 RUN BAD
        </button>
        <button
          className="btn btn-cyan"
          onClick={onRunFix}
          disabled={loading}
          style={{ flex: 1, minWidth: '120px' }}
        >
          ✅ RUN FIX
        </button>
      </div>
      {loading && (
        <div style={{ marginTop: '14px', fontFamily: 'var(--font-mono)', fontSize: '12px', color: 'var(--magenta)', fontWeight: '700', animation: 'pulse 1s infinite' }}>
          ⏳ ĐANG THỰC THI stored procedure trong SQL Server... Vui lòng đợi.
        </div>
      )}
    </div>
  );
}
