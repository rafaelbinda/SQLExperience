/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-21
Version     : 1.0
Task        : Q0013 - Sql Server Programming Objects
Databases   : ExamplesDB 
Object      : Script
Description : Examples demonstrating SQL Server Triggers, including DML
              triggers, INSERTED and DELETED virtual tables, UPDATE handling,
              DDL triggers, and a login trigger example
Notes       : notes/A0015-programming-objects-triggers.md
=============================================================================== 
INDEX
1 - DML Trigger (INSERT)
2 - Trigger using INSERTED table
3 - Trigger using DELETED table
4 - Trigger handling UPDATE operation
5 - DDL Trigger
6 - Login Trigger
7 - Managing Triggers (DROP and DISABLE)
=============================================================================== 
*/

IF OBJECT_ID('dbo.Example_TriggerAudit', 'U') IS NOT NULL
    DROP TABLE dbo.Example_TriggerAudit;
GO

IF OBJECT_ID('dbo.Example_TriggerProducts', 'U') IS NOT NULL
    DROP TABLE dbo.Example_TriggerProducts;
GO

CREATE TABLE dbo.Example_TriggerProducts
(
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Price       DECIMAL(10,2) NOT NULL
);
GO

CREATE TABLE dbo.Example_TriggerAudit
(
    AuditID           INT IDENTITY(1,1) PRIMARY KEY,
    EventType         VARCHAR(20) NOT NULL,
    ProductID         INT NULL,
    ProductName       VARCHAR(100) NULL,
    OldPrice          DECIMAL(10,2) NULL,
    NewPrice          DECIMAL(10,2) NULL,
    LoginName         SYSNAME NULL,
    OriginalLoginName SYSNAME NULL,
    DatabaseUserName  SYSNAME NULL,
    HostName          NVARCHAR(128) NULL,
    ProgramName       NVARCHAR(128) NULL,
    ClientNetAddress  VARCHAR(48) NULL,
    EventDate         DATETIME NOT NULL DEFAULT GETDATE()
);
GO

-------------------------------------------------------------------------------
-- TRIGGERS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 1 - DML Trigger (INSERT)
-------------------------------------------------------------------------------
--Logs INSERT operations into the audit table
--Includes login, host, application, client IP, and event date

CREATE OR ALTER TRIGGER dbo.trg_Example_Product_Insert
ON dbo.Example_TriggerProducts
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClientNetAddress VARCHAR(48);

    SELECT @ClientNetAddress = CONVERT(VARCHAR(48), c.client_net_address)
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = @@SPID;

    INSERT INTO dbo.Example_TriggerAudit
    (
        EventType,
        ProductID,
        ProductName,
        NewPrice,
        LoginName,
        OriginalLoginName,
        DatabaseUserName,
        HostName,
        ProgramName,
        ClientNetAddress,
        EventDate
    )

    /*
    USER_NAME() returns the database user
    It may return 'dbo' when using sysadmin or database owner accounts
    */

    SELECT
    'INSERT',
    i.ProductID,
    i.ProductName,
    i.Price,
    SUSER_SNAME(),
    ORIGINAL_LOGIN(),
    USER_NAME(),
    HOST_NAME(),
    PROGRAM_NAME(),
    @ClientNetAddress,
    GETDATE()
    FROM INSERTED AS i;
END;
GO

-- Execution
INSERT INTO dbo.Example_TriggerProducts (ProductName, Price)
VALUES ('Notebook', 3500.00);
GO

SELECT * 
FROM Example_TriggerProducts;
GO

/*Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
*/

SELECT *
FROM dbo.Example_TriggerAudit;
GO

/*
Result:
AuditID	                1	
EventType	            INSERT
ProductID	        	1
ProductName	            Notebook
OldPrice	            NULL
NewPrice	            3500.00
LoginName	            SRVSQLSERVER\USRSQLSERVER
OriginalLoginName	    SRVSQLSERVER\USRSQLSERVER
DatabaseUserName	    dbo
HostName	            SRVSQLSERVER
ProgramName	            Microsoft SQL Server Management Studio - Query
ClientNetAddress	    fe80::e814:bdbb:30e2:13f%6
EventDate               2026-03-21 20:57:39.717
*/

