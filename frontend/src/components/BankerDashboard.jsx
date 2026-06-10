import { useState, useEffect } from 'react';
import { apiFetch, fmtMoney, fmtDate } from '../api.js';
import { Modal } from './AdminDashboard.jsx';

function BankerCustomers({ toast }) {
  const [customers, setCustomers] = useState([]);
  const [detail, setDetail] = useState(null);
  const [search, setSearch] = useState('');
  const load = () => apiFetch('/api/banker/customers').then(setCustomers).catch(() => {});
  useEffect(() => { load(); }, []);

  const filtered = customers.filter(c =>
    c.full_name.toLowerCase().includes(search.toLowerCase()) ||
    c.phone.includes(search) || c.username.toLowerCase().includes(search.toLowerCase())
  );

  const viewDetail = async (id) => {
    try { setDetail(await apiFetch(`/api/banker/customers/${id}`)); }
    catch (e) { toast.err(e.message); }
  };

  return (
    <>
      <div className="search-bar">
        <input className="search-input" value={search} onChange={e => setSearch(e.target.value)} placeholder="Tìm kiếm tên, SĐT, username..." />
        <button className="search-btn">🔍</button>
      </div>
      <div className="table-wrapper">
        <div className="table-header"><h3>Danh sách Khách hàng</h3></div>
        <table><thead><tr><th>Họ tên</th><th>Username</th><th>Email</th><th>SĐT</th><th>Status</th><th></th></tr></thead>
          <tbody>
            {filtered.map(c => (
              <tr key={c.customer_id}>
                <td style={{ fontWeight: 600 }}>{c.full_name}</td>
                <td className="mono">{c.username}</td>
                <td>{c.email}</td>
                <td className="mono">{c.phone}</td>
                <td><span className={`badge badge-${c.status}`}>{c.status}</span></td>
                <td><button className="btn btn-secondary btn-sm" onClick={() => viewDetail(c.customer_id)}>CHI TIẾT</button></td>
              </tr>
            ))}
          </tbody>
        </table>
        {!filtered.length && <div className="empty-state">Không tìm thấy</div>}
      </div>
      <Modal title="CHI TIẾT KHÁCH HÀNG" open={!!detail} onClose={() => setDetail(null)}>
        {detail && (
          <>
            <div className="modal-body">
              <div className="form-row" style={{ marginBottom: 12 }}>
                <div><div className="form-label">Họ tên</div><b>{detail.full_name}</b></div>
                <div><div className="form-label">Username</div><span className="mono">{detail.username}</span></div>
              </div>
              <div className="form-row" style={{ marginBottom: 12 }}>
                <div><div className="form-label">Email</div>{detail.email}</div>
                <div><div className="form-label">SĐT</div><span className="mono">{detail.phone}</span></div>
              </div>
              <div><div className="form-label">Địa chỉ</div>{detail.address || '—'}</div>
              <hr className="divider" />
              <div className="form-label">Tài khoản ngân hàng ({detail.accounts?.length})</div>
              {detail.accounts?.map(a => (
                <div key={a.account_id} style={{ background: 'white', border: '2px solid black', padding: 12, marginTop: 8 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <span className="mono" style={{ fontWeight: 700 }}>{a.account_number}</span>
                    <span className={`badge badge-${a.status}`}>{a.status}</span>
                  </div>
                  <div style={{ fontSize: 12, color: '#555', marginTop: 4 }}>{a.account_type.toUpperCase()}</div>
                  <div style={{ fontSize: 20, fontWeight: 800, marginTop: 4 }}>{fmtMoney(a.balance)}</div>
                </div>
              ))}
            </div>
            <div className="modal-footer">
              <button className="btn btn-secondary" onClick={() => setDetail(null)}>Đóng</button>
            </div>
          </>
        )}
      </Modal>
    </>
  );
}

function BankerAccounts({ toast }) {
  const [accounts, setAccounts] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ customer_id: '', account_type: 'payment', account_number: '', initial_balance: 0 });
  const load = () => apiFetch('/api/banker/accounts').then(setAccounts).catch(() => {});
  useEffect(() => {
    load();
    apiFetch('/api/banker/customers').then(setCustomers).catch(() => {});
  }, []);

  const updateStatus = async (id, status) => {
    try {
      await apiFetch(`/api/banker/accounts/${id}/status`, { method: 'PATCH', body: JSON.stringify({ status }) });
      toast.ok(`Cập nhật trạng thái thành ${status}`); load();
    } catch (e) { toast.err(e.message); }
  };

  const submit = async (e) => {
    e.preventDefault();
    try {
      await apiFetch('/api/banker/accounts', { method: 'POST', body: JSON.stringify({ ...form, initial_balance: Number(form.initial_balance) }) });
      toast.ok('Tạo tài khoản thành công!'); setModal(false); load();
    } catch (e) { toast.err(e.message); }
  };
  const f = k => e => setForm(p => ({ ...p, [k]: e.target.value }));

  return (
    <>
      <div className="table-wrapper">
        <div className="table-header">
          <h3>Quản lý Tài khoản</h3>
          <button className="btn btn-primary btn-sm" onClick={() => setModal(true)}>+ TẠO TÀI KHOẢN</button>
        </div>
        <table><thead><tr><th>Số TK</th><th>Loại</th><th>Số dư</th><th>Chủ TK</th><th>Status</th><th></th></tr></thead>
          <tbody>
            {accounts.map(a => (
              <tr key={a.account_id}>
                <td className="mono">{a.account_number}</td>
                <td><span className={`badge badge-${a.account_type}`}>{a.account_type}</span></td>
                <td className="mono amount-positive">{fmtMoney(a.balance)}</td>
                <td style={{ fontWeight: 600 }}>{a.owner}</td>
                <td><span className={`badge badge-${a.status}`}>{a.status}</span></td>
                <td style={{ display: 'flex', gap: 4 }}>
                  {a.status === 'active'
                    ? <button className="btn btn-sm btn-magenta" onClick={() => updateStatus(a.account_id, 'locked')}>KHÓA</button>
                    : <button className="btn btn-sm btn-cyan" onClick={() => updateStatus(a.account_id, 'active')}>MỞ</button>}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {!accounts.length && <div className="empty-state">Không có tài khoản</div>}
      </div>
      <Modal title="TẠO TÀI KHOẢN MỚI" open={modal} onClose={() => setModal(false)}>
        <form onSubmit={submit}>
          <div className="modal-body">
            <div className="form-group">
              <label className="form-label">Khách hàng</label>
              <select className="form-control" value={form.customer_id} onChange={f('customer_id')} required>
                <option value="">-- Chọn KH --</option>
                {customers.map(c => <option key={c.customer_id} value={c.customer_id}>{c.full_name} ({c.username})</option>)}
              </select>
            </div>
            <div className="form-row">
              <div className="form-group">
                <label className="form-label">Loại TK</label>
                <select className="form-control" value={form.account_type} onChange={f('account_type')}>
                  <option value="payment">Payment</option>
                  <option value="saving">Saving</option>
                  <option value="debit">Debit</option>
                </select>
              </div>
              <div className="form-group">
                <label className="form-label">Số TK</label>
                <input className="form-control" value={form.account_number} onChange={f('account_number')} placeholder="9704XXXXXXX" required />
              </div>
            </div>
            <div className="form-group">
              <label className="form-label">Số dư ban đầu (VND)</label>
              <input className="form-control" type="number" value={form.initial_balance} onChange={f('initial_balance')} min="0" />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={() => setModal(false)}>Hủy</button>
            <button type="submit" className="btn btn-primary">TẠO</button>
          </div>
        </form>
      </Modal>
    </>
  );
}

function BankerTransactions({ toast }) {
  const [txns, setTxns] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState({ account_id: '', amount: '', transaction_type: 'deposit', description: '' });
  const [accounts, setAccounts] = useState([]);
  const load = () => apiFetch('/api/banker/transactions').then(setTxns).catch(() => {});
  useEffect(() => {
    load();
    apiFetch('/api/banker/accounts').then(setAccounts).catch(() => {});
  }, []);

  const submit = async (e) => {
    e.preventDefault();
    try {
      await apiFetch('/api/banker/transactions', { method: 'POST', body: JSON.stringify({ ...form, amount: Number(form.amount) }) });
      toast.ok('Giao dịch thành công!'); setModal(false); load();
    } catch (e) { toast.err(e.message); }
  };
  const f = k => e => setForm(p => ({ ...p, [k]: e.target.value }));

  return (
    <>
      <div className="table-wrapper">
        <div className="table-header">
          <h3>Lịch sử Giao dịch</h3>
          <button className="btn btn-primary btn-sm" onClick={() => setModal(true)}>+ THỰC HIỆN GD</button>
        </div>
        <table><thead><tr><th>Loại</th><th>Từ TK</th><th>Đến TK</th><th>Số tiền</th><th>Status</th><th>Người tạo</th><th>Thời gian</th></tr></thead>
          <tbody>
            {txns.map(t => (
              <tr key={t.id}>
                <td><span className={`badge badge-${t.type}`}>{t.type}</span></td>
                <td className="mono" style={{ fontSize: 11 }}>{t.from_account || '—'}</td>
                <td className="mono" style={{ fontSize: 11 }}>{t.to_account || '—'}</td>
                <td className="mono amount-positive">{fmtMoney(t.amount)}</td>
                <td><span className={`badge badge-${t.status}`}>{t.status}</span></td>
                <td className="mono" style={{ fontSize: 11 }}>{t.created_by}</td>
                <td className="mono" style={{ fontSize: 11 }}>{fmtDate(t.created_at)}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {!txns.length && <div className="empty-state">Chưa có giao dịch</div>}
      </div>
      <Modal title="THỰC HIỆN GIAO DỊCH" open={modal} onClose={() => setModal(false)}>
        <form onSubmit={submit}>
          <div className="modal-body">
            <div className="form-group">
              <label className="form-label">Loại giao dịch</label>
              <select className="form-control" value={form.transaction_type} onChange={f('transaction_type')}>
                <option value="deposit">Nạp tiền</option>
                <option value="withdraw">Rút tiền</option>
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Tài khoản</label>
              <select className="form-control" value={form.account_id} onChange={f('account_id')} required>
                <option value="">-- Chọn TK --</option>
                {accounts.filter(a => a.status === 'active').map(a => (
                  <option key={a.account_id} value={a.account_id}>{a.account_number} - {a.owner} ({fmtMoney(a.balance)})</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Số tiền (VND)</label>
              <input className="form-control" type="number" value={form.amount} onChange={f('amount')} min="1" required />
            </div>
            <div className="form-group">
              <label className="form-label">Mô tả</label>
              <input className="form-control" value={form.description} onChange={f('description')} />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn btn-secondary" onClick={() => setModal(false)}>Hủy</button>
            <button type="submit" className="btn btn-cyan">THỰC HIỆN</button>
          </div>
        </form>
      </Modal>
    </>
  );
}

export { BankerCustomers, BankerAccounts, BankerTransactions };
