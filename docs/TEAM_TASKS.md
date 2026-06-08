# Team Task Matrix

Ma trận công việc cho Banking Transaction Management System.  
Tham chiếu: `USE_CASES.md`, `UI_SCREEN_MAP.md`, `DB_OBJECT_MAP.md`, `UI_FIRST_REVIEW.md`.

**Chú thích Note:** `✅` đã có UI mock · `⚠️` gap / một phần · `❌` chưa làm · `🔜` tích hợp SQL sau

---

## Auth

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| AUTH-01 | UC-ADMIN-01, UC-BANKER-01, UC-CUSTOMER-01 | `GET /login` | `auth/login.html` | — | — | ✅ Form đăng nhập + chọn role |
| AUTH-02 | UC-ADMIN-01, UC-BANKER-01, UC-CUSTOMER-01 | `POST /login` | `auth/login.html` | `auth_service.mock_login()` | `sp_Login` | ✅ Mock login; 🔜 thay `sp_Login` |
| AUTH-03 | UC-ADMIN-01, UC-BANKER-01, UC-CUSTOMER-01 | `GET /logout` | — | — (session clear) | — | ✅ Flash đăng xuất |
| AUTH-04 | — | — | — | `auth_service.get_dashboard_url_for_role()` | — | ✅ Helper redirect theo role |
| AUTH-05 | — | Tất cả route `/admin/*`, `/banker/*`, `/customer/*` | — | — (middleware/decorator) | — | ❌ **GAP:** chưa có role guard — user truy cập chéo URL được |
| AUTH-06 | UC-ADMIN-01, UC-BANKER-01, UC-CUSTOMER-01 | `POST /login` | `auth/login.html` | `auth_service.mock_login()` | `sp_Login`, `LoginLogs` | 🔜 Ghi login log thật khi tích hợp DB |

---

## Admin

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| ADMIN-01 | — (chưa có UC) | `GET /admin/dashboard` | `admin/dashboard.html` | `dashboard_service.get_admin_dashboard()` | `vw_AdminDashboard` | ⚠️ **GAP:** có UI mock; thiếu UC trong `USE_CASES.md`; thiếu view trong `DB_OBJECT_MAP.md` |
| ADMIN-02 | UC-ADMIN-02 | `GET /admin/users` | `admin/users.html` | `admin_service.get_users()` | `vw_Users` | ✅ Bảng users mock |
| ADMIN-03 | UC-ADMIN-03 | `POST /admin/users/<id>/toggle-status` | `admin/users.html` | `admin_service.toggle_user_status()` | `sp_LockUser`, `sp_UnlockUser` | ✅ Nút Lock/Unlock mock in-memory |
| ADMIN-04 | UC-ADMIN-04 | `GET /admin/audit-logs` | `admin/audit_logs.html` | `admin_service.get_audit_logs()` | `vw_AuditLogs` | ✅ Bảng audit logs mock |
| ADMIN-05 | UC-ADMIN-05 | `GET /admin/login-logs` | `admin/login_logs.html` | `admin_service.get_login_logs()` | `vw_LoginLogs` | ✅ Bảng login logs mock |
| ADMIN-06 | — | — | `admin_base.html` | — | — | ✅ Layout + sidebar Admin |
| ADMIN-07 | UC-ADMIN-03 | — | — | `admin_service.toggle_user_status()` | `trg_Audit_Users` | ⚠️ **GAP:** trigger có trong `UI_SCREEN_MAP` nhưng chưa có trong `DB_OBJECT_MAP.md` |
| ADMIN-08 | — | — | — | — | — | 🔜 Ghi nhận UC phụ `UC-ADMIN-00` Dashboard vào `USE_CASES.md` (tùy team) |

---

