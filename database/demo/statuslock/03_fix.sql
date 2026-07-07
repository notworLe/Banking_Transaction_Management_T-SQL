USE banking_transaction;
GO
-- ============================================================
-- DEMO: STATUS LOCK (Non-Repeatable Read) - BẢN FIX
-- Giải pháp: Dùng Lock Hint WITH (UPDLOCK, ROWLOCK)
-- 1. Chuyển khoản (T1) đọc trạng thái lần 1 với UPDLOCK, giữ khóa U.
-- 2. T1 bị delay. Banker (T2) cố gắng khóa tài khoản -> BỊ CHẶN (Block) vì T1 đang giữ khóa.
-- 3. T1 đọc trạng thái lần 2 -> vẫn là 'active' (vì T2 chưa update được).
-- 4. T1 trừ tiền thành công, COMMIT, nhả khóa.
-- 5. T2 được thả (unblock), tiếp tục update thành 'locked'.
-- ============================================================

DROP PROCEDURE IF EXISTS dbo.sp_Demo_StatusLock_Fix;
GO
CREATE PROCEDURE dbo.sp_Demo_StatusLock_Fix
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
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'BEGIN', N'[T1-FIX] Bắt đầu Giao dịch Chuyển khoản (Có UPDLOCK)';
            BEGIN TRANSACTION;

            -- Đọc lần 1 VÀ GIỮ KHÓA
            SELECT @Status1 = Status FROM dbo.BankAccounts WITH (UPDLOCK, ROWLOCK) WHERE BankAccountId = @FromAccountId;
            
            SET @Message = CONCAT(N'[T1-FIX] Đọc lần 1: Status = ''', ISNULL(@Status1, ''), N'''. Đang giữ khóa UPDLOCK!');
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'READ 1', @Message;

            IF @Status1 <> 'active'
            BEGIN
                EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'ROLLBACK', N'[T1-FIX] Tài khoản không active ở lần đọc 1. Hủy giao dịch.';
                COMMIT TRANSACTION;
                THROW 51000, N'Tài khoản không active', 1;
            END

            -- Giả lập xử lý nghiệp vụ
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'DELAY', N'[T1-FIX] Đang xử lý nghiệp vụ... T2 sẽ bị CHẶN nếu cố gắng UPDATE dòng này.';
            WAITFOR DELAY @Delay;

            -- Đọc lần 2 (Chắc chắn không đổi)
            SELECT @Status2 = Status FROM dbo.BankAccounts WITH (UPDLOCK, ROWLOCK) WHERE BankAccountId = @FromAccountId;

            SET @Message = CONCAT(N'[T1-FIX] Đọc lần 2: Status = ''', ISNULL(@Status2, ''), N'''. Nhờ UPDLOCK nên Status được bảo toàn!');
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'READ 2', @Message;

            IF @Status1 <> @Status2
            BEGIN
                -- Sẽ không lọt vào đây
                COMMIT TRANSACTION;
                THROW 51001, N'Lỗi Non-repeatable Read', 1;
            END

            -- Trừ tiền an toàn
            UPDATE dbo.BankAccounts SET Balance = Balance - @TransferAmount WHERE BankAccountId = @FromAccountId;
            UPDATE dbo.BankAccounts SET Balance = Balance + @TransferAmount WHERE BankAccountId = @ToAccountId;

            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'COMMIT', N'[T1-FIX] Trừ tiền thành công. Commit transaction & Nhả khóa UPDLOCK.';
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
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'BEGIN', N'[T2-FIX] Banker bắt đầu khóa tài khoản...';
            BEGIN TRANSACTION;

            -- Lệnh này sẽ bị BLOCK cho đến khi T1 commit/rollback
            UPDATE dbo.BankAccounts
            SET Status = 'locked'
            WHERE BankAccountId = @FromAccountId;

            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'UPDATE', N'[T2-FIX] Đã cập nhật Status = ''locked'' (sau khi phải chờ T1 nhả khóa).';

            COMMIT TRANSACTION;
            EXEC dbo.sp_Demo_Log @Scenario, @Actor, N'COMMIT', N'[T2-FIX] Giao dịch khóa tài khoản hoàn tất.';
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
