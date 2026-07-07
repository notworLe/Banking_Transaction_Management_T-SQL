import { useState, useEffect } from 'react';
import { apiFetch, fmtMoney, fmtDate } from '../api.js';

function useToast() {
  const [toasts, setToasts] = useState([]);
  const add = (msg, type = 'success') => {
    const id = Date.now();
    setToasts(t => [...t, { id, msg, type }]);
    setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 3500);
  };
  return { toasts, ok: msg => add(msg, 'success'), err: msg => add(msg, 'error') };
}

function Toast({ toasts }) {
  return (
    <div className="toast">
      {toasts.map(t => (
        <div key={t.id} className={`toast-item toast-${t.type}`}>{t.msg}</div>
      ))}
    </div>
  );
}

function Modal({ title, open, onClose, children }) {
  if (!open) return null;
  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h3>{title}</h3>
          <button className="modal-close" onClick={onClose}>✕</button>
        </div>
        {children}
      </div>
    </div>
  );
}

/* ─────── ADMIN DASHBOARD ─────── */
function AdminStats() {
  const [stats, setStats] = useState(null);
  useEffect(() => { apiFetch('/api/admin/stats').then(setStats).catch(() => {}); }, []);
  if (!stats) return <div className="loading">LOADING STATS...</div>;
  return (
    <div className="stats-grid">
      <div className="stat-card yellow"><div className="stat-label">Tổng Users</div><div className="stat-value">{stats.total_users}</div></div>
      <div className="stat-card cyan"><div className="stat-label">Bankers</div><div className="stat-value">{stats.total_bankers}</div></div>
      <div className="stat-card magenta"><div className="stat-label">Customers</div><div className="stat-value">{stats.total_customers}</div></div>
      <div className="stat-card purple"><div className="stat-label">Giao dịch</div><div className="stat-value">{stats.total_transactions}</div></div>
      <div className="stat-card white" style={{ gridColumn: 'span 1' }}>
        <div className="stat-label">Tổng nạp</div>
        <div className="stat-value" style={{ fontSize: 20 }}>{fmtMoney(stats.total_deposit)}</div>
      </div>
    </div>
  );
}

