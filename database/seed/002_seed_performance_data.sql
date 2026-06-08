/*
================================================================================
PERFORMANCE SEED — Dữ liệu lớn sinh bằng T-SQL (set-based)
================================================================================
Chạy SAU 001_seed_sample_data.sql (cần Roles và admin demo sẵn có).

PasswordHash: placeholder hash_Perf@000 — không phải bcrypt thật.

Marker: nếu đã tồn tại username perf_customer_000001 thì script bỏ qua (idempotent).
Không DROP DATABASE.

Chỉnh volume ở khối CONFIG bên dưới trước khi chạy.
================================================================================
*/

USE BankingTransactionDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

-- ── CONFIG ────────────────────────────────────────────────────
DECLARE @CustomerCount     INT = 1000;
DECLARE @BankerCount       INT = 20;
DECLARE @AccountCount      INT = 3000;
DECLARE @TransactionCount  INT = 100000;
DECLARE @LoginLogCount     INT = 20000;
DECLARE @AuditLogCount     INT = 30000;

-- ── Marker: tránh chạy trùng ─────────────────────────────────
IF EXISTS (SELECT 1 FROM Users WHERE Username = N'perf_customer_000001')
BEGIN
    PRINT N'[002] Performance seed đã tồn tại (marker: perf_customer_000001) — bỏ qua.';
    RETURN;
END;

DECLARE @RoleBanker   UNIQUEIDENTIFIER;
DECLARE @RoleCustomer UNIQUEIDENTIFIER;
DECLARE @AdminUserId  UNIQUEIDENTIFIER;

SELECT @RoleBanker   = RoleId FROM Roles WHERE RoleName = N'Banker';
SELECT @RoleCustomer = RoleId FROM Roles WHERE RoleName = N'Customer';
SELECT @AdminUserId  = UserId FROM Users WHERE Username = N'admin';

IF @RoleCustomer IS NULL OR @AdminUserId IS NULL
BEGIN
    RAISERROR(N'Chạy 001_seed_sample_data.sql trước (thiếu Roles hoặc admin).', 16, 1);
    RETURN;
END;

DECLARE @AccountsPerCustomer INT = @AccountCount / @CustomerCount;
IF @AccountsPerCustomer < 1 OR (@AccountsPerCustomer * @CustomerCount) <> @AccountCount
BEGIN
    RAISERROR(N'@AccountCount phải chia hết cho @CustomerCount.', 16, 1);
    RETURN;
END;

PRINT N'[002] Bắt đầu performance seed...';

-- ── Staging tables ────────────────────────────────────────────
CREATE TABLE #PerfBankers (
    Seq        INT              NOT NULL PRIMARY KEY,
    UserId     UNIQUEIDENTIFIER NOT NULL,
    BankerId   UNIQUEIDENTIFIER NOT NULL
);

CREATE TABLE #PerfCustomers (
    Seq        INT              NOT NULL PRIMARY KEY,
    UserId     UNIQUEIDENTIFIER NOT NULL,
    CustomerId UNIQUEIDENTIFIER NOT NULL
);

CREATE TABLE #PerfAccounts (
    AccSeq        INT              NOT NULL PRIMARY KEY,
    BankAccountId UNIQUEIDENTIFIER NOT NULL,
    CustomerId    UNIQUEIDENTIFIER NOT NULL,
    CustomerSeq   INT              NOT NULL,
    Balance       DECIMAL(18, 2)   NOT NULL,
    Status        NVARCHAR(20)     NOT NULL,
    AccountNumber NVARCHAR(20)     NOT NULL,
    AccountType   NVARCHAR(20)     NOT NULL,
    OpenedAt      DATETIME2        NOT NULL,
    ClosedAt      DATETIME2        NULL
);

-- ── 1. Bankers ────────────────────────────────────────────────
;WITH n AS (
    SELECT TOP (@BankerCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Seq
    FROM sys.all_objects
)
INSERT INTO #PerfBankers (Seq, UserId, BankerId)
SELECT Seq, NEWID(), NEWID() FROM n;

INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt, CreatedAt)
SELECT
    b.UserId,
    @RoleBanker,
    N'perf_banker_' + RIGHT(N'000' + CAST(b.Seq AS NVARCHAR(10)), 3),
    N'hash_Perf@banker',
    CASE WHEN b.Seq % 8 = 0 THEN N'locked' ELSE N'active' END,
    CASE WHEN b.Seq % 5 = 0 THEN NULL ELSE DATEADD(DAY, -(b.Seq % 180), SYSDATETIME()) END,
    DATEADD(DAY, -(b.Seq % 540), DATEADD(MONTH, -6, SYSDATETIME()))
FROM #PerfBankers b;

