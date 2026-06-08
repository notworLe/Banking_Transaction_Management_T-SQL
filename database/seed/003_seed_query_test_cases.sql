/*
================================================================================
QUERY TEST CASES — Dữ liệu đặc biệt để test query / stored procedure
================================================================================
Chạy SAU 001_seed_sample_data.sql (cần Roles).

PasswordHash: placeholder hash_QC@test — không phải bcrypt thật.

Marker: username qc_customer_multi — nếu đã tồn tại thì bỏ qua (idempotent).
Không DROP DATABASE.

10 test cases:
  1. Customer nhiều tài khoản (5 TK)
  2. Một tài khoản có rất nhiều giao dịch (80 TX)
  3. Tài khoản locked
  4. Tài khoản closed
  5. User locked
  6. Login failed — username không tồn tại
  7. Giao dịch failed — không đủ số dư
  8. Giao dịch pending
  9. Transfer giữa 2 TK cùng customer
 10. Transfer giữa 2 customer khác nhau
================================================================================
*/

USE BankingTransactionDB;
GO

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM Users WHERE Username = N'qc_customer_multi')
BEGIN
    PRINT N'[003] Query test cases đã tồn tại (marker: qc_customer_multi) — bỏ qua.';
    RETURN;
END;

DECLARE @RoleAdmin    UNIQUEIDENTIFIER;
DECLARE @RoleBanker   UNIQUEIDENTIFIER;
DECLARE @RoleCustomer UNIQUEIDENTIFIER;
DECLARE @UBanker      UNIQUEIDENTIFIER;
DECLARE @AdminUserId  UNIQUEIDENTIFIER;

SELECT @RoleAdmin    = RoleId FROM Roles WHERE RoleName = N'Admin';
SELECT @RoleBanker   = RoleId FROM Roles WHERE RoleName = N'Banker';
SELECT @RoleCustomer = RoleId FROM Roles WHERE RoleName = N'Customer';
SELECT @AdminUserId  = UserId FROM Users WHERE Username = N'admin';
SELECT @UBanker      = UserId FROM Users WHERE Username = N'banker_nam';

IF @RoleCustomer IS NULL
BEGIN
    RAISERROR(N'Chạy 001_seed_sample_data.sql trước.', 16, 1);
    RETURN;
END;

IF @UBanker IS NULL
    SET @UBanker = @AdminUserId;

-- ── Fixed IDs (QC = Query Case) ───────────────────────────────
DECLARE @UMulti   UNIQUEIDENTIFIER = 'AAAAAAAA-0001-0001-0001-000000000001';
DECLARE @ULocked  UNIQUEIDENTIFIER = 'AAAAAAAA-0002-0002-0002-000000000002';
DECLARE @UCustA   UNIQUEIDENTIFIER = 'AAAAAAAA-0003-0003-0003-000000000003';
DECLARE @UCustB   UNIQUEIDENTIFIER = 'AAAAAAAA-0004-0004-0004-000000000004';

DECLARE @CMulti   UNIQUEIDENTIFIER = 'BBBBBBBB-0001-0001-0001-000000000001';
DECLARE @CLocked  UNIQUEIDENTIFIER = 'BBBBBBBB-0002-0002-0002-000000000002';
DECLARE @CCustA   UNIQUEIDENTIFIER = 'BBBBBBBB-0003-0003-0003-000000000003';
DECLARE @CCustB   UNIQUEIDENTIFIER = 'BBBBBBBB-0004-0004-0004-000000000004';

DECLARE @AccMulti1 UNIQUEIDENTIFIER = 'CCCCCCCC-0001-0001-0001-000000000001';
DECLARE @AccMulti2 UNIQUEIDENTIFIER = 'CCCCCCCC-0001-0001-0001-000000000002';
DECLARE @AccMulti3 UNIQUEIDENTIFIER = 'CCCCCCCC-0001-0001-0001-000000000003';
DECLARE @AccMulti4 UNIQUEIDENTIFIER = 'CCCCCCCC-0001-0001-0001-000000000004';
DECLARE @AccMulti5 UNIQUEIDENTIFIER = 'CCCCCCCC-0001-0001-0001-000000000005';
DECLARE @AccHeavy  UNIQUEIDENTIFIER = 'CCCCCCCC-0002-0002-0002-000000000002';
DECLARE @AccLocked UNIQUEIDENTIFIER = 'CCCCCCCC-0003-0003-0003-000000000003';
DECLARE @AccClosed UNIQUEIDENTIFIER = 'CCCCCCCC-0004-0004-0004-000000000004';
DECLARE @AccCustA1 UNIQUEIDENTIFIER = 'CCCCCCCC-0005-0005-0005-000000000005';
DECLARE @AccCustA2 UNIQUEIDENTIFIER = 'CCCCCCCC-0005-0005-0005-000000000006';
DECLARE @AccCustB1 UNIQUEIDENTIFIER = 'CCCCCCCC-0006-0006-0006-000000000007';

