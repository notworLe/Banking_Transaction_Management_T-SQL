USE banking_transaction;
GO
-- ============================================================
-- DEMO: STATUS LOCK (Non-Repeatable Read) - BẢN LỖI (BAD)
-- Kịch bản: 
-- 1. Chuyển khoản (T1) đọc trạng thái lần 1 (thấy 'active')
-- 2. T1 bị delay. Trong lúc đó Banker (T2) khóa tài khoản.
-- 3. T1 đọc trạng thái lần 2 (thấy 'locked' khác 'active') -> NON-REPEATABLE READ.
-- 4. Vì thấy trạng thái bị đổi, T1 CHẶN giao dịch (rollback) -> Giao dịch chuyển khoản thất bại oan uổng do đọc lại không nhất quán.
-- ============================================================

DROP PROCEDURE IF EXISTS dbo.sp_Demo_StatusLock_Bad;
GO
CREATE PROCEDURE dbo.sp_Demo_StatusLock_Bad
    @Delay CHAR(8) = '00:00:08',
    @Role  NVARCHAR(10) = 'TRANSFER'   -- 'TRANSFER' hoặc 'LOCK'
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'STATUSLOCK';
    DECLARE @Actor    NVARCHAR(20) = CONCAT(N'Session ', @@SPID);
    DECLARE @Message  NVARCHAR(500);

    DECLARE @FromAccountId  UNIQUEIDENTIFIER;
    DECLARE @ToAccountId    UNIQUEIDENTIFIER;
    DECLARE @TransferAmount DECIMAL(18,2) = 15000000;
    
    DECLARE @Status1 NVARCHAR(20);
    DECLARE @Status2 NVARCHAR(20);

    -- Tìm tài khoản
    SELECT TOP 1 @FromAccountId = BankAccountId FROM dbo.BankAccounts WHERE AccountNumber = '9704001000001';
    SELECT TOP 1 @ToAccountId = BankAccountId FROM dbo.BankAccounts WHERE Status = 'active' AND BankAccountId <> @FromAccountId;

    -- ==========================================
    -- ROLE: T1 (CUSTOMER - TRANSFER)
    -- ==========================================
    IF @Role = 'TRANSFER'
    BEGIN
        BEGIN TRY
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'BEGIN', N'[T1-BAD] Bắt đầu Giao dịch Chuyển khoản (READ COMMITTED)';
            BEGIN TRANSACTION;

            -- Đọc lần 1
            SELECT @Status1 = Status FROM dbo.BankAccounts WHERE BankAccountId = @FromAccountId;
            
            SET @Message = CONCAT(N'[T1-BAD] Đọc lần 1: Status = ''', ISNULL(@Status1, ''), N'''. Nhả khóa Shared ngay lập tức.');
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'READ 1', @Message;

            IF @Status1 <> 'active'
            BEGIN
                EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'ROLLBACK', N'[T1-BAD] Tài khoản không active ở lần đọc 1. Hủy giao dịch.';
                COMMIT TRANSACTION;
                THROW 51000, N'Tài khoản không active', 1;
            END

            -- Giả lập xử lý nghiệp vụ
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'DELAY', N'[T1-BAD] Đang xử lý nghiệp vụ... tạo sơ hở cho T2 chen vào.';
            WAITFOR DELAY @Delay;

            -- Đọc lần 2 (Re-check trước khi update)
            SELECT @Status2 = Status FROM dbo.BankAccounts WHERE BankAccountId = @FromAccountId;

            SET @Message = CONCAT(N'[T1-BAD] Đọc lần 2: Status = ''', ISNULL(@Status2, ''), N'''.');
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'READ 2', @Message;

            -- KIỂM TRA NON-REPEATABLE READ
            IF @Status1 <> @Status2
            BEGIN
                SET @Message = CONCAT(N'[T1-BAD] NON-REPEATABLE READ PHÁT HIỆN! Lần 1 = ''', @Status1, N''', Lần 2 = ''', @Status2, N'''. Giao dịch bị hủy!');
                EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'ERROR', @Message;
                COMMIT TRANSACTION;
                THROW 51001, N'Lỗi Non-repeatable Read: Trạng thái tài khoản đã bị thay đổi ngầm. Hủy giao dịch!', 1;
            END

            -- Nếu giống nhau (thực tế kịch bản Bad sẽ không lọt vào đây nếu T2 chạy)
            UPDATE dbo.BankAccounts SET Balance = Balance - @TransferAmount WHERE BankAccountId = @FromAccountId;
            UPDATE dbo.BankAccounts SET Balance = Balance + @TransferAmount WHERE BankAccountId = @ToAccountId;

            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'COMMIT', N'[T1-BAD] Trừ tiền thành công. Commit transaction.';
            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            DECLARE @Err NVARCHAR(4000) = ERROR_MESSAGE();
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'ROLLBACK', @Err;
            THROW;
        END CATCH
    END

    -- ==========================================
    -- ROLE: T2 (BANKER - LOCK ACCOUNT)
    -- ==========================================
    IF @Role = 'LOCK'
    BEGIN
        BEGIN TRY
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'BEGIN', N'[T2-BAD] Banker bắt đầu khóa tài khoản...';
            BEGIN TRANSACTION;

            UPDATE dbo.BankAccounts
            SET Status = 'locked'
            WHERE BankAccountId = @FromAccountId;

            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'UPDATE', N'[T2-BAD] Cập nhật Status = ''locked'' thành công do T1 không giữ khóa.';

            COMMIT TRANSACTION;
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'COMMIT', N'[T2-BAD] Giao dịch khóa tài khoản hoàn tất.';
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            DECLARE @Err2 NVARCHAR(4000) = ERROR_MESSAGE();
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'ROLLBACK', @Err2;
            THROW;
        END CATCH
    END
END;
GO