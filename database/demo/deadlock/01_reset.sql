USE banking_transaction;
GO

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Deadlock_Reset
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Scenario NVARCHAR(50) = N'DEADLOCK';
    DECLARE @Actor NVARCHAR(20) = N'System';
    DECLARE @Action NVARCHAR(30) = N'RESET';

    EXEC dbo.sp_Demo_ClearLogs @Scenario = @Scenario;

    UPDATE dbo.BankAccounts
    SET Balance = 15000000.00
    WHERE AccountNumber = '9704001000001';

    UPDATE dbo.BankAccounts
    SET Balance = 50000000.00
    WHERE AccountNumber = '9704001000002';

    UPDATE dbo.BankAccounts
    SET Balance = 8500000.00
    WHERE AccountNumber = '9704002000001';

    EXEC dbo.sp_Demo_Log
        @Scenario = @Scenario,
        @Actor = @Actor,
        @Action = @Action,
        @Message = N'RESET: Demo balances restored for the transfer-based deadlock scenario.';
END;
GO
