/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-29
Version     : 1.0
Task        : INST-Q0007 - Database Files Space Usage
Object      : Script
Description : Returns database file details including logical name, physical
              name, file type, size, used space, free space and percent used
Notes       : notes/A0003-mantendo-banco-de-dados.md
Examples    : scripts/Q0001-sql-database-file-management.sql
===============================================================================

INDEX
1 - Database files space usage
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
df.size * 8 / 1024.0 AS size_mb,
FILEPROPERTY(df.name, 'SpaceUsed') * 8 / 1024.0 AS space_used_mb,
(df.size - FILEPROPERTY(df.name, 'SpaceUsed')) * 8 / 1024.0 AS free_space_mb,
CAST(FILEPROPERTY(df.name, 'SpaceUsed') AS DECIMAL(18,4))
    / NULLIF(CAST(df.size AS DECIMAL(18,4)), 0) * 100 AS percent_used,
CASE 
    WHEN df.max_size = -1 THEN 'UNLIMITED'
    WHEN df.max_size = 0 THEN 'NO GROWTH'
    ELSE CAST(df.max_size * 8 / 1024.0 AS VARCHAR(20))
END AS max_size,
df.growth,
df.is_percent_growth
FROM sys.database_files AS df
LEFT JOIN sys.filegroups AS fg
ON df.data_space_id = fg.data_space_id
ORDER BY df.file_id;
GO