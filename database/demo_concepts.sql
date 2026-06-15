-- ============================================================
-- BANKING SYSTEM - T-SQL DEMO: CÁC KHÁI NIỆM DBMS
-- Chạy từng SECTION riêng lẻ trên SSMS
-- Yêu cầu: excer.sql đã được chạy trước
-- ============================================================

-- ⚙ SETUP: Bật SNAPSHOT ISOLATION (chỉ cần chạy 1 lần)
USE master;
GO
ALTER DATABASE banking_transaction SET ALLOW_SNAPSHOT_ISOLATION ON;
ALTER DATABASE banking_transaction SET READ_COMMITTED_SNAPSHOT ON;
GO
USE banking_transaction;
GO

-- ============================================================
-- SECTION 1: TRANSACTION & ACID
-- ============================================================
-- ACID = Atomicity, Consistency, Isolation, Durability
--
-- DEMO: Chuyển tiền 2,000,000đ từ TK A sang TK B
-- Atomicity: nếu 1 bước lỗi → toàn bộ rollback
-- ============================================================

PRINT '=== SECTION 1: ACID Transaction ===';

-- Xem số dư TRƯỚC
SELECT AccountNumber, Balance FROM BankAccounts
WHERE AccountNumber IN ('9704001000001','9704002000001');

