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
-- SAMPLE DATA
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
-- Passwords are SHA-256 placeholders (in production use bcrypt)
DECLARE @UAdmin   UNIQUEIDENTIFIER = NEWID();
DECLARE @UBanker1 UNIQUEIDENTIFIER = NEWID();
DECLARE @UBanker2 UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust1   UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust2   UNIQUEIDENTIFIER = NEWID();
DECLARE @UCust3   UNIQUEIDENTIFIER = NEWID();
 
INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt) VALUES
    (@UAdmin,   @RoleAdmin,    'admin',       'hash_Admin@123',    'active', '2025-06-05 08:00:00'),
    (@UBanker1, @RoleBanker,   'banker_nam',  'hash_Banker@123',   'active', '2025-06-05 08:15:00'),
    (@UBanker2, @RoleBanker,   'banker_lan',  'hash_Banker@456',   'locked', '2025-05-20 09:00:00'),
    (@UCust1,   @RoleCustomer, 'nguyen_van_a','hash_Cust@111',     'active', '2025-06-05 10:00:00'),
    (@UCust2,   @RoleCustomer, 'tran_thi_b',  'hash_Cust@222',     'active', '2025-06-04 14:30:00'),
    (@UCust3,   @RoleCustomer, 'le_van_c',    'hash_Cust@333',     'locked', '2025-05-01 11:00:00');
 
-- ── Bankers ───────────────────────────────────────────────────
DECLARE @Banker1 UNIQUEIDENTIFIER = NEWID();
DECLARE @Banker2 UNIQUEIDENTIFIER = NEWID();
 
INSERT INTO Bankers (BankerId, UserId, EmployeeCode, FullName, Email, PhoneNumber) VALUES
    (@Banker1, @UBanker1, 'EMP-001', N'Trần Văn Nam',  'nam.tran@vcb.vn',   '0901234567'),
    (@Banker2, @UBanker2, 'EMP-002', N'Nguyễn Thị Lan','lan.nguyen@vcb.vn', '0912345678');
 
-- ── Customers ─────────────────────────────────────────────────
DECLARE @Cust1 UNIQUEIDENTIFIER = NEWID();
DECLARE @Cust2 UNIQUEIDENTIFIER = NEWID();
DECLARE @Cust3 UNIQUEIDENTIFIER = NEWID();
 
INSERT INTO Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay) VALUES
    (@Cust1, @UCust1, N'Nguyễn Văn A', 'a.nguyen@gmail.com', '0933111222',
        N'12 Lê Lợi, Q.1, TP.HCM', '1995-03-15'),
    (@Cust2, @UCust2, N'Trần Thị B',   'b.tran@gmail.com',   '0944222333',
        N'45 Trần Hưng Đạo, Hải Phòng', '1998-07-22'),
    (@Cust3, @UCust3, N'Lê Văn C',     'c.le@gmail.com',     '0955333444',
        N'78 Nguyễn Huệ, Đà Nẵng', '1990-11-05');
 
-- ── BankAccounts ──────────────────────────────────────────────
DECLARE @Acc1A UNIQUEIDENTIFIER = NEWID();  -- Cust1 payment
DECLARE @Acc1B UNIQUEIDENTIFIER = NEWID();  -- Cust1 saving
DECLARE @Acc2A UNIQUEIDENTIFIER = NEWID();  -- Cust2 payment
DECLARE @Acc3A UNIQUEIDENTIFIER = NEWID();  -- Cust3 payment (locked)
 
INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt) VALUES
    (@Acc1A, @Cust1, '9704001000001', 'payment', 15000000.00, 'active', '2023-01-10 09:00:00'),
    (@Acc1B, @Cust1, '9704001000002', 'saving',  50000000.00, 'active', '2023-06-01 10:00:00'),
    (@Acc2A, @Cust2, '9704002000001', 'payment',  8500000.00, 'active', '2024-03-15 08:30:00'),
    (@Acc3A, @Cust3, '9704003000001', 'debit',    2000000.00, 'locked', '2022-11-20 11:00:00');
 
-- ── Transactions ──────────────────────────────────────────────
-- deposit vào Acc1A
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (NULL, @Acc1A, @UCust1, 'deposit', 5000000.00, 'success', N'Nạp tiền ATM');
 
-- withdraw từ Acc1A
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc1A, NULL, @UCust1, 'withdraw', 1000000.00, 'success', N'Rút tiền quầy');
 
-- transfer Acc1A → Acc2A
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc1A, @Acc2A, @UCust1, 'transfer', 2000000.00, 'success', N'Chuyển tiền cho bạn B');
 
-- transfer Acc2A → Acc1A (pending - để demo concurrency)
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc2A, @Acc1A, @UCust2, 'transfer', 500000.00, 'pending', N'Chuyển lại tiền');
 
-- failed withdraw (số dư không đủ giả lập)
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)
VALUES (@Acc3A, NULL, @UCust3, 'withdraw', 5000000.00, 'failed', N'Số dư không đủ');
 
-- ── AuditLogs ─────────────────────────────────────────────────
INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description) VALUES
    (@UAdmin,   'CREATE_BANKER',   'Bankers',      @Banker1, N'Admin tạo tài khoản banker EMP-001'),
    (@UAdmin,   'CREATE_BANKER',   'Bankers',      @Banker2, N'Admin tạo tài khoản banker EMP-002'),
    (@UAdmin,   'LOCK_USER',       'Users',        @UBanker2, N'Admin khoá banker EMP-002'),
    (@UBanker1, 'CREATE_ACCOUNT',  'BankAccounts', @Acc1A, N'Banker tạo tài khoản thanh toán cho Nguyễn Văn A'),
    (@UBanker1, 'LOCK_ACCOUNT',    'BankAccounts', @Acc3A, N'Banker khoá tài khoản của Lê Văn C theo yêu cầu'),
    (@UBanker1, 'VIEW_CUSTOMER',   'Customers',    @Cust2, N'Banker xem thông tin Trần Thị B');
 
-- ── LoginLogs ─────────────────────────────────────────────────
INSERT INTO LoginLogs (UserId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress) VALUES
    (@UAdmin,   'admin',       '2025-06-05 08:00:00', '2025-06-05 11:00:00', 'success', '192.168.1.1'),
    (@UBanker1, 'banker_nam',  '2025-06-05 08:15:00', '2025-06-05 17:30:00', 'success', '192.168.1.10'),
    (@UCust1,   'nguyen_van_a','2025-06-05 10:00:00', '2025-06-05 10:45:00', 'success', '14.232.0.1'),
    (@UCust1,   'nguyen_van_a','2025-06-04 09:00:00', NULL,                  'failed',  '14.232.0.1'),
    (@UCust2,   'tran_thi_b',  '2025-06-04 14:30:00', '2025-06-04 15:00:00', 'success', '27.65.10.5'),
    (@UCust3,   'le_van_c',    '2025-05-01 11:00:00', '2025-05-01 11:02:00', 'success', '113.185.4.2');
 
GO