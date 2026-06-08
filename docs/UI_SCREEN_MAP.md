## UC-ADMIN-01: Đăng nhập (Admin)

### Actor
- Admin

### Purpose
Cho phép quản trị viên đăng nhập vào hệ thống.

### Routes
- GET `/login`
- POST `/login`
- GET `/logout`

### Template
- `app/templates/auth/login.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| username | Tên đăng nhập | Yes | Mock — chưa xác thực DB |
| password | Mật khẩu | Yes | Mock — không kiểm tra mật khẩu thật |
| role | Vai trò | Yes | Chọn `admin` để vào dashboard Admin |

### Service
- `auth_service.mock_login(username, password, role)`

### Expected UI Behavior

GET:
- Hiển thị form đăng nhập (Username, Password, Role).
- Role mặc định: Admin.

POST success (role = admin):
- Lưu session mock.
- Flash thông báo đăng nhập thành công.
- Redirect `/admin/dashboard`.

POST failure:
- Thiếu username hoặc password → flash cảnh báo, giữ lại dữ liệu đã nhập.
- Role không hợp lệ → flash cảnh báo.

GET `/logout`:
- Xóa session.
- Flash thông báo đăng xuất.
- Redirect `/login`.

### Future Database Objects
- `sp_Login`
- `vw_LoginLogs`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-ADMIN-02: Xem danh sách users

### Actor
- Admin

### Purpose
Cho phép quản trị viên xem danh sách tất cả người dùng trong hệ thống.

### Routes
- GET `/admin/users`

### Template
- `app/templates/admin/users.html`

### Service
- `admin_service.get_users()`

### Expected UI Behavior

GET:
- Hiển thị bảng người dùng với các cột: Username, Role, Status, LastLoginAt, CreatedAt.
- Có nút Lock/Unlock mock trên mỗi dòng (UC-ADMIN-03).
- Sidebar active tại mục "Danh sách người dùng".

### Future Database Objects
- `vw_Users`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-ADMIN-03: Khóa/mở tài khoản user

### Actor
- Admin

### Purpose
Cho phép quản trị viên khóa hoặc mở khóa tài khoản người dùng.

### Routes
- POST `/admin/users/<user_id>/toggle-status`

### Template
- `app/templates/admin/users.html` (nút Lock/Unlock trên bảng)

### Service
- `admin_service.toggle_user_status(user_id)`

### Expected UI Behavior

POST success:
- Cập nhật trạng thái mock (active ↔ locked).
- Flash thông báo thành công.
- Redirect về `/admin/users`.

POST failure:
- Flash thông báo lỗi nếu không tìm thấy user.
- Redirect về `/admin/users`.

### Future Database Objects
- `sp_LockUser`
- `sp_UnlockUser`
- `trg_Audit_Users`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-ADMIN-04: Xem audit logs

### Actor
- Admin

### Purpose
Cho phép quản trị viên xem nhật ký thao tác trên hệ thống.

### Routes
- GET `/admin/audit-logs`

### Template
- `app/templates/admin/audit_logs.html`

### Service
- `admin_service.get_audit_logs()`

### Expected UI Behavior

GET:
- Hiển thị bảng audit logs: User, ActionType, TargetTable, TargetId, Description, CreatedAt.
- Sidebar active tại mục "Audit logs".

### Future Database Objects
- `vw_AuditLogs`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-ADMIN-05: Xem login logs

### Actor
- Admin

### Purpose
Cho phép quản trị viên xem nhật ký đăng nhập và đăng xuất.

### Routes
- GET `/admin/login-logs`

### Template
- `app/templates/admin/login_logs.html`

### Service
- `admin_service.get_login_logs()`

### Expected UI Behavior

GET:
- Hiển thị bảng login logs: Username, LoginTime, LogoutTime, LoginStatus, IPAddress.
- Sidebar active tại mục "Login logs".

### Future Database Objects
- `vw_LoginLogs`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-01: Đăng nhập (Banker)

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng đăng nhập vào hệ thống.

### Routes
- GET `/login`
- POST `/login`
- GET `/logout`

### Template
- `app/templates/auth/login.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| username | Tên đăng nhập | Yes | Mock — chưa xác thực DB |
| password | Mật khẩu | Yes | Mock — không kiểm tra mật khẩu thật |
| role | Vai trò | Yes | Chọn `banker` để vào dashboard Banker |

