USE BankingTransactionDB;
GO

-- ============================================================
-- 1. ROLES
-- ============================================================
CREATE TABLE Roles (
    RoleId   UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Roles PRIMARY KEY DEFAULT NEWID(),
    RoleName NVARCHAR(50)     NOT NULL CONSTRAINT UQ_Roles_RoleName UNIQUE
);
GO

-- ============================================================
-- 2. USERS (shared login table for all 3 roles)
-- ============================================================
CREATE TABLE Users (
    UserId       UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Users PRIMARY KEY DEFAULT NEWID(),
    RoleId       UNIQUEIDENTIFIER NOT NULL,
    Username     NVARCHAR(100)    NOT NULL CONSTRAINT UQ_Users_Username UNIQUE,
    PasswordHash NVARCHAR(256)    NOT NULL,
    Status       NVARCHAR(20)     NOT NULL CONSTRAINT DF_Users_Status DEFAULT 'active',
    LastLoginAt  DATETIME2        NULL,
    CreatedAt    DATETIME2        NOT NULL CONSTRAINT DF_Users_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Users_Roles FOREIGN KEY (RoleId) REFERENCES Roles(RoleId),
    CONSTRAINT CK_Users_Status CHECK (Status IN ('active', 'locked'))
);
GO

CREATE INDEX IX_Users_RoleId ON Users(RoleId);
CREATE INDEX IX_Users_CreatedAt ON Users(CreatedAt);
GO

-- ============================================================
-- 3. CUSTOMERS
-- ============================================================
CREATE TABLE Customers (
    CustomerId  UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Customers PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL,
    FullName    NVARCHAR(150)    NOT NULL,
    Email       NVARCHAR(200)    NOT NULL CONSTRAINT UQ_Customers_Email UNIQUE,
    PhoneNumber NVARCHAR(20)     NOT NULL CONSTRAINT UQ_Customers_PhoneNumber UNIQUE,
    Address     NVARCHAR(500)    NULL,
    BirthDay    DATE             NULL,
    CreatedAt   DATETIME2        NOT NULL CONSTRAINT DF_Customers_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Customers_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT UQ_Customers_UserId UNIQUE (UserId)
);
GO

CREATE INDEX IX_Customers_CreatedAt ON Customers(CreatedAt);
GO

-- ============================================================
-- 4. BANKERS
-- ============================================================
CREATE TABLE Bankers (
    BankerId     UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Bankers PRIMARY KEY DEFAULT NEWID(),
    UserId       UNIQUEIDENTIFIER NOT NULL,
    EmployeeCode NVARCHAR(20)     NOT NULL CONSTRAINT UQ_Bankers_EmployeeCode UNIQUE,
    FullName     NVARCHAR(150)    NOT NULL,
    Email        NVARCHAR(200)    NOT NULL CONSTRAINT UQ_Bankers_Email UNIQUE,
    PhoneNumber  NVARCHAR(20)     NOT NULL,
    CreatedAt    DATETIME2        NOT NULL CONSTRAINT DF_Bankers_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Bankers_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT UQ_Bankers_UserId UNIQUE (UserId)
);
GO

CREATE INDEX IX_Bankers_CreatedAt ON Bankers(CreatedAt);
GO

-- ============================================================
-- 5. BANK ACCOUNTS (one customer can have multiple accounts)
-- AccountType via CHECK: payment | saving | debit (không dùng bảng AccountTypes)
-- ============================================================
CREATE TABLE BankAccounts (
    BankAccountId UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_BankAccounts PRIMARY KEY DEFAULT NEWID(),
    CustomerId    UNIQUEIDENTIFIER NOT NULL,
    AccountNumber NVARCHAR(20)     NOT NULL CONSTRAINT UQ_BankAccounts_AccountNumber UNIQUE,
    AccountType   NVARCHAR(20)     NOT NULL CONSTRAINT DF_BankAccounts_AccountType DEFAULT 'payment',
    Balance       DECIMAL(18, 2)   NOT NULL CONSTRAINT DF_BankAccounts_Balance DEFAULT 0.00,
    Status        NVARCHAR(20)     NOT NULL CONSTRAINT DF_BankAccounts_Status DEFAULT 'active',
    OpenedAt      DATETIME2        NOT NULL CONSTRAINT DF_BankAccounts_OpenedAt DEFAULT SYSDATETIME(),
    ClosedAt      DATETIME2        NULL,
    CONSTRAINT FK_BankAccounts_Customers FOREIGN KEY (CustomerId) REFERENCES Customers(CustomerId),
    CONSTRAINT CK_BankAccounts_AccountType CHECK (AccountType IN ('payment', 'saving', 'debit')),
    CONSTRAINT CK_BankAccounts_Balance CHECK (Balance >= 0),
    CONSTRAINT CK_BankAccounts_Status CHECK (Status IN ('active', 'locked', 'closed'))
);
GO

