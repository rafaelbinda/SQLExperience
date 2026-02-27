/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-24
Version     : 3.0
Task        : Q0003 - SQL Fundamentals
Databases   : ExamplesDB, AdventureWorks
Object      : Script
Description : Examples for command types, batches, errors, naming, variables,
              operators, dynamic SQL and flow control 
Notes       : -
===============================================================================
*/

SET NOCOUNT ON;
GO 

USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- Create demo table for batch/error examples
-------------------------------------------------------------------------------
CREATE TABLE dbo.TestError
(
    ColumnTest CHAR(13) NOT NULL
);
GO

-------------------------------------------------------------------------------
-- 1 - Batch + Syntax error
-------------------------------------------------------------------------------
/*
Example 1 - Syntax error
→ Syntax errors are detected before execution of the entire batch
Expected behavior:
→ SQL Server validates the syntax of the entire batch
→ The batch is not executed (no rows inserted)
*/

INSERT dbo.TestError VALUES ('INFORMATION 1');
INSERT dbo.TestError ('INFORMATION 2');         -- <-- Syntax error
INSERT dbo.TestError VALUES ('INFORMATION 3');
GO

/*
Result:
Msg 102, Level 15, State 1, Line 42
Incorrect syntax near ';'.
*/

-- Check: should be empty (because the whole batch failed)
SELECT * FROM dbo.TestError;
GO

/*
Example 2 - Same syntax error, but separated by GO (different batches)
Expected behavior:
→ Batch 1 fails (no inserts)
→ Batch 2 executes (INFORMATION 3 is inserted)
*/

INSERT dbo.TestError VALUES ('INFORMATION 1');   -- Batch 1
INSERT dbo.TestError ('INFORMATION 2');          -- Batch 1 (syntax error)
GO
INSERT dbo.TestError VALUES ('INFORMATION 3');   -- Batch 2
GO

/*
Result:
Msg 102, Level 15, State 1, Line 64
Incorrect syntax near ';'.
*/

-- Expect: INFORMATION 3
SELECT * FROM dbo.TestError; 
GO

-------------------------------------------------------------------------------
-- 2 - Execution error (syntax OK, runtime fails)
-------------------------------------------------------------------------------
/*
Execution error example:
→ NEWID() returns UNIQUEIDENTIFIER
→ ColumnTest is CHAR(13)
→ This fails at runtime (truncation error)
Expected behavior (without explicit transaction):
→ First INSERT happens
→ Second fails
→ Third does not execute
*/
TRUNCATE TABLE dbo.TestError;
GO

INSERT dbo.TestError VALUES ('INFORMATION 1');
INSERT dbo.TestError VALUES (NEWID());          -- may fail due to truncation
INSERT dbo.TestError VALUES ('INFORMATION 3');
GO

/*
Result:
Msg 8170, Level 16, State 2, Line 96
Insufficient result space to convert uniqueidentifier value to char.
*/

-- Expect: INFORMATION 1
SELECT * FROM dbo.TestError;
GO

-------------------------------------------------------------------------------
-- 3 - Naming rules + schema + object qualification + Dynamic SQL
-------------------------------------------------------------------------------
/*
Goal:
→ Show dbo as default schema
→ Create a custom schema and create a table there
→ Demonstrate why schema qualification matters
*/

-- 3.1 - Using default schema demo (dbo)
IF OBJECT_ID('dbo.TableDbo','U') IS NOT NULL
    DROP TABLE dbo.TableDbo;
GO

CREATE TABLE dbo.TableDbo
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Info VARCHAR(50) NOT NULL
);
GO

INSERT dbo.TableDbo (Info) VALUES ('Row in dbo');
GO

-- 3.2 - Create schema and a table inside it
/*
→ DDL statements do not accept variables directly
→ This command fails:

DECLARE @SchemaName SYSNAME = 'lab';
CREATE SCHEMA @SchemaName;  -- does not work

AUTHORIZATION dbo → Defines the owner of the schema.

dbo is:
→ A special user
→ Normally the default owner of the database
→ It means that the lab schema will be controlled by dbo

*/

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'lab')
    EXEC('CREATE SCHEMA lab AUTHORIZATION dbo;');
GO

IF OBJECT_ID('lab.TableSchema','U') IS NOT NULL
    DROP TABLE lab.TableSchema;
GO

CREATE TABLE lab.TableSchema
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Info VARCHAR(50) NOT NULL
);
GO

INSERT lab.TableSchema (Info) VALUES ('Row in lab schema');
GO

-- Show where objects are
SELECT
    s.name  AS SchemaName,
    o.name  AS ObjectName,
    o.type_desc
FROM sys.objects o
JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.name IN ('TableDbo','TableSchema')
ORDER BY s.name, o.name;
GO

/*
Result:
SchemaName	ObjectName	type_desc
dbo	        TableDbo	USER_TABLE
lab	        TableSchema	USER_TABLE
*/

-- Query the data (always qualify schema)
SELECT * FROM dbo.TableDbo;
SELECT * FROM lab.TableSchema;
GO

-------------------------------------------------------------------------------
-- 4 - Variables + SET vs SELECT + @@ERROR (simple demos)
-------------------------------------------------------------------------------
DECLARE @Msg VARCHAR(100);                  --Declare the variable
SET @Msg = 'Hello from SET';                --Set a message
SELECT @Msg AS Msg_Set;                     --Select using the variable
GO

DECLARE @Count INT;                         --Declare the variable
SELECT @Count = COUNT(*) FROM dbo.TableDbo; --Set the result of count into variable
SELECT @Count AS RowsIn_dbo_TableDbo;       --Select using the variable
GO

-- @@ERROR demo (classic style)
-- Note: @@ERROR must be checked immediately after the statement
DECLARE @Err INT;

