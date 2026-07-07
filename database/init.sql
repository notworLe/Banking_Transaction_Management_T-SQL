USE master;
GO

IF EXISTS(SELECT 1 FROM sys.databases WHERE name = 'banking_transaction')
	DROP DATABASE banking_transaction
GO

CREATE DATABASE banking_transaction;
GO

USE banking_transaction;
GO





-- ============================================================
-- 1. ROLES
-- ============================================================
CREATE TABLE Roles (
    RoleId   UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RoleName NVARCHAR(50) NOT NULL UNIQUE  -- 'Admin','Banker','Customer'
);
 
-- ============================================================
-- 2. USERS  (shared login table for all 3 roles)
-- ============================================================
CREATE TABLE Users (
    UserId       UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    RoleId       UNIQUEIDENTIFIER NOT NULL REFERENCES Roles(RoleId),
    Username     NVARCHAR(100)    NOT NULL UNIQUE,
    PasswordHash NVARCHAR(256)    NOT NULL,           -- bcrypt / sha256 hash
    Status       NVARCHAR(20)     NOT NULL DEFAULT 'active'  -- active | locked
        CHECK (Status IN ('active','locked')),
    LastLoginAt  DATETIME2        NULL,
    CreatedAt    DATETIME2        NOT NULL DEFAULT SYSDATETIME()
);
 
-- ============================================================
-- 3. CUSTOMERS
-- ============================================================
CREATE TABLE Customers (
    CustomerId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES Users(UserId),
    FullName    NVARCHAR(150)    NOT NULL,
    Email       NVARCHAR(200)    NOT NULL UNIQUE,
    PhoneNumber NVARCHAR(20)     NOT NULL UNIQUE,
    Address     NVARCHAR(500)    NULL,
    BirthDay    DATE             NULL
);
 
-- ============================================================
-- 4. BANKERS
-- ============================================================
CREATE TABLE Bankers (
    BankerId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId       UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES Users(UserId),
    EmployeeCode NVARCHAR(20)     NOT NULL UNIQUE,
    FullName     NVARCHAR(150)    NOT NULL,
    Email        NVARCHAR(200)    NOT NULL UNIQUE,
    PhoneNumber  NVARCHAR(20)     NOT NULL
);
 
-- ============================================================
-- 5. BANK ACCOUNTS  (one customer can have multiple accounts)
-- ============================================================
CREATE TABLE BankAccounts (
    BankAccountId UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    CustomerId    UNIQUEIDENTIFIER NOT NULL REFERENCES Customers(CustomerId),
    AccountNumber NVARCHAR(20)     NOT NULL UNIQUE,
    AccountType   NVARCHAR(20)     NOT NULL DEFAULT 'payment'
        CHECK (AccountType IN ('payment','saving','debit')),
    Balance       DECIMAL(18,2)    NOT NULL DEFAULT 0.00
        CHECK (Balance >= 0),
    Status        NVARCHAR(20)     NOT NULL DEFAULT 'active'
        CHECK (Status IN ('active','locked','closed')),
    OpenedAt      DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    ClosedAt      DATETIME2        NULL
);
 
-- ============================================================
-- 6. TRANSACTIONS
-- ============================================================
CREATE TABLE Transactions (
    TransactionId     UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    FromBankAccountId UNIQUEIDENTIFIER NULL REFERENCES BankAccounts(BankAccountId),
    ToBankAccountId   UNIQUEIDENTIFIER NULL REFERENCES BankAccounts(BankAccountId),
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL REFERENCES Users(UserId),
    Type              NVARCHAR(20)     NOT NULL
        CHECK (Type IN ('deposit','withdraw','transfer')),
    Amount            DECIMAL(18,2)    NOT NULL CHECK (Amount > 0),
    Status            NVARCHAR(20)     NOT NULL DEFAULT 'pending'
        CHECK (Status IN ('pending','success','failed')),
    Description       NVARCHAR(500)    NULL,
    CreatedAt         DATETIME2        NOT NULL DEFAULT SYSDATETIME()
);
 
-- ============================================================
-- 7. AUDIT LOGS  (Banker / Admin actions)
-- ============================================================
CREATE TABLE AuditLogs (
    AuditLogId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(UserId),
    ActionType  NVARCHAR(100)    NOT NULL,  -- e.g. 'LOCK_ACCOUNT','CREATE_BANKER'
    TargetTable NVARCHAR(100)    NULL,
    TargetId    UNIQUEIDENTIFIER NULL,
    Description NVARCHAR(1000)   NULL,
    CreatedAt   DATETIME2        NOT NULL DEFAULT SYSDATETIME()
);
 
-- ============================================================
-- 8. LOGIN LOGS
-- ============================================================
CREATE TABLE LoginLogs (
    LoginLogId  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL REFERENCES Users(UserId),
    UserName    NVARCHAR(100)    NOT NULL,
    LoginTime   DATETIME2        NOT NULL DEFAULT SYSDATETIME(),
    LogoutTime  DATETIME2        NULL,
    LoginStatus NVARCHAR(20)     NOT NULL
        CHECK (LoginStatus IN ('success','failed')),
    IPAddress   NVARCHAR(45)     NULL   -- supports IPv6
);
 
GO
 
-- ============================================================
-- SEED DATA
-- ============================================================

-- ── Roles ────────────────────────────────────────────────────
DECLARE @RoleAdmin    UNIQUEIDENTIFIER = NEWID();
DECLARE @RoleBanker   UNIQUEIDENTIFIER = NEWID();
DECLARE @RoleCustomer UNIQUEIDENTIFIER = NEWID();

INSERT INTO Roles (RoleId, RoleName) VALUES
    (@RoleAdmin,    'Admin'),
    (@RoleBanker,   'Banker'),
    (@RoleCustomer, 'Customer');

-- ── Users ─────────────────────────────────────────────────────
-- PasswordHash = bcrypt của "Admin@123", "Banker@123", "Cust@111/222/333"
-- (placeholder hash - backend xác thực qua sp_Login / Python bcrypt)
DECLARE @UAdmin   UNIQUEIDENTIFIER = NEWID();
DECLARE @UBanker1 UNIQUEIDENTIFIER = NEWID();
DECLARE @UBanker2 UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust1   UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust2   UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust3   UNIQUEIDENTIFIER = NEWID();

