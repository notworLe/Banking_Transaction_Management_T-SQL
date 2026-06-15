USE banking_transaction;
GO

IF OBJECT_ID('dbo.Demo_Logs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.Demo_Logs (
        LogId BIGINT IDENTITY(1,1) PRIMARY KEY,
        DemoName NVARCHAR(100) NOT NULL,
        SessionId INT NOT NULL,
        ActionTime DATETIME2(3) NOT NULL DEFAULT SYSDATETIME(),
        Message NVARCHAR(1000) NOT NULL
    );
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE name = 'IX_DemoLogs_DemoName_ActionTime'
      AND object_id = OBJECT_ID('dbo.Demo_Logs')
)
BEGIN
    CREATE INDEX IX_DemoLogs_DemoName_ActionTime
    ON dbo.Demo_Logs (DemoName, ActionTime, LogId);
END;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Log
    @DemoName NVARCHAR(100),
    @Message NVARCHAR(1000)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Demo_Logs (DemoName, SessionId, ActionTime, Message)
    VALUES (@DemoName, @@SPID, SYSDATETIME(), @Message);
END;
GO

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

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Limit_Reset
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DemoName NVARCHAR(100) = N'PHANTOM_LIMIT_RESET';
    DECLARE @FromAccountId UNIQUEIDENTIFIER;
    DECLARE @ToAccountId UNIQUEIDENTIFIER;
    DECLARE @UserId UNIQUEIDENTIFIER;

    DELETE FROM dbo.Transactions
    WHERE Description LIKE N'PHANTOM_LIMIT_DEMO|%';

    DELETE FROM dbo.Demo_Logs
    WHERE DemoName IN (
        N'PHANTOM_LIMIT_BAD',
        N'PHANTOM_LIMIT_FIX',
        N'PHANTOM_LIMIT_RESET'
    );

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
        80000000,
        'success',
        SYSDATETIME(),
        N'PHANTOM_LIMIT_DEMO|BASELINE|Today total starts at 80,000,000'
    );

    EXEC dbo.sp_Demo_Log @DemoName, N'Reset complete. Baseline transfer = 80,000,000.';
END;
GO