### Service
- `auth_service.mock_login(username, password, role)`

### Expected UI Behavior

GET:
- Hiển thị form đăng nhập (Username, Password, Role).

POST success (role = banker):
- Lưu session mock.
- Flash thông báo đăng nhập thành công.
- Redirect `/banker/dashboard`.

POST failure:
- Thiếu username hoặc password → flash cảnh báo, giữ lại dữ liệu đã nhập.
- Role không hợp lệ → flash cảnh báo.

GET `/logout`:
- Xóa session.
- Flash thông báo đăng xuất.
- Redirect `/login`.

### Future Database Objects
- `sp_Login`
- `vw_LoginLogs`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-02: Xem danh sách khách hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng xem danh sách khách hàng.

### Routes
- GET `/banker/customers`

### Template
- `app/templates/banker/customers.html`

### Service
- `customer_service.get_customers()`

### Expected UI Behavior

GET:
- Hiển thị bảng khách hàng: FullName, Email, PhoneNumber, Address, Username, CreatedAt.
- Có nút chuyển tới trang tạo khách hàng.

### Future Database Objects
- `vw_Customers`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-03: Tạo khách hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng tạo khách hàng mới.

### Routes
- GET `/banker/customers/new`
- POST `/banker/customers/new`

### Template
- `app/templates/banker/customers_new.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| full_name | FullName | Yes | Họ và tên |
| email | Email | Yes | |
| phone_number | PhoneNumber | Yes | |
| address | Address | No | |
| birth_day | BirthDay | No | |
| username | Username | Yes | |
| password | Password | Yes | Mock — chưa hash |

### Service
- `customer_service.create_customer(...)`

### Expected UI Behavior

GET:
- Hiển thị form tạo khách hàng.

POST success:
- Flash thông báo mock thành công.
- Redirect `/banker/customers`.

POST failure:
- Flash cảnh báo nếu thiếu trường bắt buộc.
- Giữ lại dữ liệu đã nhập.

### Future Database Objects
- `sp_CreateCustomer`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-04: Mở tài khoản ngân hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng mở tài khoản mới cho khách hàng.

### Routes
- GET `/banker/accounts`
- GET `/banker/accounts/open`
- POST `/banker/accounts/open`

### Template
- `app/templates/banker/accounts.html`
- `app/templates/banker/accounts_open.html`

### Form Fields (mở tài khoản)
| Field | Label | Required | Note |
|---|---|---|---|
| customer_id | Customer | Yes | Chọn từ danh sách khách hàng |
| account_type | AccountType | Yes | Thanh toán / Tiết kiệm |
| initial_balance | InitialBalance | No | Số dư ban đầu |

### Service
- `account_service.get_accounts()`
- `account_service.open_account(customer_id, account_type, initial_balance, created_by_user_id)`

### Expected UI Behavior

GET `/banker/accounts`:
- Hiển thị bảng tài khoản: AccountNumber, Customer, AccountType, Balance, Status, OpenedAt.

GET `/banker/accounts/open`:
- Hiển thị form mở tài khoản.

POST success:
- Flash mock thành công.
- Redirect `/banker/accounts`.

### Future Database Objects
- `sp_OpenBankAccount`
- `vw_BankAccounts`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-05: Khóa tài khoản ngân hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên khóa tài khoản ngân hàng.

### Routes
- GET `/banker/accounts` (hiển thị trạng thái)

### Template
- `app/templates/banker/accounts.html`

### Service
- `account_service.get_accounts()` (mock hiển thị status)

### Expected UI Behavior
- Trang danh sách tài khoản hiển thị badge trạng thái (Hoạt động / Đã khóa).
- Chức năng khóa tài khoản sẽ tích hợp sau qua `sp_LockBankAccount`.

### Future Database Objects
- `sp_LockBankAccount`

### Status
- UI: Mock (chỉ hiển thị)
- Backend Service: Pending
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-06: Đóng tài khoản ngân hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên đóng tài khoản ngân hàng.

### Routes
- GET `/banker/accounts` (hiển thị trạng thái)

### Template
- `app/templates/banker/accounts.html`

### Service
- `account_service.get_accounts()` (mock hiển thị status)

### Expected UI Behavior
- Trang danh sách tài khoản sẵn sàng hiển thị trạng thái đóng.
- Chức năng đóng tài khoản sẽ tích hợp sau qua `sp_CloseBankAccount`.

### Future Database Objects
- `sp_CloseBankAccount`

### Status
- UI: Mock (chỉ hiển thị)
- Backend Service: Pending
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-08: Rút tiền

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng rút tiền từ tài khoản khách hàng.

### Routes
- GET `/banker/transactions/withdraw`
- POST `/banker/transactions/withdraw`

### Template
- `app/templates/banker/withdraw.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| account_number | AccountNumber | Yes | |
| amount | Amount | Yes | |
| description | Description | No | |