-- Passwords: admin=Admin@123 | banker_nam/banker_lan=Banker@123 | nguyen_van_a=Cust@111 | tran_thi_b=Cust@222 | le_van_c=Cust@333
INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt) VALUES
    (@UAdmin,   @RoleAdmin,    'admin',        '$2b$12$NNhFElWSGbdai9kR/Epqjev.HgErRR0j3P85tImiFMcuRCQ8T0Wm.',  'active', '2025-06-05 08:00:00'),
    (@UBanker1, @RoleBanker,   'banker_nam',   '$2b$12$YHwefJpLYFbjcs0tHCZMM.pOsFV7c.lbjRJtaa3ayQgw025IihnFK', 'active', '2025-06-05 08:15:00'),
    (@UBanker2, @RoleBanker,   'banker_lan',   '$2b$12$YHwefJpLYFbjcs0tHCZMM.pOsFV7c.lbjRJtaa3ayQgw025IihnFK', 'locked', '2025-05-20 09:00:00'),
    (@UCust1,   @RoleCustomer, 'nguyen_van_a', '$2b$12$4DTBQ0USePdF3fEC8LnAWezcqgjCj6EvqNLgeDGGjFTpgMOrE51dK', 'active', '2025-06-05 10:00:00'),
    (@UCust2,   @RoleCustomer, 'tran_thi_b',   '$2b$12$BnoANF.eawK1tmqIUw732OfajuAIMuiNjFNuXG2ooP7vS6sjQ52lG', 'active', '2025-06-04 14:30:00'),
    (@UCust3,   @RoleCustomer, 'le_van_c',     '$2b$12$JehHmEu04blFKnZnE8jA3.8lq6aifKXRlJcUE1ISkokW0TDx0igHe', 'locked', '2025-05-01 11:00:00');

-- ── Bankers ───────────────────────────────────────────────────
DECLARE @Banker1 UNIQUEIDENTIFIER = NEWID();
DECLARE @Banker2 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Bankers (BankerId, UserId, EmployeeCode, FullName, Email, PhoneNumber) VALUES
    (@Banker1, @UBanker1, 'EMP-001', N'Trần Văn Nam',   'nam.tran@vcb.vn',   '0901234567'),
    (@Banker2, @UBanker2, 'EMP-002', N'Nguyễn Thị Lan', 'lan.nguyen@vcb.vn', '0912345678');

-- ── Customers ─────────────────────────────────────────────────
DECLARE @Cust1 UNIQUEIDENTIFIER = NEWID();
DECLARE @Cust2 UNIQUEIDENTIFIER = NEWID();
DECLARE @Cust3 UNIQUEIDENTIFIER = NEWID();

INSERT INTO Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay) VALUES
    (@Cust1, @UCust1, N'Nguyễn Văn A', 'a.nguyen@gmail.com', '0933111222', N'12 Lê Lợi, Q.1, TP.HCM',            '1995-03-15'),
    (@Cust2, @UCust2, N'Trần Thị B',   'b.tran@gmail.com',   '0944222333', N'45 Trần Hưng Đạo, Hải Phòng',        '1998-07-22'),
    (@Cust3, @UCust3, N'Lê Văn C',     'c.le@gmail.com',     '0955333444', N'78 Nguyễn Huệ, Đà Nẵng',             '1990-11-05');

-- ── BankAccounts ──────────────────────────────────────────────
DECLARE @Acc1A UNIQUEIDENTIFIER = NEWID();  -- Cust1 payment
DECLARE @Acc1B UNIQUEIDENTIFIER = NEWID();  -- Cust1 saving
DECLARE @Acc2A UNIQUEIDENTIFIER = NEWID();  -- Cust2 payment
DECLARE @Acc3A UNIQUEIDENTIFIER = NEWID();  -- Cust3 debit (locked)

INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt) VALUES
    (@Acc1A, @Cust1, '9704001000001', 'payment', 15000000.00, 'active', '2023-01-10 09:00:00'),
    (@Acc1B, @Cust1, '9704001000002', 'saving',  50000000.00, 'active', '2023-06-01 10:00:00'),
    (@Acc2A, @Cust2, '9704002000001', 'payment',  8500000.00, 'active', '2024-03-15 08:30:00'),
    (@Acc3A, @Cust3, '9704003000001', 'debit',    2000000.00, 'locked', '2022-11-20 11:00:00');

-- ── Transactions ──────────────────────────────────────────────
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (NULL,   @Acc1A, @UCust1, 'deposit',  5000000.00, 'success', N'Nạp tiền ATM');

INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc1A, NULL,   @UCust1, 'withdraw', 1000000.00, 'success', N'Rút tiền quầy');

INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc1A, @Acc2A, @UCust1, 'transfer', 2000000.00, 'success', N'Chuyển tiền cho bạn B');

INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc2A, @Acc1A, @UCust2, 'transfer',  500000.00, 'pending', N'Chuyển lại tiền');

INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc3A, NULL,   @UCust3, 'withdraw', 5000000.00, 'failed',  N'Số dư không đủ');

-- ── AuditLogs ─────────────────────────────────────────────────
INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description) VALUES
    (@UAdmin,   'CREATE_BANKER',  'Bankers',      @Banker1, N'Admin tạo tài khoản banker EMP-001'),
    (@UAdmin,   'CREATE_BANKER',  'Bankers',      @Banker2, N'Admin tạo tài khoản banker EMP-002'),
    (@UAdmin,   'LOCK_USER',      'Users',        @UBanker2, N'Admin khoá banker EMP-002'),
    (@UBanker1, 'CREATE_ACCOUNT', 'BankAccounts', @Acc1A,   N'Banker tạo tài khoản thanh toán cho Nguyễn Văn A'),
    (@UBanker1, 'LOCK_ACCOUNT',   'BankAccounts', @Acc3A,   N'Banker khoá tài khoản của Lê Văn C theo yêu cầu'),
    (@UBanker1, 'VIEW_CUSTOMER',  'Customers',    @Cust2,   N'Banker xem thông tin Trần Thị B');

-- ── LoginLogs ─────────────────────────────────────────────────
INSERT INTO LoginLogs (UserId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress) VALUES
    (@UAdmin,   'admin',        '2025-06-05 08:00:00', '2025-06-05 11:00:00', 'success', '192.168.1.1'),
    (@UBanker1, 'banker_nam',   '2025-06-05 08:15:00', '2025-06-05 17:30:00', 'success', '192.168.1.10'),
    (@UCust1,   'nguyen_van_a', '2025-06-05 10:00:00', '2025-06-05 10:45:00', 'success', '14.232.0.1'),
    (@UCust1,   'nguyen_van_a', '2025-06-04 09:00:00', NULL,                  'failed',  '14.232.0.1'),
    (@UCust2,   'tran_thi_b',   '2025-06-04 14:30:00', '2025-06-04 15:00:00', 'success', '27.65.10.5'),
    (@UCust3,   'le_van_c',     '2025-05-01 11:00:00', '2025-05-01 11:02:00', 'success', '113.185.4.2');

GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

-- ──────────────────────────────────────────────────────────────
-- sp_RegisterCustomer
-- Đăng ký khách hàng mới + tạo tài khoản thanh toán mặc định
-- Tất cả trong 1 atomic transaction: nếu bất kỳ bước nào lỗi
-- thì toàn bộ bị ROLLBACK (không có user "mồ côi" hay customer
-- không có tài khoản).
-- ──────────────────────────────────────────────────────────────
CREATE OR ALTER PROCEDURE dbo.sp_RegisterCustomer
    @Username     NVARCHAR(100),
    @PasswordHash NVARCHAR(256),   -- bcrypt hash từ Python
    @FullName     NVARCHAR(150),
    @Email        NVARCHAR(200),
    @PhoneNumber  NVARCHAR(20),
    @Address      NVARCHAR(500)  = NULL,
    @BirthDay     DATE           = NULL,
    -- OUTPUT params để trả kết quả về Python
    @UserId       UNIQUEIDENTIFIER OUTPUT,
    @CustomerId   UNIQUEIDENTIFIER OUTPUT,
    @AccountNumber NVARCHAR(20)  OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;   -- tự ROLLBACK nếu có lỗi runtime

    BEGIN TRANSACTION;
    BEGIN TRY

        -- ── 1. Kiểm tra username / email chưa tồn tại ────────
        IF EXISTS (SELECT 1 FROM dbo.Users WHERE Username = @Username)
            THROW 50010, N'Username đã tồn tại', 1;

        IF EXISTS (SELECT 1 FROM dbo.Customers WHERE Email = @Email)
            THROW 50011, N'Email đã được sử dụng', 1;

        IF EXISTS (SELECT 1 FROM dbo.Customers WHERE PhoneNumber = @PhoneNumber)
            THROW 50012, N'Số điện thoại đã được sử dụng', 1;

        -- ── 2. Lấy RoleId của Customer ────────────────────────
        DECLARE @RoleId UNIQUEIDENTIFIER;
        SELECT @RoleId = RoleId FROM dbo.Roles WHERE RoleName = 'Customer';
        IF @RoleId IS NULL
            THROW 50013, N'Role Customer không tồn tại trong hệ thống', 1;

        -- ── 3. Tạo User ───────────────────────────────────────
        SET @UserId = NEWID();
        INSERT INTO dbo.Users (UserId, RoleId, Username, PasswordHash)
        VALUES (@UserId, @RoleId, @Username, @PasswordHash);

        -- ── 4. Tạo Customer profile ───────────────────────────
        SET @CustomerId = NEWID();
        INSERT INTO dbo.Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay)
        VALUES (@CustomerId, @UserId, @FullName, @Email, @PhoneNumber, @Address, @BirthDay);

        -- ── 5. Sinh số tài khoản tự động (9704 + 9 chữ số) ───
        -- Dùng timestamp microseconds để đảm bảo unique
        DECLARE @Suffix NVARCHAR(9);
        SET @Suffix = RIGHT('000000000' + CAST(
            ABS(CHECKSUM(NEWID())) % 1000000000
        AS NVARCHAR(9)), 9);
        SET @AccountNumber = '9704' + @Suffix;

        -- Đảm bảo số TK chưa tồn tại (collision rất hiếm nhưng phòng ngừa)
        WHILE EXISTS (SELECT 1 FROM dbo.BankAccounts WHERE AccountNumber = @AccountNumber)
        BEGIN
            SET @Suffix = RIGHT('000000000' + CAST(
                ABS(CHECKSUM(NEWID())) % 1000000000
            AS NVARCHAR(9)), 9);
            SET @AccountNumber = '9704' + @Suffix;
        END

        -- ── 6. Tạo BankAccount thanh toán mặc định ───────────
        INSERT INTO dbo.BankAccounts (CustomerId, AccountNumber, AccountType, Balance)
        VALUES (@CustomerId, @AccountNumber, 'payment', 0.00);

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        -- Re-throw lỗi lên tầng Python để xử lý
        THROW;
    END CATCH
END;
GO

-- ──────────────────────────────────────────────────────────────
-- DEMO: ATOMICITY - Tạo tài khoản Customer
-- Kịch bản minh họa tầm quan trọng của BEGIN TRANSACTION
-- ──────────────────────────────────────────────────────────────

-- 1. RESET: Dọn dữ liệu demo
CREATE OR ALTER PROCEDURE dbo.sp_Demo_Register_Reset
AS
BEGIN
    SET NOCOUNT ON;

    -- Xóa theo đúng thứ tự FK dependencies:
    -- Transactions → BankAccounts → Customers → Users

    -- 1. Xóa Transactions tham chiếu BankAccounts/Users của demo
    DELETE FROM dbo.Transactions
    WHERE FromBankAccountId IN (
        SELECT ba.BankAccountId FROM dbo.BankAccounts ba
        JOIN dbo.Customers c ON ba.CustomerId = c.CustomerId
        JOIN dbo.Users u ON c.UserId = u.UserId
        WHERE u.Username LIKE 'demo_%'
    )
    OR ToBankAccountId IN (
        SELECT ba.BankAccountId FROM dbo.BankAccounts ba
        JOIN dbo.Customers c ON ba.CustomerId = c.CustomerId
        JOIN dbo.Users u ON c.UserId = u.UserId
        WHERE u.Username LIKE 'demo_%'
    )
    OR CreatedByUserId IN (
        SELECT UserId FROM dbo.Users WHERE Username LIKE 'demo_%'
    );

    -- 2. Xóa AuditLogs
    DELETE FROM dbo.AuditLogs
    WHERE UserId IN (SELECT UserId FROM dbo.Users WHERE Username LIKE 'demo_%');

    -- 3. Xóa LoginLogs
    DELETE FROM dbo.LoginLogs
    WHERE UserId IN (SELECT UserId FROM dbo.Users WHERE Username LIKE 'demo_%');

    -- 4. Xóa BankAccounts
    DELETE FROM dbo.BankAccounts
    WHERE CustomerId IN (
        SELECT c.CustomerId FROM dbo.Customers c
        JOIN dbo.Users u ON c.UserId = u.UserId
        WHERE u.Username LIKE 'demo_%'
    );

    -- 5. Xóa Customers
    DELETE FROM dbo.Customers
    WHERE UserId IN (SELECT UserId FROM dbo.Users WHERE Username LIKE 'demo_%');

    -- 6. Xóa Users
    DELETE FROM dbo.Users WHERE Username LIKE 'demo_%';

    -- 7. Clear demo logs
    EXEC dbo.sp_Demo_ClearLogs @Scenario = N'REGISTER';

    EXEC dbo.sp_Demo_Log
        @Scenario = N'REGISTER',
        @Actor    = N'System',
        @Action   = N'RESET',
        @Message  = N'Reset hoàn tất. Đã xóa tất cả demo users, transactions, accounts.';
