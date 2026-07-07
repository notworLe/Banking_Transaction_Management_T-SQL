USE banking_transaction;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Deadlock_Bad
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
    DECLARE @BeginMessage NVARCHAR(500);
    DECLARE @LockSourceMessage NVARCHAR(500);
    DECLARE @WaitMessage NVARCHAR(500);
    DECLARE @LockDestinationMessage NVARCHAR(500);

    IF @SourceAccount IS NULL OR LTRIM(RTRIM(@SourceAccount)) = ''
       OR @DestinationAccount IS NULL OR LTRIM(RTRIM(@DestinationAccount)) = ''
    BEGIN
        THROW 52001, N'Source and Destination accounts cannot be empty.', 1;
    END;

    IF LTRIM(RTRIM(@SourceAccount)) = LTRIM(RTRIM(@DestinationAccount))
    BEGIN
        THROW 52002, N'Source and Destination accounts must be different.', 1;
    END;

    SELECT TOP 1 @SourceAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE AccountNumber = @SourceAccount;

    SELECT TOP 1 @DestinationAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE AccountNumber = @DestinationAccount;

    IF @SourceAccountId IS NULL OR @DestinationAccountId IS NULL
    BEGIN
        THROW 52003, N'One or both account numbers do not exist.', 1;
    END;

    SELECT @SourceBalance = Balance
    FROM dbo.BankAccounts
    WHERE BankAccountId = @SourceAccountId;

    IF @SourceBalance < @Amount
    BEGIN
        THROW 52004, N'Source account does not have enough funds for this transfer.', 1;
    END;

    BEGIN TRY
        SET @BeginMessage = N'BAD: Bắt đầu chuyển khoản từ ' + @SourceAccount + N' đến ' + @DestinationAccount;
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'BEGIN',
            @Message = @BeginMessage;

        BEGIN TRANSACTION;

        UPDATE dbo.BankAccounts WITH (ROWLOCK)
        SET Balance = Balance - @Amount
        WHERE BankAccountId = @SourceAccountId;

        SET @LockSourceMessage = N'BAD: Đã khóa tài khoản nguồn ' + @SourceAccount + N' và trừ ' + CAST(@Amount AS NVARCHAR(30));
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'LOCK_SOURCE',
            @Message = @LockSourceMessage;

        SET @WaitMessage = N'BAD: Đang chờ trước khi khóa tài khoản đích ' + @DestinationAccount;
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'WAIT',
            @Message = @WaitMessage;

        WAITFOR DELAY @Delay;

        UPDATE dbo.BankAccounts WITH (ROWLOCK)
        SET Balance = Balance + @Amount
        WHERE BankAccountId = @DestinationAccountId;

        COMMIT TRANSACTION;

        -- Give the opposing transaction time to record its deadlock victim status before this transaction records success.
        WAITFOR DELAY '00:00:03';

        SET @LockDestinationMessage = N'BAD: Đã khóa tài khoản đích ' + @DestinationAccount + N' và cộng ' + CAST(@Amount AS NVARCHAR(30));
        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'LOCK_DESTINATION',
            @Message = @LockDestinationMessage;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'COMMIT',
            @Message = N'BAD: Chuyển khoản đã commit thành công.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrNum INT = ERROR_NUMBER();
        DECLARE @ErrMsg NVARCHAR(500) = ERROR_MESSAGE();

        SET @Message = N'BAD: Lỗi ' + CAST(@ErrNum AS NVARCHAR(10)) + N' - ' + @ErrMsg;
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
                @Message = N'BAD: SQL Server phát hiện deadlock.';

            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'DEADLOCK_VICTIM',
                @Message = N'BAD: Giao dịch này bị chọn làm deadlock victim.';
        END;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'ROLLBACK',
            @Message = N'BAD: Giao dịch đã rollback.';

        THROW;
    END CATCH;
END;
GO
