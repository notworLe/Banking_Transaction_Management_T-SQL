USE banking_transaction;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Deadlock_Fix
    @SourceAccount NVARCHAR(20) = NULL,
    @DestinationAccount NVARCHAR(20) = NULL,
    @Amount DECIMAL(18, 2) = 100000.00,
    @Delay VARCHAR(20) = '00:00:08'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'DEADLOCK';
    DECLARE @Actor NVARCHAR(20) = CONCAT(N'Session ', @@SPID);
    DECLARE @Message NVARCHAR(500);

    DECLARE @SourceAccountId UNIQUEIDENTIFIER;
    DECLARE @DestinationAccountId UNIQUEIDENTIFIER;
    DECLARE @SourceBalance DECIMAL(18, 2);
    DECLARE @FirstAccount NVARCHAR(20);
    DECLARE @SecondAccount NVARCHAR(20);
    DECLARE @FirstAction NVARCHAR(30);
    DECLARE @SecondAction NVARCHAR(30);
    DECLARE @BeginMessage NVARCHAR(500);
    DECLARE @FirstLockMessage NVARCHAR(500);
    DECLARE @WaitMessage NVARCHAR(500);
    DECLARE @SecondLockMessage NVARCHAR(500);

    -- Table variable to preserve logs across transaction rollback
    DECLARE @TempLogs TABLE (
        Action NVARCHAR(30),
        Message NVARCHAR(500),
        ActionTime DATETIME2 DEFAULT SYSDATETIME()
    );

    IF @SourceAccount IS NULL OR LTRIM(RTRIM(@SourceAccount)) = ''
       OR @DestinationAccount IS NULL OR LTRIM(RTRIM(@DestinationAccount)) = ''
    BEGIN
        THROW 53001, N'Source and Destination accounts cannot be empty.', 1;
    END;

    IF LTRIM(RTRIM(@SourceAccount)) = LTRIM(RTRIM(@DestinationAccount))
    BEGIN
        THROW 53002, N'Source and Destination accounts must be different.', 1;
    END;

    SELECT TOP 1 @SourceAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE AccountNumber = @SourceAccount;

    SELECT TOP 1 @DestinationAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE AccountNumber = @DestinationAccount;

    IF @SourceAccountId IS NULL OR @DestinationAccountId IS NULL
    BEGIN
        THROW 53003, N'One or both account numbers do not exist.', 1;
    END;

    SELECT @SourceBalance = Balance
    FROM dbo.BankAccounts
    WHERE BankAccountId = @SourceAccountId;

    IF @SourceBalance < @Amount
    BEGIN
        THROW 53004, N'Source account does not have enough funds for this transfer.', 1;
    END;

    IF @SourceAccount < @DestinationAccount
    BEGIN
        SET @FirstAccount = @SourceAccount;
        SET @SecondAccount = @DestinationAccount;
        SET @FirstAction = N'LOCK_SOURCE';
        SET @SecondAction = N'LOCK_DESTINATION';
    END
    ELSE
    BEGIN
        SET @FirstAccount = @DestinationAccount;
        SET @SecondAccount = @SourceAccount;
        SET @FirstAction = N'LOCK_DESTINATION';
        SET @SecondAction = N'LOCK_SOURCE';
    END;

    BEGIN TRY
        SET @BeginMessage = N'FIX: Bắt đầu chuyển khoản theo thứ tự khóa từ ' + @SourceAccount + N' đến ' + @DestinationAccount;
        INSERT INTO @TempLogs (Action, Message) VALUES (N'BEGIN', @BeginMessage);

        BEGIN TRANSACTION;

        IF @FirstAction = N'LOCK_SOURCE'
        BEGIN
            UPDATE dbo.BankAccounts WITH (ROWLOCK)
            SET Balance = Balance - @Amount
            WHERE BankAccountId = @SourceAccountId;

            SET @FirstLockMessage = N'FIX: Đã khóa tài khoản đầu tiên ' + @FirstAccount + N' và trừ ' + CAST(@Amount AS NVARCHAR(30));
            INSERT INTO @TempLogs (Action, Message) VALUES (@FirstAction, @FirstLockMessage);
        END
        ELSE
        BEGIN
            UPDATE dbo.BankAccounts WITH (ROWLOCK)
            SET Balance = Balance + @Amount
            WHERE BankAccountId = @DestinationAccountId;

            SET @FirstLockMessage = N'FIX: Đã khóa tài khoản đầu tiên ' + @FirstAccount + N' và cộng ' + CAST(@Amount AS NVARCHAR(30));
            INSERT INTO @TempLogs (Action, Message) VALUES (@FirstAction, @FirstLockMessage);
        END;

        SET @WaitMessage = N'FIX: Đang chờ trước khi khóa tài khoản thứ hai ' + @SecondAccount;
        INSERT INTO @TempLogs (Action, Message) VALUES (N'WAIT', @WaitMessage);

        WAITFOR DELAY @Delay;

        IF @SecondAction = N'LOCK_DESTINATION'
        BEGIN
            UPDATE dbo.BankAccounts WITH (ROWLOCK)
            SET Balance = Balance + @Amount
            WHERE BankAccountId = @DestinationAccountId;

            SET @SecondLockMessage = N'FIX: Đã khóa tài khoản thứ hai ' + @SecondAccount + N' và cộng ' + CAST(@Amount AS NVARCHAR(30));
            INSERT INTO @TempLogs (Action, Message) VALUES (@SecondAction, @SecondLockMessage);
        END
        ELSE
        BEGIN
            UPDATE dbo.BankAccounts WITH (ROWLOCK)
            SET Balance = Balance - @Amount
            WHERE BankAccountId = @SourceAccountId;

            SET @SecondLockMessage = N'FIX: Đã khóa tài khoản thứ hai ' + @SecondAccount + N' và trừ ' + CAST(@Amount AS NVARCHAR(30));
            INSERT INTO @TempLogs (Action, Message) VALUES (@SecondAction, @SecondLockMessage);
        END;

        COMMIT TRANSACTION;

        -- Write preserved logs to Demo_Logs
        INSERT INTO dbo.Demo_Logs (Scenario, SessionId, Actor, Action, ActionTime, Message)
        SELECT @Scenario, @@SPID, @Actor, Action, ActionTime, Message
        FROM @TempLogs;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'COMMIT',
            @Message = N'FIX: Chuyển khoản đã commit thành công.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Write preserved logs to Demo_Logs (survived rollback)
        INSERT INTO dbo.Demo_Logs (Scenario, SessionId, Actor, Action, ActionTime, Message)
        SELECT @Scenario, @@SPID, @Actor, Action, ActionTime, Message
        FROM @TempLogs;

        DECLARE @ErrNum INT = ERROR_NUMBER();
        DECLARE @ErrMsg NVARCHAR(500) = ERROR_MESSAGE();

        SET @Message = N'FIX: Lỗi ' + CAST(@ErrNum AS NVARCHAR(10)) + N' - ' + @ErrMsg;
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ERROR',
            @Message = @Message;

        IF @ErrNum = 1205
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'DEADLOCK_DETECTED',
                @Message = N'FIX: SQL Server phát hiện deadlock.';

            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'DEADLOCK_VICTIM',
                @Message = N'FIX: Giao dịch này bị chọn làm deadlock victim.';
        END;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ROLLBACK',
            @Message = N'FIX: Giao dịch đã rollback.';

        THROW;
    END CATCH;
END;
GO
