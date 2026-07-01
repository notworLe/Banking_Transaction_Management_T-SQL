USE banking_transaction;
GO
EXEC dbo.sp_Demo_Phantom_Reset;
GO


USE banking_transaction;
GO
SELECT *
FROM dbo.Demo_Logs
ORDER BY ActionTime ASC, LogId ASC;