-- ── Users ─────────────────────────────────────────────────────
INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt, CreatedAt) VALUES
    (@UMulti,  @RoleCustomer, N'qc_customer_multi',  N'hash_QC@test', N'active', SYSDATETIME(), '2024-06-01 08:00:00'),
    (@ULocked, @RoleCustomer, N'qc_user_locked',     N'hash_QC@test', N'locked', NULL,          '2024-06-02 08:00:00'),
    (@UCustA,  @RoleCustomer, N'qc_customer_a',     N'hash_QC@test', N'active', SYSDATETIME(), '2024-06-03 08:00:00'),
    (@UCustB,  @RoleCustomer, N'qc_customer_b',     N'hash_QC@test', N'active', SYSDATETIME(), '2024-06-04 08:00:00');

-- ── Customers ─────────────────────────────────────────────────
INSERT INTO Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay, CreatedAt) VALUES
    (@CMulti,  @UMulti,  N'Võ Thị Nhiều Tài Khoản', N'qc.multi@demo.local',  N'0900111001', N'100 Nguyễn Văn Cừ, Q.5, TP.HCM',     '1988-04-12', '2024-06-01 09:00:00'),
    (@CLocked, @ULocked, N'Phan Văn Bị Khóa',       N'qc.locked@demo.local', N'0900111002', N'22 Lý Tự Trọng, Q.1, TP.HCM',        '1992-08-20', '2024-06-02 09:00:00'),
    (@CCustA,  @UCustA,  N'Đinh Thị An',            N'qc.custa@demo.local',  N'0900111003', N'15 Hai Bà Trưng, Hoàn Kiếm, Hà Nội', '1995-01-05', '2024-06-03 09:00:00'),
    (@CCustB,  @UCustB,  N'Lương Văn Bình',         N'qc.custb@demo.local',  N'0900111004', N'8 Bạch Đằng, Hải Châu, Đà Nẵng',     '1990-11-30', '2024-06-04 09:00:00');

-- ── BankAccounts ──────────────────────────────────────────────
-- Case 1: 5 tài khoản cho qc_customer_multi
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt) VALUES
    (@AccMulti1, @CMulti, N'QC9704000000001', N'payment', 25000000.00, N'active', '2022-01-15 09:00:00', NULL),
    (@AccMulti2, @CMulti, N'QC9704000000002', N'saving',  80000000.00, N'active', '2022-06-01 10:00:00', NULL),
    (@AccMulti3, @CMulti, N'QC9704000000003', N'debit',   5000000.00, N'active', '2023-03-10 11:00:00', NULL),
    (@AccMulti4, @CMulti, N'QC9704000000004', N'payment', 12000000.00, N'active', '2023-09-20 08:30:00', NULL),
    (@AccMulti5, @CMulti, N'QC9704000000005', N'saving',  35000000.00, N'active', '2024-01-05 14:00:00', NULL);

-- Case 2: tài khoản heavy transaction
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt) VALUES
    (@AccHeavy, @CCustA, N'QC9704000000010', N'payment', 100000000.00, N'active', '2021-05-01 09:00:00', NULL);

-- Case 3: locked account
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt) VALUES
    (@AccLocked, @CLocked, N'QC9704000000020', N'payment', 3000000.00, N'locked', '2020-08-10 10:00:00', NULL);

-- Case 4: closed account
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt) VALUES
    (@AccClosed, @CLocked, N'QC9704000000030', N'saving', 0.00, N'closed', '2019-03-01 09:00:00', '2024-12-31 17:00:00');

-- Case 9 & 10: accounts for transfer tests
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt, ClosedAt) VALUES
    (@AccCustA1, @CCustA, N'QC9704000000040', N'payment', 20000000.00, N'active', '2023-01-01 09:00:00', NULL),
    (@AccCustA2, @CCustA, N'QC9704000000041', N'saving',  15000000.00, N'active', '2023-06-01 09:00:00', NULL),
    (@AccCustB1, @CCustB, N'QC9704000000050', N'payment', 18000000.00, N'active', '2023-02-01 09:00:00', NULL);