INSERT INTO Bankers (BankerId, UserId, EmployeeCode, FullName, Email, PhoneNumber, CreatedAt)
SELECT
    b.BankerId,
    b.UserId,
    N'PERF-EMP-' + RIGHT(N'000' + CAST(b.Seq AS NVARCHAR(10)), 3),
    CASE b.Seq % 10
        WHEN 0 THEN N'Phạm Minh Tuấn'  WHEN 1 THEN N'Hoàng Thị Hương'
        WHEN 2 THEN N'Vũ Đức Anh'      WHEN 3 THEN N'Đặng Thu Hà'
        WHEN 4 THEN N'Bùi Quốc Huy'    WHEN 5 THEN N'Ngô Thị Mai'
        WHEN 6 THEN N'Lý Văn Phúc'     WHEN 7 THEN N'Đỗ Thị Lan'
        WHEN 8 THEN N'Mai Hoàng Nam'   ELSE N'Trịnh Văn Đức'
    END,
    N'perf.banker' + RIGHT(N'000' + CAST(b.Seq AS NVARCHAR(10)), 3) + N'@demo.local',
    N'09' + RIGHT(N'10000000' + CAST(b.Seq AS NVARCHAR(10)), 8),
    DATEADD(DAY, -(b.Seq % 400), DATEADD(MONTH, -6, SYSDATETIME()))
FROM #PerfBankers b;

-- ── 2. Customers ──────────────────────────────────────────────
;WITH n AS (
    SELECT TOP (@CustomerCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Seq
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO #PerfCustomers (Seq, UserId, CustomerId)
SELECT Seq, NEWID(), NEWID() FROM n;

INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt, CreatedAt)
SELECT
    c.UserId,
    @RoleCustomer,
    N'perf_customer_' + RIGHT(N'000000' + CAST(c.Seq AS NVARCHAR(10)), 6),
    N'hash_Perf@cust',
    CASE WHEN c.Seq % 12 = 0 THEN N'locked' ELSE N'active' END,
    CASE WHEN c.Seq % 7 = 0 THEN NULL ELSE DATEADD(DAY, -(c.Seq % 365), SYSDATETIME()) END,
    DATEADD(DAY, -(c.Seq % 720), DATEADD(YEAR, -1, SYSDATETIME()))
FROM #PerfCustomers c;

INSERT INTO Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay, CreatedAt)
SELECT
    c.CustomerId,
    c.UserId,
    CASE c.Seq % 4
        WHEN 0 THEN N'Nguyễn Văn '   WHEN 1 THEN N'Trần Thị '
        WHEN 2 THEN N'Lê Văn '       ELSE N'Phạm Thị '
    END + CAST(c.Seq AS NVARCHAR(10)),
    N'perf.c' + RIGHT(N'000000' + CAST(c.Seq AS NVARCHAR(10)), 6) + N'@demo.local',
    N'08' + RIGHT(N'10000000' + CAST(c.Seq AS NVARCHAR(10)), 8),
    CASE c.Seq % 5
        WHEN 0 THEN N'Số ' + CAST(c.Seq AS NVARCHAR(10)) + N' Đường Lê Lợi, Q.1, TP.HCM'
        WHEN 1 THEN N'Số ' + CAST(c.Seq AS NVARCHAR(10)) + N' Phố Trần Hưng Đạo, Hà Nội'
        WHEN 2 THEN N'Số ' + CAST(c.Seq AS NVARCHAR(10)) + N' Đường Nguyễn Huệ, Đà Nẵng'
        WHEN 3 THEN N'Số ' + CAST(c.Seq AS NVARCHAR(10)) + N' Đường Lê Duẩn, Hải Phòng'
        ELSE N'Số ' + CAST(c.Seq AS NVARCHAR(10)) + N' Đường 30/4, Cần Thơ'
    END,
    DATEADD(YEAR, -(20 + (c.Seq % 35)), DATEFROMPARTS(2000, 1, 1)),
    DATEADD(DAY, -(c.Seq % 600), SYSDATETIME())
FROM #PerfCustomers c;

