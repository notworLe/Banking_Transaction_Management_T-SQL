# DATABASE OBJECT CATALOG

# Database Object Overview

Hệ thống quản lý giao dịch ngân hàng được thiết kế theo mô hình phân tầng, trong đó mỗi loại Database Object đảm nhiệm một vai trò riêng biệt nhằm đảm bảo tính rõ ràng, dễ bảo trì và dễ mở rộng.

| Object | Vai trò chính |
|---------|---------------|
| View | Chuẩn hóa và cung cấp dữ liệu phục vụ truy vấn, báo cáo và giao diện người dùng. |
| Function | Thực hiện các xử lý nhỏ, phép tính hoặc kiểm tra có khả năng tái sử dụng. |
| Stored Procedure | Triển khai Business Logic và các quy trình nghiệp vụ chính của hệ thống. |
| Trigger | Tự động xử lý khi dữ liệu thay đổi, chủ yếu dùng cho Audit và Validation. |
| Index | Tối ưu hiệu năng truy vấn và giảm thời gian tìm kiếm dữ liệu. |

---
# 1. Views
## Definition

View là một bảng ảo (Virtual Table) được tạo ra từ kết quả của một hoặc nhiều câu lệnh `SELECT`. Dữ liệu trong View không được lưu trữ riêng mà được truy xuất trực tiếp từ các bảng nguồn mỗi khi View được gọi.

Trong hệ thống quản lý giao dịch ngân hàng, View được sử dụng để chuẩn hóa dữ liệu phục vụ việc hiển thị trên giao diện, báo cáo và tra cứu. View giúp giảm việc lặp lại các câu lệnh JOIN phức tạp, tăng khả năng tái sử dụng và đảm bảo tính nhất quán của dữ liệu trả về.

### Characteristics

- Chỉ phục vụ mục đích truy vấn dữ liệu.
- Không chứa Business Logic.
- Có thể JOIN nhiều bảng.
- Có thể được sử dụng bởi Stored Procedures hoặc trực tiếp từ Backend.
- Không nên thực hiện các phép tính nghiệp vụ phức tạp.

### Typical Use Cases

- Hiển thị danh sách tài khoản khách hàng.
- Hiển thị lịch sử giao dịch.
- Hiển thị báo cáo thống kê.
- Tổng hợp dữ liệu phục vụ Dashboard.

---

Views chỉ phục vụ đọc dữ liệu, không chứa business logic.

---

## 1.1 vw_CustomerAccounts

### Purpose

Hiển thị danh sách tài khoản thuộc về một khách hàng.

Được sử dụng để hiển thị thông tin tài khoản trên giao diện Customer Portal và Banker Portal.

---

### Used By

- Customer Dashboard
- Banker Dashboard

---

### Data Source

- Customers
- BankAccounts

---

### Returned Information

- Customer Name
- Account Number
- Account Type
- Balance
- Status
- Opened Date

---

### Main Processing

1. Đọc thông tin từ Customers.
2. Join với BankAccounts.
3. Chỉ lấy các tài khoản thuộc khách hàng.
4. Chuẩn hóa dữ liệu trả về.
5. Không cập nhật dữ liệu.

---

### Dependencies

Tables

- Customers
- BankAccounts
---

## 1.2 vw_TransactionHistory

### Purpose

Hiển thị lịch sử giao dịch đầy đủ của hệ thống.

---

### Used By

- Customer
- Banker
- Admin

---

### Data Source

- Transactions
- BankAccounts
- Customers

---

### Returned Information

- Transaction Id
- Transaction Time
- From Account
- To Account
- Amount
- Transaction Type
- Status
- Description

---

### Main Processing

1. Đọc Transactions.
2. Join tài khoản nguồn.
3. Join tài khoản nhận.
4. Join Customers.
5. Chuẩn hóa dữ liệu.
6. Trả về dữ liệu chỉ đọc.

---

### Dependencies

Tables

- Transactions
- BankAccounts
- Customers

---

# 2. Functions
## Definition

Function là một đối tượng trong SQL Server dùng để xử lý dữ liệu và trả về một giá trị hoặc một tập dữ liệu. Function thường được sử dụng để tái sử dụng các đoạn xử lý có tính lặp lại, giúp giảm trùng lặp mã nguồn và làm cho Stored Procedure trở nên ngắn gọn, dễ bảo trì hơn.

Trong hệ thống ngân hàng, Function chủ yếu thực hiện các phép tính đơn giản, kiểm tra điều kiện hoặc trả về dữ liệu phục vụ cho Business Logic.

### Function Types

#### Scalar Function

Trả về duy nhất một giá trị.

Ví dụ:

- Số dư tài khoản
- Tuổi khách hàng
- Kiểm tra quyền sở hữu tài khoản

#### Table-Valued Function

Trả về một bảng dữ liệu.

Ví dụ:

- Danh sách giao dịch của khách hàng
- Danh sách tài khoản theo Customer

### Characteristics

- Có thể nhận tham số.
- Có thể được gọi trong SELECT hoặc Stored Procedure.
- Không nên thực hiện cập nhật dữ liệu.
- Chỉ thực hiện xử lý nhỏ, có khả năng tái sử dụng.

