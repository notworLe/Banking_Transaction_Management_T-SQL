# DATABASE OBJECT CATALOG

# 1. Giới thiệu

## 1.1. Mục đích

Tài liệu này mô tả các đối tượng (Database Objects) được sử dụng trong cơ sở dữ liệu của hệ thống **Banking Transaction Management System**.

Mục tiêu của tài liệu là:

- Giúp thành viên mới nhanh chóng hiểu kiến trúc Database.
- Thống nhất vai trò của từng loại Database Object.
- Là tài liệu tham khảo trong quá trình phát triển và bảo trì hệ thống.
- Hỗ trợ quá trình báo cáo, vấn đáp và nghiệm thu đồ án.

Tài liệu này **không trình bày chi tiết mã nguồn SQL**, mà chỉ tập trung mô tả mục đích, chức năng và vai trò của từng đối tượng trong hệ thống.

---

## 1.2. Phạm vi

Tài liệu bao gồm:

- Kiến trúc Database
- Quy ước thiết kế
- View
- Function
- Stored Procedure
- Trigger
- Index
- Luồng xử lý các nghiệp vụ chính

---

# 2. Kiến trúc Database

## 2.1. Tổng quan

Trong hệ thống này, SQL Server không chỉ đóng vai trò lưu trữ dữ liệu mà còn đảm nhiệm phần lớn nghiệp vụ của hệ thống.

Toàn bộ các thao tác như:

- Đăng nhập
- Chuyển tiền
- Nạp tiền
- Rút tiền
- Mở tài khoản
- Khóa tài khoản

đều được thực hiện thông qua **Stored Procedure**.

Backend không thao tác trực tiếp với các bảng dữ liệu nhằm:

- Đảm bảo tính nhất quán.
- Tăng tính bảo mật.
- Dễ kiểm soát Transaction.
- Hạn chế lỗi do nhiều nơi cùng xử lý nghiệp vụ.

---

## 2.2. Luồng xử lý

```text
React Frontend
        │
        ▼
FastAPI Backend
        │
        ▼
Stored Procedure
        │
 ┌──────┼──────────────┐
 ▼      ▼              ▼
View Function      Trigger
        │
        ▼
    SQL Server
```

### Mô tả

**Frontend**

- Hiển thị giao diện.
- Thu thập dữ liệu từ người dùng.

↓

**Backend**

- Xác thực request.
- Kiểm tra dữ liệu đầu vào.
- Gọi Stored Procedure tương ứng.

↓

**Stored Procedure**

- Kiểm tra điều kiện nghiệp vụ.
- Bắt đầu Transaction.
- Thao tác dữ liệu.
- Commit hoặc Rollback.

↓

**Database Objects**

Các View, Function và Trigger hỗ trợ Stored Procedure trong quá trình xử lý.

---

# 3. Nguyên tắc thiết kế

Trong quá trình phát triển Database, nhóm thống nhất các nguyên tắc sau.

## 3.1. Business Logic

Toàn bộ nghiệp vụ được xử lý trong Stored Procedure.

Ví dụ:

- Chuyển tiền
- Rút tiền
- Nạp tiền
- Mở tài khoản
- Khóa tài khoản

Backend không tự cập nhật dữ liệu bằng câu lệnh UPDATE hoặc INSERT.

---

## 3.2. Transaction

Các nghiệp vụ có thay đổi dữ liệu đều phải thực hiện trong Transaction.

```text
BEGIN TRANSACTION

...

COMMIT

hoặc

ROLLBACK
```

Điều này giúp đảm bảo tính toàn vẹn của dữ liệu khi xảy ra lỗi.

---

## 3.3. Error Handling

Các Stored Procedure cần sử dụng:

- TRY...CATCH
- COMMIT
- ROLLBACK

để xử lý lỗi.

Không để Transaction mở khi Procedure kết thúc.

---

## 3.4. Trigger

Trigger chỉ được sử dụng cho:

- Audit
- Logging
- Validation đơn giản

Không đặt toàn bộ nghiệp vụ trong Trigger để tránh khó kiểm soát luồng xử lý.

---

## 3.5. View

View được sử dụng để:

- Đơn giản hóa truy vấn.
- Ẩn cấu trúc bảng.
- Tái sử dụng các câu SELECT.

View không chứa nghiệp vụ.

---

## 3.6. Function