### Service
- `transaction_service.withdraw(account_number, amount, description, created_by_user_id)`

### Expected UI Behavior

GET:
- Hiển thị form rút tiền.
- Có nút quay lại `/banker/transactions`.

POST success:
- Flash mock thành công.
- Redirect `/banker/transactions`.

### Future Database Objects
- `sp_Withdraw`
- `vw_TransactionHistory`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-09: Chuyển khoản hộ khách hàng

### Actor
- Banker

### Purpose
Cho phép nhân viên thực hiện chuyển khoản giữa các tài khoản.

### Routes
- GET `/banker/transactions/transfer`
- POST `/banker/transactions/transfer`

### Template
- `app/templates/banker/transfer.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| from_account_number | FromAccountNumber | Yes | |
| to_account_number | ToAccountNumber | Yes | |
| amount | Amount | Yes | |
| description | Description | No | |

### Service
- `transaction_service.transfer(from_account_number, to_account_number, amount, description, created_by_user_id)`

### Expected UI Behavior

GET:
- Hiển thị form chuyển khoản.

POST success:
- Flash mock thành công.
- Redirect `/banker/transactions`.

### Future Database Objects
- `sp_Transfer`
- `vw_TransactionHistory`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-10: Xem lịch sử giao dịch

### Actor
- Banker

### Purpose
Cho phép nhân viên xem lịch sử giao dịch.

### Routes
- GET `/banker/transactions`

### Template
- `app/templates/banker/transactions.html`

### Service
- `transaction_service.get_transactions()`

### Expected UI Behavior

GET:
- Hiển thị bảng giao dịch: TransactionId, loại, tài khoản nguồn/đích, Amount, Description, CreatedAt, CreatedBy.
- Có shortcut tới form Nạp/Rút/Chuyển khoản.

### Future Database Objects
- `vw_TransactionHistory`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-CUSTOMER-01: Đăng nhập (Customer)

### Actor
- Customer

### Purpose
Cho phép khách hàng đăng nhập vào hệ thống.

### Routes
- GET `/login`
- POST `/login`
- GET `/logout`

### Template
- `app/templates/auth/login.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| username | Tên đăng nhập | Yes | Mock — chưa xác thực DB |
| password | Mật khẩu | Yes | Mock — không kiểm tra mật khẩu thật |
| role | Vai trò | Yes | Chọn `customer` để vào dashboard Customer |

### Service
- `auth_service.mock_login(username, password, role)`

### Expected UI Behavior

GET:
- Hiển thị form đăng nhập (Username, Password, Role).

POST success (role = customer):
- Lưu session mock.
- Flash thông báo đăng nhập thành công.
- Redirect `/customer/dashboard`.

POST failure:
- Thiếu username hoặc password → flash cảnh báo, giữ lại dữ liệu đã nhập.
- Role không hợp lệ → flash cảnh báo.

GET `/logout`:
- Xóa session.
- Flash thông báo đăng xuất.
- Redirect `/login`.

### Future Database Objects
- `sp_Login`
- `vw_LoginLogs`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-CUSTOMER-02: Xem dashboard cá nhân

### Actor
- Customer

### Purpose
Cho phép khách hàng xem tổng quan tài khoản và giao dịch cá nhân.

### Routes
- GET `/customer/dashboard`

### Template
- `app/templates/customer/dashboard.html`

### Service
- `customer_portal_service.get_dashboard(username)`

