# Tài liệu Phân tích Kiến trúc Cơ sở Dữ liệu & Giải pháp Demo Concurrency

Tài liệu này phân tích cấu trúc dữ liệu hiện tại từ file [excer.sql](file:///d:/Banking_Transaction_Management_T-SQL/database/excer.sql), đánh giá khả năng hỗ trợ demo các lỗi tranh chấp đồng thời (Concurrency), đề xuất bảng ghi log chuyên dụng và ánh xạ các API cần thiết cho Frontend.

---

## 1. Trích xuất và giải thích các bảng nghiệp vụ cốt lõi

Dựa trên cấu trúc trong [excer.sql](file:///d:/Banking_Transaction_Management_T-SQL/database/excer.sql), hệ thống được tổ chức thành 8 bảng chính. Dưới đây là giải thích chi tiết và vai trò của từng bảng:

### Nhóm 1: Phân quyền và Người dùng
*   **Roles (Vai trò)**:
    *   *Nhiệm vụ*: Định nghĩa các vai trò truy cập trong hệ thống.
    *   *Các vai trò mặc định*: `Admin` (Quản trị viên), `Banker` (Giao dịch viên), `Customer` (Khách hàng).
*   **Users (Tài khoản đăng nhập)**:
    *   *Nhiệm vụ*: Bảng trung gian quản lý thông tin đăng nhập tập trung (tên đăng nhập, mật khẩu mã hóa, trạng thái hoạt động và thời gian đăng nhập gần nhất) cho cả 3 vai trò.
    *   *Quan hệ*: Mỗi tài khoản liên kết với duy nhất một vai trò (`RoleId`).

### Nhóm 2: Thông tin Đối tượng
*   **Customers (Thông tin Khách hàng)**:
    *   *Nhiệm vụ*: Lưu trữ thông tin cá nhân chi tiết của khách hàng (Họ tên, Email, Số điện thoại, Địa chỉ, Ngày sinh).
    *   *Quan hệ*: Mỗi khách hàng liên kết với duy nhất một tài khoản đăng nhập (`UserId`).
*   **Bankers (Thông tin Nhân viên)**:
    *   *Nhiệm vụ*: Lưu trữ thông tin cá nhân và mã nhân viên (`EmployeeCode`) của giao dịch viên ngân hàng.
    *   *Quan hệ*: Mỗi nhân viên liên kết với duy nhất một tài khoản đăng nhập (`UserId`).

### Nhóm 3: Tài khoản & Giao dịch (Trọng tâm nghiệp vụ)
*   **BankAccounts (Tài khoản Ngân hàng)**:
    *   *Nhiệm vụ*: Lưu trữ thông tin tài khoản tài chính của khách hàng. Chứa thông tin số tài khoản (`AccountNumber`), loại tài khoản (`payment`, `saving`, `debit`), số dư hiện tại (`Balance`) và trạng thái tài khoản (`active`, `locked`, `closed`).
    *   *Quan hệ*: Một khách hàng (`CustomerId`) có thể sở hữu nhiều tài khoản ngân hàng.
    *   *Điểm lưu ý*: Cột `Balance` (Số dư) chính là tài nguyên cốt lõi bị tranh chấp trực tiếp khi thực hiện các kịch bản lỗi Concurrency.
*   **Transactions (Giao dịch tài chính)**:
    *   *Nhiệm vụ*: Ghi nhận mọi giao dịch phát sinh trên hệ thống bao gồm nạp tiền (`deposit`), rút tiền (`withdraw`), và chuyển khoản (`transfer`). Lưu vết tài khoản gửi (`FromBankAccountId`), tài khoản nhận (`ToBankAccountId`), số tiền (`Amount`), trạng thái giao dịch (`pending`, `success`, `failed`), và người thực hiện (`CreatedByUserId`).
    *   *Quan hệ*: Liên kết trực tiếp tới các tài khoản ngân hàng và người dùng tạo giao dịch.

### Nhóm 4: Nhật ký Hệ thống
*   **AuditLogs (Nhật ký Kiểm toán)**:
    *   *Nhiệm vụ*: Lưu lại các hành động quản trị hoặc nghiệp vụ quan trọng của Banker và Admin (ví dụ: khóa tài khoản, tạo nhân viên mới).
*   **LoginLogs (Nhật ký Đăng nhập)**:
    *   *Nhiệm vụ*: Lưu lại lịch sử đăng nhập/đăng xuất, trạng thái thành công/thất bại và địa chỉ IP của người dùng để phục vụ mục đích bảo mật.

---

## 2. Đánh giá Khả năng Lưu vết Demo Concurrency

### Đánh giá cấu trúc hiện tại
Với cấu trúc hiện tại trong DB, hệ thống **CHƯA ĐỦ** khả năng thực hiện lưu vết phục vụ cho việc **demo trực quan** các lỗi Concurrency (Lost Update, Dirty Read, Non-repeatable Read, Phantom Read).

**Lý do**:
1.  **Chỉ lưu trạng thái cuối cùng**: Bảng `Transactions` hay `AuditLogs` chỉ ghi nhận kết quả cuối cùng sau khi một tiến trình hoàn thành. Các lỗi Concurrency xảy ra do sự xen kẽ (interleaving) của các hành động đọc/ghi ở các bước trung gian của hai hay nhiều Transaction chạy đồng thời.
2.  **Thiếu thông tin luồng thực thi**: Hệ thống không lưu vết các thông tin kỹ thuật thấp (low-level) như: Session ID (SPID) của kết nối database, Isolation Level đang áp dụng cho phiên làm việc, thời điểm chính xác (mili-giây) mà truy vấn `SELECT` hay `UPDATE` được thực hiện.
3.  **Không lưu dữ liệu tạm thời**: Để demo trực quan (ví dụ: vẽ biểu đồ Sequence Diagram trên giao diện Frontend chỉ ra luồng A đọc ra giá trị rác trước khi luồng B rollback), hệ thống bắt buộc phải ghi lại các giá trị đọc tạm thời (Dirty Value) tại từng bước nhỏ.

### Đề xuất cấu trúc bảng ghi Log chuyên dụng: `Demo_Logs`

Để hỗ trợ ghi nhận và minh họa từng bước chạy xen kẽ của các giao dịch đồng thời, chúng ta cần bổ sung một bảng lưu vết demo. Bảng này sẽ được mô tả cấu trúc bằng văn bản dưới đây:

*   **LogId**: Kiểu chuỗi định danh duy nhất (UUID/GUID). Khóa chính của bảng.
*   **DemoSessionId**: Kiểu chuỗi định danh (UUID/GUID hoặc Chuỗi ký tự). Dùng để nhóm toàn bộ các dòng log của một lượt bấm chạy thử nghiệm kịch bản demo trên Frontend.
*   **StepNumber**: Kiểu số nguyên (Integer). Ghi nhận số thứ tự bước thực hiện của kịch bản (ví dụ: Bước 1: Giao dịch A đọc số dư; Bước 2: Giao dịch B cập nhật số dư;...).
*   **SessionSpid**: Kiểu số nguyên (Integer). Lưu mã định danh phiên làm việc của database (SPID) để phân biệt kết nối vật lý nào đang thực hiện câu lệnh.
*   **TransactionName**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 50 ký tự). Nhãn để phân biệt các luồng giao dịch đồng thời (ví dụ: `"Giao dịch A"`, `"Giao dịch B"`).
*   **IsolationLevel**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 50 ký tự). Lưu mức độ cô lập đang cấu hình cho giao dịch tại thời điểm đó (ví dụ: `Read Uncommitted`, `Read Committed`, `Repeatable Read`, `Serializable`).
*   **ActionType**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 50 ký tự). Ghi nhận hành động cụ thể đang thực hiện (ví dụ: `BEGIN TRAN`, `SELECT (Read)`, `UPDATE (Write)`, `COMMIT`, `ROLLBACK`, `LOCK_WAIT`, `DEADLOCK`).
*   **TargetAccount**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 20 ký tự). Số tài khoản ngân hàng đang bị tác động trong bước này.
*   **CurrentBalance**: Kiểu số thập phân (Decimal 18, 2). Giá trị số dư tài khoản ghi nhận trực tiếp trong Database ngay trước khi hành động xảy ra.
*   **ValueRead**: Kiểu số thập phân (Decimal 18, 2), cho phép rỗng (NULL). Giá trị số dư mà giao dịch này đọc được (để chứng minh lỗi Dirty Read đọc ra giá trị chưa commit, hoặc Non-repeatable Read đọc ra giá trị khác nhau giữa 2 lần SELECT).
*   **ValueWritten**: Kiểu số thập phân (Decimal 18, 2), cho phép rỗng (NULL). Giá trị số dư mới mà giao dịch cố gắng ghi xuống tài khoản.
*   **ExecutionStatus**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 50 ký tự). Trạng thái thực thi của bước này (ví dụ: `Success` - Thành công, `Blocked` - Đang bị khóa phải chờ, `Error` - Gặp lỗi deadlock/timeout).
*   **ErrorMessage**: Kiểu chuỗi ký tự (NVARCHAR, tối đa 500 ký tự), cho phép rỗng (NULL). Ghi chi tiết lỗi từ hệ quản trị CSDL nếu bước đó bị rollback hoặc lỗi.
*   **LoggedAt**: Kiểu ngày giờ độ chính xác cao (DATETIME2, độ phân giải mili-giây). Ghi nhận thời gian chính xác để sắp xếp thứ tự các sự kiện xảy ra trên trục thời gian (Timeline).