## Banker

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| BANKER-01 | — (chưa có UC) | `GET /banker/dashboard` | `banker/dashboard.html` | `dashboard_service.get_banker_dashboard()` | `vw_BankerDashboard` | ⚠️ **GAP:** có UI mock; thiếu UC; thiếu view trong DB map |
| BANKER-02 | UC-BANKER-02 | `GET /banker/customers` | `banker/customers.html` | `customer_service.get_customers()` | `vw_Customers` | ✅ Danh sách khách hàng |
| BANKER-03 | UC-BANKER-03 | `GET /banker/customers/new` | `banker/customers_new.html` | — | — | ✅ Form tạo KH |
| BANKER-04 | UC-BANKER-03 | `POST /banker/customers/new` | `banker/customers_new.html` | `customer_service.create_customer()` | `sp_CreateCustomer` | ✅ Mock success; ❌ chưa mock error nghiệp vụ |
| BANKER-05 | UC-BANKER-04, UC-BANKER-05, UC-BANKER-06 | `GET /banker/accounts` | `banker/accounts.html` | `account_service.get_accounts()` | `vw_BankAccounts` | ⚠️ Chỉ xem; hiển thị Status cho UC-05/06 |
| BANKER-06 | UC-BANKER-04 | `GET /banker/accounts/open` | `banker/accounts_open.html` | `account_service.get_customers_for_select()`, `get_account_types()` | `vw_Customers`, `AccountTypes` | ✅ Form mở TK; ⚠️ `AccountTypes` chưa có trong DB map |
| BANKER-07 | UC-BANKER-04 | `POST /banker/accounts/open` | `banker/accounts_open.html` | `account_service.open_account()` | `sp_OpenBankAccount` | ✅ Mock success |
| BANKER-08 | UC-BANKER-05 | `POST /banker/accounts/<no>/lock` (dự kiến) | `banker/accounts.html` | `account_service.lock_account()` (dự kiến) | `sp_LockBankAccount` | ❌ **GAP:** chưa có route, nút, service placeholder |
| BANKER-09 | UC-BANKER-06 | `POST /banker/accounts/<no>/close` (dự kiến) | `banker/accounts.html` | `account_service.close_account()` (dự kiến) | `sp_CloseBankAccount` | ❌ **GAP:** chưa có route, nút, service placeholder |
| BANKER-10 | UC-BANKER-10 | `GET /banker/transactions` | `banker/transactions.html` | `transaction_service.get_transactions()` | `vw_TransactionHistory` | ✅ Lịch sử GD banker |
| BANKER-11 | — | — | `banker_base.html` | — | — | ✅ Layout + sidebar Banker |

---

## Account

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| ACCT-01 | UC-BANKER-04 | `GET /banker/accounts` | `banker/accounts.html` | `account_service.get_accounts()` | `vw_BankAccounts` | ✅ |
| ACCT-02 | UC-BANKER-04 | `POST /banker/accounts/open` | `banker/accounts_open.html` | `account_service.open_account()` | `sp_OpenBankAccount` | ✅ |
| ACCT-03 | UC-BANKER-05 | — | `banker/accounts.html` | `account_service.lock_account()` | `sp_LockBankAccount` | ❌ **GAP:** service + UI action chưa có |
| ACCT-04 | UC-BANKER-06 | — | `banker/accounts.html` | `account_service.close_account()` | `sp_CloseBankAccount` | ❌ **GAP:** service + UI action chưa có |
| ACCT-05 | UC-BANKER-04 | `GET /banker/accounts/open` | `banker/accounts_open.html` | `account_service.get_account_types()` | `AccountTypes` (table/lookup) | ⚠️ **GAP:** lookup chưa document trong `DB_OBJECT_MAP.md` |
| ACCT-06 | UC-BANKER-04 | `GET /banker/accounts/open` | `banker/accounts_open.html` | `account_service.get_customers_for_select()` | `vw_Customers` | ✅ Dropdown KH |
| ACCT-07 | UC-CUSTOMER-03 | `GET /customer/accounts` | `customer/accounts.html` | `customer_portal_service.get_accounts()` | `vw_CustomerAccounts` | ✅ TK theo user đăng nhập |
| ACCT-08 | — | — | — | — | `BankAccounts` (table) | ❌ Schema bảng chưa có script trong `database/` |

---

