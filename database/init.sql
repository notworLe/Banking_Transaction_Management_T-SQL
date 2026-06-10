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
-- SEED DATA (Roles only - Users seeded by Python seed.py with bcrypt)
-- ============================================================

-- ── Roles ────────────────────────────────────────────────────
INSERT INTO Roles (RoleName) VALUES ('Admin');
INSERT INTO Roles (RoleName) VALUES ('Banker');
INSERT INTO Roles (RoleName) VALUES ('Customer');

GO

-- ============================================================
-- STORED PROCEDURES
-- ============================================================

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