-- ── 3. BankAccounts (mỗi customer @AccountsPerCustomer tài khoản) ──
;WITH acc AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY c.Seq, s.Slot) AS AccSeq,
        c.CustomerId,
        c.Seq AS CustomerSeq,
        s.Slot
    FROM #PerfCustomers c
    CROSS JOIN (SELECT 1 AS Slot UNION ALL SELECT 2 UNION ALL SELECT 3) s
    WHERE s.Slot <= @AccountsPerCustomer
)
INSERT INTO #PerfAccounts (
    AccSeq, BankAccountId, CustomerId, CustomerSeq, Balance, Status,
    AccountNumber, AccountType, OpenedAt, ClosedAt
)
SELECT
    a.AccSeq,
    NEWID(),
    a.CustomerId,
    a.CustomerSeq,
    CAST((a.AccSeq % 500 + 1) AS DECIMAL(18, 2)) * 100000.00,
    CASE
        WHEN a.AccSeq % 47 = 0 THEN N'closed'
        WHEN a.AccSeq % 19 = 0 THEN N'locked'
        ELSE N'active'
    END,
    N'P' + RIGHT(N'000000000000000' + CAST(a.AccSeq AS NVARCHAR(20)), 16),
    CASE a.AccSeq % 3 WHEN 0 THEN N'payment' WHEN 1 THEN N'saving' ELSE N'debit' END,
    CAST(DATEADD(DAY, -(a.AccSeq % 3650), DATEFROMPARTS(2020, 1, 1)) AS DATETIME2),
    CASE WHEN a.AccSeq % 47 = 0
        THEN CAST(DATEADD(DAY, 180, DATEADD(DAY, -(a.AccSeq % 3650), DATEFROMPARTS(2020, 1, 1))) AS DATETIME2)
        ELSE NULL
    END
FROM acc a;

INSERT INTO BankAccounts (
    BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt
)
SELECT
    BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt
FROM #PerfAccounts;

