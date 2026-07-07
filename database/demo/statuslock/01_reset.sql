USE banking_transaction;
GO

-- ============================================================
-- DEMO: STATUS LOCK (Non-Repeatable Read trên Status)
-- Reset: Đưa tài khoản nguồn về trạng thái active,
--        xóa transactions demo, xóa logs
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.sp_Demo_StatusLock_Reset
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'STATUSLOCK';
    DECLARE @Actor NVARCHAR(20) = N'System';
    DECLARE @FromAccountId UNIQUEIDENTIFIER;

    -- Tìm tài khoản nguồn (9704001000001)
    SELECT TOP 1 @FromAccountId = BankAccountId
    FROM dbo.BankAccounts
    WHERE AccountNumber = '9704001000001';

    IF @FromAccountId IS NULL
    BEGIN
        THROW 54000, N'Không tìm thấy tài khoản 9704001000001.', 1;
    END;

    -- 1. Xóa transactions demo cũ
    DELETE FROM dbo.Transactions
    WHERE Description LIKE N'STATUSLOCK_DEMO|%';

    -- 2. Đưa tài khoản nguồn về active và reset số dư
    UPDATE dbo.BankAccounts
    SET Status = 'active', Balance = 50000000
    WHERE BankAccountId = @FromAccountId;

    -- 3. Xóa logs
    EXEC dbo.sp_Demo_ClearLogs @Scenario = @Scenario;

    -- 4. Ghi log reset
    EXEC dbo.sp_Demo_Log
        @Scenario = @Scenario,
        @Actor = @Actor,
        @Action = N'RESET',
        @Message = N'Reset hoàn tất. TK 9704001000001 = active. Sẵn sàng chạy demo.';
END;
GO
