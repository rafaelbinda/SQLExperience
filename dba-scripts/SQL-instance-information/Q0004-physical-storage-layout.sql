/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-22
Version     : 1.0
Task        : Q0004 - Physical Layout
Object      : Script
Description : Identify SQL Server physical storage layout
===============================================================================
*/

SET NOCOUNT ON;
GO

-------------------------------------------------------------------------------
-- List all directories used by SQL Server
-- (Data files, Log files and TempDB)
-------------------------------------------------------------------------------
SELECT DISTINCT
type_desc AS FileType,
LEFT(physical_name,LEN(physical_name) - CHARINDEX('\', REVERSE(physical_name))) AS Directory
FROM sys.master_files
ORDER BY FileType;
GO

-------------------------------------------------------------------------------
-- Show default directories used when creating new databases
-------------------------------------------------------------------------------
SELECT
SERVERPROPERTY('InstanceDefaultDataPath') AS DefaultDataPath,
SERVERPROPERTY('InstanceDefaultLogPath')  AS DefaultLogPath;
GO

-------------------------------------------------------------------------------
-- Identify TempDB physical location
-------------------------------------------------------------------------------
SELECT
name,
type_desc,
physical_name,
size/128 AS SizeMB
FROM tempdb.sys.database_files;
GO

-------------------------------------------------------------------------------
-- Identify which database is not following the standard pattern 
-------------------------------------------------------------------------------
SELECT
DB_NAME(database_id) AS DatabaseName,
type_desc,
physical_name
FROM sys.master_files
WHERE database_id > 4
ORDER BY DatabaseName;