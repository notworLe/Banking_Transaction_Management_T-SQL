import React from 'react';

export default function AnomalyInfo({ anomaly }) {
  if (!anomaly) return <div className="empty-state">Chọn một anomaly để xem chi tiết</div>;

  return (
    <div className="card" style={{ background: 'var(--white)', border: 'var(--border)', boxShadow: 'var(--shadow)', padding: '24px', marginBottom: '24px' }}>
      <h3 style={{ fontSize: '24px', fontWeight: '800', marginBottom: '16px', borderBottom: '2px solid var(--black)', paddingBottom: '8px' }}>
        {anomaly.displayName}
      </h3>
      
      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        <div>
          <h4 style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', fontWeight: '700', textTransform: 'uppercase', color: '#555', marginBottom: '4px' }}>
            Mô tả lỗi (Description)
          </h4>
          <p style={{ fontSize: '14px', lineHeight: '1.5', fontWeight: '500' }}>{anomaly.description}</p>
        </div>
        
        <div>
          <h4 style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', fontWeight: '700', textTransform: 'uppercase', color: '#555', marginBottom: '4px' }}>
            Kịch bản mô phỏng (Scenario)
          </h4>
          <p style={{ fontSize: '14px', lineHeight: '1.5', whiteSpace: 'pre-line', fontWeight: '500' }}>{anomaly.scenario}</p>
        </div>
        
        <div>
          <h4 style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', fontWeight: '700', textTransform: 'uppercase', color: '#555', marginBottom: '4px' }}>
            Kết quả mong đợi (Expected Result)
          </h4>
          <p style={{ fontSize: '14px', lineHeight: '1.5', fontWeight: '500' }}>{anomaly.expected_result}</p>
        </div>
        
        <div className="alert alert-info" style={{ margin: '8px 0 0 0', display: 'block', padding: '16px' }}>
          <h4 style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', fontWeight: '700', textTransform: 'uppercase', color: 'var(--black)', marginBottom: '4px' }}>
            Bài học kinh nghiệm (Learning)
          </h4>
          <p style={{ fontSize: '14px', lineHeight: '1.5', fontWeight: '600' }}>{anomaly.learning}</p>
        </div>
      </div>
    </div>
  );
}