## Transaction

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| TXN-01 | UC-BANKER-07 | `GET /banker/transactions/deposit` | `banker/deposit.html` | — | — | ✅ Form nạp tiền |
| TXN-02 | UC-BANKER-07 | `POST /banker/transactions/deposit` | `banker/deposit.html` | `transaction_service.deposit()` | `sp_Deposit` | ✅ Mock; ❌ chưa mock lỗi (TK khóa, amount ≤ 0) |
| TXN-03 | UC-BANKER-08 | `GET /banker/transactions/withdraw` | `banker/withdraw.html` | — | — | ✅ Form rút tiền |
| TXN-04 | UC-BANKER-08 | `POST /banker/transactions/withdraw` | `banker/withdraw.html` | `transaction_service.withdraw()` | `sp_Withdraw` | ✅ Mock; ❌ chưa mock lỗi (số dư không đủ) |
| TXN-05 | UC-BANKER-09 | `GET /banker/transactions/transfer` | `banker/transfer.html` | — | — | ✅ Form CK banker |
| TXN-06 | UC-BANKER-09 | `POST /banker/transactions/transfer` | `banker/transfer.html` | `transaction_service.transfer()` | `sp_Transfer` | ✅ Mock; không cộng/trừ tiền trong Python |
| TXN-07 | UC-BANKER-10 | `GET /banker/transactions` | `banker/transactions.html` | `transaction_service.get_transactions()` | `vw_TransactionHistory` | ✅ |
| TXN-08 | UC-CUSTOMER-05 | `GET /customer/transfer` | `customer/transfer.html` | `customer_portal_service.get_owned_account_numbers()` | `vw_CustomerAccounts` | ✅ Dropdown TK nguồn |
| TXN-09 | UC-CUSTOMER-05 | `POST /customer/transfer` | `customer/transfer.html` | `transaction_service.transfer()` | `sp_Transfer` | ✅ Mock success |
| TXN-10 | UC-CUSTOMER-04 | `GET /customer/transactions` | `customer/transactions.html` | `customer_portal_service.get_transactions()` | `vw_CustomerTransactions` | ✅ |
| TXN-11 | UC-BANKER-07 | — | — | — | `trg_Audit_Transactions` | ⚠️ **GAP:** có trong `UI_SCREEN_MAP`; chưa có trong `DB_OBJECT_MAP.md` |
| TXN-12 | — | — | — | `transaction_service.*` | — | ❌ **GAP:** bổ sung mock `success=False` + message lỗi nghiệp vụ cho deposit/withdraw/transfer |
| TXN-13 | — | — | — | — | `Transactions` (table) | ❌ Schema bảng chưa có script trong `database/` |

---

## Customer Portal

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| CUST-01 | UC-CUSTOMER-02 | `GET /customer/dashboard` | `customer/dashboard.html` | `customer_portal_service.get_dashboard()` | `vw_CustomerDashboard` | ✅ 3 stat cards + preview |
| CUST-02 | UC-CUSTOMER-03 | `GET /customer/accounts` | `customer/accounts.html` | `customer_portal_service.get_accounts()` | `vw_CustomerAccounts` | ✅ |
| CUST-03 | UC-CUSTOMER-04 | `GET /customer/transactions` | `customer/transactions.html` | `customer_portal_service.get_transactions()` | `vw_CustomerTransactions` | ✅ |
| CUST-04 | UC-CUSTOMER-05 | `GET/POST /customer/transfer` | `customer/transfer.html` | `transaction_service.transfer()` | `sp_Transfer` | ✅ |
| CUST-05 | — | — | `customer_base.html` | — | — | ✅ Layout + sidebar Customer |
| CUST-06 | — | — | — | `customer_portal_service` | — | ⚠️ Naming: đối lập `customer_service` (Banker) — cần glossary team |
| CUST-07 | — | — | — | `dashboard_service.get_customer_dashboard()` | — | ❌ Dead code; dọn khi refactor |
| CUST-08 | UC-CUSTOMER-01 | `GET/POST /login` | `auth/login.html` | `auth_service.mock_login()` | `sp_Login` | ✅ Role customer → `/customer/dashboard` |

---

## Database

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| DB-01 | — | — | — | — | `Users` | ❌ Tạo bảng + seed trong `database/` |
| DB-02 | UC-BANKER-03 | — | — | — | `Customers` | ❌ |
| DB-03 | UC-BANKER-04 | — | — | — | `BankAccounts` | ❌ |
| DB-04 | UC-BANKER-07~09 | — | — | — | `Transactions` | ❌ |
| DB-05 | UC-ADMIN-04 | — | — | — | `AuditLogs` | ❌ |
| DB-06 | UC-ADMIN-05 | — | — | — | `LoginLogs` | ❌ |
| DB-07 | UC-BANKER-04 | — | — | — | `AccountTypes` | ❌ **GAP:** chưa document; lookup Thanh toán/Tiết kiệm |
| DB-08 | — | — | — | `app/config.py` | — | 🔜 Cấu hình `pyodbc` từ `.env` |
| DB-09 | — | — | — | — | `database/` folder | ❌ Hiện trống (chỉ `.gitkeep`) |
| DB-10 | — | — | — | — | FK / index / constraint | ❌ Thiết kế ERD + ràng buộc toàn vẹn |

---

