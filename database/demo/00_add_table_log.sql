USE banking_transaction;
GO

/*==============================================================
    DEMO INFRASTRUCTURE
    Dùng chung cho toàn bộ demo:
    - Dirty Read
    - Non-repeatable Read
    - Phantom
    - Lost Update
    - Deadlock
==============================================================*/

------------------------------------------------------------
-- 1. Demo_Logs
------------------------------------------------------------

IF OBJECT_ID('dbo.Demo_Logs', 'U') IS NOT NULL
BEGIN
    DROP TABLE dbo.Demo_Logs;
END
GO

CREATE TABLE dbo.Demo_Logs
(
    LogId INT IDENTITY(1,1) PRIMARY KEY,
    Scenario NVARCHAR(50) NOT NULL,
    SessionId INT NOT NULL,
    Actor NVARCHAR(20) NOT NULL,
    Action NVARCHAR(30),
    ActionTime DATETIME2(3)
        CONSTRAINT DF_DemoLogs_ActionTime
        DEFAULT SYSDATETIME(),
    Message NVARCHAR(500) NOT NULL
);
GO

------------------------------------------------------------
-- 2. sp_Demo_Log
------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_Demo_Log
(
    @Scenario NVARCHAR(50),
    @Actor NVARCHAR(20),
    @Action NVARCHAR(30),
    @Message NVARCHAR(500),
    @ActionTime DATETIME2(3) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.Demo_Logs
    (
        Scenario,
        SessionId,
        Actor,
        Action,
        ActionTime,
        Message
    )
    VALUES
    (
        @Scenario,
        @@SPID,
        @Actor,
        @Action,
        ISNULL(@ActionTime, SYSDATETIME()),
        @Message
    );
END
GO

------------------------------------------------------------
-- 3. sp_Demo_ClearLogs
------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_Demo_ClearLogs
(
    @Scenario NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    IF @Scenario IS NULL
    BEGIN
        DELETE FROM dbo.Demo_Logs;
    END
    ELSE
    BEGIN
        DELETE FROM dbo.Demo_Logs
        WHERE Scenario = @Scenario;
    END
END
GO

------------------------------------------------------------
-- 4. sp_Demo_GetLogs
------------------------------------------------------------

CREATE OR ALTER PROCEDURE dbo.sp_Demo_GetLogs
(
    @Scenario NVARCHAR(50) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        LogId,
        Scenario,
        SessionId,
        Actor,
        Action,
        ActionTime,
        Message
    FROM dbo.Demo_Logs
    WHERE
        @Scenario IS NULL
        OR Scenario = @Scenario
    ORDER BY
        ActionTime,
        LogId;
END
GO

------------------------------------------------------------
-- 5. Test dữ liệu (tuỳ chọn)
------------------------------------------------------------

/*
EXEC dbo.sp_Demo_Log
    @Scenario='TEST',
    @Actor='A',
    @Message='BEGIN TRANSACTION';

EXEC dbo.sp_Demo_Log
    @Scenario='TEST',
    @Actor='B',
    @Message='READ ACCOUNT';

EXEC dbo.sp_Demo_GetLogs;

EXEC dbo.sp_Demo_ClearLogs;

EXEC dbo.sp_Demo_GetLogs;
*/
GO