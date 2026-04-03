/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-26
Version     : 1.0
Task        : INST-Q0005 - Database Files and Filegroups Overview
Object      : Script
Description : Queries for quick inspection of database files, filegroups,
              growth settings, physical paths, and log file configuration
Notes       : notes/A0016-database-architecture.md
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
--1 - Database files overview
-------------------------------------------------------------------------------
--Shows database, logical file name, physical path, file type, size, and growth
 
SELECT
database_name         = DB_NAME(mf.database_id),
file_id               = mf.file_id,
logical_file_name     = mf.name,
file_type             = mf.type_desc,
physical_name         = mf.physical_name,
filegroup_name        = fg.name,
size_mb               = CAST(mf.size * 8.0 / 1024 AS DECIMAL(18,2)),
max_size_mb           = CASE
                            WHEN mf.max_size = -1 THEN -1
                            ELSE CAST(mf.max_size * 8.0 / 1024 AS DECIMAL(18,2))
                        END,
growth_value          = mf.growth,
growth_unit           = CASE
                            WHEN mf.is_percent_growth = 1 THEN 'Percent'
                            ELSE 'Pages'
                        END,
growth_description    = CASE
                            WHEN mf.is_percent_growth = 1
                            THEN CAST(mf.growth AS VARCHAR(20)) + '%'
                            ELSE CAST(CAST(mf.growth * 8.0 / 1024 AS DECIMAL(18,2)) AS VARCHAR(20)) + ' MB'
                        END,
state_desc            = mf.state_desc
FROM sys.master_files AS mf
LEFT JOIN sys.filegroups AS fg
ON mf.data_space_id = fg.data_space_id
WHERE DB_NAME(mf.database_id) = 'AdventureWorks'
ORDER BY mf.type_desc, mf.file_id;
GO

-------------------------------------------------------------------------------
-- 2 - Filegroups overview
-------------------------------------------------------------------------------
--Shows filegroups and whether they are configured as default or read-only

USE AdventureWorks;
GO

SELECT
filegroup_id_   = fg.data_space_id,
filegroup_name_ = fg.name,
fg.type_desc,
fg.is_default,
fg.is_read_only
,*
FROM sys.filegroups AS fg
ORDER BY fg.data_space_id;
GO

-------------------------------------------------------------------------------
--3 - Files by filegroup
-------------------------------------------------------------------------------
-- Relates each data file to its filegroup

SELECT
filegroup_name_       = fg.name,
logical_file_name     = df.name,
physical_name         = df.physical_name,
size_mb               = CAST(df.size * 8.0 / 1024 AS DECIMAL(18,2)),
max_size_mb           = CASE
                            WHEN df.max_size = -1 THEN -1
                            ELSE CAST(df.max_size * 8.0 / 1024 AS DECIMAL(18,2))
                        END,
growth_description    = CASE
                            WHEN df.is_percent_growth = 1
                            THEN CAST(df.growth AS VARCHAR(20)) + '%'
                            ELSE CAST(CAST(df.growth * 8.0 / 1024 AS DECIMAL(18,2)) AS VARCHAR(20)) + ' MB'
                        END
FROM sys.database_files AS df
INNER JOIN sys.filegroups AS fg
ON df.data_space_id = fg.data_space_id
WHERE df.type_desc = 'ROWS'
ORDER BY fg.name, df.file_id;
GO

-------------------------------------------------------------------------------
-- 4 - Log files overview
-------------------------------------------------------------------------------
-- Shows transaction log files for the database
SELECT
logical_file_name     = df.name,
physical_name         = df.physical_name,
file_type             = df.type_desc,
size_mb               = CAST(df.size * 8.0 / 1024 AS DECIMAL(18,2)),
max_size_mb           = CASE
                            WHEN df.max_size = -1 THEN -1
                            ELSE CAST(df.max_size * 8.0 / 1024 AS DECIMAL(18,2))
                        END,
growth_description    = CASE
                            WHEN df.is_percent_growth = 1
                            THEN CAST(df.growth AS VARCHAR(20)) + '%'
                            ELSE CAST(CAST(df.growth * 8.0 / 1024 AS DECIMAL(18,2)) AS VARCHAR(20)) + ' MB'
                        END
FROM sys.database_files AS df
WHERE df.type_desc = 'LOG';
GO

-------------------------------------------------------------------------------
--5 - Database properties related to storage
-------------------------------------------------------------------------------
-- Useful for correlating architecture with recovery and access behavior
 
SELECT
database_name_          = d.name,
d.recovery_model_desc,
d.user_access_desc,
d.state_desc,
d.is_read_only,
d.is_auto_close_on,
d.compatibility_level
FROM sys.databases AS d
WHERE d.name = 'AdventureWorks';
GO