Function dùng cho:

- Tính toán.
- Kiểm tra điều kiện.
- Trả về dữ liệu.

Function không cập nhật dữ liệu.

---

# 4. Database Objects

## 4.1. View

### Định nghĩa

View là một bảng ảo (Virtual Table) được tạo từ một hoặc nhiều câu lệnh SELECT.

View không lưu dữ liệu vật lý mà chỉ lưu câu truy vấn.

Mỗi lần truy cập View, SQL Server sẽ thực thi lại câu truy vấn tương ứng để trả về kết quả.

### Vai trò

Trong dự án, View được sử dụng để:

- Tổng hợp dữ liệu từ nhiều bảng.
- Giảm độ phức tạp của câu lệnh SELECT.
- Hạn chế việc Backend truy cập trực tiếp vào bảng.
- Chuẩn hóa dữ liệu đầu ra.

### Quy tắc sử dụng

- Chỉ dùng cho mục đích đọc dữ liệu.
- Không chứa Business Logic.
- Không thay thế Stored Procedure.

### Các View tiêu biểu

---

#### vw_CustomerAccounts

**Chức năng**

Trả về danh sách các tài khoản thuộc một khách hàng.

**Thông tin hiển thị**

- Mã khách hàng
- Số tài khoản
- Loại tài khoản
- Số dư
- Trạng thái

**Đối tượng sử dụng**

- Customer
- Banker

---

#### vw_TransactionHistory

**Chức năng**

Hiển thị lịch sử giao dịch của tài khoản.

**Thông tin hiển thị**

- Thời gian giao dịch
- Loại giao dịch
- Số tiền
- Nội dung
- Trạng thái

**Đối tượng sử dụng**

- Customer
- Banker

---

#### vw_DailyTransferSummary

**Chức năng**

Tổng hợp số tiền chuyển theo ngày.

View này được sử dụng để:

- Kiểm tra hạn mức chuyển tiền.
- Thống kê giao dịch.
- Hỗ trợ demo Phantom Read.

---

## 4.2. Function

### Định nghĩa

Function là đối tượng dùng để thực hiện các phép tính hoặc trả về dữ liệu.

Khác với Stored Procedure, Function không dùng để thay đổi dữ liệu trong hệ thống.

### Vai trò

Trong dự án, Function được sử dụng để:

- Kiểm tra điều kiện.
- Tính toán.
- Tái sử dụng các đoạn logic đơn giản.

### Phân loại

Hệ thống sử dụng hai loại Function:

- Scalar Function
- Table-valued Function

### 4.2.1. Scalar Function

Scalar Function trả về duy nhất một giá trị sau khi thực hiện tính toán hoặc kiểm tra điều kiện.

Trong dự án, Scalar Function chủ yếu được sử dụng để hỗ trợ Stored Procedure thay vì được gọi trực tiếp từ Backend.

---

#### fn_GetBalance

**Chức năng**

Trả về số dư hiện tại của một tài khoản.

**Đầu vào**

- AccountId

**Đầu ra**

- Balance

**Được sử dụng trong**

- sp_Deposit
- sp_Withdraw
- sp_Transfer

---

#### fn_IsAccountOwner

**Chức năng**

Kiểm tra một tài khoản có thuộc quyền sở hữu của người dùng đang đăng nhập hay không.

Function này giúp đảm bảo người dùng chỉ có thể thao tác trên tài khoản của chính mình.

**Đầu vào**

- UserId
- AccountId

**Đầu ra**

- 1: Có quyền
- 0: Không có quyền

**Được sử dụng trong**

- sp_Transfer
- sp_Withdraw
- sp_GetBalance

---

### 4.2.2. Table-valued Function

Table-valued Function trả về một tập kết quả (Result Set), có thể sử dụng tương tự như một bảng trong câu lệnh SELECT.

---

#### fn_GetCustomerTransactions

**Chức năng**

Trả về toàn bộ lịch sử giao dịch của một khách hàng.

**Thông tin trả về**

- TransactionId
- TransactionType
- Amount
- CreatedAt
- Description

**Được sử dụng trong**

- Tra cứu lịch sử giao dịch
- Báo cáo
- Thống kê

---

#### fn_GetAccountsByCustomer

**Chức năng**

Trả về danh sách tất cả tài khoản thuộc một khách hàng.

**Thông tin trả về**

