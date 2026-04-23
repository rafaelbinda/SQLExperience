/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0017 - Backup Device Inspection
Object      : Script
Description : Queries to inspect backup devices, physical paths, related backup
              history, and operational risks associated with registered devices
Notes       : 03-backup-and-restore/notes/A0028-backup-device-vs-backup-file.md
Examples    : 03-backup-and-restore/scripts/Q0025-sql-backup-device-vs-backup-file.sql
===============================================================================

INDEX
1 - List registered backup devices
2 - View physical path and device type
3 - Identify backup history associated with backup devices
4 - Compare device usage versus direct file usage
5 - Identify backup devices without recent usage
6 - Review media information linked to device-based backups
7 - Summarize device usage by database
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - List registered backup devices
-------------------------------------------------------------------------------
/*
→ Shows all backup devices registered in master
*/

SELECT
bd.name,
bd.physical_name,
bd.type_desc
FROM sys.backup_devices AS bd
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 2 - View physical path and device type
-------------------------------------------------------------------------------
/*
→ Highlights logical name, physical destination, and device type
→ Useful to validate whether the registered device still points to the expected path
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type,
bd.type_desc
FROM sys.backup_devices AS bd
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 3 - Identify backup history associated with backup devices
-------------------------------------------------------------------------------
/*
→ Shows backups written to paths that match registered backup devices
→ Helps validate whether the device is actually being used
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name AS registered_physical_name,
bs.database_name,
bs.backup_start_date,
bs.backup_finish_date,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    WHEN 'F' THEN 'FILE OR FILEGROUP'
    WHEN 'G' THEN 'DIFFERENTIAL FILE'
    WHEN 'P' THEN 'PARTIAL'
    WHEN 'Q' THEN 'DIFFERENTIAL PARTIAL'
    ELSE bs.type
END AS backup_type_desc
FROM sys.backup_devices AS bd
LEFT JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
LEFT JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
ORDER BY bd.name, bs.backup_start_date DESC;
GO

-------------------------------------------------------------------------------
-- 4 - Compare device usage versus direct file usage
-------------------------------------------------------------------------------
/*
→ Compares registered backup device paths with backup history in msdb
→ Helps identify whether backups are being written through devices or directly to files
*/

SELECT
bmf.physical_device_name,
CASE
    WHEN bd.name IS NOT NULL THEN 'REGISTERED BACKUP DEVICE'
    ELSE 'DIRECT FILE OR UNREGISTERED PATH'
END AS usage_type,
COUNT(*) AS total_backups
FROM msdb.dbo.backupmediafamily AS bmf
LEFT JOIN sys.backup_devices AS bd
    ON bmf.physical_device_name = bd.physical_name
GROUP BY bmf.physical_device_name,
CASE
    WHEN bd.name IS NOT NULL THEN 'REGISTERED BACKUP DEVICE'
    ELSE 'DIRECT FILE OR UNREGISTERED PATH'
END
ORDER BY total_backups DESC, bmf.physical_device_name;
GO

-------------------------------------------------------------------------------
-- 5 - Identify backup devices without recent usage
-------------------------------------------------------------------------------
/*
→ Shows devices that are registered but have no matching backup history
→ Useful to identify unused or obsolete backup device registrations
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type_desc
FROM sys.backup_devices AS bd
LEFT JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
WHERE bmf.physical_device_name IS NULL
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 6 - Review media information linked to device-based backups
-------------------------------------------------------------------------------
/*
→ Displays media and backup metadata for registered device paths
→ Useful for validating file reuse, media growth, and device-based backup history
*/

SELECT
bd.name AS backup_device_name,
bmf.physical_device_name,
bs.database_name,
bs.backup_start_date,
bs.position,
bs.backup_size,
bs.compressed_backup_size,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE bs.type
END AS backup_type_desc
FROM sys.backup_devices AS bd
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
INNER JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
ORDER BY bd.name, bs.backup_start_date DESC;
GO

-------------------------------------------------------------------------------
-- 7 - Summarize device usage by database
-------------------------------------------------------------------------------
/*
→ Summarizes how each registered backup device has been used per database
→ Useful for operational review and troubleshooting
*/

SELECT
bd.name AS backup_device_name,
bs.database_name,
COUNT(*) AS total_backups,
MIN(bs.backup_start_date) AS first_backup_start,
MAX(bs.backup_start_date) AS last_backup_start
FROM sys.backup_devices AS bd
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
INNER JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
GROUP BY bd.name, bs.database_name
ORDER BY bd.name, bs.database_name;
GO