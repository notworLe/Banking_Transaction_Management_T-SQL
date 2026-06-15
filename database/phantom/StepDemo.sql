USE banking_transaction;
GO

EXEC dbo.sp_Demo_Phantom_Limit_Reset;
GO



/* Check limit before demo */
USE banking_transaction;
GO

DECLARE @StartOfDay DATETIME2(3) =
    CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

DECLARE @EndOfDay DATETIME2(3) =
    DATEADD(DAY, 1, @StartOfDay);

SELECT
    SUM(Amount) AS TodayTotal
FROM dbo.Transactions
WHERE Type = 'transfer'
  AND Status = 'success'
  AND CreatedAt >= @StartOfDay
  AND CreatedAt < @EndOfDay
  AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';




/*Check time*/
SELECT 
    CONVERT(VARCHAR(8), DATEADD(SECOND, 30, SYSDATETIME()), 108) AS StartAt;




/*Check log demo option bad or fix*/
USE banking_transaction;
GO

SELECT
    LogId,
    DemoName,
    SessionId,
    ActionTime,
    Message
FROM dbo.Demo_Logs
WHERE DemoName = N'PHANTOM_LIMIT_BAD'
ORDER BY ActionTime, LogId;




/* Check limit after demo */
USE banking_transaction;
GO

DECLARE @StartOfDay DATETIME2(3) =
    CONVERT(DATETIME2(3), CONVERT(DATE, SYSDATETIME()));

DECLARE @EndOfDay DATETIME2(3) =
    DATEADD(DAY, 1, @StartOfDay);

SELECT
    SUM(Amount) AS FinalTodayTotal
FROM dbo.Transactions
WHERE Type = 'transfer'
  AND Status = 'success'
  AND CreatedAt >= @StartOfDay
  AND CreatedAt < @EndOfDay
  AND Description LIKE N'PHANTOM_LIMIT_DEMO|%';