BEGIN TRY
    BEGIN TRANSACTION;

        -- Bước 1: Trừ tiền tài khoản nguồn
        UPDATE BankAccounts
        SET    Balance = Balance - 2000000
        WHERE  AccountNumber = '9704001000001'
        AND    Balance >= 2000000;   -- Consistency: không cho âm

        IF @@ROWCOUNT = 0
            THROW 50001, N'Số dư không đủ!', 1;

        -- Bước 2: Cộng tiền tài khoản đích
        UPDATE BankAccounts
        SET    Balance = Balance + 2000000
        WHERE  AccountNumber = '9704002000001';

        -- Ghi log giao dịch
        INSERT INTO Transactions
            (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        SELECT fa.BankAccountId, ta.BankAccountId,
               (SELECT TOP 1 UserId FROM Users WHERE Username='nguyen_van_a'),
               'transfer', 2000000, 'success', N'Demo ACID Transfer'
        FROM   BankAccounts fa CROSS JOIN BankAccounts ta
        WHERE  fa.AccountNumber='9704001000001'
        AND    ta.AccountNumber='9704002000001';

    COMMIT TRANSACTION;
    PRINT N'✅ Commit thành công - Durability: dữ liệu đã được lưu vĩnh viễn';

END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;  -- Atomicity: hoàn tác tất cả
    PRINT N'❌ Rollback: ' + ERROR_MESSAGE();
END CATCH;

-- Xem số dư SAU
SELECT AccountNumber, Balance FROM BankAccounts
WHERE AccountNumber IN ('9704001000001','9704002000001');
GO


-- ============================================================
-- SECTION 2: SAVEPOINT (điểm lưu tạm trong transaction)
-- ============================================================
PRINT '=== SECTION 2: SAVEPOINT ===';

BEGIN TRANSACTION;

    -- Nạp tiền tài khoản A
    UPDATE BankAccounts SET Balance = Balance + 500000
    WHERE  AccountNumber = '9704001000001';
    PRINT N'Nạp 500k xong';

    SAVE TRANSACTION SavePoint1;   -- << Đánh dấu điểm quay lại

    -- Thao tác có thể sai: rút quá nhiều
    UPDATE BankAccounts SET Balance = Balance - 99999999
    WHERE  AccountNumber = '9704001000001';
    PRINT N'Rút 99 triệu...';

    IF (SELECT Balance FROM BankAccounts WHERE AccountNumber='9704001000001') < 0
    BEGIN
        ROLLBACK TRANSACTION SavePoint1;  -- Chỉ rollback về savepoint
        PRINT N'⚠ Rollback về SavePoint1, giữ lại lệnh nạp tiền';
    END

COMMIT TRANSACTION;

SELECT AccountNumber, Balance FROM BankAccounts
WHERE  AccountNumber = '9704001000001';
GO


-- ============================================================
-- SECTION 3: ISOLATION LEVEL - Các mức cô lập
-- ============================================================
PRINT '=== SECTION 3: ISOLATION LEVELS ===';

-- READ UNCOMMITTED: đọc "dirty data" (dữ liệu chưa commit)
-- Dùng để demo: Session khác có thể thấy dữ liệu chưa commit
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT AccountNumber, Balance FROM BankAccounts;

-- READ COMMITTED (default): chỉ đọc dữ liệu đã commit
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT AccountNumber, Balance FROM BankAccounts;

-- REPEATABLE READ: đọc cùng row nhiều lần → kết quả không đổi
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT Balance FROM BankAccounts WHERE AccountNumber='9704001000001';
    -- (Session khác không thể UPDATE row này trong lúc này)
    WAITFOR DELAY '00:00:02';
    SELECT Balance FROM BankAccounts WHERE AccountNumber='9704001000001';
COMMIT;

-- SERIALIZABLE: không có Phantom Read, cao nhất
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT COUNT(*) AS SoTaiKhoan FROM BankAccounts WHERE AccountType='payment';
    -- (Session khác không thể INSERT payment account mới)
    SELECT COUNT(*) AS SoTaiKhoan FROM BankAccounts WHERE AccountType='payment';
COMMIT;

-- Reset về default
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO


-- ============================================================
-- SECTION 4: DEADLOCK - Demo & Phòng tránh
-- ============================================================
-- ⚠ Deadlock xảy ra khi 2 session chờ nhau → SQL Server kill 1 bên
--
-- Cách tái tạo (chạy SONG SONG 2 tab SSMS):
--
-- [TAB 1 - Session A]:
--   BEGIN TRAN;
--   UPDATE BankAccounts SET Balance=Balance WHERE AccountNumber='9704001000001'; -- lock A
--   WAITFOR DELAY '00:00:05';
--   UPDATE BankAccounts SET Balance=Balance WHERE AccountNumber='9704002000001'; -- chờ B
--   COMMIT;
--
-- [TAB 2 - Session B - chạy ngay sau Tab 1]:
--   BEGIN TRAN;
--   UPDATE BankAccounts SET Balance=Balance WHERE AccountNumber='9704002000001'; -- lock B
--   WAITFOR DELAY '00:00:05';
--   UPDATE BankAccounts SET Balance=Balance WHERE AccountNumber='9704001000001'; -- chờ A → DEADLOCK!
--   COMMIT;
--
-- SQL Server tự phát hiện và rollback 1 session (deadlock victim)
-- ============================================================
PRINT '=== SECTION 4: DEADLOCK Prevention ===';
GO
-- PHÒNG TRÁNH DEADLOCK: luôn lock theo thứ tự tăng dần (AccountNumber ASC)
-- Stored proc sp_Transfer trong init.sql đã làm điều này:

CREATE OR ALTER PROCEDURE sp_SafeTransfer
    @FromAcc  NVARCHAR(20),
    @ToAcc    NVARCHAR(20),
    @Amount   DECIMAL(18,2),
    @ByUser   UNIQUEIDENTIFIER,
    @Desc     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Lock theo thứ tự AccountNumber → phòng deadlock
        DECLARE @FirstAcc  NVARCHAR(20) = CASE WHEN @FromAcc < @ToAcc THEN @FromAcc ELSE @ToAcc END;
        DECLARE @SecondAcc NVARCHAR(20) = CASE WHEN @FromAcc < @ToAcc THEN @ToAcc   ELSE @FromAcc END;

        -- Lock row theo thứ tự đã xác định
        SELECT BankAccountId FROM BankAccounts WITH (UPDLOCK, ROWLOCK)
        WHERE AccountNumber IN (@FirstAcc, @SecondAcc)
        ORDER BY AccountNumber;

        -- Kiểm tra số dư
        IF (SELECT Balance FROM BankAccounts WHERE AccountNumber=@FromAcc) < @Amount
            THROW 50002, N'Số dư không đủ', 1;

        UPDATE BankAccounts SET Balance = Balance - @Amount WHERE AccountNumber=@FromAcc;
        UPDATE BankAccounts SET Balance = Balance + @Amount WHERE AccountNumber=@ToAcc;

        INSERT INTO Transactions
            (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        SELECT fa.BankAccountId, ta.BankAccountId, @ByUser,
               'transfer', @Amount, 'success', @Desc
        FROM   BankAccounts fa CROSS JOIN BankAccounts ta
        WHERE  fa.AccountNumber=@FromAcc AND ta.AccountNumber=@ToAcc;

        COMMIT TRANSACTION;
        PRINT N'✅ Transfer thành công';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

-- Test sp_SafeTransfer
EXEC sp_SafeTransfer
    '9704002000001', '9704001000001', 500000,
    (SELECT TOP 1 UserId FROM Users WHERE Username='tran_thi_b'),
    N'Demo deadlock-safe transfer';

SELECT AccountNumber, Balance FROM BankAccounts
WHERE  AccountNumber IN ('9704001000001','9704002000001');
GO


-- ============================================================
-- SECTION 5: LOCKING - UPDLOCK, ROWLOCK, NOLOCK
-- ============================================================
PRINT '=== SECTION 5: Locking Hints ===';

-- NOLOCK (= READ UNCOMMITTED): đọc nhanh, chấp nhận dirty read
SELECT AccountNumber, Balance
FROM   BankAccounts WITH (NOLOCK);

-- UPDLOCK: báo sẽ UPDATE, tránh deadlock khi nhiều session cùng đọc rồi ghi
BEGIN TRANSACTION;
    SELECT Balance FROM BankAccounts WITH (UPDLOCK, ROWLOCK)
    WHERE  AccountNumber = '9704001000001';
    -- Chỉ 1 session có lock này tại 1 thời điểm
COMMIT;

-- TABLOCKX: lock cả bảng (dùng khi import hàng loạt)
BEGIN TRANSACTION;
    SELECT COUNT(*) FROM Transactions WITH (TABLOCKX);
COMMIT;
GO


-- ============================================================
-- SECTION 6: INDEX - Tăng tốc truy vấn
-- ============================================================
PRINT '=== SECTION 6: Index ===';

-- Tìm theo AccountNumber: thường xuyên dùng → nên index
-- (AccountNumber đã là UNIQUE → có clustered index ngầm định)

-- Tạo index tổng hợp để tăng tốc query lịch sử giao dịch theo status + date
CREATE INDEX IX_Transactions_Status_Date
ON Transactions (Status, CreatedAt DESC)
INCLUDE (Amount, Type);

-- Demo: query dùng index
SELECT Type, Amount, Status, CreatedAt
FROM   Transactions
WHERE  Status = 'success'
ORDER BY CreatedAt DESC;

-- Xem execution plan để xác nhận index được dùng
-- (Nhấn Ctrl+M trong SSMS để bật Include Actual Execution Plan)
GO


-- ============================================================
-- SECTION 7: VIEW - Đơn giản hóa truy vấn phức tạp
-- ============================================================
PRINT '=== SECTION 7: Views ===';
GO

CREATE OR ALTER VIEW vw_CustomerBalance AS
    SELECT c.FullName, u.Username, u.Status AS UserStatus,
           ba.AccountNumber, ba.AccountType,
           ba.Balance, ba.Status AS AccStatus
    FROM   Customers c
    JOIN   Users       u  ON c.UserId      = u.UserId
    JOIN   BankAccounts ba ON c.CustomerId = ba.CustomerId;
GO

-- Sử dụng view như bảng thường
SELECT * FROM vw_CustomerBalance ORDER BY Balance DESC;
GO

CREATE OR ALTER VIEW vw_TransactionHistory AS
    SELECT t.CreatedAt,
           fa.AccountNumber AS FromAcc,
           ta.AccountNumber AS ToAcc,
           t.Type, t.Amount, t.Status, t.Description,
           u.Username AS CreatedBy
    FROM   Transactions t
    LEFT JOIN BankAccounts fa ON t.FromBankAccountId = fa.BankAccountId
    LEFT JOIN BankAccounts ta ON t.ToBankAccountId   = ta.BankAccountId
    JOIN  Users u ON t.CreatedByUserId = u.UserId;
GO

SELECT * FROM vw_TransactionHistory ORDER BY CreatedAt DESC;
GO


-- ============================================================
-- SECTION 8: TRIGGER - Tự động audit khi số dư thay đổi
-- ============================================================
PRINT '=== SECTION 8: Trigger ===';
GO

CREATE OR ALTER TRIGGER trg_AuditBalanceChange
ON BankAccounts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    -- Chỉ trigger khi Balance thực sự thay đổi
    IF UPDATE(Balance)
    BEGIN
        INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description)
        SELECT
            (SELECT TOP 1 UserId FROM Users WHERE Status='active' ORDER BY CreatedAt),
            'BALANCE_CHANGE',
            'BankAccounts',
            i.BankAccountId,
            CONCAT(N'Số dư thay đổi: ',
                   FORMAT(d.Balance,'N0'), N'đ → ', FORMAT(i.Balance,'N0'), N'đ')
        FROM inserted i
        JOIN deleted  d ON i.BankAccountId = d.BankAccountId
        WHERE i.Balance <> d.Balance;
    END;
END;
GO

-- Demo trigger: update balance → xem AuditLogs tự động sinh ra
UPDATE BankAccounts SET Balance = Balance + 1 WHERE AccountNumber='9704001000001';
UPDATE BankAccounts SET Balance = Balance - 1 WHERE AccountNumber='9704001000001';

SELECT TOP 5 ActionType, Description, CreatedAt
FROM AuditLogs ORDER BY CreatedAt DESC;
GO


-- ============================================================
-- SECTION 9: CONCURRENCY - Đọc số liệu thống kê đồng thời
-- ============================================================
PRINT '=== SECTION 9: Concurrency - Aggregate ===';

-- Tổng số dư toàn hệ thống (snapshot nhất quán)
SET TRANSACTION ISOLATION LEVEL SNAPSHOT;   -- cần ALLOW_SNAPSHOT_ISOLATION ON

BEGIN TRANSACTION;
    SELECT SUM(Balance) AS TongSoDu, COUNT(*) AS SoTaiKhoan
    FROM   BankAccounts WHERE Status='active';
    -- Kết quả không bị ảnh hưởng bởi các transaction đang chạy song song
COMMIT;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
GO


-- ============================================================
-- SECTION 10: QUICK DEMO SCRIPT
-- Chạy toàn bộ luồng: đăng ký → mở TK → chuyển tiền → xem log
-- ============================================================
PRINT '=== SECTION 10: Full Flow Demo ===';

DECLARE @RoleCust UNIQUEIDENTIFIER = (SELECT RoleId FROM Roles WHERE RoleName='Customer');
DECLARE @NewUser  UNIQUEIDENTIFIER;
DECLARE @NewCust  UNIQUEIDENTIFIER;
DECLARE @NewAcc   UNIQUEIDENTIFIER;

-- 1. Tạo user mới
INSERT INTO Users (RoleId, Username, PasswordHash) OUTPUT INSERTED.UserId
VALUES (@RoleCust, 'demo_user', 'hash_demo');
SET @NewUser = (SELECT TOP 1 UserId FROM Users WHERE Username='demo_user');

-- 2. Tạo hồ sơ customer
INSERT INTO Customers (UserId, FullName, Email, PhoneNumber)
OUTPUT INSERTED.CustomerId
VALUES (@NewUser, N'Demo Nguyễn', 'demo@bank.vn', '0999888777');
SET @NewCust = (SELECT TOP 1 CustomerId FROM Customers WHERE UserId=@NewUser);

-- 3. Mở tài khoản với 5 triệu
INSERT INTO BankAccounts (CustomerId, AccountNumber, AccountType, Balance)
OUTPUT INSERTED.BankAccountId
VALUES (@NewCust, '9704999000001', 'payment', 5000000);
SET @NewAcc = (SELECT TOP 1 BankAccountId FROM BankAccounts WHERE AccountNumber='9704999000001');

-- 4. Chuyển 1 triệu sang TK Nguyễn Văn A
EXEC sp_SafeTransfer
    '9704999000001', '9704001000001', 1000000,
    @NewUser, N'Demo full flow transfer';

-- 5. Xem kết quả
SELECT c.FullName, ba.AccountNumber, ba.Balance
FROM   Customers c JOIN BankAccounts ba ON c.CustomerId=ba.CustomerId
WHERE  c.UserId = @NewUser;

SELECT * FROM vw_TransactionHistory
WHERE  FromAcc='9704999000001' OR ToAcc='9704999000001';
GO

PRINT N'✅ Demo hoàn tất!';
