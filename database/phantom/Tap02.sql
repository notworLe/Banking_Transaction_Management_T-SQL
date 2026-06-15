SELECT @@SPID AS SessionB;


USE banking_transaction;
GO

WAITFOR TIME '09:53:30';

EXEC dbo.sp_Demo_Phantom_Limit_Fix_Transfer
    @Delay = '00:00:02';
GO