### Typical Use Cases

- Kiểm tra quyền sở hữu tài khoản.
- Tính số dư.
- Tính lãi suất.
- Trả về danh sách giao dịch.
---

Functions dùng để xử lý các phép tính hoặc trả về dữ liệu phục vụ Stored Procedures.

---

## 2.1 fn_GetBalance

### Function Type

Scalar Function

---

### Purpose

Lấy số dư hiện tại của một tài khoản.

---

### Input

| Parameter | Description |
|------------|------------|
| AccountId | Mã tài khoản |

---

### Output

Balance (DECIMAL)

---

### Main Processing

1. Kiểm tra AccountId.
2. Đọc Balance.
3. Trả về số dư.
4. Không cập nhật dữ liệu.

---

### Used By

- sp_CustomerTransfer
- sp_Deposit
- sp_Withdraw

---

### Dependencies

Tables

- BankAccounts

---

## 2.2 fn_IsAccountOwner

### Function Type

Scalar Function

---

### Purpose

Kiểm tra tài khoản có thuộc quyền sở hữu của User hay không.

---

### Input

| Parameter | Description |
|------------|------------|
| UserId | Người dùng |
| AccountId | Tài khoản |

---

### Output

BIT

---

### Main Processing

1. Tìm Customer từ User.
2. Join BankAccounts.
3. So sánh quyền sở hữu.
4. Trả TRUE hoặc FALSE.

---

### Used By

- sp_CustomerTransfer
- sp_Withdraw
- sp_Deposit

---

### Dependencies

Tables

- Users
- Customers
- BankAccounts

---

# 3. Stored Procedures

## Definition

Stored Procedure là tập hợp các câu lệnh SQL được lưu trữ sẵn trong cơ sở dữ liệu nhằm thực hiện một chức năng hoặc một quy trình nghiệp vụ hoàn chỉnh.

Trong hệ thống quản lý giao dịch ngân hàng, Stored Procedure là nơi triển khai phần lớn Business Logic. Mọi thao tác thêm, sửa, xóa dữ liệu quan trọng đều được thực hiện thông qua Stored Procedure để đảm bảo tính nhất quán, bảo mật và tuân thủ nguyên tắc ACID.

### Characteristics

- Có thể nhận nhiều tham số đầu vào.
- Có thể trả về nhiều kết quả.
- Có thể sử dụng Transaction.
- Có thể gọi Function.
- Có thể gọi Stored Procedure khác.
- Có thể xử lý lỗi bằng TRY...CATCH.

### Typical Processing Flow

Một Stored Procedure nghiệp vụ thường bao gồm các bước:

1. Kiểm tra dữ liệu đầu vào.
2. Kiểm tra quyền thực hiện.
3. Kiểm tra dữ liệu nghiệp vụ.
4. Bắt đầu Transaction.
5. Thực hiện xử lý dữ liệu.
6. Ghi Audit Log.
7. Commit Transaction.
8. Rollback nếu xảy ra lỗi.

### Typical Use Cases

- Đăng nhập.
- Chuyển tiền.
- Nạp tiền.
- Rút tiền.
- Mở tài khoản.
- Khóa tài khoản.
---

Stored Procedures chứa business logic chính của hệ thống.

---

## 3.1 sp_CustomerTransfer

### Purpose

Thực hiện giao dịch chuyển tiền giữa hai tài khoản.

---

### Used By

- Customer Portal

---

### Input

| Parameter | Description |
|------------|------------|
| UserId | Người thực hiện |
| FromAccount | Tài khoản nguồn |
| ToAccount | Tài khoản nhận |
| Amount | Số tiền |
| Description | Nội dung |

---

### Output

- TransactionId
- Success / Failed
- Error Message

---

### Main Processing

1. Begin Transaction.
2. Kiểm tra User.
3. Kiểm tra tài khoản nguồn.
4. Kiểm tra tài khoản nhận.
5. Kiểm tra quyền sở hữu.
6. Kiểm tra số dư.
7. Kiểm tra hạn mức.
8. Trừ tiền.
9. Cộng tiền.
10. Ghi Transactions.
11. Ghi AuditLogs.
12. Commit.
13. Rollback nếu có lỗi.

---

### Dependencies

Tables

- Users
- Customers
- BankAccounts
- Transactions
- AuditLogs

Functions

- fn_GetBalance
- fn_IsAccountOwner

Triggers

- trg_Audit_Transactions

Views

- vw_TransactionHistory

---

## 3.2 sp_OpenBankAccount

### Purpose

Mở tài khoản mới cho khách hàng.

---

### Used By

- Banker

---

### Input

- CustomerId
- AccountType
- InitialBalance

---

### Output

- AccountId

---

### Main Processing

1. Begin Transaction.
2. Kiểm tra Customer.
3. Sinh Account Number.
4. Kiểm tra trùng.
5. Tạo tài khoản.
6. Ghi Audit.
7. Commit.
8. Rollback nếu lỗi.

---

### Dependencies

Tables

- Customers
- BankAccounts
- AuditLogs

Triggers

- trg_Audit_BankAccounts

---