## View

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| VW-01 | UC-ADMIN-02 | — | — | `admin_service.get_users()` | `vw_Users` | 🔜 SQL script |
| VW-02 | UC-ADMIN-04 | — | — | `admin_service.get_audit_logs()` | `vw_AuditLogs` | 🔜 |
| VW-03 | UC-ADMIN-05 | — | — | `admin_service.get_login_logs()` | `vw_LoginLogs` | 🔜 |
| VW-04 | UC-BANKER-02 | — | — | `customer_service.get_customers()` | `vw_Customers` | 🔜 |
| VW-05 | UC-BANKER-04~06 | — | — | `account_service.get_accounts()` | `vw_BankAccounts` | 🔜 |
| VW-06 | UC-BANKER-07~10 | — | — | `transaction_service.get_transactions()` | `vw_TransactionHistory` | 🔜 |
| VW-07 | UC-CUSTOMER-02 | — | — | `customer_portal_service.get_dashboard()` | `vw_CustomerDashboard` | 🔜 |
| VW-08 | UC-CUSTOMER-03 | — | — | `customer_portal_service.get_accounts()` | `vw_CustomerAccounts` | 🔜 |
| VW-09 | UC-CUSTOMER-04 | — | — | `customer_portal_service.get_transactions()` | `vw_CustomerTransactions` | 🔜 |
| VW-10 | — | `GET /admin/dashboard` | — | `dashboard_service.get_admin_dashboard()` | `vw_AdminDashboard` | ❌ **GAP:** chưa có trong `DB_OBJECT_MAP.md` |
| VW-11 | — | `GET /banker/dashboard` | — | `dashboard_service.get_banker_dashboard()` | `vw_BankerDashboard` | ❌ **GAP:** chưa có trong `DB_OBJECT_MAP.md` |

---

## Stored Procedure

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| SP-01 | UC-ADMIN-01, UC-BANKER-01, UC-CUSTOMER-01 | `POST /login` | — | `auth_service.mock_login()` | `sp_Login` | 🔜 Thay mock login |
| SP-02 | UC-ADMIN-03 | `POST /admin/users/<id>/toggle-status` | — | `admin_service.toggle_user_status()` | `sp_LockUser` | 🔜 Tách lock/unlock khi tích hợp |
| SP-03 | UC-ADMIN-03 | `POST /admin/users/<id>/toggle-status` | — | `admin_service.toggle_user_status()` | `sp_UnlockUser` | 🔜 |
| SP-04 | UC-BANKER-03 | `POST /banker/customers/new` | — | `customer_service.create_customer()` | `sp_CreateCustomer` | 🔜 |
| SP-05 | UC-BANKER-04 | `POST /banker/accounts/open` | — | `account_service.open_account()` | `sp_OpenBankAccount` | 🔜 |
| SP-06 | UC-BANKER-05 | — | — | `account_service.lock_account()` | `sp_LockBankAccount` | ❌ Chưa có UI/service |
| SP-07 | UC-BANKER-06 | — | — | `account_service.close_account()` | `sp_CloseBankAccount` | ❌ Chưa có UI/service |
| SP-08 | UC-BANKER-07 | `POST /banker/transactions/deposit` | — | `transaction_service.deposit()` | `sp_Deposit` | 🔜 Logic cộng tiền trong SP |
| SP-09 | UC-BANKER-08 | `POST /banker/transactions/withdraw` | — | `transaction_service.withdraw()` | `sp_Withdraw` | 🔜 Logic trừ tiền trong SP |
| SP-10 | UC-BANKER-09, UC-CUSTOMER-05 | `POST .../transfer` | — | `transaction_service.transfer()` | `sp_Transfer` | 🔜 Logic CK trong SP; dùng chung Banker + Customer |

---

## Function

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| FN-01 | UC-BANKER-07~09, UC-CUSTOMER-05 | — | — | — | `fn_ValidateAccountActive` | ❌ Kiểm tra TK tồn tại + trạng thái active |
| FN-02 | UC-BANKER-08, UC-CUSTOMER-05 | — | — | — | `fn_CheckSufficientBalance` | ❌ Kiểm tra số dư đủ (gọi từ SP) |
| FN-03 | — | — | — | — | `fn_FormatCurrency` | ❌ Tùy chọn — format VNĐ trong view/report |
| FN-04 | UC-BANKER-04 | — | — | `account_service.get_account_types()` | `fn_GetAccountTypeLabel` | ❌ Hoặc dùng bảng `AccountTypes` thay function |

---

