USE banking_transaction;
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