END;

GO

-- 2. BAD: Tạo tài khoản KHÔNG dùng TRANSACTION
--    → Nếu bước tạo BankAccount lỗi, User và Customer vẫn bị ghi vào DB (orphan)
CREATE OR ALTER PROCEDURE dbo.sp_Demo_Register_Bad
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Scenario   NVARCHAR(50) = N'REGISTER';
    DECLARE @Actor      NVARCHAR(20) = N'BAD';
    DECLARE @UserId     UNIQUEIDENTIFIER = NEWID();
    DECLARE @CustomerId UNIQUEIDENTIFIER = NEWID();
    DECLARE @RoleId     UNIQUEIDENTIFIER;

    -- Lấy role Customer
    SELECT @RoleId = RoleId FROM dbo.Roles WHERE RoleName = 'Customer';

    EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'START',
        @Message=N'[BAD] Bắt đầu đăng ký - KHÔNG có BEGIN TRANSACTION';

    -- Bước 1: Tạo User (KHÔNG có transaction bao ngoài)
    BEGIN TRY
        INSERT INTO dbo.Users (UserId, RoleId, Username, PasswordHash)
        VALUES (@UserId, @RoleId, 'demo_user_bad', '$2b$12$placeholder_hash_bad');

        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
            @Message=N'[BAD] ✅ Bước 1: INSERT Users thành công → UserId = ' +
                     CAST(@UserId AS NVARCHAR(36));
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg1 NVARCHAR(1000) = N'[BAD] ❌ Bước 1 thất bại: ' + ERROR_MESSAGE();
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'ERROR',
            @Message=@ErrMsg1;
        RETURN;
    END CATCH;

    -- Bước 2: Tạo Customer (KHÔNG có transaction)
    BEGIN TRY
        INSERT INTO dbo.Customers (CustomerId, UserId, FullName, Email, PhoneNumber)
        VALUES (@CustomerId, @UserId, N'Demo User (BAD)', 'demo_bad@test.com', '0900000001');

        DECLARE @Msg2 NVARCHAR(1000) = N'[BAD] ✅ Bước 2: INSERT Customers thành công → CustomerId = ' + CAST(@CustomerId AS NVARCHAR(36));
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
            @Message=@Msg2;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg2 NVARCHAR(1000) = N'[BAD] ❌ Bước 2 thất bại: ' + ERROR_MESSAGE();
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'ERROR',
            @Message=@ErrMsg2;
        RETURN;
    END CATCH;

    -- Bước 3: Tạo BankAccount - CỐ TÌNH GÂY LỖI (AccountType không hợp lệ)
    EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
        @Message=N'[BAD] ⚡ Bước 3: Đang INSERT BankAccounts với AccountType không hợp lệ...';

    BEGIN TRY
        INSERT INTO dbo.BankAccounts (CustomerId, AccountNumber, AccountType, Balance)
        VALUES (@CustomerId, '9704_DEMO_BAD', 'INVALID_TYPE', 0.00);
        -- ↑ CHECK CONSTRAINT sẽ REJECT vì AccountType phải là payment/saving/debit
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg3 NVARCHAR(1000) = N'[BAD] ❌ Bước 3 THẤT BẠI: ' + ERROR_MESSAGE();
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'ERROR',
            @Message=@ErrMsg3;

        DECLARE @Msg3 NVARCHAR(1000) = N'[BAD] ⚠️ KẾT QUẢ: User + Customer ĐÃ ĐƯỢC GHI vào DB nhưng KHÔNG có BankAccount! → Customer "mồ côi" không thể đăng nhập có tài khoản.';
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'RESULT',
            @Message=@Msg3;
    END CATCH;
END;
GO

-- 3. FIX: Tạo tài khoản CÓ dùng TRANSACTION (gọi sp_RegisterCustomer)
--    → Nếu bất kỳ bước nào lỗi, ROLLBACK toàn bộ — DB sạch sẽ
CREATE OR ALTER PROCEDURE dbo.sp_Demo_Register_Fix
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Scenario      NVARCHAR(50) = N'REGISTER';
    DECLARE @Actor         NVARCHAR(20) = N'FIX';
    DECLARE @UserId        UNIQUEIDENTIFIER;
    DECLARE @CustomerId    UNIQUEIDENTIFIER;
    DECLARE @AccountNumber NVARCHAR(20);

    EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'START',
        @Message=N'[FIX] Bắt đầu đăng ký - CÓ BEGIN TRANSACTION (gọi sp_RegisterCustomer)';

    EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'BEGIN',
        @Message=N'[FIX] BEGIN TRANSACTION — toàn bộ 3 bước INSERT nằm trong 1 transaction';

    BEGIN TRY
        -- Gọi sp_RegisterCustomer - bên trong nó có BEGIN TRANSACTION / ROLLBACK
        EXEC dbo.sp_RegisterCustomer
            @Username      = 'demo_user_fix',
            @PasswordHash  = '$2b$12$placeholder_hash_fix',
            @FullName      = N'Demo User (FIX)',
            @Email         = 'demo_fix@test.com',
            @PhoneNumber   = '0900000002',
            @UserId        = @UserId        OUTPUT,
            @CustomerId    = @CustomerId    OUTPUT,
            @AccountNumber = @AccountNumber OUTPUT;

        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
            @Message=N'[FIX] ✅ Bước 1: INSERT Users thành công';

        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
            @Message=N'[FIX] ✅ Bước 2: INSERT Customers thành công';

        DECLARE @MsgFix NVARCHAR(1000) = N'[FIX] ✅ Bước 3: INSERT BankAccounts thành công → Số TK: ' + @AccountNumber;
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'INSERT',
            @Message=@MsgFix;

        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'COMMIT',
            @Message=N'[FIX] ✅ COMMIT — Tất cả 3 bước thành công, dữ liệu được lưu hoàn chỉnh.';

        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'RESULT',
            @Message=N'[FIX] ✅ KẾT QUẢ: User + Customer + BankAccount đều được tạo đầy đủ và nhất quán.';

    END TRY
    BEGIN CATCH
        DECLARE @ErrFix NVARCHAR(1000) = N'[FIX] 🔄 ROLLBACK — Lỗi xảy ra: ' + ERROR_MESSAGE() + N' → TOÀN BỘ bị hoàn tác, DB vẫn sạch.';
        EXEC dbo.sp_Demo_Log @Scenario=@Scenario, @Actor=@Actor, @Action=N'ROLLBACK',
            @Message=@ErrFix;
    END CATCH;