-------------------------------------------------------------------------------
-- 2 - Trigger using INSERTED table
-------------------------------------------------------------------------------
--Uses the INSERTED virtual table to validate inserted rows
--Prevents inserting products with price less than or equal to zero

CREATE OR ALTER TRIGGER dbo.trg_Example_Product_InsertValidation
ON dbo.Example_TriggerProducts
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS
    (
        SELECT 1
        FROM inserted
        WHERE Price <= 0
    )
    BEGIN
        RAISERROR ('Price must be greater than zero.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
GO

-- Valid execution
INSERT INTO dbo.Example_TriggerProducts (ProductName, Price)
VALUES ('Monitor', 1200.00);
GO

SELECT * 
FROM Example_TriggerProducts;
GO

/*
Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
2	        Monitor	        1200.00
*/

SELECT *
FROM dbo.Example_TriggerAudit;
GO

/*
Result:
AuditID	            2	
EventType	        INSERT
ProductID	        2
ProductName	        Monitor
OldPrice	        NULL
NewPrice	        1200.00
LoginName	        SRVSQLSERVER\USRSQLSERVER
OriginalLoginName	SRVSQLSERVER\USRSQLSERVER
DatabaseUserName	dbo
HostName	        SRVSQLSERVER
ProgramName	        Microsoft SQL Server Management Studio - Query
ClientNetAddress	fe80::e814:bdbb:30e2:13f%6
EventDate           2026-03-21 21:02:57.397
*/


--→ Invalid execution 
INSERT INTO dbo.Example_TriggerProducts (ProductName, Price)
VALUES ('Invalid Product', 0.00);
GO

/*
Result:
Msg 50000, Level 16, State 1, Procedure trg_Example_Product_InsertValidation, 
Line 15 [Batch Start Line 194]
Price must be greater than zero.
Msg 3609, Level 16, State 1, Line 195
The transaction ended in the trigger. The batch has been aborted.

Completion time: 2026-03-21T21:18:46.3468894-03:00
*/


-------------------------------------------------------------------------------
-- 3 - Trigger using DELETED table
-------------------------------------------------------------------------------
--Logs DELETE operations using the DELETED virtual table
--Includes login, host, application, client IP, and event date

CREATE OR ALTER TRIGGER dbo.trg_Example_Product_Delete
ON dbo.Example_TriggerProducts
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClientNetAddress VARCHAR(48);

    SELECT @ClientNetAddress = CONVERT(VARCHAR(48), c.client_net_address)
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = @@SPID;

    INSERT INTO dbo.Example_TriggerAudit
    (
        EventType,
        ProductID,
        ProductName,
        OldPrice,
        LoginName,
        OriginalLoginName,
        DatabaseUserName,
        HostName,
        ProgramName,
        ClientNetAddress,
        EventDate
    )

    /*
    USER_NAME() returns the database user
    It may return 'dbo' when using sysadmin or database owner accounts
    */

    SELECT
    'DELETE',
    d.ProductID,
    d.ProductName,
    d.Price,
    SUSER_SNAME(),
    ORIGINAL_LOGIN(),
    USER_NAME(),
    HOST_NAME(),
    PROGRAM_NAME(),
    @ClientNetAddress,
    GETDATE()
    FROM DELETED AS d;
END;
GO

SELECT * 
FROM Example_TriggerProducts;
GO

/*
Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
2	        Monitor	        1200.00
*/

-- Execution
DELETE FROM dbo.Example_TriggerProducts
WHERE ProductName = 'Monitor';
GO

SELECT * 
FROM Example_TriggerProducts;
GO

/*
Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00 
*/

SELECT *
FROM dbo.Example_TriggerAudit;
GO

/*
→ Identity value 3 does not appear in Example_TriggerAudit because it was 
allocated during the insert attempt, but the transaction was not committed

Result:
AuditID	                4 
EventType	            DELETE
ProductID	            2
ProductName	            Monitor
OldPrice	            1200.00
NewPrice	            NULL
LoginName	            SRVSQLSERVER\USRSQLSERVER
OriginalLoginName	    SRVSQLSERVER\USRSQLSERVER
DatabaseUserName	    dbo
HostName	            SRVSQLSERVER
ProgramName             Microsoft SQL Server Management Studio - Query
ClientNetAddress	    fe80::e814:bdbb:30e2:13f%6
EventDate               2026-03-21 21:21:35.110				
*/

-------------------------------------------------------------------------------
-- 4 - Trigger handling UPDATE operation
-------------------------------------------------------------------------------
--Uses INSERTED and DELETED virtual tables to log old and new values
--Includes login, host, application, client IP, and event date

CREATE OR ALTER TRIGGER dbo.trg_Example_Product_Update
ON dbo.Example_TriggerProducts
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ClientNetAddress VARCHAR(48);

    SELECT @ClientNetAddress = CONVERT(VARCHAR(48), c.client_net_address)
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = @@SPID;

    INSERT INTO dbo.Example_TriggerAudit
    (
        EventType,
        ProductID,
        ProductName,
        OldPrice,
        NewPrice,
        LoginName,
        OriginalLoginName,
        DatabaseUserName,
        HostName,
        ProgramName,
        ClientNetAddress,
        EventDate
    )
    SELECT
    'UPDATE',
    i.ProductID,
    i.ProductName,
    d.Price,
    i.Price,
    SUSER_SNAME(),
    ORIGINAL_LOGIN(),
    USER_NAME(),
    HOST_NAME(),
    PROGRAM_NAME(),
    @ClientNetAddress,
    GETDATE()
    FROM INSERTED AS i
    INNER JOIN DELETED AS d
    ON i.ProductID = d.ProductID;
END;
GO

-- Execution
UPDATE dbo.Example_TriggerProducts
SET Price = 3700.00
WHERE ProductName = 'Notebook';
GO

SELECT *
FROM dbo.Example_TriggerAudit;
GO

/*
Result:
AuditID	                5
EventType	            UPDATE
ProductID	            1
ProductName	            Notebook
OldPrice	            3500.00
NewPrice	            3700.00
LoginName	            SRVSQLSERVER\USRSQLSERVER
OriginalLoginName	    SRVSQLSERVER\USRSQLSERVER
DatabaseUserName	    dbo
HostName	            SRVSQLSERVER
ProgramName	            Microsoft SQL Server Management Studio - Query
ClientNetAddress	    fe80::e814:bdbb:30e2:13f%6
EventDate               2026-03-21 21:33:57.723
*/

-------------------------------------------------------------------------------
-- 5 - DDL Trigger
-------------------------------------------------------------------------------
--Captures CREATE_TABLE events in the current database
--Includes login, host, application, client IP, and event date

IF OBJECT_ID('dbo.Example_DDLTriggerLog', 'U') IS NOT NULL
    DROP TABLE dbo.Example_DDLTriggerLog;
GO

CREATE TABLE dbo.Example_DDLTriggerLog
(
    LogID             INT IDENTITY(1,1) PRIMARY KEY,
    EventType         VARCHAR(100),
    ObjectName        VARCHAR(256),
    LoginName         SYSNAME NULL,
    OriginalLoginName SYSNAME NULL,
    DatabaseUserName  SYSNAME NULL,
    HostName          NVARCHAR(128) NULL,
    ProgramName       NVARCHAR(128) NULL,
    ClientNetAddress  VARCHAR(48) NULL,
    EventDate         DATETIME NOT NULL DEFAULT GETDATE(),
    CommandText       XML
   
);
GO
 
CREATE OR ALTER TRIGGER trg_Example_DDL_CreateTable
ON DATABASE
FOR CREATE_TABLE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @EventData XML = EVENTDATA();
    DECLARE @ClientNetAddress VARCHAR(48);

    SELECT @ClientNetAddress = CONVERT(VARCHAR(48), c.client_net_address)
    FROM sys.dm_exec_connections AS c
    WHERE c.session_id = @@SPID;

    INSERT INTO dbo.Example_DDLTriggerLog
    (
        EventType,
        ObjectName,
        LoginName,
        OriginalLoginName,
        DatabaseUserName,
        HostName,
        ProgramName,
        ClientNetAddress,
        EventDate,
        CommandText        
    )
    VALUES
    (
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'VARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/ObjectName)[1]', 'VARCHAR(256)'),
        SUSER_SNAME(),
        ORIGINAL_LOGIN(),
        USER_NAME(),
        HOST_NAME(),
        PROGRAM_NAME(),
        @ClientNetAddress,
        GETDATE(),
        @EventData
        
    );
