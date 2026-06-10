// Khi chạy trong Docker: dùng proxy Vite (/api → app:8000)
// Khi dev ngoài Docker: dùng localhost:8000 trực tiếp
const API = typeof window !== 'undefined' && window.location.port === '3000'
  ? ''   // relative → Vite proxy
  : 'http://localhost:8000';

const getToken = () => localStorage.getItem('token');
const getUser  = () => {
  const raw = localStorage.getItem('user');
  return raw ? JSON.parse(raw) : null;
};

export async function apiFetch(path, options = {}) {
  const token = getToken();
  const headers = { 'Content-Type': 'application/json', ...options.headers };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  const res = await fetch(`${API}${path}`, { ...options, headers });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: 'Lỗi kết nối' }));
    throw new Error(err.detail || 'Lỗi không xác định');
  }
  return res.json();
}

export const fmtMoney = (n) =>
  new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n ?? 0);

export const fmtDate = (s) => {
  if (!s || s === 'None') return '—';
  try { return new Date(s).toLocaleString('vi-VN'); } catch { return s; }
};

export { getToken, getUser };
