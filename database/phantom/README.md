# Phantom Read Demo - Daily Transfer Limit

## 1. Mục tiêu

Thư mục này dùng để demo lỗi **Phantom Read** trong SQL Server thông qua kịch bản nghiệp vụ ngân hàng:

> Một tài khoản chỉ được chuyển tối đa **100.000.000 VND/ngày**.
> Ban đầu tài khoản đã chuyển **80.000.000 VND** trong ngày.
> Hai transaction chạy đồng thời, mỗi transaction muốn chuyển thêm **15.000.000 VND**.

Nếu xử lý sai concurrency, cả hai transaction đều đọc tổng cũ là `80.000.000`, sau đó cùng insert giao dịch thành công, làm tổng cuối thành:

```text
80.000.000 + 15.000.000 + 15.000.000 = 110.000.000
```

Kết quả này vượt hạn mức `100.000.000`, chứng minh lỗi phantom/race trên điều kiện tổng hợp `SUM(Amount)`.

---

## 2. Các file trong demo

```text
database/phantom/
├── 001_create_demo_logs.sql
├── 002_phantom_limit_bad.sql
├── 003_phantom_limit_fix.sql
├── StepDemo.sql
├── Tap01.sql
├── Tap02.sql
└── README.md
```

### `001_create_demo_logs.sql`

Tạo các object phục vụ demo:

* `Demo_Logs`: lưu timeline các hành động của transaction.
* `sp_Demo_Log`: procedure ghi log.
* `IX_DemoLogs_DemoName_ActionTime`: index hỗ trợ xem log theo thời gian.
* `IX_Transactions_DailyLimitDemo`: index hỗ trợ truy vấn/range lock cho demo.
* `sp_Demo_Phantom_Limit_Reset`: reset dữ liệu demo về trạng thái ban đầu.

### `002_phantom_limit_bad.sql`

Tạo procedure lỗi:

```sql
sp_Demo_Phantom_Limit_Bad_Transfer
```

Procedure này dùng isolation mặc định, đọc tổng tiền đã chuyển trong ngày, chờ bằng `WAITFOR DELAY`, rồi insert giao dịch nếu tổng cũ vẫn nằm trong hạn mức.

Khi chạy đồng thời hai session, procedure này có thể làm tổng tiền chuyển trong ngày vượt hạn mức.

### `003_phantom_limit_fix.sql`

Tạo procedure đã sửa:

```sql
sp_Demo_Phantom_Limit_Fix_Transfer
```

Procedure này dùng:

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
```

và lock hint:

```sql
WITH (UPDLOCK, HOLDLOCK)
```

để ngăn transaction khác insert thêm dòng mới vào cùng vùng dữ liệu đang được kiểm tra.

### `StepDemo.sql, Tap01.sql, Tap02.sql`
code chạy demo

---

## 3. Cách chạy setup

Trước tiên cần chạy file tạo database/schema/seed chính của project, sau đó chạy các file demo theo thứ tự:

```text
1. database/phantom/001_create_demo_logs.sql
2. database/phantom/002_phantom_limit_bad.sql
3. database/phantom/003_phantom_limit_fix.sql
```
---

## 4. Reset dữ liệu demo

Trước mỗi lần test, chạy:

```sql
USE banking_transaction;
GO

EXEC dbo.sp_Demo_Phantom_Limit_Reset;
GO
```

Sau đó kiểm tra baseline:

```sql
USE banking_transaction;
GO

DECLARE @StartOfDay DATETIME2(3) =
    CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

DECLARE @EndOfDay DATETIME2(3) =
    DATEADD(DAY, 1, @StartOfDay);

SELECT
    SUM(Amount) AS TodayTotal
FROM dbo.Transactions
WHERE Type = 'transfer'
  AND Status = 'success'
  AND CreatedAt >= @StartOfDay
  AND CreatedAt < @EndOfDay
  AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';
```

Kết quả mong muốn:

```text
TodayTotal = 80000000
```

---

## 5. Test bản lỗi `PHANTOM_LIMIT_BAD`

Cần mở **2 query window khác nhau** trong VS Code để tạo 2 session SQL Server riêng.

Kiểm tra SPID:

```sql
SELECT @@SPID AS CurrentSessionId;
```

Hai tab phải có `SPID` khác nhau.

### Bước 1: lấy giờ hẹn chạy

Chạy:

```sql
SELECT 
    CONVERT(VARCHAR(8), DATEADD(SECOND, 30, SYSDATETIME()), 108) AS StartAt;
```

Ví dụ kết quả:

```text
10:15:30
```

Dùng cùng một thời điểm này cho cả 2 tab.

### Tab A

```sql
USE banking_transaction;
GO

WAITFOR TIME '10:15:30';

EXEC dbo.sp_Demo_Phantom_Limit_Bad_Transfer
    @Delay = '00:00:08';
GO
```

### Tab B

```sql
USE banking_transaction;
GO

WAITFOR TIME '10:15:30';

EXEC dbo.sp_Demo_Phantom_Limit_Bad_Transfer
    @Delay = '00:00:02';