END;
GO

-- Execution
IF OBJECT_ID('dbo.Example_DDLTestTable', 'U') IS NOT NULL
    DROP TABLE dbo.Example_DDLTestTable;
GO

CREATE TABLE dbo.Example_DDLTestTable
(
    ID INT
);
GO

SELECT *
FROM dbo.Example_DDLTriggerLog;
GO

/*
Result
LogID	                1
EventType	            CREATE_TABLE
ObjectName	            Example_DDLTestTable
LoginName	            SRVSQLSERVER\USRSQLSERVER
OriginalLoginName	    SRVSQLSERVER\USRSQLSERVER
DatabaseUserName	    dbo
HostName	            SRVSQLSERVER
ProgramName	            Microsoft SQL Server Management Studio - Query
ClientNetAddress	    fe80::e814:bdbb:30e2:13f%6
EventDate	            2026-03-21 21:43:53.880
CommandText             ... 

*/

-- To view the content formatted, use the query below:
SELECT CAST(CommandText AS XML)
FROM dbo.Example_DDLTriggerLog
WHERE LogID = 1;
GO
/*
<EVENT_INSTANCE>
  <EventType>CREATE_TABLE</EventType>
  <PostTime>2026-03-21T21:43:53.873</PostTime>
  <SPID>76</SPID>
  <ServerName>SRVSQLSERVER</ServerName>
  <LoginName>SRVSQLSERVER\USRSQLSERVER</LoginName>
  <UserName>dbo</UserName>
  <DatabaseName>ExamplesDB</DatabaseName>
  <SchemaName>dbo</SchemaName>
  <ObjectName>Example_DDLTestTable</ObjectName>
  <ObjectType>TABLE</ObjectType>
  <TSQLCommand>
    <SetOptions ANSI_NULLS="ON" ANSI_NULL_DEFAULT="ON" ANSI_PADDING="ON" QUOTED_IDENTIFIER="ON" ENCRYPTED="FALSE" />
    <CommandText>CREATE TABLE dbo.Example_DDLTestTable
(
    ID INT
)</CommandText>
  </TSQLCommand>
</EVENT_INSTANCE>
*/