END;
GO

-- sp_Deposit: Nạp tiền vào tài khoản
CREATE OR ALTER PROCEDURE sp_Deposit
    @BankAccountId   UNIQUEIDENTIFIER,
    @Amount          DECIMAL(18,2),
    @CreatedByUserId UNIQUEIDENTIFIER,
    @Description     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @Amount <= 0
            THROW 50001, N'Số tiền phải lớn hơn 0', 1;

        IF NOT EXISTS (
            SELECT 1 FROM BankAccounts
            WHERE BankAccountId = @BankAccountId AND Status = 'active'
        )
            THROW 50002, N'Tài khoản không tồn tại hoặc bị khóa', 1;

        UPDATE BankAccounts
        SET Balance = Balance + @Amount
        WHERE BankAccountId = @BankAccountId;

        INSERT INTO Transactions
            (ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        VALUES
            (@BankAccountId, @CreatedByUserId, 'deposit', @Amount, 'success', @Description);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- sp_Withdraw: Rút tiền từ tài khoản
CREATE OR ALTER PROCEDURE sp_Withdraw
    @BankAccountId   UNIQUEIDENTIFIER,
    @Amount          DECIMAL(18,2),
    @CreatedByUserId UNIQUEIDENTIFIER,
    @Description     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @Amount <= 0
            THROW 50001, N'Số tiền phải lớn hơn 0', 1;

        DECLARE @Balance DECIMAL(18,2);
        DECLARE @Status  NVARCHAR(20);

        SELECT @Balance = Balance, @Status = Status
        FROM BankAccounts
        WHERE BankAccountId = @BankAccountId;

        IF @Status IS NULL
            THROW 50002, N'Tài khoản không tồn tại', 1;
        IF @Status != 'active'
            THROW 50003, N'Tài khoản bị khóa hoặc đã đóng', 1;
        IF @Balance < @Amount
            THROW 50004, N'Số dư không đủ', 1;

        UPDATE BankAccounts
        SET Balance = Balance - @Amount
        WHERE BankAccountId = @BankAccountId;

        INSERT INTO Transactions
            (FromBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        VALUES
            (@BankAccountId, @CreatedByUserId, 'withdraw', @Amount, 'success', @Description);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        -- Ghi nhận thất bại
        INSERT INTO Transactions
            (FromBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        VALUES
            (@BankAccountId, @CreatedByUserId, 'withdraw', @Amount, 'failed',
             ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- sp_Transfer: Chuyển khoản (atomic)
CREATE OR ALTER PROCEDURE sp_Transfer
    @FromBankAccountId UNIQUEIDENTIFIER,
    @ToBankAccountId   UNIQUEIDENTIFIER,
    @Amount            DECIMAL(18,2),
    @CreatedByUserId   UNIQUEIDENTIFIER,
    @Description       NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF @Amount <= 0
            THROW 50001, N'Số tiền phải lớn hơn 0', 1;
        IF @FromBankAccountId = @ToBankAccountId
            THROW 50005, N'Không thể chuyển cho chính mình', 1;

        DECLARE @FromBalance DECIMAL(18,2), @FromStatus NVARCHAR(20);
        SELECT @FromBalance = Balance, @FromStatus = Status
        FROM BankAccounts WHERE BankAccountId = @FromBankAccountId;

        IF @FromStatus IS NULL  THROW 50002, N'Tài khoản nguồn không tồn tại', 1;
        IF @FromStatus != 'active' THROW 50003, N'Tài khoản nguồn bị khóa', 1;
        IF @FromBalance < @Amount  THROW 50004, N'Số dư không đủ', 1;

        IF NOT EXISTS (
            SELECT 1 FROM BankAccounts
            WHERE BankAccountId = @ToBankAccountId AND Status = 'active'
        )
            THROW 50006, N'Tài khoản đích không tồn tại hoặc bị khóa', 1;

        UPDATE BankAccounts SET Balance = Balance - @Amount
        WHERE BankAccountId = @FromBankAccountId;

        UPDATE BankAccounts SET Balance = Balance + @Amount
        WHERE BankAccountId = @ToBankAccountId;

        INSERT INTO Transactions
            (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        VALUES
            (@FromBankAccountId, @ToBankAccountId, @CreatedByUserId,
             'transfer', @Amount, 'success', @Description);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        INSERT INTO Transactions
            (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
        VALUES
            (@FromBankAccountId, @ToBankAccountId, @CreatedByUserId,
             'transfer', @Amount, 'failed', ERROR_MESSAGE());
        THROW;
    END CATCH
END
GO

-- ============================================================
-- DEMO LOGS & PROCEDURES (Sprint 2 & 3 Demo Framework)
-- ============================================================

IF OBJECT_ID('dbo.Demo_Logs', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Demo_Logs;
END
GO

CREATE TABLE dbo.Demo_Logs
(
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    Scenario NVARCHAR(50) NOT NULL,
    SessionId INT NOT NULL,
    Actor NVARCHAR(20) NOT NULL,
    Action NVARCHAR(30),
    ActionTime DATETIME2(3)
        CONSTRAINT DF_DemoLogs_ActionTime
        DEFAULT SYSDATETIME(),
    Message NVARCHAR(500) NOT NULL
);
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Log
(
    @Scenario NVARCHAR(50),
    @Actor NVARCHAR(20),
    @Action NVARCHAR(30),
    @Message NVARCHAR(500)
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Demo_Logs
    (
        Scenario,
        SessionId,
        Actor,
        Action,
        Message
    )
    VALUES
    (
        @Scenario,
        @@SPID,
        @Actor,
        @Action,
        @Message
    );
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_ClearLogs
(
    @Scenario NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Scenario IS NULL
    BEGIN
        DELETE FROM dbo.Demo_Logs;
    END
    ELSE
    BEGIN
        DELETE FROM dbo.Demo_Logs
        WHERE Scenario = @Scenario;
    END
END
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_GetLogs
(
    @Scenario NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LogId,
        Scenario,
        SessionId,
        Actor,
        Action,
        ActionTime,
        Message
    FROM dbo.Demo_Logs
    WHERE
        @Scenario IS NULL
        OR Scenario = @Scenario
    ORDER BY
        ActionTime,
        LogId;
END
GO

-- Ensure the index for range locking exists
IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_Transactions_DailyLimitDemo'
      AND object_id = OBJECT_ID('dbo.Transactions')
)
BEGIN
    CREATE INDEX IX_Transactions_DailyLimitDemo
    ON dbo.Transactions (FromBankAccountId, Type, Status, CreatedAt)
    INCLUDE (Amount);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Reset
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'PHANTOM';
    DECLARE @Actor NVARCHAR(20) = N'System';
    DECLARE @Action NVARCHAR(30) = N'RESET';

    -- 1. Xóa các giao dịch demo cũ
    DELETE FROM dbo.Transactions
    WHERE Description LIKE N'PHANTOM_LIMIT_DEMO|%';

    -- 2. Xóa logs của Scenario PHANTOM
    EXEC dbo.sp_Demo_ClearLogs @Scenario = @Scenario;

    -- 3. Tìm tài khoản nguồn, tài khoản đích và User active
    DECLARE @FromAccountId UNIQUEIDENTIFIER;
    DECLARE @ToAccountId UNIQUEIDENTIFIER;
    DECLARE @UserId UNIQUEIDENTIFIER;

    SELECT TOP 1 @FromAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
    ORDER BY AccountNumber;

    SELECT TOP 1 @ToAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
      AND BankAccountId <> @FromAccountId
    ORDER BY AccountNumber;

    SELECT TOP 1 @UserId = UserId
    FROM dbo.Users
    WHERE Status = 'active'
    ORDER BY Username;

    IF @FromAccountId IS NULL OR @ToAccountId IS NULL OR @UserId IS NULL
    BEGIN
        THROW 51000, N'Không đủ dữ liệu mẫu: cần ít nhất 2 tài khoản active và 1 user active.', 1;
    END;

    -- Reset balance of from account to 200M so we have enough balance to demo limit
    UPDATE dbo.BankAccounts
    SET Balance = 200000000.00
    WHERE BankAccountId = @FromAccountId;

    -- 4. Tạo baseline giao dịch chuyển khoản 80.000.000 VND cho ngày hôm nay
    INSERT INTO dbo.Transactions (
        TransactionId,
        FromBankAccountId,
        ToBankAccountId,
        CreatedByUserId,
        Type,
        Amount,
        Status,
        CreatedAt,
        Description
    )
    VALUES (
        NEWID(),
        @FromAccountId,
        @ToAccountId,
        @UserId,
        'transfer',
        80000000.00,
        'success',
        SYSDATETIME(),
        N'PHANTOM_LIMIT_DEMO|BASELINE|Today total starts at 80,000,000'
    );

    -- 5. Ghi log hoàn thành reset
    EXEC dbo.sp_Demo_Log 
        @Scenario = @Scenario,
        @Actor = @Actor,
        @Action = @Action,
        @Message = N'Reset complete. Baseline transfer = 80,000,000.';
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Bad
    @Delay CHAR(8) = '00:00:08'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'PHANTOM';
    DECLARE @Actor NVARCHAR(20) = CONCAT(N'Session ', @@SPID);
    DECLARE @Message NVARCHAR(500);

    DECLARE @DailyLimit DECIMAL(18,2) = 100000000;
    DECLARE @TransferAmount DECIMAL(18,2) = 15000000;
    DECLARE @TodayTotal DECIMAL(18,2);
    DECLARE @FinalTotal DECIMAL(18,2);

    DECLARE @FromAccountId UNIQUEIDENTIFIER;
    DECLARE @ToAccountId UNIQUEIDENTIFIER;
    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @TransactionId UNIQUEIDENTIFIER = NEWID();

    DECLARE @StartOfDay DATETIME2(3) =
        CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

    DECLARE @EndOfDay DATETIME2(3) =
        DATEADD(DAY, 1, @StartOfDay);

    -- Tìm dữ liệu mẫu
    SELECT TOP 1 @FromAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
    ORDER BY AccountNumber;

    SELECT TOP 1 @ToAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
      AND BankAccountId <> @FromAccountId
    ORDER BY AccountNumber;

    SELECT TOP 1 @UserId = UserId
    FROM dbo.Users
    WHERE Status = 'active'
    ORDER BY Username;

    IF @FromAccountId IS NULL OR @ToAccountId IS NULL OR @UserId IS NULL
    BEGIN
        THROW 52000, N'Không đủ dữ liệu mẫu: cần ít nhất 2 tài khoản active và 1 user active.', 1;
    END;

    BEGIN TRY
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'BEGIN',
            @Message = N'BAD: BEGIN TRANSACTION';

        BEGIN TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = N'BAD: Before reading today transfer SUM';

        -- Đọc tổng tiền chuyển hôm nay dưới mức Read Committed
        SELECT @TodayTotal = ISNULL(SUM(Amount), 0)
        FROM dbo.Transactions
        WHERE FromBankAccountId = @FromAccountId
          AND Type = 'transfer'
          AND Status = 'success'
          AND CreatedAt >= @StartOfDay
          AND CreatedAt < @EndOfDay
          AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';

        SET @Message = CONCAT(
            N'BAD: TodayTotal read = ',
            CONVERT(NVARCHAR(50), CAST(@TodayTotal AS MONEY), 1)
        );

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = @Message;

        SET @Message = CONCAT(N'BAD: Before WAITFOR ', @Delay);

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'WAITFOR',
            @Message = @Message;

        -- Chờ để tạo cơ hội đồng thời
        WAITFOR DELAY @Delay;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'AFTER WAITFOR',
            @Message = N'BAD: After WAITFOR';

        -- Kiểm tra hạn mức dựa trên tổng cũ đã đọc
        IF @TodayTotal + @TransferAmount <= @DailyLimit
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = N'BAD: Limit check PASSED based on old SUM. Before INSERT';

            INSERT INTO dbo.Transactions (
                TransactionId,
                FromBankAccountId,
                ToBankAccountId,
                CreatedByUserId,
                Type,
                Amount,
                Status,
                CreatedAt,
                Description
            )
            VALUES (
                @TransactionId,
                @FromAccountId,
                @ToAccountId,
                @UserId,
                'transfer',
                @TransferAmount,
                'success',
                SYSDATETIME(),
                N'PHANTOM_LIMIT_DEMO|BAD|Inserted transfer after stale SUM check'
            );

            SET @Message = CONCAT(
                N'BAD: Inserted transfer amount = ',
                CONVERT(NVARCHAR(50), CAST(@TransferAmount AS MONEY), 1),
                N', TransactionId = ',
                CONVERT(NVARCHAR(36), @TransactionId)
            );

            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'INSERT',
                @Message = @Message;
        END
        ELSE
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = N'BAD: Limit check FAILED. No insert.';
        END;

        -- Đọc lại tổng tiền chuyển để ghi log kiểm tra
        SELECT @FinalTotal = ISNULL(SUM(Amount), 0)
        FROM dbo.Transactions
        WHERE FromBankAccountId = @FromAccountId
          AND Type = 'transfer'
          AND Status = 'success'
          AND CreatedAt >= @StartOfDay
          AND CreatedAt < @EndOfDay
          AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';

        SET @Message = CONCAT(
            N'BAD: FinalTotal visible inside transaction = ',
            CONVERT(NVARCHAR(50), CAST(@FinalTotal AS MONEY), 1)
        );

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'FINAL SUM',
            @Message = @Message;

        COMMIT TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'COMMIT',
            @Message = N'BAD: COMMIT';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Message = CONCAT(N'BAD ERROR: ', ERROR_MESSAGE());

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ROLLBACK',
            @Message = @Message;

        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Fix
    @Delay CHAR(8) = '00:00:08'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'PHANTOM';
    DECLARE @Actor NVARCHAR(20) = CONCAT(N'Session ', @@SPID);
    DECLARE @Message NVARCHAR(500);

    DECLARE @DailyLimit DECIMAL(18,2) = 100000000;
    DECLARE @TransferAmount DECIMAL(18,2) = 15000000;
    DECLARE @TodayTotal DECIMAL(18,2);
    DECLARE @FinalTotal DECIMAL(18,2);

    DECLARE @FromAccountId UNIQUEIDENTIFIER;
    DECLARE @ToAccountId UNIQUEIDENTIFIER;
    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @TransactionId UNIQUEIDENTIFIER = NEWID();

    DECLARE @StartOfDay DATETIME2(3) =
        CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

    DECLARE @EndOfDay DATETIME2(3) =
        DATEADD(DAY, 1, @StartOfDay);

    -- Tìm dữ liệu mẫu
    SELECT TOP 1 @FromAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
    ORDER BY AccountNumber;

    SELECT TOP 1 @ToAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE Status = 'active'
      AND BankAccountId <> @FromAccountId
    ORDER BY AccountNumber;

    SELECT TOP 1 @UserId = UserId
    FROM dbo.Users
    WHERE Status = 'active'
    ORDER BY Username;

    IF @FromAccountId IS NULL OR @ToAccountId IS NULL OR @UserId IS NULL
    BEGIN
        THROW 53000, N'Không đủ dữ liệu mẫu: cần ít nhất 2 tài khoản active và 1 user active.', 1;
    END;

    -- Thiết lập mức cô lập SERIALIZABLE để tránh lỗi Phantom Read
    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'BEGIN',
            @Message = N'FIX: BEGIN TRANSACTION with SERIALIZABLE';

        BEGIN TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = N'FIX: Before reading today SUM with UPDLOCK, HOLDLOCK';

        -- Sử dụng UPDLOCK, HOLDLOCK trên chỉ mục thích hợp để đặt Range Lock
        SELECT @TodayTotal = ISNULL(SUM(Amount), 0)
        FROM dbo.Transactions WITH (UPDLOCK, HOLDLOCK, INDEX(IX_Transactions_DailyLimitDemo))
        WHERE FromBankAccountId = @FromAccountId
          AND Type = 'transfer'
          AND Status = 'success'
          AND CreatedAt >= @StartOfDay
          AND CreatedAt < @EndOfDay
          AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';

        SET @Message = CONCAT(
            N'FIX: TodayTotal read = ',
            CONVERT(NVARCHAR(50), CAST(@TodayTotal AS MONEY), 1)
        );

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = @Message;

        SET @Message = CONCAT(N'FIX: Before WAITFOR ', @Delay);

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'WAITFOR',
            @Message = @Message;

        -- Chờ để tạo cơ hội đồng thời
        WAITFOR DELAY @Delay;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'AFTER WAITFOR',
            @Message = N'FIX: After WAITFOR';

        -- Kiểm tra hạn mức
        IF @TodayTotal + @TransferAmount <= @DailyLimit
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = N'FIX: Limit check PASSED. Before INSERT';

            INSERT INTO dbo.Transactions (
                TransactionId,
                FromBankAccountId,
                ToBankAccountId,
                CreatedByUserId,
                Type,
                Amount,
                Status,
                CreatedAt,
                Description
            )
            VALUES (
                @TransactionId,
                @FromAccountId,
                @ToAccountId,
                @UserId,
                'transfer',
                @TransferAmount,
                'success',
                SYSDATETIME(),
                N'PHANTOM_LIMIT_DEMO|FIX|Inserted transfer after protected SUM check'
            );

            SET @Message = CONCAT(
                N'FIX: Inserted transfer amount = ',
                CONVERT(NVARCHAR(50), CAST(@TransferAmount AS MONEY), 1),
                N', TransactionId = ',
                CONVERT(NVARCHAR(36), @TransactionId)
            );

            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'INSERT',
                @Message = @Message;
        END
        ELSE
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = N'FIX: Limit check FAILED. No insert.';
        END;

        -- Đọc lại tổng để ghi log kiểm tra
        SELECT @FinalTotal = ISNULL(SUM(Amount), 0)
        FROM dbo.Transactions
        WHERE FromBankAccountId = @FromAccountId
          AND Type = 'transfer'
          AND Status = 'success'
          AND CreatedAt >= @StartOfDay
          AND CreatedAt < @EndOfDay
          AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';

        SET @Message = CONCAT(
            N'FIX: FinalTotal visible inside transaction = ',
            CONVERT(NVARCHAR(50), CAST(@FinalTotal AS MONEY), 1)
        );

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'FINAL SUM',
            @Message = @Message;

        COMMIT TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'COMMIT',
            @Message = N'FIX: COMMIT';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Message = CONCAT(N'FIX ERROR: ', ERROR_MESSAGE());

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ROLLBACK',
            @Message = @Message;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        THROW;
    END CATCH;

    -- Đưa mức cô lập trở về mặc định của connection
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END;
GO

-- ============================================================
-- sp_Demo_Phantom_Transfer: Hỗ trợ demo tương tranh Phantom Read
-- ============================================================
CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Transfer
    @FromBankAccountId UNIQUEIDENTIFIER,
    @ToBankAccountId   UNIQUEIDENTIFIER,
    @Amount            DECIMAL(18,2),
    @CreatedByUserId   UNIQUEIDENTIFIER,
    @Description       NVARCHAR(500),
    @Delay             CHAR(8),
    @IsFix             INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- All DECLARE statements at the very top
    DECLARE @Scenario NVARCHAR(50);
    DECLARE @Actor NVARCHAR(20);
    DECLARE @Message NVARCHAR(500);
    DECLARE @DailyLimit DECIMAL(18,2);
    DECLARE @TodayTotal DECIMAL(18,2);
    DECLARE @StartOfDay DATETIME2(3);
    DECLARE @EndOfDay DATETIME2(3);
    DECLARE @Prefix NVARCHAR(10);
    DECLARE @BeginMsg NVARCHAR(100);
    DECLARE @ReadMsg NVARCHAR(100);
    DECLARE @FinalTotal DECIMAL(18,2);

    -- Assignments
    SET @Scenario = N'PHANTOM';
    SET @DailyLimit = 100000000;
    SET @Actor = CONCAT(N'Session ', @@SPID);
    SET @StartOfDay = CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));
    SET @EndOfDay = DATEADD(DAY, 1, @StartOfDay);
    IF @IsFix = 1
    BEGIN
        SET @Prefix = N'FIX';
        SET @BeginMsg = N'FIX: BEGIN TRANSACTION with SERIALIZABLE';
        SET @ReadMsg = N'FIX: Before reading today SUM with UPDLOCK, HOLDLOCK';
    END
    ELSE
    BEGIN
        SET @Prefix = N'BAD';
        SET @BeginMsg = N'BAD: BEGIN TRANSACTION';
        SET @ReadMsg = N'BAD: Before reading today transfer SUM';
    END

    IF @IsFix = 1
    BEGIN
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 3. Read Today's Total
        IF @IsFix = 1
        BEGIN
            SELECT @TodayTotal = ISNULL(SUM(Amount), 0)
            FROM dbo.Transactions WITH (UPDLOCK, HOLDLOCK, INDEX(IX_Transactions_DailyLimitDemo))
            WHERE FromBankAccountId = @FromBankAccountId
              AND Type = 'transfer'
              AND Status = 'success'
              AND CreatedAt >= @StartOfDay
              AND CreatedAt < @EndOfDay
              AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';
        END
        ELSE
        BEGIN
            SELECT @TodayTotal = ISNULL(SUM(Amount), 0)
            FROM dbo.Transactions
            WHERE FromBankAccountId = @FromBankAccountId
              AND Type = 'transfer'
              AND Status = 'success'
              AND CreatedAt >= @StartOfDay
              AND CreatedAt < @EndOfDay
              AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';
        END

        -- 4. Log TodayTotal Read
        SET @Message = @Prefix + N': TodayTotal read = ' + CONVERT(NVARCHAR(50), CAST(@TodayTotal AS MONEY), 1);
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = @Message;

        -- 5. Log Before WAITFOR
        SET @Message = @Prefix + N': Before WAITFOR ' + @Delay;
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'WAITFOR',
            @Message = @Message;

        -- 6. WAITFOR DELAY
        WAITFOR DELAY @Delay;

        -- 7. Log After WAITFOR
        SET @Message = @Prefix + N': After WAITFOR';
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'AFTER WAITFOR',
            @Message = @Message;

        -- 8. Limit Check
        IF @TodayTotal + @Amount > @DailyLimit
        BEGIN
            SET @Message = @Prefix + N': Limit check FAILED. No insert.';
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = @Message;

            ;THROW 51001, N'Vượt hạn mức chuyển khoản trong ngày (100tr)', 1;
        END

        SET @Message = @Prefix + N': Limit check PASSED. Before INSERT';
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'LIMIT CHECK',
            @Message = @Message;

        -- 9. Execute the REAL sp_Transfer
        EXEC dbo.sp_Transfer
            @FromBankAccountId = @FromBankAccountId,
            @ToBankAccountId = @ToBankAccountId,
            @Amount = @Amount,
            @CreatedByUserId = @CreatedByUserId,
            @Description = @Description;

        -- 10. Log SUCCESS INSERT
        SET @Message = @Prefix + N': Inserted transfer amount = ' + CONVERT(NVARCHAR(50), CAST(@Amount AS MONEY), 1);
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'INSERT',
            @Message = @Message;

        -- 11. Final Sum check and log
        SELECT @FinalTotal = ISNULL(SUM(Amount), 0)
        FROM dbo.Transactions
        WHERE FromBankAccountId = @FromBankAccountId
          AND Type = 'transfer'
          AND Status = 'success'
          AND CreatedAt >= @StartOfDay
          AND CreatedAt < @EndOfDay
          AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';

        SET @Message = @Prefix + N': FinalTotal visible inside transaction = ' + CONVERT(NVARCHAR(50), CAST(@FinalTotal AS MONEY), 1);
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'FINAL SUM',
            @Message = @Message;

        COMMIT TRANSACTION;

        -- 12. Log COMMIT
        SET @Message = @Prefix + N': COMMIT';
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'COMMIT',
            @Message = @Message;

        IF @IsFix = 1
        BEGIN
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        END
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        IF @IsFix = 1
        BEGIN
            SET @Message = N'FIX ERROR: ' + ERROR_MESSAGE();
        END
        ELSE
        BEGIN
            SET @Message = N'BAD ERROR: ' + ERROR_MESSAGE();
        END

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ROLLBACK',
            @Message = @Message;

        IF @IsFix = 1
        BEGIN
            SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
        END

        ;THROW;
    END CATCH
END
GO