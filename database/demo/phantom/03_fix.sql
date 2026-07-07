USE banking_transaction;
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
            @Message = N'FIX: BẮT ĐẦU GIAO DỊCH với mức cô lập SERIALIZABLE';

        BEGIN TRANSACTION;

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = N'FIX: Trước khi đọc SUM hôm nay với UPDLOCK, HOLDLOCK';

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
            N'FIX: Đọc TodayTotal = ',
            CONVERT(NVARCHAR(50), CAST(@TodayTotal AS MONEY), 1)
        );

        EXEC dbo.sp_Demo_Log
            @Scenario = @Scenario,
            @Actor = @Actor,
            @Action = N'READ',
            @Message = @Message;

        SET @Message = CONCAT(N'FIX: Trước khi chờ (WAITFOR) ', @Delay);

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
            @Message = N'FIX: Sau khi chờ (WAITFOR)';

        -- Kiểm tra hạn mức
        IF @TodayTotal + @TransferAmount <= @DailyLimit
        BEGIN
            EXEC dbo.sp_Demo_Log
                @Scenario = @Scenario,
                @Actor = @Actor,
                @Action = N'LIMIT CHECK',
                @Message = N'FIX: Kiểm tra hạn mức ĐẠT. Trước khi chèn (INSERT)';

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
                N'PHANTOM_LIMIT_DEMO|FIX|Đã chèn giao dịch chuyển tiền sau khi kiểm tra SUM được bảo vệ'
            );

            SET @Message = CONCAT(
                N'FIX: Đã chèn số tiền chuyển = ',
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
                @Message = N'FIX: Kiểm tra hạn mức THẤT BẠI. Không thực hiện chèn.';
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
            N'FIX: Đọc FinalTotal nhìn thấy trong transaction = ',
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
            @Message = N'FIX: COMMIT thành công';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        SET @Message = CONCAT(N'LỖI FIX: ', ERROR_MESSAGE());

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