-------------------------------------------------------------------------------
-- 6 - Login Trigger
-------------------------------------------------------------------------------
--Example of a server-level login trigger
--Use with caution because login triggers can block access to SQL Server
--This example is created disabled to avoid accidental lockout

USE master;
GO

IF OBJECT_ID('dbo.Example_LoginTriggerAudit', 'U') IS NOT NULL
    DROP TABLE dbo.Example_LoginTriggerAudit;
GO

CREATE TABLE dbo.Example_LoginTriggerAudit
(
    AuditID          INT IDENTITY(1,1) PRIMARY KEY,
    LoginName        SYSNAME NULL,
    OriginalLogin    SYSNAME NULL,
    HostName         NVARCHAR(128) NULL,
    ProgramName      NVARCHAR(128) NULL,
    ClientHost       NVARCHAR(128) NULL,
    EventType        NVARCHAR(100) NULL,
    PostTime         DATETIME NULL,
    EventDate        DATETIME NOT NULL DEFAULT GETDATE(),
    EventData        XML NULL
);
GO

CREATE OR ALTER TRIGGER trg_Example_LoginAudit
ON ALL SERVER
FOR LOGON
AS
BEGIN
    DECLARE @EventData XML = EVENTDATA();

    INSERT INTO master.dbo.Example_LoginTriggerAudit
    (
        LoginName,
        OriginalLogin,
        HostName,
        ProgramName,
        ClientHost,
        EventType,
        PostTime,
        EventDate,
        EventData
    )
    VALUES
    (
        SUSER_SNAME(),
        ORIGINAL_LOGIN(),
        HOST_NAME(),
        PROGRAM_NAME(),
        @EventData.value('(/EVENT_INSTANCE/ClientHost)[1]', 'NVARCHAR(128)'),
        @EventData.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @EventData.value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME'),
        GETDATE(),
        @EventData
    );