GO
```

### Xem log bản lỗi

```sql
USE banking_transaction;
GO

SELECT
    LogId,
    DemoName,
    SessionId,
    ActionTime,
    Message
FROM dbo.Demo_Logs
WHERE DemoName = N'PHANTOM_LIMIT_BAD'
ORDER BY ActionTime, LogId;
```

### Kiểm tra tổng cuối

```sql
USE banking_transaction;
GO

DECLARE @StartOfDay DATETIME2(3) =
    CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

DECLARE @EndOfDay DATETIME2(3) =
    DATEADD(DAY, 1, @StartOfDay);

SELECT
    SUM(Amount) AS FinalTodayTotal
FROM dbo.Transactions
WHERE Type = 'transfer'
  AND Status = 'success'
  AND CreatedAt >= @StartOfDay
  AND CreatedAt < @EndOfDay
  AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';
```

Kết quả mong muốn của bản lỗi:

```text
FinalTodayTotal = 110000000
```

Điều này chứng minh hệ thống đã cho phép vượt hạn mức do hai transaction cùng đọc tổng cũ.

---

## 6. Test bản fix `PHANTOM_LIMIT_FIX`

Reset lại dữ liệu demo:

```sql
USE banking_transaction;
GO

EXEC dbo.sp_Demo_Phantom_Limit_Reset;
GO
```

Lấy giờ hẹn chạy:

```sql
SELECT 
    CONVERT(VARCHAR(8), DATEADD(SECOND, 30, SYSDATETIME()), 108) AS StartAt;
```

### Tab A

```sql
USE banking_transaction;
GO

WAITFOR TIME '10:20:30';

EXEC dbo.sp_Demo_Phantom_Limit_Fix_Transfer
    @Delay = '00:00:08';
GO
```

### Tab B

```sql
USE banking_transaction;
GO

WAITFOR TIME '10:20:30';

EXEC dbo.sp_Demo_Phantom_Limit_Fix_Transfer
    @Delay = '00:00:02';
GO
```

Trong bản fix, một session có thể bị chờ vài giây. Đây là hành vi đúng vì transaction còn lại đang giữ lock.

### Xem log bản fix

```sql
USE banking_transaction;
GO

SELECT
    LogId,
    DemoName,
    SessionId,
    ActionTime,
    Message
FROM dbo.Demo_Logs
WHERE DemoName = N'PHANTOM_LIMIT_FIX'
ORDER BY ActionTime, LogId;
```

### Kiểm tra tổng cuối

```sql
USE banking_transaction;
GO

DECLARE @StartOfDay DATETIME2(3) =
    CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

DECLARE @EndOfDay DATETIME2(3) =
    DATEADD(DAY, 1, @StartOfDay);

SELECT
    SUM(Amount) AS FinalTodayTotal
FROM dbo.Transactions
WHERE Type = 'transfer'
  AND Status = 'success'
  AND CreatedAt >= @StartOfDay
  AND CreatedAt < @EndOfDay
  AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';
```

Kết quả mong muốn của bản fix:

```text
FinalTodayTotal = 95000000
```

Điều này chứng minh chỉ một transaction được insert thêm. Transaction còn lại sau khi chờ lock sẽ đọc lại tổng mới là `95.000.000`, phát hiện nếu thêm `15.000.000` nữa sẽ vượt hạn mức, nên không insert.

---

## 7. So sánh kết quả

| Phiên bản           |  Kết quả cuối | Ý nghĩa                            |
| ------------------- | ------------: | ---------------------------------- |
| `PHANTOM_LIMIT_BAD` | `110.000.000` | Lỗi phantom làm vượt hạn mức       |
| `PHANTOM_LIMIT_FIX` |  `95.000.000` | Fix thành công, không vượt hạn mức |

---

## 8. Giải thích ngắn gọn khi demo

Ở bản lỗi, hai transaction chạy đồng thời và cùng đọc:

```text
TodayTotal = 80.000.000
```

Cả hai đều kết luận:

```text
80.000.000 + 15.000.000 <= 100.000.000
```

nên cả hai đều insert giao dịch mới. Tổng cuối thành `110.000.000`.

Ở bản fix, transaction dùng `SERIALIZABLE` và `UPDLOCK, HOLDLOCK` để khóa vùng dữ liệu đang kiểm tra. Vì vậy transaction thứ hai phải chờ transaction thứ nhất hoàn tất. Sau đó nó đọc được tổng mới là `95.000.000` và từ chối insert thêm.

---

## 9. Lưu ý khi chạy demo

* Phải dùng 2 query window khác nhau.
* Hai query window phải có `@@SPID` khác nhau.
* Nên dùng `WAITFOR TIME` để hai session bắt đầu gần như đồng thời.
* Trước mỗi lần demo phải chạy `sp_Demo_Phantom_Limit_Reset`.
* Bản lỗi đúng khi tổng cuối là `110.000.000`.
* Bản fix đúng khi tổng cuối là `95.000.000`.
* Các transaction demo được đánh dấu bằng `Description LIKE N'PHANTOM_LIMIT_DEMO|%'`.
