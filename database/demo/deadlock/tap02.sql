USE banking_transaction;
GO

DECLARE @SourceAccount NVARCHAR(20) = '9704001000002';
DECLARE @DestinationAccount NVARCHAR(20) = '9704001000001';

-- Session B: run this in a second SSMS window at the same time as Session A.
-- This creates the opposite lock order and should trigger the BAD deadlock.
-- To verify the FIX scenario, replace sp_Demo_Deadlock_Bad with sp_Demo_Deadlock_Fix.
EXEC dbo.sp_Demo_Deadlock_Bad
    @SourceAccount = @SourceAccount,
    @DestinationAccount = @DestinationAccount,
    @Delay = '00:00:02';
GO
