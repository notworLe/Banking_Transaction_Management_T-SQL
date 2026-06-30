import React from 'react';

export default function AnomalySelector({ anomalies, selectedKey, onSelect }) {
  return (
    <div className="anomaly-selector">
      <div className="nav-section-label" style={{ paddingLeft: 0, marginBottom: 12, color: 'var(--black)' }}>
        DANH SÁCH ANOMALIES
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {Object.entries(anomalies).map(([key, anomaly]) => (
          <button
            key={key}
            onClick={() => onSelect(key)}
            className={`btn ${selectedKey === key ? 'btn-primary' : 'btn-secondary'}`}
            style={{
              justifyContent: 'flex-start',
              textAlign: 'left',
              width: '100%',
              fontSize: '14px',
              fontFamily: 'var(--font-body)',
              padding: '12px 16px'
            }}
          >
            <span>🧪</span> {anomaly.displayName}
          </button>
        ))}
      </div>
    </div>
  );
}
