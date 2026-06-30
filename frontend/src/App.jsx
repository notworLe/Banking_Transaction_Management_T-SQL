import { useState, useEffect } from 'react';
import './index.css';
import LoginPage from './components/LoginPage.jsx';
import { AdminStats, AdminUsers, AdminBankers, AdminAuditLogs, AdminLoginLogs, Toast, useToast } from './components/AdminDashboard.jsx';
import { BankerCustomers, BankerAccounts, BankerTransactions } from './components/BankerDashboard.jsx';
import { CustomerProfile, CustomerAccounts, CustomerTransactions, CustomerTransfer, CustomerWithdrawDeposit } from './components/CustomerDashboard.jsx';
import { apiFetch, getUser } from './api.js';
import TransactionDemo from './pages/TransactionDemo.jsx';

const NAV = {
  Admin: [
    { key: 'overview', icon: '📊', label: 'Tổng quan' },
    { key: 'users',    icon: '👥', label: 'Users' },
    { key: 'bankers',  icon: '🏦', label: 'Bankers' },
    { key: 'audit',    icon: '📋', label: 'Audit Logs' },
    { key: 'logins',   icon: '🔐', label: 'Login Logs' },
    { key: 'demo',     icon: '🧪', label: 'Demo T-SQL' },
  ],
  Banker: [
    { key: 'customers',    icon: '👥', label: 'Khách hàng' },
    { key: 'accounts',     icon: '💳', label: 'Tài khoản' },
    { key: 'transactions', icon: '💸', label: 'Giao dịch' },
  ],
  Customer: [
    { key: 'dashboard',    icon: '🏠', label: 'Tổng quan' },
    { key: 'transfer',     icon: '↔️',  label: 'Chuyển tiền' },
    { key: 'withdraw',     icon: '💵',  label: 'Rút / Nạp' },
    { key: 'history',      icon: '📜',  label: 'Lịch sử GD' },
    { key: 'profile',      icon: '👤',  label: 'Hồ sơ' },
  ],
};

function Sidebar({ role, username, active, onNav, onLogout }) {
  const badgeClass = { Admin: 'badge-admin', Banker: 'badge-banker', Customer: 'badge-customer' }[role] || '';
  return (
    <div className="sidebar">
      <div className="sidebar-logo">
        <h1>🏦 BANKING<br />SYSTEM</h1>
        <div className={`role-badge ${badgeClass}`}>{role}</div>
        <div style={{ marginTop: 6, fontSize: 12, color: '#888', fontFamily: 'var(--font-mono)' }}>@{username}</div>
      </div>
      <nav className="sidebar-nav">
        <div className="nav-section-label">MENU</div>
        {(NAV[role] || []).map(item => (
          <button key={item.key} className={`nav-item ${active === item.key ? 'active' : ''}`}
            onClick={() => onNav(item.key)}>
            <span className="nav-icon">{item.icon}</span>
            {item.label}
          </button>
        ))}
      </nav>
      <div className="sidebar-footer">
        <button className="btn-logout" onClick={onLogout}>↩ ĐĂNG XUẤT</button>
      </div>
    </div>
  );
}

function PageContent({ role, page, toast }) {
  if (role === 'Admin') {
    if (page === 'overview')  return <><div className="page-header"><h2>TỔNG QUAN HỆ THỐNG</h2><p>Thống kê tổng hợp</p></div><AdminStats /></>;
    if (page === 'users')     return <><div className="page-header"><h2>QUẢN LÝ USERS</h2><p>Khóa / mở tài khoản</p></div><AdminUsers toast={toast} /></>;
    if (page === 'bankers')   return <><div className="page-header"><h2>QUẢN LÝ BANKERS</h2><p>Tạo và quản lý nhân viên</p></div><AdminBankers toast={toast} /></>;
    if (page === 'audit')     return <><div className="page-header"><h2>AUDIT LOGS</h2><p>Nhật ký hoạt động hệ thống</p></div><AdminAuditLogs /></>;
    if (page === 'logins')    return <><div className="page-header"><h2>LOGIN LOGS</h2><p>Lịch sử đăng nhập</p></div><AdminLoginLogs /></>;
    if (page === 'demo')      return <><div className="page-header"><h2>DEMO CONCURRENCY ANOMALIES</h2><p>Mô phỏng và khắc phục tranh chấp giao dịch</p></div><TransactionDemo toast={toast} /></>;
  }
  if (role === 'Banker') {
    if (page === 'customers')    return <><div className="page-header"><h2>KHÁCH HÀNG</h2><p>Xem và tìm kiếm thông tin khách hàng</p></div><BankerCustomers toast={toast} /></>;
    if (page === 'accounts')     return <><div className="page-header"><h2>TÀI KHOẢN</h2><p>Quản lý tài khoản ngân hàng</p></div><BankerAccounts toast={toast} /></>;
    if (page === 'transactions') return <><div className="page-header"><h2>GIAO DỊCH</h2><p>Thực hiện và xem lịch sử giao dịch</p></div><BankerTransactions toast={toast} /></>;
  }
  if (role === 'Customer') {
    if (page === 'dashboard') return (
      <>
        <div className="page-header"><h2>XIN CHÀO! 👋</h2><p>Tổng quan tài khoản của bạn</p></div>
        <CustomerAccounts />
      </>
    );
    if (page === 'transfer')  return <><div className="page-header"><h2>CHUYỂN TIỀN</h2><p>Chuyển khoản an toàn</p></div><CustomerTransfer toast={toast} /></>;
    if (page === 'withdraw')  return <><div className="page-header"><h2>RÚT / NẠP TIỀN</h2><p>Thực hiện giao dịch nhanh</p></div><CustomerWithdrawDeposit toast={toast} /></>;
    if (page === 'history')   return <><div className="page-header"><h2>LỊCH SỬ GIAO DỊCH</h2><p>Tất cả giao dịch của bạn</p></div><CustomerTransactions /></>;
    if (page === 'profile')   return <><div className="page-header"><h2>HỒ SƠ CÁ NHÂN</h2><p>Thông tin tài khoản</p></div><CustomerProfile /></>;
  }
  return <div className="empty-state">Chọn mục từ menu bên trái</div>;
}

const defaultPage = { Admin: 'overview', Banker: 'customers', Customer: 'dashboard' };

export default function App() {
  const [role, setRole] = useState(null);
  const [username, setUsername] = useState('');
  const [page, setPage] = useState('');
  const toast = useToast();

  useEffect(() => {
    const u = getUser();
    if (u) { setRole(u.role); setUsername(u.username); setPage(defaultPage[u.role] || ''); }
  }, []);

  const handleLogin = (r) => {
    const u = getUser();
    setRole(r); setUsername(u?.username || ''); setPage(defaultPage[r] || '');
  };

  const handleLogout = async () => {
    try { await apiFetch('/api/auth/logout', { method: 'POST' }); } catch {}
    localStorage.removeItem('token'); localStorage.removeItem('user');
    setRole(null); setUsername(''); setPage('');
  };

  if (!role) return <LoginPage onLogin={handleLogin} />;

  return (
    <div className="app-layout">
      <Sidebar role={role} username={username} active={page} onNav={setPage} onLogout={handleLogout} />
      <main className="main-content">
        <PageContent role={role} page={page} toast={toast} />
      </main>
      <Toast toasts={toast.toasts} />
    </div>
  );
}
