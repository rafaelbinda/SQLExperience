/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-29
Version     : 1.0
Task        : Q0002 - SQL Move Database File
Object      : Script
Description : Demonstrates how to move a database file (log file) to a new
              location using ALTER DATABASE and offline/online operations
Notes       : notes/A0003-database-file-management.md
===============================================================================

INDEX
1 - Create test database
2 - Check logical and physical file names
3 - Set database OFFLINE
4 - Modify file location (metadata)
5 - Move file at OS level (manual step)
6 - Set database ONLINE
7 - Validate file location
8 - Cleanup
*/

-------------------------------------------------------------------------------
-- 1 - Create test database
-------------------------------------------------------------------------------

USE master;
GO

DROP DATABASE IF EXISTS ExamplesDB_FileMove;
GO

CREATE DATABASE ExamplesDB_FileMove;
GO

-------------------------------------------------------------------------------
-- 2 - Check logical and physical file names
-------------------------------------------------------------------------------
 
SELECT
name,
physical_name,
type_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'ExamplesDB_FileMove');
GO

/*
Result:
name	                    physical_name	                                type_desc
ExamplesDB_FileMove	        C:\MSSQLSERVER\DATA\ExamplesDB_FileMove.mdf	    ROWS
ExamplesDB_FileMove_log 	C:\MSSQLSERVER\LOG\ExamplesDB_FileMove_log.ldf	LOG
*/

-------------------------------------------------------------------------------
-- 3 - Set database OFFLINE
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_FileMove
SET OFFLINE WITH ROLLBACK IMMEDIATE;
GO

-------------------------------------------------------------------------------
-- 4 - Modify file location (metadata)
-------------------------------------------------------------------------------
-- Example: moving the LOG file

ALTER DATABASE ExamplesDB_FileMove
MODIFY FILE
(
    NAME = N'ExamplesDB_FileMove_log',
    FILENAME = N'C:\MSSQLSERVER\NEWLOG\ExamplesDB_FileMove_log.ldf'
);
GO

/*
Result:
The file "ExamplesDB_FileMove_log" has been modified in the system catalog. 
The new path will be used the next time the database is started.
Completion time: 2026-03-29T20:25:55.3826605-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Move file at OS level (manual step)
-------------------------------------------------------------------------------
-- IMPORTANT:
-- 1. Copy the file from the old location to the new location
-- 2. Ensure SQL Server service account has access to the new folder

-- Example (manual step):
-- From: C:\...\ExamplesDB_FileMove_log.ldf
-- To  : C:\MSSQLSERVER\NEWLOG\ExamplesDB_FileMove_log.ldf

-------------------------------------------------------------------------------
-- 6 - Set database ONLINE
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_FileMove
SET ONLINE;
GO

-------------------------------------------------------------------------------
-- 7 - Validate file location
-------------------------------------------------------------------------------

SELECT
name,
physical_name,
type_desc
FROM sys.master_files
WHERE database_id = DB_ID(N'ExamplesDB_FileMove');
GO

/*
Result:
name	                physical_name	                                    type_desc
ExamplesDB_FileMove	    C:\MSSQLSERVER\DATA\ExamplesDB_FileMove.mdf	        ROWS
ExamplesDB_FileMove_log	C:\MSSQLSERVER\NEWLOG\ExamplesDB_FileMove_log.ldf	LOG
*/

-------------------------------------------------------------------------------
-- 8 - Cleanup
-------------------------------------------------------------------------------

DROP DATABASE IF EXISTS ExamplesDB_FileMove;
GO
