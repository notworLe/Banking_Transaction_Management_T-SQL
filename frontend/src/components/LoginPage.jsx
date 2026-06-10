import { useState } from 'react';
import { apiFetch } from '../api.js';

export default function LoginPage({ onLogin }) {
  const [tab, setTab] = useState('login');
  const [loginForm, setLoginForm] = useState({ username: '', password: '' });
  const [regForm, setRegForm] = useState({ username: '', password: '', full_name: '', email: '', phone: '', address: '', birthday: '' });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const data = await apiFetch('/api/auth/login', { method: 'POST', body: JSON.stringify(loginForm) });
      localStorage.setItem('token', data.access_token);
      localStorage.setItem('user', JSON.stringify({ username: data.username, role: data.role }));
      onLogin(data.role);
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setError(''); setSuccess(''); setLoading(true);
    try {
      await apiFetch('/api/auth/register', { method: 'POST', body: JSON.stringify(regForm) });
      setSuccess('Đăng ký thành công! Hãy đăng nhập.');
      setTab('login');
      setLoginForm({ username: regForm.username, password: '' });
      setRegForm({ username: '', password: '', full_name: '', email: '', phone: '', address: '', birthday: '' });
    } catch (e) { setError(e.message); }
    finally { setLoading(false); }
  };

  const lf = k => e => setLoginForm(p => ({ ...p, [k]: e.target.value }));
  const rf = k => e => setRegForm(p => ({ ...p, [k]: e.target.value }));

  return (
    <div className="login-page">
      <div className="login-box" style={{ maxWidth: tab === 'register' ? 520 : 420 }}>
        <div className="login-header">
          <h1>🏦 BANKING SYSTEM</h1>
          <p>Transaction Management Platform</p>
        </div>

        {/* Tab switcher */}
        <div style={{ display: 'flex', borderBottom: '3px solid black' }}>
          {['login', 'register'].map(t => (
            <button key={t} onClick={() => { setTab(t); setError(''); setSuccess(''); }}
              style={{
                flex: 1, padding: '12px', border: 'none', borderRight: t === 'login' ? '2px solid black' : 'none',
                fontFamily: 'var(--font-body)', fontWeight: 700, fontSize: 13,
                textTransform: 'uppercase', letterSpacing: 1, cursor: 'pointer',
                background: tab === t ? 'var(--yellow)' : 'var(--white)',
                color: 'var(--black)',
              }}>
              {t === 'login' ? '🔑 Đăng nhập' : '✏️ Đăng ký'}
            </button>
          ))}
        </div>

        <div className="login-body">
          {error   && <div className="login-error">⚠ {error}</div>}
          {success && <div className="alert alert-success" style={{ marginBottom: 16 }}>✅ {success}</div>}

          {/* LOGIN FORM */}
          {tab === 'login' && (
            <form onSubmit={handleLogin}>
              <div className="form-group">
                <label className="form-label">Username</label>
                <input className="form-control" value={loginForm.username}
                  onChange={lf('username')} placeholder="Nhập username..." required />
              </div>
              <div className="form-group">
                <label className="form-label">Password</label>
                <input className="form-control" type="password" value={loginForm.password}
                  onChange={lf('password')} placeholder="Nhập mật khẩu..." required />
              </div>
              <button className="btn btn-primary" disabled={loading}
                style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
                {loading ? 'ĐANG ĐĂNG NHẬP...' : 'ĐĂNG NHẬP →'}
              </button>
              <hr className="divider" />
              <div style={{ fontSize: 11, fontFamily: 'var(--font-mono)', color: '#888', lineHeight: 2 }}>
                <div>👤 <b>admin</b> / Admin@123 — <span style={{ color: '#f43' }}>Admin</span></div>
                <div>👤 <b>banker_nam</b> / Banker@123 — <span style={{ color: '#0cc' }}>Banker</span></div>
                <div>👤 <b>nguyen_van_a</b> / Cust@111 — <span style={{ color: '#0a6' }}>Customer</span></div>
              </div>
            </form>
          )}

          {/* REGISTER FORM */}
          {tab === 'register' && (
            <form onSubmit={handleRegister}>
              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Họ và tên *</label>
                  <input className="form-control" value={regForm.full_name}
                    onChange={rf('full_name')} placeholder="Nguyễn Văn A" required />
                </div>
                <div className="form-group">
                  <label className="form-label">Username *</label>
                  <input className="form-control" value={regForm.username}
                    onChange={rf('username')} placeholder="username_123" required />
                </div>
              </div>
              <div className="form-group">
                <label className="form-label">Mật khẩu *</label>
                <input className="form-control" type="password" value={regForm.password}
                  onChange={rf('password')} placeholder="Tối thiểu 6 ký tự" required />
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Email *</label>
                  <input className="form-control" type="email" value={regForm.email}
                    onChange={rf('email')} placeholder="email@gmail.com" required />
                </div>
                <div className="form-group">
                  <label className="form-label">Số điện thoại *</label>
                  <input className="form-control" value={regForm.phone}
                    onChange={rf('phone')} placeholder="0901234567" required />
                </div>
              </div>
              <div className="form-row">
                <div className="form-group">
                  <label className="form-label">Ngày sinh</label>
                  <input className="form-control" type="date" value={regForm.birthday}
                    onChange={rf('birthday')} />
                </div>
                <div className="form-group">
                  <label className="form-label">Địa chỉ</label>
                  <input className="form-control" value={regForm.address}
                    onChange={rf('address')} placeholder="123 Đường ABC, TP.HCM" />
                </div>
              </div>
              <button className="btn btn-cyan" disabled={loading}
                style={{ width: '100%', justifyContent: 'center', marginTop: 8 }}>
                {loading ? 'ĐANG XỬ LÝ...' : '✏️ TẠO TÀI KHOẢN →'}
              </button>
              <p style={{ fontSize: 11, color: '#888', marginTop: 12, textAlign: 'center' }}>
                Sau khi đăng ký, liên hệ Banker để mở tài khoản ngân hàng
              </p>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}
