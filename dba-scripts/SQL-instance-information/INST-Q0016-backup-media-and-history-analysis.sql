/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0016 - Backup Media and History Analysis
Object      : Script
Description : Queries to analyze backup media usage, file distribution,
              compression efficiency, and backup growth trends
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
              03-backup-and-restore/notes/A0027-backup-device-vs-backup-file.md
===============================================================================

INDEX
1 - View backup media files and locations
2 - Identify multiple backups in the same file
3 - Analyze backup size and compression
4 - Detect backup growth over time
5 - Identify most recent backups per database
6 - Analyze backup frequency
===============================================================================
*/

USE msdb;
GO

-------------------------------------------------------------------------------
-- 1 - View backup media files and locations
-------------------------------------------------------------------------------
/*
→ Shows physical location of backup files
*/

SELECT
bs.database_name,
bs.backup_start_date,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE bs.type
END AS backup_type_desc,
bmf.physical_device_name,
bs.backup_size,
bs.compressed_backup_size
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
ORDER BY bs.backup_start_date DESC;
GO

-------------------------------------------------------------------------------
-- 2 - Identify multiple backups in the same file
-------------------------------------------------------------------------------
/*
→ Detects if backups are being appended (NOINIT)
*/

SELECT
bmf.physical_device_name,
COUNT(*) AS total_backups_in_file,
MIN(bs.backup_start_date) AS first_backup,
MAX(bs.backup_start_date) AS last_backup
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
GROUP BY bmf.physical_device_name
HAVING COUNT(*) > 1
ORDER BY total_backups_in_file DESC;
GO

-------------------------------------------------------------------------------
-- 3 - Analyze backup size and compression
-------------------------------------------------------------------------------
/*
→ Measures compression efficiency
*/

SELECT
bs.database_name,
bs.backup_start_date,
bs.type,
bs.backup_size,
bs.compressed_backup_size,
CAST(
    CASE
        WHEN bs.backup_size > 0
        THEN (1.0 - (CAST(bs.compressed_backup_size AS DECIMAL(18,2)) /
                        CAST(bs.backup_size AS DECIMAL(18,2)))) * 100
        ELSE NULL
    END AS DECIMAL(10,2)
) AS compression_saving_percent
FROM msdb.dbo.backupset bs
WHERE bs.compressed_backup_size IS NOT NULL
ORDER BY bs.backup_start_date DESC;
GO

-------------------------------------------------------------------------------
-- 4 - Detect backup growth over time
-------------------------------------------------------------------------------
/*
→ Identifies growth trends in FULL backups
*/

SELECT
bs.database_name,
bs.backup_start_date,
bs.backup_size / 1024 / 1024 AS backup_size_mb,
LAG(bs.backup_size / 1024 / 1024) OVER
    (PARTITION BY bs.database_name ORDER BY bs.backup_start_date) AS previous_size_mb
FROM msdb.dbo.backupset bs
WHERE bs.type = 'D'
ORDER BY bs.database_name, bs.backup_start_date;
GO

-------------------------------------------------------------------------------
-- 5 - Identify most recent backups per database
-------------------------------------------------------------------------------

SELECT
database_name,
MAX(CASE WHEN type = 'D' THEN backup_finish_date END) AS last_full,
MAX(CASE WHEN type = 'I' THEN backup_finish_date END) AS last_diff,
MAX(CASE WHEN type = 'L' THEN backup_finish_date END) AS last_log
FROM msdb.dbo.backupset
GROUP BY database_name
ORDER BY database_name;
GO

-------------------------------------------------------------------------------
-- 6 - Analyze backup frequency
-------------------------------------------------------------------------------
/*
→ Shows how often backups are taken
*/

SELECT
database_name,
type,
COUNT(*) AS total_backups,
MIN(backup_start_date) AS first_backup,
MAX(backup_start_date) AS last_backup
FROM msdb.dbo.backupset
GROUP BY database_name, type
ORDER BY database_name, type;
GO