function AdminUsers({ toast }) {
  const [users, setUsers] = useState([]);
  const load = () => apiFetch('/api/admin/users').then(setUsers).catch(() => {});
  useEffect(() => { load(); }, []);
  const toggle = async (u) => {
    const ns = u.status === 'active' ? 'locked' : 'active';
    try {
      await apiFetch(`/api/admin/users/${u.user_id}/status`, { method: 'PATCH', body: JSON.stringify({ status: ns }) });
      toast.ok(`Đã ${ns === 'locked' ? 'khóa' : 'mở'} tài khoản ${u.username}`);
      load();
    } catch (e) { toast.err(e.message); }
  };
  return (
    <div className="table-wrapper">
      <div className="table-header"><h3>Danh sách Users</h3></div>
      <table><thead><tr><th>Username</th><th>Role</th><th>Status</th><th>Last Login</th><th>Ngày tạo</th><th></th></tr></thead>
        <tbody>
          {users.map(u => (
            <tr key={u.user_id}>
              <td className="mono">{u.username}</td>
              <td><span className={`badge badge-${u.role}`}>{u.role}</span></td>
              <td><span className={`badge badge-${u.status}`}>{u.status}</span></td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(u.last_login)}</td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(u.created_at)}</td>
              <td>
                <button className={`btn btn-sm ${u.status === 'active' ? 'btn-magenta' : 'btn-cyan'}`}
                  onClick={() => toggle(u)}>
                  {u.status === 'active' ? 'KHÓA' : 'MỞ'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {!users.length && <div className="empty-state">Không có dữ liệu</div>}
    </div>
  );
}

function AdminBankers({ toast }) {
  const [bankers, setBankers] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ username: '', password: '', full_name: '', email: '', phone: '', employee_code: '' });
  const load = () => apiFetch('/api/admin/bankers').then(setBankers).catch(() => {});
  useEffect(() => { load(); }, []);

  const toggleStatus = async (b) => {
    const ns = b.status === 'active' ? 'locked' : 'active';
    try {
      await apiFetch(`/api/admin/users/${b.user_id}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status: ns })
      });
      toast.ok(`Đã ${ns === 'locked' ? 'khóa' : 'mở khóa'} banker ${b.username}`);
      load();
    } catch (e) { toast.err(e.message); }
  };

  const submit = async (e) => {
    e.preventDefault();
    try {
      await apiFetch('/api/admin/bankers', { method: 'POST', body: JSON.stringify(form) });
      toast.ok('Tạo Banker thành công!'); setModal(false);
      setForm({ username: '', password: '', full_name: '', email: '', phone: '', employee_code: '' });
      load();
    } catch (e) { toast.err(e.message); }
  };
  const f = (k) => e => setForm(p => ({ ...p, [k]: e.target.value }));
  return (
    <>
      <div className="table-wrapper">
        <div className="table-header">
          <h3>Danh sách Bankers</h3>
          <button className="btn btn-primary btn-sm" onClick={() => setModal(true)}>+ TẠO BANKER</button>
        </div>
        <table><thead><tr><th>Mã NV</th><th>Họ tên</th><th>Username</th><th>Email</th><th>SĐT</th><th>Status</th><th></th></tr></thead>
          <tbody>
            {bankers.map(b => (
              <tr key={b.banker_id}>
                <td className="mono">{b.employee_code}</td>
                <td style={{ fontWeight: 600 }}>{b.full_name}</td>
                <td className="mono">{b.username}</td>
                <td>{b.email}</td>
                <td className="mono">{b.phone}</td>
                <td><span className={`badge badge-${b.status}`}>{b.status}</span></td>
                <td>
                  <button
                    className={`btn btn-sm ${b.status === 'active' ? 'btn-magenta' : 'btn-cyan'}`}
                    onClick={() => toggleStatus(b)}
                  >
                    {b.status === 'active' ? 'KHÓA' : 'MỞ KHÓA'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!bankers.length && <div className="empty-state">Chưa có banker</div>}
      </div>
      <Modal title="TẠO BANKER MỚI" open={modal} onClose={() => setModal(false)}>
        <form onSubmit={submit}>
          <div className="modal-body">
            <div className="form-row">
              <div className="form-group"><label className="form-label">Mã NV</label><input className="form-control" value={form.employee_code} onChange={f('employee_code')} required /></div>
              <div className="form-group"><label className="form-label">Họ tên</label><input className="form-control" value={form.full_name} onChange={f('full_name')} required /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label className="form-label">Username</label><input className="form-control" value={form.username} onChange={f('username')} required /></div>
              <div className="form-group"><label className="form-label">Password</label><input className="form-control" type="password" value={form.password} onChange={f('password')} required /></div>
            </div>
            <div className="form-row">
              <div className="form-group"><label className="form-label">Email</label><input className="form-control" type="email" value={form.email} onChange={f('email')} required /></div>
              <div className="form-group"><label className="form-label">SĐT</label><input className="form-control" value={form.phone} onChange={f('phone')} required /></div>
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={() => setModal(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">TẠO BANKER</button>
          </div>
        </form>
      </Modal>
    </>
  );
}


function AdminAuditLogs() {
  const [logs, setLogs] = useState([]);
  useEffect(() => { apiFetch('/api/admin/audit-logs').then(setLogs).catch(() => {}); }, []);
  return (
    <div className="table-wrapper">
      <div className="table-header"><h3>Audit Logs</h3></div>
      <table><thead><tr><th>User</th><th>Action</th><th>Target</th><th>Mô tả</th><th>Thời gian</th></tr></thead>
        <tbody>
          {logs.map(l => (
            <tr key={l.id}>
              <td className="mono">{l.username}</td>
              <td><span className="badge badge-Admin" style={{ fontSize: 10 }}>{l.action}</span></td>
              <td className="mono" style={{ fontSize: 11 }}>{l.target_table}</td>
              <td style={{ fontSize: 12 }}>{l.description}</td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(l.created_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {!logs.length && <div className="empty-state">Không có log</div>}
    </div>
  );
}

function AdminLoginLogs() {
  const [logs, setLogs] = useState([]);
  useEffect(() => { apiFetch('/api/admin/login-logs').then(setLogs).catch(() => {}); }, []);
  return (
    <div className="table-wrapper">
      <div className="table-header"><h3>Login Logs</h3></div>
      <table><thead><tr><th>Username</th><th>Đăng nhập</th><th>Đăng xuất</th><th>Status</th><th>IP</th></tr></thead>
        <tbody>
          {logs.map(l => (
            <tr key={l.id}>
              <td className="mono">{l.username}</td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(l.login_time)}</td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(l.logout_time)}</td>
              <td><span className={`badge badge-${l.status}`}>{l.status}</span></td>
              <td className="mono" style={{ fontSize: 11 }}>{l.ip || '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {!logs.length && <div className="empty-state">Không có log</div>}
    </div>
  );
}

export { AdminStats, AdminUsers, AdminBankers, AdminAuditLogs, AdminLoginLogs, Modal, Toast, useToast };