---

## 3. Ánh xạ (Mapping) ra các API cơ bản phục vụ Frontend

Để vận hành một ứng dụng Web Demo Concurrency hoàn chỉnh, Frontend cần tương tác với Backend qua các API được chia làm hai nhóm chính: nhóm API nghiệp vụ thông thường và nhóm API điều khiển demo lỗi.

### Nhóm A: API Nghiệp vụ Giao dịch cơ bản

| Phương thức | Đường dẫn API | Mô tả nghiệp vụ | Dữ liệu đầu vào (Request Body) | Dữ liệu trả về (Response) |
| :--- | :--- | :--- | :--- | :--- |
| **POST** | `/api/auth/login` | Đăng nhập tài khoản | `Username`, `Password` | Token xác thực, Thông tin User & Role |
| **GET** | `/api/accounts` | Danh sách tài khoản của khách hàng | Không có (xác thực qua token) | Mảng chứa danh sách tài khoản (Số tài khoản, Số dư, Trạng thái...) |
| **GET** | `/api/accounts/{id}/balance` | Xem số dư tài khoản trực tiếp | Không có | Số dư hiện tại, Số tài khoản |
| **POST** | `/api/transactions/deposit` | Nạp tiền vào tài khoản | `TargetAccountId`, `Amount`, `Description` | Thông tin giao dịch đã tạo |
| **POST** | `/api/transactions/withdraw` | Rút tiền từ tài khoản | `SourceAccountId`, `Amount`, `Description` | Thông tin giao dịch đã tạo |
| **POST** | `/api/transactions/transfer` | Chuyển khoản từ tài khoản A sang B | `SourceAccountId`, `TargetAccountId`, `Amount`, `Description` | Thông tin giao dịch đã tạo |
| **GET** | `/api/transactions/history` | Lấy lịch sử giao dịch gần đây | Query Params: `AccountId`, `Page`, `Limit` | Danh sách giao dịch của tài khoản |

