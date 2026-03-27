/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-26
Version     : 1.0
Task        : INST-Q0006 - Database Properties and Access Modes
Object      : Script
Description : Queries for inspecting database properties, compatibility level,
              recovery model, access-related settings, file sizes, and
              DATABASEPROPERTYEX values in SQL Server
Notes       : notes/A0002-database-properties-and-access-modes.md
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
--1 - Database properties overview
-------------------------------------------------------------------------------
/*
   Lists main database properties related to compatibility, recovery model,
   page verification, and selected access-related settings
*/

SELECT
[Banco]                    = d.[name],
[Collation]                = d.collation_name,
[VersaoSQL]                = CASE d.[compatibility_level]
                                WHEN 80  THEN 'SQL2000'
                                WHEN 90  THEN 'SQL2005'
                                WHEN 100 THEN 'SQL2008'
                                WHEN 110 THEN 'SQL2012'
                                WHEN 120 THEN 'SQL2014'
                                WHEN 130 THEN 'SQL2016'
                                WHEN 140 THEN 'SQL2017'
                                WHEN 150 THEN 'SQL2019'
                                WHEN 160 THEN 'SQL2022'
                                ELSE LTRIM(STR(d.compatibility_level))
                                END,
[RecoveryModel]            = d.recovery_model_desc,
[PageVerify]               = d.page_verify_option_desc,
[Auto_Close]               = CASE
                                WHEN d.is_auto_close_on = 1 THEN 'ON'
                                ELSE 'OFF'
                                END,
[Auto_Shrink]              = CASE
                                WHEN d.is_auto_shrink_on = 1 THEN 'ON'
                                ELSE 'OFF'
                                END,
[Read_Committed_Snapshot]  = CASE
                                WHEN d.is_read_committed_snapshot_on = 1 THEN 'ON'
                                ELSE 'OFF'
                                END
FROM sys.databases AS d
WHERE d.database_id > 4
ORDER BY d.[name];
GO

-------------------------------------------------------------------------------
--2 - Base catalog views
-------------------------------------------------------------------------------
-- Raw views useful for direct inspection of database and file metadata

SELECT *
FROM sys.databases;
GO

SELECT *
FROM sys.master_files;
GO

-------------------------------------------------------------------------------
-- 3 - Database size overview (data and log)
-------------------------------------------------------------------------------
/*
   Combines sys.databases and sys.master_files to show total data and log size
   in MB for each user database
*/

;WITH CTE_TamanhoBD_Dados AS
(
    SELECT
    [Banco]            = b.name,
    [TamanhoMB_Dados]  = SUM((a.size * 8) / 1024)
    FROM sys.master_files AS a
    INNER JOIN sys.databases AS b
    ON a.database_id = b.database_id
    WHERE a.type_desc <> 'LOG'
    GROUP BY b.name
),
CTE_TamanhoBD_Log AS
(
    SELECT
    [Banco]          = b.name,
    [TamanhoMB_Log]  = SUM((a.size * 8) / 1024)
    FROM sys.master_files AS a
    INNER JOIN sys.databases AS b
    ON a.database_id = b.database_id
    WHERE a.type_desc = 'LOG'
    GROUP BY b.name
)
SELECT
[Banco]         = a.name,
[Recovery]      = a.recovery_model_desc,
[Versao]        = CASE a.compatibility_level
                        WHEN 80  THEN 'SQL2000'
                        WHEN 90  THEN 'SQL2005'
                        WHEN 100 THEN 'SQL2008'
                        WHEN 110 THEN 'SQL2012'
                        WHEN 120 THEN 'SQL2014'
                        WHEN 130 THEN 'SQL2016'
                        WHEN 140 THEN 'SQL2017'
                        WHEN 150 THEN 'SQL2019'
                        WHEN 160 THEN 'SQL2022'
                        ELSE LTRIM(STR(a.compatibility_level))
                    END,
[Collation]     = a.collation_name,
[TamanhoMB_Dados] = b.TamanhoMB_Dados,
[TamanhoMB_Log]   = c.TamanhoMB_Log
FROM master.sys.databases AS a
INNER JOIN CTE_TamanhoBD_Dados AS b
ON a.name = b.Banco
INNER JOIN CTE_TamanhoBD_Log AS c
ON a.name = c.Banco
WHERE a.database_id > 4
ORDER BY b.TamanhoMB_Dados DESC;
GO

 
-------------------------------------------------------------------------------
-- 4 - DATABASEPROPERTYEX examples
-------------------------------------------------------------------------------
-- Returns individual properties for a specific database

SELECT DATABASEPROPERTYEX('AdventureWorks', 'Collation') AS [Collation];
GO

SELECT DATABASEPROPERTYEX('AdventureWorks', 'Recovery') AS [Recovery];
GO

SELECT DATABASEPROPERTYEX('AdventureWorks', 'Status') AS [Status];
GO

/*
ONLINE     : Database is available for use
OFFLINE    : Database is unavailable and files are accessible on disk
RESTORING  : Database is in restore process
RECOVERING : Database is in recovery process
SUSPECT    : Database may be corrupted or unavailable
EMERGENCY  : Restricted access for administrative recovery operations
*/

SELECT DATABASEPROPERTYEX('AdventureWorks', 'IsAutoShrink') AS [IsAutoShrink];
GO