SELECT 1/0;                                 -- runtime error
SELECT @Err = @@ERROR;                      -- capture
SELECT @Err AS LastErrorNumber;
GO

/*
Result:
Msg 8134, Level 16, State 1, Line 218
Divide by zero error encountered.
*/

-------------------------------------------------------------------------------
-- 5 - Operators + precedence
-------------------------------------------------------------------------------
DECLARE @A INT = 10, @B INT = 5, @C INT = 2;

SELECT
    @A + @B * @C      AS WithoutParentheses,   -- 10 + (5*2) = 20
    (@A + @B) * @C    AS WithParentheses;      -- (10+5)*2 = 30
GO

/*
Result:
WithoutParentheses	WithParentheses
20	                30
*/

-------------------------------------------------------------------------------
-- 6 - Dynamic SQL (EXEC + safer option with sp_executesql)
-------------------------------------------------------------------------------
/*
Simple dynamic SQL.
Better approach: use QUOTENAME for object names and sp_executesql for parameters

Explanation:
Why do I use EXEC() in this example?
When I put it inside EXEC('...'), I am saying:
→ "Execute this string as a T-SQL command"
→ This is called Dynamic SQL
→ The item 6 includes more examples about it

*/

/*
SYSNAME is an internal SQL Server alias for NVARCHAR(128), which is exactly the 
maximum size allowed for identifiers in SQL Server.
It is recommended when the variable represents an object name (database, schema, 
table, login).
*/

-- Database name
DECLARE @DB SYSNAME = N'AdventureWorks';

-- Schema name + table name (2-part name)
DECLARE @RealTable NVARCHAR(256) = N'Production.Product';

/*
Split schema and object using PARSENAME.
PARSENAME() is a function that breaks a multipart name into parts separated by a dot "."
It works well for up to 4 parts (server.database.schema.object), counting from right to left.
*/
DECLARE @Schema SYSNAME = PARSENAME(@RealTable, 2);
DECLARE @Object SYSNAME = PARSENAME(@RealTable, 1);

-- If the object is NULL for some reason, assume dbo
IF @Object IS NULL
BEGIN
    SET @Object = @RealTable;
    SET @Schema = N'dbo';
END;

IF @Schema IS NULL
    SET @Schema = N'dbo';

-- Build the fully qualified name using QUOTENAME for each part
DECLARE @FullTable NVARCHAR(300) = QUOTENAME(@Schema) + N'.' + QUOTENAME(@Object);

-- 1) Simple execution (no parameters)
-- FIX: add semicolon/newline after USE to avoid "USE AdventureWorksSELECT ..."
DECLARE @SQL NVARCHAR(MAX) =
    N'USE ' + QUOTENAME(@DB) + N'; ' +
    N'SELECT TOP (5) Name FROM ' + @FullTable + N';';

EXEC sys.sp_executesql @SQL;

/*
Result:
Adjustable Race
All-Purpose Bike Stand
AWC Logo Cap
BB Ball Bearing
Bearing Ball
*/

-- 2) Execution with a filter parameter (sp_executesql)
SET @SQL =
    N'USE ' + QUOTENAME(@DB) + N'; ' +
    N'SELECT TOP (5) Name
      FROM ' + @FullTable + N'
      WHERE Name LIKE @P1;';

EXEC sys.sp_executesql
    @SQL,
    N'@P1 NVARCHAR(100)',
    @P1 = N'%B%';

/*
Result:
Adjustable Race
All-Purpose Bike Stand
BB Ball Bearing
Bearing Ball
Bike Wash - Dissolver
*/

-------------------------------------------------------------------------------
-- 7 - Flow control (IF/ELSE, WHILE, CASE)
-------------------------------------------------------------------------------
-- IF/ELSE demo
DECLARE @Rows INT;

SELECT @Rows = COUNT(1) FROM dbo.TableDbo;

IF @Rows > 0
    BEGIN
        SELECT 'dbo.TableDbo has rows' AS Info, @Rows AS RowCountA;
    END
ELSE
    BEGIN
        SELECT 'dbo.TableDbo is empty' AS Info, @Rows AS RowCountB;
    END
GO

/*
Result:
Info	                RowCountA
dbo.TableDbo has rows	7
*/

-- WHILE demo (insert 5 rows)
DECLARE @i INT = 1;

WHILE @i <= 5
BEGIN
    INSERT dbo.TableDbo (Info)
    VALUES (CONCAT('Loop row ', @i));

    SET @i += 1;
END
GO

SELECT * 
FROM dbo.TableDbo 
ORDER BY Id DESC;
GO

/*
Result after 3 runs:
Id	Info
22	Loop row 5      --3
21	Loop row 4
20	Loop row 3
19	Loop row 2
18	Loop row 1
17	Loop row 5      --2
16	Loop row 4
15	Loop row 3
14	Loop row 2
13	Loop row 1
12	Loop row 5      --1
11	Loop row 4
10	Loop row 3
9	Loop row 2
8	Loop row 1
7	Row in dbo
6	Row in dbo
5	Row in dbo
4	Row in dbo
3	Row in dbo
2	Row in dbo
1	Row in dbo
*/

-- CASE demo (label row count)
DECLARE @Total INT;
SELECT @Total = COUNT(1) FROM dbo.TableDbo;

SELECT
    @Total AS TotalRows,
    CASE
        WHEN @Total = 0 THEN 'Empty'
        WHEN @Total BETWEEN 1 AND 5 THEN 'Small'
        WHEN @Total BETWEEN 6 AND 35 THEN 'Medium'
        ELSE 'Large'
    END AS SizeLabel;
GO

/*
Result:
TotalRows	SizeLabel
22	        Medium
*/