## Trigger

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| TRG-01 | UC-ADMIN-03 | — | — | — | `trg_Audit_Users` | ❌ **GAP:** có trong `UI_SCREEN_MAP`; thiếu `DB_OBJECT_MAP.md` |
| TRG-02 | UC-BANKER-07~09 | — | — | — | `trg_Audit_Transactions` | ❌ **GAP:** có trong `UI_SCREEN_MAP`; thiếu `DB_OBJECT_MAP.md` |
| TRG-03 | UC-BANKER-03, UC-BANKER-04 | — | — | — | `trg_Audit_Customers` | ❌ Gợi ý — ghi audit khi tạo KH/mở TK |
| TRG-04 | UC-BANKER-05, UC-BANKER-06 | — | — | — | `trg_Audit_BankAccounts` | ❌ Gợi ý — ghi audit khi khóa/đóng TK |

---

## Integration

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| INT-01 | — | — | — | — | `pyodbc` connection module | ❌ Tạo `app/db.py` hoặc tương đương |
| INT-02 | — | — | — | Tất cả `*_service.py` | Tất cả SP/VW | 🔜 Thay `mock_data` bằng gọi SQL |
| INT-03 | AUTH-05 | — | — | — | — | ❌ **GAP:** implement role guard trước go-live |
| INT-04 | — | — | — | `auth_service` | `sp_Login` | 🔜 Bỏ mock role selector khi có auth thật (hoặc giữ dev mode) |
| INT-05 | — | — | — | — | `.env` + `config.py` | ✅ Skeleton có; chưa kết nối thật |
| INT-06 | — | — | — | — | `instnwnd.sql` / seed | ❌ Liên kết seed DB với mock data hiện tại |
| INT-07 | TXN-12 | — | — | `transaction_service`, `customer_service`, `account_service` | SP output `Success/Message` | ❌ Map lỗi SP → flash danger trên UI |
| INT-08 | — | — | — | `customer_service` vs `customer_portal_service` | — | ⚠️ Refactor naming trước khi tích hợp |
| INT-09 | — | — | — | `mock_data/` | — | ⚠️ Tách `shared_accounts` — `customer.py` import `banker.py` |

---

## Test

| Task ID | Use Case | UI Route | Template | Python Service | DB Object | Note |
|---------|----------|----------|----------|----------------|-----------|------|
| TST-01 | — | Tất cả GET routes | — | — | — | ❌ Smoke test tự động (pytest + Flask client) |
| TST-02 | UC-ADMIN-01~05 | Auth + Admin routes | — | — | — | ❌ Test flow Admin mock |
| TST-03 | UC-BANKER-01~10 | Banker routes | — | — | — | ❌ Test flow Banker mock |
| TST-04 | UC-CUSTOMER-01~05 | Customer routes | — | — | — | ❌ Test flow Customer mock |
| TST-05 | TXN-12 | POST giao dịch | — | `transaction_service` | — | ❌ **GAP:** test UI khi `success=False` |
| TST-06 | BANKER-08, BANKER-09 | — | — | `account_service` | `sp_Lock/Close` | ❌ Test sau khi có UI lock/close |
| TST-07 | AUTH-05 | Cross-role URLs | — | — | — | ❌ Test role guard từ chối 403/redirect |
| TST-08 | — | — | — | — | SP + VW | ❌ Integration test SQL Server (Docker/local) |
| TST-09 | UC-BANKER-07~09 | — | — | — | `sp_Deposit/Withdraw/Transfer` | ❌ Test số dư thay đổi đúng trong DB (không test trong Python) |

---

## Tổng hợp gap ưu tiên (từ UI_FIRST_REVIEW)

| # | Gap | Task ID liên quan |
|---|-----|------------------|
| 1 | UC-BANKER-05/06 thiếu action + service | BANKER-08, BANKER-09, ACCT-03, ACCT-04, SP-06, SP-07, TST-06 |
| 2 | Dashboard Admin/Banker thiếu UC + DB view | ADMIN-01, BANKER-01, VW-10, VW-11, ADMIN-08 |
| 3 | DB map thiếu trigger audit | ADMIN-07, TXN-11, TRG-01, TRG-02 |
| 4 | DB map thiếu `AccountTypes`, dashboard views | ACCT-05, DB-07, VW-10, VW-11 |
| 5 | Thiếu mock error nghiệp vụ | TXN-12, BANKER-04, TXN-02~04, TST-05, INT-07 |
| 6 | Thiếu role guard | AUTH-05, INT-03, TST-07 |
| 7 | Dead code / naming | CUST-06, CUST-07, INT-08, INT-09 |