END;
GO

-- To enable manually:
-- ENABLE TRIGGER trg_Example_LoginAudit ON ALL SERVER;
-- GO

-- To disable again:
-- DISABLE TRIGGER trg_Example_LoginAudit ON ALL SERVER;
-- GO

SELECT * FROM Example_LoginTriggerAudit;
GO

/*
→ The login trigger fires once per new login session
→ In SSMS, each query window usually creates a separate session/connection
→ For example, if 7 query windows are opened, the audit table may receive
  7 records
*/

/*
AuditID	LoginName	                OriginalLogin	            HostName	    ProgramName                 	                                    ClientHost	                EventType	    PostTime	                EventDate                   EventData
1	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.603	    2026-03-21 21:58:09.613     XML content
2	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.663	    2026-03-21 21:58:09.663     XML content
3	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.667	    2026-03-21 21:58:09.667     XML content
4	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.670	    2026-03-21 21:58:09.670     XML content
5	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.673	    2026-03-21 21:58:09.673     XML content
6	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.677	    2026-03-21 21:58:09.677     XML content
7	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.727	    2026-03-21 21:58:09.727     XML content
8	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	SQL Server Management Studio	                                    <local machine>	            LOGON	        2026-03-21 21:58:09.777	    2026-03-21 21:58:09.777     XML content
9	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	Microsoft SQL Server Management Studio - Transact-SQL IntelliSense	fe80::e814:bdbb:30e2:13f%6	LOGON	        2026-03-21 22:01:10.000	    2026-03-21 22:01:10.000     XML content
10	    SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	Microsoft SQL Server Management Studio - Transact-SQL IntelliSense	fe80::e814:bdbb:30e2:13f%6	LOGON	        2026-03-21 22:01:10.010	    2026-03-21 22:01:10.010     XML content
*/


-------------------------------------------------------------------------------
-- 7 - Managing Triggers (DROP and DISABLE)
-------------------------------------------------------------------------------
--Demonstrates how to disable, enable, and drop triggers
--Disabling a trigger prevents execution without removing it
--Dropping a trigger permanently removes it from the database

-- Disable DML trigger (table level)
DISABLE TRIGGER dbo.trg_Example_Product_Insert 
ON dbo.Example_TriggerProducts;
GO

-- Enable DML trigger
ENABLE TRIGGER dbo.trg_Example_Product_Insert 
ON dbo.Example_TriggerProducts;
GO

-- Drop DML trigger
DROP TRIGGER IF EXISTS dbo.trg_Example_Product_Insert;
GO

-- Disable DDL trigger (database level)
DISABLE TRIGGER trg_Example_DDL_CreateTable 
ON DATABASE;
GO

-- Enable DDL trigger
ENABLE TRIGGER trg_Example_DDL_CreateTable 
ON DATABASE;
GO

-- Drop DDL trigger
DROP TRIGGER IF EXISTS trg_Example_DDL_CreateTable 
ON DATABASE;
GO

-- Disable login trigger (server level)
DISABLE TRIGGER trg_Example_LoginAudit 
ON ALL SERVER;
GO

-- Enable login trigger
ENABLE TRIGGER trg_Example_LoginAudit 
ON ALL SERVER;
GO

-- Drop login trigger
DROP TRIGGER IF EXISTS trg_Example_LoginAudit 
ON ALL SERVER;
GO