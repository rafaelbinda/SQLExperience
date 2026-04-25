/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 2.0
Task        : INST-Q0016 - Backup Media and History Analysis
Object      : Script
Description : Analyze backup files, media usage, compression, and distribution
              for a specific database since the latest FULL backup
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
Related     : INST-Q0012 - Backup Chain and Restore Sequence Inspection
===============================================================================

INDEX
1 - Define database and identify last FULL backup
2 - Analyze backup distribution by type
3 - List backup files used since last FULL
4 - Identify multiple backups in the same file
5 - Analyze compression and size
6 - Detect lastest 5 FULL backup growth trend
*/

USE msdb;
GO

-------------------------------------------------------------------------------
-- 1 - Define database and identify last FULL backup
-------------------------------------------------------------------------------

DECLARE @DATABASE SYSNAME = N'ExamplesDB_BackupRestore';
DECLARE @LASTFULL DATETIME2;

SELECT @LASTFULL = MAX(backup_start_date)
FROM msdb.dbo.backupset
WHERE database_name = @DATABASE
AND type = 'D';

SELECT
@DATABASE AS database_name,
@LASTFULL AS last_full_backup_start;

-------------------------------------------------------------------------------
-- 2 - Analyze backup distribution by type
-------------------------------------------------------------------------------

SELECT
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
END AS backup_type,
COUNT(*) AS total_backups,
COUNT(DISTINCT bmf.physical_device_name) AS total_files_used
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = @DATABASE
AND bs.type IN ('D','I','L')
AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
GROUP BY bs.type;

-------------------------------------------------------------------------------
-- 3 - List backup files used since last FULL
-------------------------------------------------------------------------------
/*
→ Shows real backup files used in the current restore context
→ Includes FULL, DIFFERENTIAL and LOG
*/

SELECT
bs.database_name,
bs.backup_start_date,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
END AS backup_type_desc,
bmf.physical_device_name,
bs.media_set_id,
bs.position
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = @DATABASE
AND bs.type IN ('D','I','L')
AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
ORDER BY bs.backup_start_date;

-------------------------------------------------------------------------------
-- 4 - Identify multiple backups in the same file
-------------------------------------------------------------------------------

SELECT
bmf.physical_device_name,
COUNT(*) AS total_backups,
MIN(bs.backup_start_date) AS first_backup,
MAX(bs.backup_start_date) AS last_backup
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = @DATABASE
AND bs.type IN ('D','I','L')
AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
GROUP BY bmf.physical_device_name
HAVING COUNT(*) > 1
ORDER BY total_backups DESC;

-------------------------------------------------------------------------------
-- 5 - Analyze compression and size
-------------------------------------------------------------------------------

SELECT
bs.database_name,
bs.type,
bs.backup_start_date,
bs.backup_size,
bs.compressed_backup_size,
CAST(
    CASE
        WHEN bs.backup_size > 0 AND bs.compressed_backup_size IS NOT NULL
        THEN (1.0 - (CAST(bs.compressed_backup_size AS DECIMAL(18,2)) /
                     CAST(bs.backup_size AS DECIMAL(18,2)))) * 100
        ELSE NULL
    END AS DECIMAL(10,2)
) AS compression_percent
FROM msdb.dbo.backupset bs
WHERE bs.database_name = @DATABASE
AND bs.type IN ('D','I','L')
AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
ORDER BY bs.backup_start_date DESC;
 
-------------------------------------------------------------------------------
-- 6 - Detect latest 5 FULL backup growth trend
-------------------------------------------------------------------------------
/*
→ Shows the latest 5 FULL backups and compares each one with the previous FULL
→ growth_percent indicates how much the FULL backup increased or decreased
*/

;WITH FullBackups AS
(
    SELECT
    bs.backup_start_date,
    bs.backup_size,
    CAST(bs.backup_size / POWER(1024.0, 2) AS DECIMAL(18,2)) AS current_size_mb,
    LAG(bs.backup_size) OVER (ORDER BY bs.backup_start_date) AS previous_size_bytes
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'D'
),
LatestFullBackups AS
(
    SELECT TOP (5)
    *
    FROM FullBackups
    ORDER BY backup_start_date DESC
)
SELECT
backup_start_date,
CASE 
    WHEN backup_size >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST(backup_size / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')
    WHEN backup_size >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST(backup_size / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')
    WHEN backup_size >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST(backup_size / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')
    ELSE CONCAT(CAST(backup_size AS DECIMAL(18,2)), ' Bytes')
END AS backup_size_formatted,
CAST(previous_size_bytes / POWER(1024.0, 2) AS DECIMAL(18,2)) AS previous_size_mb,
CAST(current_size_mb AS DECIMAL(18,2)) AS current_size_mb,
CAST(
    CASE 
        WHEN previous_size_bytes IS NULL OR previous_size_bytes = 0 
        THEN NULL
        ELSE ((backup_size - previous_size_bytes) / CAST(previous_size_bytes AS DECIMAL(18,2))) * 100
    END
AS DECIMAL(10,2)) AS growth_percent,
CASE
    WHEN previous_size_bytes IS NULL 
    THEN 'NO PREVIOUS FULL BACKUP'
    WHEN previous_size_bytes = 0 
    THEN 'PREVIOUS BACKUP SIZE ZERO'
    WHEN ((backup_size - previous_size_bytes) / CAST(previous_size_bytes AS DECIMAL(18,2))) * 100 > 20
    THEN 'HIGH GROWTH'
    WHEN ((backup_size - previous_size_bytes) / CAST(previous_size_bytes AS DECIMAL(18,2))) * 100 > 5
    THEN 'MODERATE GROWTH'
    WHEN ((backup_size - previous_size_bytes) / CAST(previous_size_bytes AS DECIMAL(18,2))) * 100 < 0
    THEN 'SIZE DECREASED'
    ELSE 'STABLE'
END AS growth_status
FROM LatestFullBackups
ORDER BY backup_start_date ASC;