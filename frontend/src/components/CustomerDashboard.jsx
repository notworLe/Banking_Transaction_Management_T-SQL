import { useState, useEffect } from 'react';
import { apiFetch, fmtMoney, fmtDate } from '../api.js';

function CustomerProfile() {
  const [profile, setProfile] = useState(null);
  useEffect(() => { apiFetch('/api/customer/profile').then(setProfile).catch(() => {}); }, []);
  if (!profile) return <div className="loading">LOADING...</div>;
  return (
    <div className="card">
      <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 20 }}>
        <div style={{ width: 64, height: 64, background: 'var(--black)', color: 'var(--yellow)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 28, border: '3px solid black', fontWeight: 800 }}>
          {profile.full_name?.[0]}
        </div>
        <div>
          <div style={{ fontSize: 22, fontWeight: 800 }}>{profile.full_name}</div>
          <div className="mono" style={{ fontSize: 13, color: '#555' }}>@{profile.username}</div>
          <span className={`badge badge-${profile.status}`}>{profile.status}</span>
        </div>
      </div>
      <div className="form-row">
        <div><div className="form-label">Email</div><div>{profile.email}</div></div>
        <div><div className="form-label">Số điện thoại</div><div className="mono">{profile.phone}</div></div>
      </div>
      <div style={{ marginTop: 12 }}><div className="form-label">Địa chỉ</div><div>{profile.address || '—'}</div></div>
      <div style={{ marginTop: 12 }}><div className="form-label">Ngày sinh</div><div className="mono">{profile.birthday ? profile.birthday.split('T')[0] : '—'}</div></div>
      <div style={{ marginTop: 12 }}><div className="form-label">Đăng nhập lần cuối</div><div className="mono">{fmtDate(profile.last_login)}</div></div>
    </div>
  );
}

function CustomerAccounts({ onSelect, selectedId }) {
  const [accounts, setAccounts] = useState([]);
  useEffect(() => { apiFetch('/api/customer/accounts').then(setAccounts).catch(() => {}); }, []);
  if (!accounts.length) return <div className="loading">LOADING ACCOUNTS...</div>;
  const typeColor = { payment: 'payment', saving: 'saving', debit: 'debit' };
  return (
    <div className="account-cards">
      {accounts.map(a => (
        <div key={a.account_id}
          className={`account-card ${typeColor[a.account_type] || 'white'} ${selectedId === a.account_id ? 'selected' : ''}`}
          onClick={() => onSelect && a.status === 'active' && onSelect(a)}>
          <div className="acc-type">{a.account_type} account</div>
          <div className="acc-number">{a.account_number.replace(/(\d{4})(?=\d)/g, '$1 ')}</div>
          <div className="acc-balance">{fmtMoney(a.balance)}</div>
          <div className="acc-balance-label">Số dư khả dụng</div>
          <div style={{ marginTop: 8 }}><span className={`badge badge-${a.status}`}>{a.status}</span></div>
        </div>
      ))}
    </div>
  );
}

function CustomerTransactions() {
  const [txns, setTxns] = useState([]);
  useEffect(() => { apiFetch('/api/customer/transactions').then(setTxns).catch(() => {}); }, []);
  return (
    <div className="table-wrapper">
      <div className="table-header"><h3>Lịch sử Giao dịch</h3></div>
      <table><thead><tr><th>Loại</th><th>Từ TK</th><th>Đến TK</th><th>Số tiền</th><th>Status</th><th>Mô tả</th><th>Thời gian</th></tr></thead>
        <tbody>
          {txns.map(t => (
            <tr key={t.id}>
              <td><span className={`badge badge-${t.type}`}>{t.type}</span></td>
              <td className="mono" style={{ fontSize: 11 }}>{t.from_account || '—'}</td>
              <td className="mono" style={{ fontSize: 11 }}>{t.to_account || '—'}</td>
              <td className="mono" style={{ fontWeight: 700 }}>{fmtMoney(t.amount)}</td>
              <td><span className={`badge badge-${t.status}`}>{t.status}</span></td>
              <td style={{ fontSize: 12 }}>{t.description || '—'}</td>
              <td className="mono" style={{ fontSize: 11 }}>{fmtDate(t.created_at)}</td>
            </tr>
          ))}
        </tbody>
      </table>
      {!txns.length && <div className="empty-state">Chưa có giao dịch</div>}
    </div>
  );
}