- Account Number
- Account Type
- Balance
- Status

---

## 4.3. Stored Procedure

### Định nghĩa

Stored Procedure là đối tượng quan trọng nhất trong hệ thống.

Toàn bộ nghiệp vụ xử lý dữ liệu đều được triển khai tại đây nhằm đảm bảo tính nhất quán, bảo mật và dễ kiểm soát Transaction.

Backend chỉ gọi Stored Procedure và nhận kết quả trả về, không thực hiện trực tiếp các thao tác INSERT, UPDATE hoặc DELETE.

---

### Vai trò

Stored Procedure chịu trách nhiệm:

- Kiểm tra dữ liệu đầu vào.
- Kiểm tra quyền truy cập.
- Kiểm tra điều kiện nghiệp vụ.
- Thực hiện Transaction.
- Commit hoặc Rollback.
- Trả kết quả về Backend.

---

### Phân nhóm Stored Procedure

Hệ thống chia Stored Procedure thành ba nhóm chính.

- Authentication
- Customer
- Banker

Trong tương lai có thể mở rộng thêm nhóm Admin hoặc Reporting.

---

### Authentication

---

#### sp_LoginUser

**Mục đích**

Xác thực người dùng trước khi sử dụng hệ thống.

**Luồng xử lý**

1. Kiểm tra Username.
2. Kiểm tra Password.
3. Kiểm tra trạng thái tài khoản.
4. Trả thông tin người dùng nếu đăng nhập thành công.

---

### Customer

---

#### sp_Deposit

**Mục đích**

Thực hiện nghiệp vụ nạp tiền vào tài khoản.

**Luồng xử lý**

1. Kiểm tra tài khoản tồn tại.
2. Kiểm tra số tiền hợp lệ (>0).
3. BEGIN TRANSACTION.
4. Cập nhật số dư.
5. Ghi lịch sử giao dịch.
6. COMMIT hoặc ROLLBACK.

---

#### sp_Withdraw

**Mục đích**

Thực hiện nghiệp vụ rút tiền.

**Luồng xử lý**

1. Kiểm tra tài khoản.
2. Kiểm tra quyền sở hữu.
3. Kiểm tra số dư.
4. BEGIN TRANSACTION.
5. Trừ số dư.
6. Ghi lịch sử giao dịch.
7. COMMIT hoặc ROLLBACK.

---

#### sp_Transfer

**Mục đích**

Thực hiện chuyển tiền giữa hai tài khoản.

Đây là Stored Procedure quan trọng nhất của hệ thống vì liên quan đến nhiều bước kiểm tra và yêu cầu đảm bảo tính toàn vẹn dữ liệu.

**Luồng xử lý**

1. Kiểm tra tài khoản nguồn.
2. Kiểm tra tài khoản nhận.
3. Không cho phép chuyển cùng một tài khoản.
4. Kiểm tra quyền sở hữu tài khoản nguồn.
5. Kiểm tra trạng thái hai tài khoản.
6. Kiểm tra số dư.
7. BEGIN TRANSACTION.
8. Trừ tiền tài khoản nguồn.
9. Cộng tiền tài khoản nhận.
10. Ghi lịch sử giao dịch.
11. COMMIT.
12. Nếu có lỗi thì ROLLBACK.

---

#### sp_GetTransactionHistory

**Mục đích**

Trả về lịch sử giao dịch của khách hàng.

Procedure này chủ yếu thực hiện truy vấn dữ liệu, không thay đổi dữ liệu.

---

### Banker

---

#### sp_OpenBankAccount

**Mục đích**

Mở tài khoản mới cho khách hàng.

**Luồng xử lý**

1. Kiểm tra khách hàng.
2. Sinh số tài khoản.
3. Tạo tài khoản.
4. Khởi tạo số dư.
5. COMMIT.

---

#### sp_LockAccount

**Mục đích**

Khóa tài khoản.

Sau khi khóa, khách hàng không thể thực hiện giao dịch.

---

#### sp_UnlockAccount

**Mục đích**

Mở khóa tài khoản đã bị khóa.

---

## 4.4. Trigger

### Định nghĩa

Trigger là đoạn mã được SQL Server tự động thực thi khi xảy ra sự kiện INSERT, UPDATE hoặc DELETE trên bảng dữ liệu.

