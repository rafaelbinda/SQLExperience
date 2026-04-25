/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 2.0
Task        : INST-Q0017 - Backup Device Inspection
Object      : Script
Description : Queries to inspect registered backup devices, physical paths,
              usage status, direct file comparison, and operational risks
              associated with backup device configuration
Notes       : 03-backup-and-restore/notes/A0028-backup-device-vs-backup-file.md
Examples    : 03-backup-and-restore/scripts/Q0025-sql-backup-device-vs-backup-file.sql
Related     : INST-Q0016 - Backup Media and History Analysis
===============================================================================

INDEX
1 - List registered backup devices
2 - Validate physical path and device type
3 - Check backup device usage history
4 - Compare registered device usage versus direct file usage
5 - Identify unused or orphan backup devices
6 - Summarize backup device usage by database
7 - Evaluate backup device operational risk
8 - Backup device creation and usage examples
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - List registered backup devices
-------------------------------------------------------------------------------
/*
→ Shows all backup devices registered in master
→ Backup devices are logical objects that point to physical backup destinations
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type_desc
FROM sys.backup_devices AS bd
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 2 - Validate physical path and device type
-------------------------------------------------------------------------------
/*
→ Highlights logical name, physical destination, and device type
→ Useful to validate whether the registered device still points to the expected path
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type,
bd.type_desc,
CASE
    WHEN bd.type_desc = 'DISK' 
    THEN 'DISK BACKUP DEVICE'
    ELSE 'REVIEW DEVICE TYPE'
END AS device_type_status
FROM sys.backup_devices AS bd
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 3 - Check backup device usage history
-------------------------------------------------------------------------------
/*
→ Checks whether registered backup devices appear in msdb backup history
→ This section validates device usage only; detailed media analysis belongs to
  INST-Q0016
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name AS registered_physical_name,
COUNT(bs.backup_set_id) AS total_backups_found,
MIN(bs.backup_start_date) AS first_backup_start,
MAX(bs.backup_start_date) AS last_backup_start,
CASE
    WHEN COUNT(bs.backup_set_id) = 0 
    THEN 'NO BACKUP HISTORY FOUND'
    ELSE 'BACKUP HISTORY FOUND'
END AS usage_status
FROM sys.backup_devices AS bd
LEFT JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
LEFT JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
GROUP BY
bd.name,
bd.physical_name
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 4 - Compare registered device usage versus direct file usage
-------------------------------------------------------------------------------
/*
→ Compares backup history paths against sys.backup_devices
→ Useful to identify whether backups are being written through registered devices
  or directly to file paths
*/

SELECT
CASE
    WHEN bd.name IS NOT NULL 
    THEN 'REGISTERED BACKUP DEVICE'
    ELSE 'DIRECT FILE OR UNREGISTERED PATH'
END AS usage_type,
COUNT(*) AS total_backup_records,
COUNT(DISTINCT bmf.physical_device_name) AS distinct_physical_destinations
FROM msdb.dbo.backupmediafamily AS bmf
LEFT JOIN sys.backup_devices AS bd
    ON bmf.physical_device_name = bd.physical_name
GROUP BY
CASE
    WHEN bd.name IS NOT NULL 
    THEN 'REGISTERED BACKUP DEVICE'
    ELSE 'DIRECT FILE OR UNREGISTERED PATH'
END
ORDER BY total_backup_records DESC;
GO

-------------------------------------------------------------------------------
-- 5 - Identify unused or orphan backup devices
-------------------------------------------------------------------------------
/*
→ Shows devices that are registered but have no matching backup history in msdb
→ Useful to identify unused, obsolete, or incorrectly registered devices
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type_desc,
'NO MATCHING BACKUP HISTORY' AS device_status
FROM sys.backup_devices AS bd
LEFT JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
WHERE bmf.physical_device_name IS NULL
ORDER BY bd.name;
GO

-------------------------------------------------------------------------------
-- 6 - Summarize backup device usage by database
-------------------------------------------------------------------------------
/*
→ Summarizes which databases have used each registered backup device
→ This is device usage analysis, not backup chain or restore validation
*/

SELECT
bd.name AS backup_device_name,
bs.database_name,
COUNT(*) AS total_backups,
MIN(bs.backup_start_date) AS first_backup_start,
MAX(bs.backup_start_date) AS last_backup_start,
MAX(CASE WHEN bs.type = 'D' THEN bs.backup_finish_date END) AS last_full_backup,
MAX(CASE WHEN bs.type = 'I' THEN bs.backup_finish_date END) AS last_differential_backup,
MAX(CASE WHEN bs.type = 'L' THEN bs.backup_finish_date END) AS last_log_backup
FROM sys.backup_devices AS bd
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
INNER JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
GROUP BY
bd.name,
bs.database_name
ORDER BY bd.name, bs.database_name;
GO