-- ── Case 2: 80 giao dịch cho @AccHeavy (loop) ────────────────
DECLARE @i INT = 1;
WHILE @i <= 80
BEGIN
    IF @i % 3 = 1
        INSERT INTO Transactions (
            FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt
        ) VALUES (
            NULL, @AccHeavy, @UCustA, N'deposit', CAST(100000 + (@i * 50000) AS DECIMAL(18, 2)), N'success',
            N'[QC] Nạp tiền heavy #' + CAST(@i AS NVARCHAR(10)), DATEADD(DAY, -@i, SYSDATETIME())
        );
    ELSE IF @i % 3 = 0
        INSERT INTO Transactions (
            FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt
        ) VALUES (
            @AccHeavy, NULL, @UCustA, N'withdraw', CAST(100000 + (@i * 50000) AS DECIMAL(18, 2)), N'success',
            N'[QC] Rút tiền heavy #' + CAST(@i AS NVARCHAR(10)), DATEADD(DAY, -@i, SYSDATETIME())
        );
    ELSE
        INSERT INTO Transactions (
            FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt
        ) VALUES (
            @AccHeavy, @AccCustA2, @UCustA, N'transfer', CAST(100000 + (@i * 50000) AS DECIMAL(18, 2)), N'success',
            N'[QC] Chuyển khoản heavy #' + CAST(@i AS NVARCHAR(10)), DATEADD(DAY, -@i, SYSDATETIME())
        );

    SET @i += 1;
END;

-- ── Cases 7, 8, 9, 10: giao dịch đặc biệt ────────────────────
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt) VALUES
    -- Case 7: failed withdraw — số dư không đủ
    (@AccLocked, NULL, @ULocked, N'withdraw', 50000000.00, N'failed',
        N'[QC] Rút tiền thất bại — số dư không đủ', '2025-05-10 14:00:00'),
    -- Case 8: pending transfer
    (@AccCustA1, @AccCustB1, @UCustA, N'transfer', 2500000.00, N'pending',
        N'[QC] Chuyển khoản đang chờ xử lý', '2025-06-01 10:00:00'),
    -- Case 9: transfer cùng customer (CustA: AccCustA1 → AccCustA2)
    (@AccCustA1, @AccCustA2, @UCustA, N'transfer', 3000000.00, N'success',
        N'[QC] Chuyển nội bộ cùng khách hàng A', '2025-05-20 11:30:00'),
    -- Case 10: transfer khác customer (CustA → CustB)
    (@AccCustA2, @AccCustB1, @UCustA, N'transfer', 1500000.00, N'success',
        N'[QC] Chuyển liên khách hàng A sang B', '2025-05-25 15:45:00');

-- ── Case 6: Login failed — username không tồn tại ─────────────
INSERT INTO LoginLogs (UserId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress) VALUES
    (NULL, N'qc_hacker_not_exist', '2025-06-05 03:22:00', NULL, N'failed', N'198.51.100.99'),
    (@ULocked, N'qc_user_locked', '2025-06-04 08:00:00', NULL, N'failed', N'10.0.0.55');

-- ── AuditLogs cho các case ────────────────────────────────────
INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description, CreatedAt) VALUES
    (@UBanker, N'OPEN_ACCOUNT',   N'BankAccounts', @AccLocked, N'[QC] Mở tài khoản cho khách hàng bị khóa sau', '2020-08-10 10:05:00'),
    (@UBanker, N'LOCK_ACCOUNT',   N'BankAccounts', @AccLocked, N'[QC] Khóa tài khoản QC9704000000020',           '2025-04-01 09:00:00'),
    (@UBanker, N'CLOSE_ACCOUNT',  N'BankAccounts', @AccClosed, N'[QC] Đóng tài khoản tiết kiệm',               '2024-12-31 17:00:00'),
    (@AdminUserId, N'LOCK_USER',  N'Users',        @ULocked,   N'[QC] Khóa user qc_user_locked',               '2025-05-15 08:30:00'),
    (@UBanker, N'TRANSFER',       N'Transactions', NULL,       N'[QC] Ghi nhận chuyển khoản liên khách hàng',  '2025-05-25 15:46:00');

PRINT N'[003] Hoàn tất query test cases (10 scenarios).';

GO