Trong dự án, Trigger chỉ được sử dụng để hỗ trợ Stored Procedure, không chứa toàn bộ Business Logic.

---

### Vai trò

- Ghi Audit Log.
- Kiểm tra điều kiện đơn giản.
- Theo dõi thay đổi dữ liệu.

---

### Các Trigger tiêu biểu

---

#### trg_Audit_Transactions

**Chức năng**

Ghi nhận mọi thay đổi trên bảng Transactions để phục vụ kiểm tra và truy vết.

---

#### trg_Audit_BankAccounts

**Chức năng**

Theo dõi các thay đổi liên quan đến tài khoản ngân hàng.

---

#### trg_PreventNegativeBalance

**Chức năng**

Kiểm tra và ngăn chặn các trường hợp số dư nhỏ hơn 0 nếu có thao tác cập nhật trực tiếp ngoài Stored Procedure.

---

## 4.5. Index

### Định nghĩa

Index là cấu trúc dữ liệu giúp SQL Server tìm kiếm dữ liệu nhanh hơn mà không cần quét toàn bộ bảng.

Việc xây dựng Index hợp lý giúp cải thiện đáng kể hiệu năng của hệ thống.

---

### Các Index tiêu biểu

---

#### IX_BankAccounts_AccountNumber

**Mục đích**

Tăng tốc tìm kiếm theo số tài khoản.

---

#### IX_Transactions_CreatedAt

**Mục đích**

Tăng tốc truy vấn lịch sử giao dịch theo thời gian.

---

#### IX_Transactions_DailyTransfer

**Mục đích**

Hỗ trợ kiểm tra hạn mức chuyển tiền trong ngày và phục vụ demo Phantom Read.

# 5. Luồng xử lý nghiệp vụ

Phần này mô tả tổng quan các bước xử lý của những nghiệp vụ chính trong hệ thống. Các luồng dưới đây không đi vào chi tiết mã nguồn SQL mà tập trung vào trình tự xử lý nghiệp vụ.

---

## 5.1. Đăng nhập

**Mục đích**

Xác thực người dùng trước khi truy cập hệ thống.

### Luồng xử lý

```text
Người dùng nhập Username và Password
                │
                ▼
Kiểm tra Username tồn tại
                │
                ▼
Kiểm tra Password
                │
                ▼
Kiểm tra trạng thái tài khoản
                │
                ▼
Đăng nhập thành công
```

**Stored Procedure**

- sp_LoginUser

---

## 5.2. Nạp tiền

**Mục đích**

Tăng số dư của một tài khoản ngân hàng.

### Luồng xử lý

```text
Kiểm tra tài khoản
        │
Kiểm tra số tiền hợp lệ
        │
BEGIN TRANSACTION
        │
Cập nhật Balance
        │
Ghi Transaction
        │
COMMIT
```

**Stored Procedure**

- sp_Deposit

---

## 5.3. Rút tiền

**Mục đích**

Rút tiền từ tài khoản của khách hàng.

### Luồng xử lý

```text
Kiểm tra tài khoản
        │
Kiểm tra quyền sở hữu
        │
Kiểm tra trạng thái tài khoản
        │
Kiểm tra số dư
        │
BEGIN TRANSACTION
        │
Trừ số dư
        │
Ghi Transaction
        │
COMMIT
```

**Stored Procedure**

- sp_Withdraw

---

## 5.4. Chuyển tiền

**Mục đích**

Chuyển tiền giữa hai tài khoản trong cùng hệ thống.

Đây là nghiệp vụ quan trọng nhất của hệ thống vì liên quan đến nhiều bước kiểm tra và yêu cầu đảm bảo tính toàn vẹn dữ liệu.

### Luồng xử lý

```text
Kiểm tra tài khoản nguồn
        │
Kiểm tra tài khoản nhận
        │
Kiểm tra quyền sở hữu
        │
Kiểm tra trạng thái hai tài khoản
        │
Kiểm tra số dư
        │
BEGIN TRANSACTION
        │
Trừ tiền tài khoản nguồn
        │
Cộng tiền tài khoản nhận
        │
Ghi Transaction
        │
COMMIT
```

**Stored Procedure**

- sp_Transfer

---

## 5.5. Mở tài khoản

**Mục đích**

Tạo tài khoản ngân hàng mới cho khách hàng.

### Luồng xử lý

