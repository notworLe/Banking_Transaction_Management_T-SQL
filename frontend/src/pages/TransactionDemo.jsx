import React, { useState, useEffect, useRef } from 'react';
import { apiFetch } from '../api.js';
import AnomalySelector from '../components/demo/AnomalySelector.jsx';
import AnomalyInfo from '../components/demo/AnomalyInfo.jsx';
import DemoControls from '../components/demo/DemoControls.jsx';
import DemoTimeline from '../components/demo/DemoTimeline.jsx';

export default function TransactionDemo({ toast }) {
  const [anomalies, setAnomalies] = useState({});
  const [selectedKey, setSelectedKey] = useState(null);
  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(false);
  const [loadingAnomalies, setLoadingAnomalies] = useState(true);
  
  // Keep track of polling interval
  const pollIntervalRef = useRef(null);

  // Load anomalies list from API on mount
  useEffect(() => {
    apiFetch('/api/demo/anomalies')
      .then(data => {
        setAnomalies(data);
        const keys = Object.keys(data);
        if (keys.length > 0) {
          setSelectedKey(keys[0]);
        }
        setLoadingAnomalies(false);
      })
      .catch(err => {
        toast.err(`Không thể tải cấu hình anomalies: ${err.message}`);
        setLoadingAnomalies(false);
      });
  }, []);

  // Fetch logs function
  const fetchLogs = (key) => {
    if (!key) return;
    apiFetch(`/api/demo/${key}/logs`)
      .then(setLogs)
      .catch(err => {
        console.error(`Lỗi tải logs: ${err.message}`);
      });
  };

  // Start polling when selectedKey changes
  useEffect(() => {
    if (pollIntervalRef.current) {
      clearInterval(pollIntervalRef.current);
    }

    if (selectedKey) {
      // Fetch immediately first
      fetchLogs(selectedKey);

      // Start interval
      pollIntervalRef.current = setInterval(() => {
        fetchLogs(selectedKey);
      }, 2000);
    }

    return () => {
      if (pollIntervalRef.current) {
        clearInterval(pollIntervalRef.current);
      }
    };
  }, [selectedKey]);

  // Handle Controls
  const handleReset = async () => {
    if (!selectedKey) return;
    setLoading(true);
    try {
      await apiFetch(`/api/demo/${selectedKey}/reset`, { method: 'POST' });
      toast.ok('Reset database demo thành công!');
      fetchLogs(selectedKey);
    } catch (err) {
      toast.err(`Reset lỗi: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleRun = async (type) => {
    if (!selectedKey) return;
    setLoading(true);
    try {
      await apiFetch(`/api/demo/${selectedKey}/run`, {
        method: 'POST',
        body: JSON.stringify({ type })
      });
      toast.ok(`Chạy demo (${type}) hoàn tất!`);
      fetchLogs(selectedKey);
    } catch (err) {
      toast.err(`Chạy demo lỗi: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  if (loadingAnomalies) {
    return <div className="loading">ĐANG TẢI THÔNG TIN DEMO...</div>;
  }

  const selectedAnomaly = selectedKey ? anomalies[selectedKey] : null;

  return (
    <div style={{ display: 'grid', gridTemplateColumns: '280px 1fr', gap: '24px' }}>
      {/* Cột trái */}
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <div className="card" style={{ padding: '20px', background: 'var(--white)' }}>
          <AnomalySelector
            anomalies={anomalies}
            selectedKey={selectedKey}
            onSelect={setSelectedKey}
          />
        </div>
      </div>

      {/* Cột phải */}
      <div style={{ display: 'flex', flexDirection: 'column' }}>
        <AnomalyInfo anomaly={selectedAnomaly} />
        
        <DemoControls
          onReset={handleReset}
          onRunBad={() => handleRun('bad')}
          onRunFix={() => handleRun('fix')}
          loading={loading}
        />

        <DemoTimeline logs={logs} loading={loading} />
      </div>
    </div>
  );
}