CREATE INDEX IX_BankAccounts_CustomerId ON BankAccounts(CustomerId);
CREATE INDEX IX_BankAccounts_OpenedAt ON BankAccounts(OpenedAt);
GO

-- ============================================================
-- 6. TRANSACTIONS
-- ============================================================
CREATE TABLE Transactions (
    TransactionId     UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_Transactions PRIMARY KEY DEFAULT NEWID(),
    FromBankAccountId UNIQUEIDENTIFIER NULL,
    ToBankAccountId   UNIQUEIDENTIFIER NULL,
    CreatedByUserId   UNIQUEIDENTIFIER NOT NULL,
    Type              NVARCHAR(20)     NOT NULL,
    Amount            DECIMAL(18, 2)   NOT NULL,
    Status            NVARCHAR(20)     NOT NULL CONSTRAINT DF_Transactions_Status DEFAULT 'pending',
    Description       NVARCHAR(500)    NULL,
    CreatedAt         DATETIME2        NOT NULL CONSTRAINT DF_Transactions_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_Transactions_FromAccount FOREIGN KEY (FromBankAccountId) REFERENCES BankAccounts(BankAccountId),
    CONSTRAINT FK_Transactions_ToAccount FOREIGN KEY (ToBankAccountId) REFERENCES BankAccounts(BankAccountId),
    CONSTRAINT FK_Transactions_CreatedByUser FOREIGN KEY (CreatedByUserId) REFERENCES Users(UserId),
    CONSTRAINT CK_Transactions_Type CHECK (Type IN ('deposit', 'withdraw', 'transfer')),
    CONSTRAINT CK_Transactions_Amount CHECK (Amount > 0),
    CONSTRAINT CK_Transactions_Status CHECK (Status IN ('pending', 'success', 'failed')),
    CONSTRAINT CK_Transactions_Type_Accounts CHECK (
        (Type = 'deposit' AND FromBankAccountId IS NULL AND ToBankAccountId IS NOT NULL)
        OR (Type = 'withdraw' AND FromBankAccountId IS NOT NULL AND ToBankAccountId IS NULL)
        OR (
            Type = 'transfer'
            AND FromBankAccountId IS NOT NULL
            AND ToBankAccountId IS NOT NULL
            AND FromBankAccountId <> ToBankAccountId
        )
    )
);
GO

CREATE INDEX IX_Transactions_FromBankAccountId ON Transactions(FromBankAccountId);
CREATE INDEX IX_Transactions_ToBankAccountId ON Transactions(ToBankAccountId);
CREATE INDEX IX_Transactions_CreatedByUserId ON Transactions(CreatedByUserId);
CREATE INDEX IX_Transactions_CreatedAt ON Transactions(CreatedAt);
GO

-- ============================================================
-- 7. AUDIT LOGS (Banker / Admin actions)
-- ============================================================
CREATE TABLE AuditLogs (
    AuditLogId  UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_AuditLogs PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NOT NULL,
    ActionType  NVARCHAR(100)    NOT NULL,
    TargetTable NVARCHAR(100)    NULL,
    TargetId    UNIQUEIDENTIFIER NULL,
    Description NVARCHAR(1000)   NULL,
    CreatedAt   DATETIME2        NOT NULL CONSTRAINT DF_AuditLogs_CreatedAt DEFAULT SYSDATETIME(),
    CONSTRAINT FK_AuditLogs_Users FOREIGN KEY (UserId) REFERENCES Users(UserId)
);
GO

CREATE INDEX IX_AuditLogs_UserId ON AuditLogs(UserId);
CREATE INDEX IX_AuditLogs_CreatedAt ON AuditLogs(CreatedAt);
GO

-- ============================================================
-- 8. LOGIN LOGS
-- UserId NULL khi đăng nhập thất bại với username không tồn tại
-- ============================================================
CREATE TABLE LoginLogs (
    LoginLogId  UNIQUEIDENTIFIER NOT NULL CONSTRAINT PK_LoginLogs PRIMARY KEY DEFAULT NEWID(),
    UserId      UNIQUEIDENTIFIER NULL,
    UserName    NVARCHAR(100)    NOT NULL,
    LoginTime   DATETIME2        NOT NULL CONSTRAINT DF_LoginLogs_LoginTime DEFAULT SYSDATETIME(),
    LogoutTime  DATETIME2        NULL,
    LoginStatus NVARCHAR(20)     NOT NULL,
    IPAddress   NVARCHAR(45)     NULL,
    CONSTRAINT FK_LoginLogs_Users FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT CK_LoginLogs_LoginStatus CHECK (LoginStatus IN ('success', 'failed'))
);
GO

CREATE INDEX IX_LoginLogs_UserId ON LoginLogs(UserId);
CREATE INDEX IX_LoginLogs_LoginTime ON LoginLogs(LoginTime);
GO