# 4. Triggers
## Definition

Trigger là một chương trình đặc biệt được SQL Server tự động kích hoạt khi xảy ra một sự kiện INSERT, UPDATE hoặc DELETE trên một bảng hoặc View.

Khác với Stored Procedure, Trigger không được gọi trực tiếp từ ứng dụng mà được thực thi hoàn toàn tự động khi dữ liệu thay đổi.

Trong hệ thống ngân hàng, Trigger chủ yếu được sử dụng để ghi Audit Log hoặc thực hiện các kiểm tra dữ liệu đơn giản nhằm đảm bảo tính toàn vẹn của dữ liệu.

### Trigger Types

#### AFTER Trigger

Được thực thi sau khi thao tác INSERT, UPDATE hoặc DELETE thành công.

Thường dùng để:

- Ghi Audit Log.
- Gửi Notification.
- Đồng bộ dữ liệu.

#### INSTEAD OF Trigger

Thay thế hoàn toàn thao tác INSERT, UPDATE hoặc DELETE.

Thường dùng để:

- Kiểm tra dữ liệu.
- Chặn thao tác không hợp lệ.

### Characteristics

- Tự động thực thi.
- Không được gọi trực tiếp.
- Không nên chứa Business Logic phức tạp.
- Chỉ nên xử lý các công việc ngắn và đơn giản.

### Typical Use Cases

- Ghi lịch sử thay đổi dữ liệu.
- Kiểm tra dữ liệu hợp lệ.
- Ngăn số dư âm.
- Ghi log đăng nhập.
---

Trigger chỉ dùng cho Audit và Validation đơn giản.

---

## 4.1 trg_Audit_Transactions

### Trigger Type

AFTER INSERT

---

### Purpose

Ghi Audit Log sau khi phát sinh giao dịch.

---

### Fired When

Có Transaction mới.

---

### Main Processing

1. Đọc inserted.
2. Chuẩn hóa dữ liệu.
3. Ghi AuditLogs.
4. Lưu thời gian.
5. Lưu người thực hiện.

---

### Dependencies

Tables

- Transactions
- AuditLogs

---

## 4.2 trg_PreventNegativeBalance

### Trigger Type

INSTEAD OF UPDATE hoặc AFTER UPDATE (tùy thiết kế)

---

### Purpose

Ngăn số dư tài khoản âm.

---

### Fired When

Có cập nhật Balance.

---

### Main Processing

1. Đọc inserted.
2. Kiểm tra Balance.
3. Nếu Balance < 0.
4. Phát sinh lỗi.
5. Rollback Transaction.

---

# 5. Indexes
## Definition

Index là cấu trúc dữ liệu đặc biệt giúp SQL Server tìm kiếm dữ liệu nhanh hơn mà không cần quét toàn bộ bảng (Full Table Scan).

Trong hệ thống ngân hàng, Index được sử dụng để tối ưu các truy vấn thường xuyên như tìm kiếm tài khoản, xem lịch sử giao dịch hoặc lập báo cáo.

Việc thiết kế Index hợp lý giúp giảm đáng kể thời gian truy vấn, đặc biệt đối với các bảng có số lượng bản ghi lớn.

### Characteristics

- Tăng tốc truy vấn.
- Chiếm thêm không gian lưu trữ.
- Làm chậm một phần thao tác INSERT, UPDATE và DELETE do phải cập nhật Index.
- Cần được thiết kế dựa trên các truy vấn thực tế.

### Typical Use Cases

- Tìm kiếm theo AccountNumber.
- Tra cứu giao dịch theo thời gian.
- Tìm kiếm khách hàng theo CCCD hoặc Email.
- Thống kê giao dịch theo ngày hoặc tháng.

---

## 5.1 IX_BankAccounts_AccountNumber

### Purpose

Tăng tốc tìm kiếm tài khoản.

---

### Applied On

BankAccounts

---

### Columns

AccountNumber

---

### Expected Queries

- Đăng nhập Internet Banking
- Chuyển khoản
- Tìm kiếm tài khoản

---

### Benefits

- Giảm Full Scan.
- Tăng tốc truy vấn.

---

## 5.2 IX_Transactions_CreatedAt

### Purpose

Tăng tốc truy vấn lịch sử giao dịch.

---

### Applied On

Transactions

---

### Columns

CreatedAt

---

### Expected Queries

- Lịch sử giao dịch
- Báo cáo theo ngày
- Báo cáo theo tháng

---

### Benefits

- Hỗ trợ ORDER BY.
- Hỗ trợ lọc theo thời gian.
- Giảm thời gian truy vấn.

---

# 6. Database Design Notes

## Design Principles

- Business Logic được triển khai chủ yếu trong Stored Procedures.
- Views chỉ phục vụ truy vấn dữ liệu.
- Functions chỉ thực hiện xử lý nhỏ và tái sử dụng.
- Trigger chỉ dùng cho Audit và Validation đơn giản.
- Không đặt Business Logic phức tạp trong Trigger.
- Mọi giao dịch tài chính phải được bao bọc trong Transaction.
- Toàn bộ thao tác thay đổi dữ liệu phải thông qua Stored Procedures.
---