function CustomerTransfer({ toast }) {
  const [accounts, setAccounts] = useState([]);
  const [form, setForm] = useState({ from_account_id: '', to_account_number: '', amount: '', description: '' });
  const [loading, setLoading] = useState(false);
  useEffect(() => { apiFetch('/api/customer/accounts').then(setAccounts).catch(() => {}); }, []);
  const f = k => e => setForm(p => ({ ...p, [k]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault(); setLoading(true);
    try {
      await apiFetch('/api/customer/transactions/transfer', { method: 'POST', body: JSON.stringify({ ...form, amount: Number(form.amount) }) });
      toast.ok('Chuyển tiền thành công!');
      setForm({ from_account_id: '', to_account_number: '', amount: '', description: '' });
    } catch (e) { toast.err(e.message); }
    finally { setLoading(false); }
  };

  return (
    <div className="card">
      <div style={{ fontSize: 18, fontWeight: 800, marginBottom: 20 }}>💸 CHUYỂN TIỀN</div>
      <form onSubmit={submit}>
        <div className="form-group">
          <label className="form-label">Tài khoản nguồn</label>
          <select className="form-control" value={form.from_account_id} onChange={f('from_account_id')} required>
            <option value="">-- Chọn tài khoản --</option>
            {accounts.filter(a => a.status === 'active').map(a => (
              <option key={a.account_id} value={a.account_id}>{a.account_number} — {fmtMoney(a.balance)}</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Số tài khoản đích</label>
          <input className="form-control" value={form.to_account_number} onChange={f('to_account_number')} placeholder="Nhập số tài khoản..." required />
        </div>
        <div className="form-group">
          <label className="form-label">Số tiền (VND)</label>
          <input className="form-control" type="number" value={form.amount} onChange={f('amount')} min="1" placeholder="0" required />
        </div>
        <div className="form-group">
          <label className="form-label">Nội dung chuyển khoản</label>
          <input className="form-control" value={form.description} onChange={f('description')} placeholder="Nội dung..." />
        </div>
        <button type="submit" className="btn btn-primary" disabled={loading} style={{ width: '100%', justifyContent: 'center' }}>
          {loading ? 'ĐANG XỬ LÝ...' : 'CHUYỂN TIỀN →'}
        </button>
      </form>
    </div>
  );
}

function CustomerWithdrawDeposit({ toast }) {
  const [accounts, setAccounts] = useState([]);
  const [tab, setTab] = useState('withdraw');
  const [form, setForm] = useState({ account_id: '', amount: '', description: '' });
  const [loading, setLoading] = useState(false);
  useEffect(() => { apiFetch('/api/customer/accounts').then(setAccounts).catch(() => {}); }, []);
  const f = k => e => setForm(p => ({ ...p, [k]: e.target.value }));

  const submit = async (e) => {
    e.preventDefault(); setLoading(true);
    const path = tab === 'withdraw' ? '/api/customer/transactions/withdraw' : '/api/customer/transactions/deposit';
    try {
      await apiFetch(path, { method: 'POST', body: JSON.stringify({ ...form, amount: Number(form.amount) }) });
      toast.ok(tab === 'withdraw' ? 'Rút tiền thành công!' : 'Nạp tiền thành công!');
      setForm({ account_id: '', amount: '', description: '' });
    } catch (e) { toast.err(e.message); }
    finally { setLoading(false); }
  };

  return (
    <div className="card">
      <div style={{ display: 'flex', gap: 0, marginBottom: 20, border: '2px solid black' }}>
        {['withdraw', 'deposit'].map(t => (
          <button key={t} style={{ flex: 1, padding: '10px', fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13, textTransform: 'uppercase', cursor: 'pointer', border: 'none', borderRight: t === 'withdraw' ? '2px solid black' : 'none', background: tab === t ? 'var(--black)' : 'var(--white)', color: tab === t ? 'var(--yellow)' : 'black' }}
            onClick={() => setTab(t)}>
            {t === 'withdraw' ? '⬇ RÚT TIỀN' : '⬆ NẠP TIỀN'}
          </button>
        ))}
      </div>
      <form onSubmit={submit}>
        <div className="form-group">
          <label className="form-label">Tài khoản</label>
          <select className="form-control" value={form.account_id} onChange={f('account_id')} required>
            <option value="">-- Chọn tài khoản --</option>
            {accounts.filter(a => a.status === 'active').map(a => (
              <option key={a.account_id} value={a.account_id}>{a.account_number} — {fmtMoney(a.balance)}</option>
            ))}
          </select>
        </div>
        <div className="form-group">
          <label className="form-label">Số tiền (VND)</label>
          <input className="form-control" type="number" value={form.amount} onChange={f('amount')} min="1" placeholder="0" required />
        </div>
        <div className="form-group">
          <label className="form-label">Mô tả</label>
          <input className="form-control" value={form.description} onChange={f('description')} />
        </div>
        <button type="submit" className="btn btn-cyan" disabled={loading} style={{ width: '100%', justifyContent: 'center' }}>
          {loading ? 'ĐANG XỬ LÝ...' : (tab === 'withdraw' ? '⬇ RÚT TIỀN' : '⬆ NẠP TIỀN')}
        </button>
      </form>
    </div>
  );
}

export { CustomerProfile, CustomerAccounts, CustomerTransactions, CustomerTransfer, CustomerWithdrawDeposit };
