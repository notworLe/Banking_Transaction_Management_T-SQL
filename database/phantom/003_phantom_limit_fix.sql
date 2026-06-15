USE banking_transaction;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Phantom_Limit_Fix_Transfer
    @Delay CHAR(8) = '00:00:08'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @DemoName NVARCHAR(100) = N'PHANTOM_LIMIT_FIX';
    DECLARE @Message NVARCHAR(1000);

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

    SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;

    BEGIN TRY
        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = N'FIX: BEGIN TRANSACTION with SERIALIZABLE';

        BEGIN TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = N'FIX: Before reading today SUM with UPDLOCK, HOLDLOCK';

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
            @DemoName = @DemoName,
            @Message = @Message;

        SET @Message = CONCAT(N'FIX: Before WAITFOR ', @Delay);

        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = @Message;

        WAITFOR DELAY @Delay;

        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = N'FIX: After WAITFOR';

        IF @TodayTotal + @TransferAmount <= @DailyLimit
        BEGIN
            EXEC dbo.sp_Demo_Log
                @DemoName = @DemoName,
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
                @DemoName = @DemoName,
                @Message = @Message;
        END
        ELSE
        BEGIN
            EXEC dbo.sp_Demo_Log
                @DemoName = @DemoName,
                @Message = N'FIX: Limit check FAILED. No insert.';
        END;

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
            @DemoName = @DemoName,
            @Message = @Message;

        COMMIT TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = N'FIX: COMMIT';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Message = CONCAT(N'FIX ERROR: ', ERROR_MESSAGE());

        EXEC dbo.sp_Demo_Log
            @DemoName = @DemoName,
            @Message = @Message;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        THROW;
    END CATCH;

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END;
GO