import React from 'react';

export default function DemoTimeline({ logs, loading }) {
  // Extract all unique SessionIds from logs
  const sessionIdsSet = new Set();
  logs.forEach(log => {
    if (log.SessionId) {
      sessionIdsSet.add(String(log.SessionId));
    }
  });
  const sessionIds = Array.from(sessionIdsSet).sort((a, b) => a.localeCompare(b));

  // Sort all logs chronologically (by ActionTime, then LogId as a tie-breaker)
  const sortedLogs = [...logs].sort((a, b) => {
    const t1 = a.ActionTime ? new Date(a.ActionTime).getTime() : 0;
    const t2 = b.ActionTime ? new Date(b.ActionTime).getTime() : 0;
    if (t1 !== t2) {
      return t1 - t2;
    }
    return (a.LogId || 0) - (b.LogId || 0);
  });

  if (!logs.length) {
    return (
      <div className="table-wrapper" style={{ marginTop: '24px' }}>
        <div className="table-header">
          <h3>Nhật ký thực thi (Timeline Logs)</h3>
        </div>
        <div className="empty-state">
          Chưa có nhật ký hoạt động. Vui lòng bấm Reset hoặc Run.
        </div>
      </div>
    );
  }

  return (
    <div style={{ marginTop: '24px' }}>
      <div className="table-header" style={{ marginBottom: '16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ margin: 0 }}>Bản đồ tiến trình giao dịch (Chronological Execution Grid)</h3>
        {loading && <span style={{ fontFamily: 'var(--font-mono)', fontSize: '11px', color: 'var(--magenta)' }}>Đang tải...</span>}
      </div>

      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: `repeat(${sessionIds.length}, 1fr)`, 
        gap: '16px 24px',
        alignItems: 'stretch'
      }}>
        {/* Column Headers */}
        {sessionIds.map(sid => (
          <div 
            key={sid} 
            style={{ 
              fontFamily: 'var(--font-mono)', 
              fontSize: '13px', 
              fontWeight: '800', 
              border: 'var(--border)', 
              background: 'var(--black)', 
              color: 'var(--yellow)',
              padding: '10px',
              textAlign: 'center',
              boxShadow: '3px 3px 0px var(--black)'
            }}
          >
            🔌 Session ID: {sid}
          </div>
        ))}

        {/* Chronological Steps */}
        {sortedLogs.map((log, index) => {
          const isError = log.Message?.toUpperCase().includes('ERROR') || log.Action?.toUpperCase().includes('ERROR');
          const isReset = log.Action === 'RESET';
          const isLimitPass = log.Message?.includes('Limit check PASSED') || log.Message?.includes('Limit check FAILED') || log.Message?.includes('baseline');
          const badgeColor = isReset ? 'badge-active' : isError ? 'badge-failed' : isLimitPass ? 'badge-success' : 'badge-pending';

          return (
            <React.Fragment key={log.LogId || index}>
              {sessionIds.map(sid => {
                const match = String(log.SessionId) === String(sid);
                return (
                  <div key={sid} style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                    {match ? (
                      <div 
                        className="card" 
                        style={{ 
                          margin: 0, 
                          borderColor: isError ? 'var(--magenta)' : 'var(--black)',
                          boxShadow: isError ? '3px 3px 0px var(--magenta)' : '3px 3px 0px var(--black)',
                          background: isError ? '#fff0f3' : 'var(--white)',
                          padding: '14px',
                          width: '100%'
                        }}
                      >
                        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '6px' }}>
                          <span className={`badge ${badgeColor}`} style={{ fontSize: '9px', textTransform: 'uppercase' }}>
                            {log.Action || 'LOG'}
                          </span>
                          <span className="mono" style={{ fontSize: '10px', color: '#666' }}>
                            {log.ActionTime ? new Date(log.ActionTime).toLocaleTimeString('vi-VN') : '—'}
                          </span>
                        </div>
                        
                        {log.Actor && (
                          <div style={{ fontSize: '11px', fontFamily: 'var(--font-mono)', color: '#666', marginBottom: '4px', fontWeight: 'bold' }}>
                            👤 {log.Actor}
                          </div>
                        )}
                        
                        <div style={{ fontSize: '13px', fontWeight: '600', whiteSpace: 'pre-line', lineHeight: '1.4' }}>
                          {log.Message}
                        </div>
                      </div>
                    ) : (
                      // Visual vertical connector lines for idle/waiting columns
                      <div style={{ 
                        display: 'flex', 
                        justifyContent: 'center', 
                        alignItems: 'center', 
                        height: '100%', 
                        minHeight: '60px' 
                      }}>
                        <div style={{ 
                          width: '2px', 
                          height: '100%', 
                          borderLeft: '2px dashed #ccc', 
                          opacity: 0.4
                        }}></div>
                      </div>
                    )}
                  </div>
                );
              })}
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}