-------------------------------------------------------------------------------
-- 7 - Evaluate backup device operational risk
-------------------------------------------------------------------------------
/*
→ Provides a lightweight operational review of registered backup devices
→ Detailed backup file/media size analysis belongs to INST-Q0016
*/

SELECT
bd.name AS backup_device_name,
bd.physical_name,
bd.type_desc,
COUNT(bs.backup_set_id) AS total_backups_found,
MAX(bs.backup_finish_date) AS last_backup_finish_date,
DATEDIFF(DAY, MAX(bs.backup_finish_date), GETDATE()) AS days_since_last_usage,
CASE
    WHEN COUNT(bs.backup_set_id) = 0
    THEN 'UNUSED DEVICE'
    WHEN DATEDIFF(DAY, MAX(bs.backup_finish_date), GETDATE()) > 90
    THEN 'STALE DEVICE USAGE'
    WHEN DATEDIFF(DAY, MAX(bs.backup_finish_date), GETDATE()) > 30
    THEN 'REVIEW DEVICE USAGE'
    ELSE 'ACTIVE DEVICE USAGE'
END AS device_risk_status
FROM sys.backup_devices AS bd
LEFT JOIN msdb.dbo.backupmediafamily AS bmf
    ON bd.physical_name = bmf.physical_device_name
LEFT JOIN msdb.dbo.backupset AS bs
    ON bmf.media_set_id = bs.media_set_id
GROUP BY
bd.name,
bd.physical_name,
bd.type_desc
ORDER BY device_risk_status, bd.name;
GO

-------------------------------------------------------------------------------
-- 8 - Backup device creation and usage examples
-------------------------------------------------------------------------------
/*
Purpose:
- Demonstrates how to create, validate, use, and drop a backup device.
- Backup Device is a logical object registered in master.
- It points to a physical backup destination.
- Modern environments often use direct file paths, but backup devices are useful
  for understanding SQL Server backup metadata and legacy configurations.

Important:
- Adjust paths before executing.
- These examples are commented to avoid accidental changes.
*/

/*
-------------------------------------------------------------------------------
-- Example 1 - Drop existing backup device if it exists
-------------------------------------------------------------------------------

USE master;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.backup_devices
    WHERE name = N'BackupDevice_ExamplesDB_BackupRestore'
)
BEGIN
    EXEC master.dbo.sp_dropdevice
        @logicalname = N'BackupDevice_ExamplesDB_BackupRestore';
END;
GO

-------------------------------------------------------------------------------
-- Example 2 - Create backup device
-------------------------------------------------------------------------------

EXEC master.dbo.sp_addumpdevice
    @devtype = N'disk',
    @logicalname = N'BackupDevice_ExamplesDB_BackupRestore',
    @physicalname = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

-------------------------------------------------------------------------------
-- Example 3 - Validate backup device registration
-------------------------------------------------------------------------------

SELECT
name,
physical_name,
type_desc
FROM sys.backup_devices
WHERE name = N'BackupDevice_ExamplesDB_BackupRestore';
GO

-------------------------------------------------------------------------------
-- Example 4 - Execute backup using registered backup device
-------------------------------------------------------------------------------

BACKUP DATABASE ExamplesDB_BackupRestore
TO BackupDevice_ExamplesDB_BackupRestore
WITH
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;
GO

-------------------------------------------------------------------------------
-- Example 5 - Inspect backup generated through device physical path
-------------------------------------------------------------------------------

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

RESTORE LABELONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

-------------------------------------------------------------------------------
-- Example 6 - Drop backup device registration
-------------------------------------------------------------------------------
-- Note:
-- sp_dropdevice removes the registered logical device.
-- The physical backup file is not deleted unless @delfile = 'delfile' is used.
-------------------------------------------------------------------------------

EXEC master.dbo.sp_dropdevice
    @logicalname = N'BackupDevice_ExamplesDB_BackupRestore';
GO

-------------------------------------------------------------------------------
-- Example 7 - Drop backup device and delete physical file
-------------------------------------------------------------------------------
-- Use with caution.
-------------------------------------------------------------------------------

EXEC master.dbo.sp_dropdevice
    @logicalname = N'BackupDevice_ExamplesDB_BackupRestore',
    @delfile = N'delfile';
GO
*/
