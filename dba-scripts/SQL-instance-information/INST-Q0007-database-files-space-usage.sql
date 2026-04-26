/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-29
Version     : 2.0
Task        : INST-Q0007 - Database Files Space Usage
Object      : Script
Description : Returns database file details including logical name, physical
              name, file type, size, used space, free space, percent used,
              growth configuration and formatted size information
Notes       : notes/A0018-database-file-management.md
Examples    : scripts/Q0014-sql-database-file-management.sql
===============================================================================
INDEX
1 - Database files space usage
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Database files space usage
-------------------------------------------------------------------------------

USE AdventureWorks;
GO

SELECT
DB_NAME() AS database_name,
df.file_id,
df.name AS logical_name,
df.physical_name,
df.type_desc,
fg.name AS filegroup_name,
df.state_desc,

-------------------------------------------------------------------------------
-- Size information
-------------------------------------------------------------------------------

CAST(df.size * 8.0 / 1024 AS DECIMAL(18,2)) AS size_mb,

CASE 
    WHEN df.size * 8.0 >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST((df.size * 8.0) / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN df.size * 8.0 >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST((df.size * 8.0) / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN df.size * 8.0 >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST((df.size * 8.0) / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    WHEN df.size * 8.0 >= 1024
    THEN CONCAT(CAST((df.size * 8.0) / 1024 AS DECIMAL(18,2)), ' KB')

    ELSE CONCAT(CAST(df.size * 8.0 AS DECIMAL(18,2)), ' Bytes')
END AS size_formatted,

-------------------------------------------------------------------------------
-- Used space information
-------------------------------------------------------------------------------

CAST(FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 / 1024 AS DECIMAL(18,2)) AS space_used_mb,

CASE 
    WHEN FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST((FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST((FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST((FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    WHEN FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 >= 1024
    THEN CONCAT(CAST((FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / 1024 AS DECIMAL(18,2)), ' KB')

    ELSE CONCAT(CAST(FILEPROPERTY(df.name, 'SpaceUsed') * 8.0 AS DECIMAL(18,2)), ' Bytes')
END AS space_used_formatted,

-------------------------------------------------------------------------------
-- Free space information
-------------------------------------------------------------------------------

CAST((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 / 1024 AS DECIMAL(18,2)) AS free_space_mb,

CASE 
    WHEN (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST(((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0) / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST(((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0) / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST(((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0) / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    WHEN (df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 >= 1024
    THEN CONCAT(CAST(((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0) / 1024 AS DECIMAL(18,2)), ' KB')

    ELSE CONCAT(CAST((df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8.0 AS DECIMAL(18,2)), ' Bytes')
END AS free_space_formatted,

-------------------------------------------------------------------------------
-- Percent used
-------------------------------------------------------------------------------

CAST(
    CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS DECIMAL(18,4))
    / NULLIF(CAST(df.size AS DECIMAL(18,4)), 0) * 100
AS DECIMAL(10,2)) AS percent_used,

-------------------------------------------------------------------------------
-- Max size information
-------------------------------------------------------------------------------

CASE 
    WHEN df.max_size = -1 THEN 'UNLIMITED'
    WHEN df.max_size = 0 THEN 'NO GROWTH'

    WHEN df.max_size * 8.0 >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST((df.max_size * 8.0) / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN df.max_size * 8.0 >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST((df.max_size * 8.0) / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN df.max_size * 8.0 >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST((df.max_size * 8.0) / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    WHEN df.max_size * 8.0 >= 1024
    THEN CONCAT(CAST((df.max_size * 8.0) / 1024 AS DECIMAL(18,2)), ' KB')

    ELSE CONCAT(CAST(df.max_size * 8.0 AS DECIMAL(18,2)), ' Bytes')
END AS max_size_formatted,

-------------------------------------------------------------------------------
-- Growth information
-------------------------------------------------------------------------------

df.growth,
df.is_percent_growth,

CASE
    WHEN df.is_percent_growth = 1
    THEN CONCAT(df.growth, ' %')

    WHEN df.growth * 8.0 >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST((df.growth * 8.0) / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN df.growth * 8.0 >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST((df.growth * 8.0) / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN df.growth * 8.0 >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST((df.growth * 8.0) / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    WHEN df.growth * 8.0 >= 1024
    THEN CONCAT(CAST((df.growth * 8.0) / 1024 AS DECIMAL(18,2)), ' KB')

    ELSE CONCAT(CAST(df.growth * 8.0 AS DECIMAL(18,2)), ' Bytes')
END AS growth_formatted

FROM sys.database_files AS df
LEFT JOIN sys.filegroups AS fg
    ON df.data_space_id = fg.data_space_id
ORDER BY df.file_id;
GO