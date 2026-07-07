USE banking_transaction;
GO

DECLARE @SourceAccount NVARCHAR(20) = '9704001000001';
DECLARE @DestinationAccount NVARCHAR(20) = '9704001000002';

-- Session A: run this in one SSMS window.
-- Start Session B at the same time to reproduce the BAD deadlock scenario.
-- To verify the FIX scenario, replace sp_Demo_Deadlock_Bad with sp_Demo_Deadlock_Fix.
EXEC dbo.sp_Demo_Deadlock_Bad
    @SourceAccount = @SourceAccount,
    @DestinationAccount = @DestinationAccount,
    @Delay = '00:00:08';
GO