-- ── 4. Transactions (UNION ALL theo loại — thỏa CHECK constraint) ──
;WITH n AS (
    SELECT TOP (@TransactionCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS TxNum
    FROM sys.all_objects a
    CROSS JOIN sys.all_objects b
    CROSS JOIN sys.all_objects c
),
tx AS (
    SELECT
        n.TxNum,
        n.TxNum % 3 AS TypeMod,
        ((n.TxNum - 1) % @AccountCount) + 1 AS FromAccSeq,
        CASE
            WHEN ((n.TxNum + 17) % @AccountCount) + 1 =
                 ((n.TxNum - 1) % @AccountCount) + 1
            THEN CASE WHEN ((n.TxNum - 1) % @AccountCount) + 1 = @AccountCount THEN 1
                      ELSE ((n.TxNum - 1) % @AccountCount) + 2 END
            ELSE ((n.TxNum + 17) % @AccountCount) + 1
        END AS ToAccSeq,
        CASE n.TxNum % 3
            WHEN 0 THEN CAST(50000 + (n.TxNum % 500) * 1000 AS DECIMAL(18, 2))
            WHEN 1 THEN CAST(500000 + (n.TxNum % 2000) * 5000 AS DECIMAL(18, 2))
            ELSE CAST(5000000 + (n.TxNum % 500) * 100000 AS DECIMAL(18, 2))
        END AS Amount,
        CASE n.TxNum % 10 WHEN 0 THEN N'pending' WHEN 1 THEN N'failed' ELSE N'success' END AS TxStatus,
        DATEADD(MINUTE, n.TxNum % 1440,
            DATEADD(DAY, -(n.TxNum % 900), CAST(DATEFROMPARTS(2023, 1, 1) AS DATETIME2))) AS CreatedAt,
        CASE WHEN n.TxNum % 4 = 0
            THEN (SELECT UserId FROM #PerfBankers WHERE Seq = (n.TxNum % @BankerCount) + 1)
            ELSE (SELECT UserId FROM #PerfCustomers WHERE Seq = (n.TxNum % @CustomerCount) + 1)
        END AS CreatedByUserId
    FROM n
)
INSERT INTO Transactions (
    FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt
)
SELECT NULL, ta.BankAccountId, tx.CreatedByUserId, N'deposit', tx.Amount, tx.TxStatus,
    N'[Perf] Nạp tiền tự động #' + CAST(tx.TxNum AS NVARCHAR(20)), tx.CreatedAt
FROM tx
INNER JOIN #PerfAccounts ta ON ta.AccSeq = tx.ToAccSeq
WHERE tx.TypeMod = 0
UNION ALL
SELECT fa.BankAccountId, NULL, tx.CreatedByUserId, N'withdraw', tx.Amount, tx.TxStatus,
    N'[Perf] Rút tiền tự động #' + CAST(tx.TxNum AS NVARCHAR(20)), tx.CreatedAt
FROM tx
INNER JOIN #PerfAccounts fa ON fa.AccSeq = tx.FromAccSeq
WHERE tx.TypeMod = 1
UNION ALL
SELECT fa.BankAccountId, ta.BankAccountId, tx.CreatedByUserId, N'transfer', tx.Amount, tx.TxStatus,
    N'[Perf] Chuyển khoản tự động #' + CAST(tx.TxNum AS NVARCHAR(20)), tx.CreatedAt
FROM tx
INNER JOIN #PerfAccounts fa ON fa.AccSeq = tx.FromAccSeq
INNER JOIN #PerfAccounts ta ON ta.AccSeq = tx.ToAccSeq
WHERE tx.TypeMod = 2 AND fa.BankAccountId <> ta.BankAccountId;

-- ── 5. LoginLogs ───────────────────────────────────────────────
;WITH n AS (
    SELECT TOP (@LoginLogCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Seq
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
INSERT INTO LoginLogs (UserId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress)
SELECT
    CASE
        WHEN n.Seq % 25 = 0 THEN NULL
        WHEN n.Seq % 2 = 0 THEN (SELECT UserId FROM #PerfCustomers WHERE Seq = (n.Seq % @CustomerCount) + 1)
        ELSE (SELECT UserId FROM #PerfBankers WHERE Seq = (n.Seq % @BankerCount) + 1)
    END,
    CASE
        WHEN n.Seq % 25 = 0 THEN N'perf_unknown_' + CAST(n.Seq AS NVARCHAR(20))
        WHEN n.Seq % 2 = 0 THEN N'perf_customer_' + RIGHT(N'000000' + CAST((n.Seq % @CustomerCount) + 1 AS NVARCHAR(10)), 6)
        ELSE N'perf_banker_' + RIGHT(N'000' + CAST((n.Seq % @BankerCount) + 1 AS NVARCHAR(10)), 3)
    END,
    DATEADD(MINUTE, n.Seq % 720, DATEADD(DAY, -(n.Seq % 400), SYSDATETIME())),
    CASE WHEN n.Seq % 3 = 0 THEN NULL
         ELSE DATEADD(MINUTE, 30 + (n.Seq % 120),
              DATEADD(MINUTE, n.Seq % 720, DATEADD(DAY, -(n.Seq % 400), SYSDATETIME())))
    END,
    CASE WHEN n.Seq % 8 = 0 THEN N'failed' ELSE N'success' END,
    CAST((n.Seq % 223) + 1 AS NVARCHAR(3)) + N'.' +
    CAST((n.Seq % 167) + 1 AS NVARCHAR(3)) + N'.' +
    CAST((n.Seq % 89) + 10 AS NVARCHAR(3)) + N'.' +
    CAST((n.Seq % 200) + 1 AS NVARCHAR(3))
FROM n;

-- ── 6. AuditLogs ───────────────────────────────────────────────
;WITH n AS (
    SELECT TOP (@AuditLogCount) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Seq
    FROM sys.all_objects a CROSS JOIN sys.all_objects b CROSS JOIN sys.all_objects c
)
INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description, CreatedAt)
SELECT
    CASE WHEN n.Seq % 5 = 0 THEN @AdminUserId
         ELSE (SELECT UserId FROM #PerfBankers WHERE Seq = (n.Seq % @BankerCount) + 1)
    END,
    CASE n.Seq % 9
        WHEN 0 THEN N'CREATE_CUSTOMER' WHEN 1 THEN N'OPEN_ACCOUNT'
        WHEN 2 THEN N'LOCK_ACCOUNT'   WHEN 3 THEN N'CLOSE_ACCOUNT'
        WHEN 4 THEN N'DEPOSIT'        WHEN 5 THEN N'WITHDRAW'
        WHEN 6 THEN N'TRANSFER'       WHEN 7 THEN N'LOCK_USER'
        ELSE N'UNLOCK_USER'
    END,
    CASE n.Seq % 4
        WHEN 0 THEN N'Users' WHEN 1 THEN N'Customers'
        WHEN 2 THEN N'BankAccounts' ELSE N'Transactions'
    END,
    CASE n.Seq % 4
        WHEN 0 THEN (SELECT UserId FROM #PerfCustomers WHERE Seq = (n.Seq % @CustomerCount) + 1)
        WHEN 1 THEN (SELECT CustomerId FROM #PerfCustomers WHERE Seq = (n.Seq % @CustomerCount) + 1)
        WHEN 2 THEN (SELECT BankAccountId FROM #PerfAccounts WHERE AccSeq = (n.Seq % @AccountCount) + 1)
        ELSE NEWID()
    END,
    N'[Perf] Audit log #' + CAST(n.Seq AS NVARCHAR(20)),
    DATEADD(MINUTE, n.Seq % 1000, DATEADD(DAY, -(n.Seq % 500), SYSDATETIME()))
FROM n;

PRINT N'[002] Hoàn tất performance seed.';
PRINT N'      Customers: ' + CAST(@CustomerCount AS NVARCHAR(20));
PRINT N'      Bankers:   ' + CAST(@BankerCount AS NVARCHAR(20));
PRINT N'      Accounts:  ' + CAST(@AccountCount AS NVARCHAR(20));
PRINT N'      Tx:        ' + CAST(@TransactionCount AS NVARCHAR(20));
PRINT N'      LoginLogs: ' + CAST(@LoginLogCount AS NVARCHAR(20));
PRINT N'      AuditLogs: ' + CAST(@AuditLogCount AS NVARCHAR(20));

GO