### Nhóm B: API Điều khiển & Lưu vết phục vụ Demo Concurrency
Nhóm API này giúp Frontend kích hoạt các kịch bản chạy thử nghiệm lỗi và lấy dữ liệu vẽ biểu đồ timeline.

| Phương thức | Đường dẫn API | Mô tả nghiệp vụ | Dữ liệu đầu vào (Request Body) | Dữ liệu trả về (Response) |
| :--- | :--- | :--- | :--- | :--- |
| **POST** | `/api/demo/trigger` | Kích hoạt kịch bản demo đồng thời (Ví dụ: Chạy 2 luồng giao dịch A và B cùng lúc tác động lên một tài khoản) | `ScenarioType` (LostUpdate / DirtyRead / NonRepeatableRead / PhantomRead), `TxA_Isolation`, `TxB_Isolation`, `DelayMiliseconds` (Độ trễ giả lập giữa các bước) | `DemoSessionId` (Mã phiên chạy để truy vấn log) |
| **GET** | `/api/demo/logs` | Lấy danh sách log chi tiết của một phiên chạy để vẽ Sequence Diagram timeline | Query Params: `DemoSessionId` | Mảng chứa các bước log từ bảng `Demo_Logs` đã sắp xếp theo `StepNumber` và `LoggedAt` |
| **POST** | `/api/demo/reset` | Thiết lập lại số dư tài khoản demo về mức mặc định để chuẩn bị cho lượt chạy mới | `AccountId`, `InitialBalance` | Trạng thái reset thành công |
| **GET** | `/api/demo/status` | Kiểm tra xem có phiên demo nào đang chạy ngầm trong Database hay không | Không có | Trạng thái (`idle` / `running`) |