### Expected UI Behavior

GET:
- Hiển thị 3 thẻ thống kê: Tổng số tài khoản, Tổng số dư, Số giao dịch gần đây.
- Hiển thị tóm tắt tài khoản và giao dịch gần đây.
- Dữ liệu theo username đăng nhập (mock).

### Future Database Objects
- `vw_CustomerDashboard`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-CUSTOMER-03: Xem danh sách tài khoản ngân hàng

### Actor
- Customer

### Purpose
Cho phép khách hàng xem danh sách tài khoản thuộc sở hữu.

### Routes
- GET `/customer/accounts`

### Template
- `app/templates/customer/accounts.html`

### Service
- `customer_portal_service.get_accounts(username)`

### Expected UI Behavior

GET:
- Hiển thị bảng tài khoản của customer hiện tại: AccountNumber, AccountType, Balance, Status, OpenedAt.

### Future Database Objects
- `vw_CustomerAccounts`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-CUSTOMER-04: Xem lịch sử giao dịch

### Actor
- Customer

### Purpose
Cho phép khách hàng xem lịch sử giao dịch trên tài khoản của mình.

### Routes
- GET `/customer/transactions`

### Template
- `app/templates/customer/transactions.html`

### Service
- `customer_portal_service.get_transactions(username)`

### Expected UI Behavior

GET:
- Hiển thị bảng giao dịch: TransactionId, loại, From/To Account, Amount, Description, CreatedAt.
- Có nút chuyển tới trang chuyển khoản.

### Future Database Objects
- `vw_CustomerTransactions`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-CUSTOMER-05: Chuyển khoản

### Actor
- Customer

### Purpose
Cho phép khách hàng chuyển tiền giữa các tài khoản.

### Routes
- GET `/customer/transfer`
- POST `/customer/transfer`

### Template
- `app/templates/customer/transfer.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| from_account_number | FromAccountNumber | Yes | Tài khoản nguồn (chọn từ tài khoản sở hữu) |
| to_account_number | ToAccountNumber | Yes | Tài khoản đích |
| amount | Amount | Yes | |
| description | Description | No | |

### Service
- `transaction_service.transfer(from_account_number, to_account_number, amount, description, created_by_user_id)`

### Expected UI Behavior

GET:
- Hiển thị form chuyển khoản.
- FromAccountNumber là dropdown các tài khoản của customer.

POST success:
- Gọi `transaction_service.transfer()` mock.
- Flash thông báo thành công.
- Redirect `/customer/transactions`.
- Không trừ/cộng tiền thật trong Python.

POST failure:
- Flash cảnh báo nếu thiếu trường bắt buộc.
- Giữ lại dữ liệu đã nhập.

### Future Database Objects
- `sp_Transfer`
- `vw_CustomerTransactions`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD

---

## UC-BANKER-07: Nạp tiền

### Actor
- Banker

### Purpose
Cho phép nhân viên ngân hàng nạp tiền vào một tài khoản ngân hàng đang hoạt động.

### Routes
- GET `/banker/transactions/deposit`
- POST `/banker/transactions/deposit`

### Template
- `app/templates/banker/deposit.html`

### Form Fields
| Field | Label | Required | Note |
|---|---|---|---|
| account_number | Số tài khoản | Yes | Tài khoản nhận tiền |
| amount | Số tiền | Yes | Phải lớn hơn 0 |
| description | Nội dung | No | Ghi chú giao dịch |

### Service
- `transaction_service.deposit(account_number, amount, description, created_by_user_id)`

### Expected UI Behavior

GET:
- Hiển thị form nạp tiền.
- Có nút quay lại danh sách giao dịch.

POST success:
- Hiển thị thông báo nạp tiền thành công.
- Hiển thị mã giao dịch nếu có.
- Có thể redirect về `/banker/transactions`.

POST failure:
- Hiển thị thông báo lỗi.
- Giữ lại dữ liệu người dùng đã nhập.
- Không redirect nếu lỗi validation.

### Future Database Objects
- `sp_Deposit`
- `trg_Audit_Transactions`
- `vw_TransactionHistory`

### Status
- UI: Mock
- Backend Service: Mock
- Database: Pending

### Owner
- TBD