```text
Kiểm tra khách hàng
        │
Sinh số tài khoản
        │
Tạo tài khoản
        │
Khởi tạo số dư
        │
COMMIT
```

**Stored Procedure**

- sp_OpenBankAccount

---

## 5.6. Khóa tài khoản

**Mục đích**

Ngăn tài khoản thực hiện các giao dịch cho đến khi được mở khóa.

### Luồng xử lý

```text
Kiểm tra tài khoản
        │
Cập nhật trạng thái
        │
Ghi Audit Log
        │
COMMIT
```

**Stored Procedure**

- sp_LockAccount

---

# 6. Quy ước đặt tên

Để thống nhất trong toàn bộ dự án, các Database Object được đặt tên theo quy ước sau.

| Loại | Prefix | Ví dụ |
|-------|--------|--------|
| View | vw_ | vw_CustomerAccounts |
| Scalar Function | fn_ | fn_GetBalance |
| Table-valued Function | fn_ | fn_GetCustomerTransactions |
| Stored Procedure | sp_ | sp_Transfer |
| Trigger | trg_ | trg_Audit_Transactions |
| Index | IX_ | IX_BankAccounts_AccountNumber |

### Quy tắc chung

- Tên sử dụng tiếng Anh.
- Sử dụng PascalCase sau tiền tố.
- Tên phản ánh đúng chức năng của đối tượng.
- Tránh viết tắt khó hiểu.
- Mỗi Stored Procedure chỉ thực hiện một nghiệp vụ chính.

---

# 7. Nguyên tắc thiết kế Database

Trong quá trình phát triển hệ thống, nhóm thống nhất các nguyên tắc sau.

## 7.1. Business Logic

- Business Logic được đặt trong Stored Procedure.
- Backend không thao tác trực tiếp với bảng dữ liệu.
- Hạn chế viết nghiệp vụ ở nhiều nơi.

---

## 7.2. Transaction

Các nghiệp vụ thay đổi dữ liệu đều phải thực hiện trong Transaction.

```sql
BEGIN TRANSACTION

...

COMMIT

-- hoặc

ROLLBACK
```

Điều này giúp đảm bảo tính toàn vẹn dữ liệu khi xảy ra lỗi.

---

## 7.3. Error Handling

Các Stored Procedure cần sử dụng:

- TRY...CATCH
- COMMIT
- ROLLBACK

để đảm bảo Transaction luôn kết thúc đúng cách.

---

## 7.4. Trigger

Trigger chỉ nên sử dụng cho:

- Audit
- Logging
- Validation đơn giản

Không sử dụng Trigger để xử lý toàn bộ nghiệp vụ.

---

## 7.5. View

View chỉ phục vụ mục đích đọc dữ liệu.

Không sử dụng View để thay thế Stored Procedure.

---

## 7.6. Function

Function dùng cho:

- Tính toán
- Kiểm tra điều kiện
- Trả về dữ liệu

Function không cập nhật dữ liệu.

---

## 7.7. Hiệu năng

Để đảm bảo hiệu năng của hệ thống:

- Tạo Index cho các cột thường xuyên tìm kiếm.
- Hạn chế sử dụng `SELECT *`.
- Chỉ trả về các cột cần thiết.
- Thiết kế Stored Procedure theo hướng tái sử dụng.
- Thực hiện kiểm tra dữ liệu trước khi cập nhật.

---

## 7.8. Bảo mật

- Người dùng chỉ được thao tác trên tài khoản thuộc quyền sở hữu của mình.
- Toàn bộ kiểm tra quyền được thực hiện trong Stored Procedure.
- Backend không thực hiện truy vấn trực tiếp vào các bảng dữ liệu nghiệp vụ.

---

# 8. Kết luận

Hệ thống Banking Transaction Management được thiết kế theo hướng tập trung nghiệp vụ tại tầng cơ sở dữ liệu nhằm đảm bảo tính nhất quán, bảo mật và khả năng kiểm soát giao dịch.

Các đối tượng như View, Function, Stored Procedure, Trigger và Index được phân chia rõ ràng về vai trò, giúp hệ thống dễ bảo trì, dễ mở rộng và thuận tiện cho việc phát triển các chức năng mới trong tương lai.

Tài liệu này là tài liệu tham khảo chính về kiến trúc Database của dự án và sẽ được cập nhật khi có thêm Database Object hoặc thay đổi về thiết kế.