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
-- 8 - Reference backup device examples
-------------------------------------------------------------------------------
/*
→ This script focuses on registered backup device inspection
→ It does NOT execute backup device creation, backup, or drop commands

For practical backup device examples, refer to:

- Q0025 - Backup Device vs Backup File

Covered hands-on topics:
1. Create backup device with sp_addumpdevice
2. Execute backup using a registered backup device
3. Execute backup using a direct physical file path
4. Compare backup device usage versus direct file usage
5. Validate backup metadata using RESTORE HEADERONLY
6. Validate media metadata using RESTORE LABELONLY
7. Drop backup device with sp_dropdevice

Important:
- INST-Q0017 inspects registered backup devices from sys.backup_devices
- INST-Q0016 analyzes backup media/history from msdb
- Q0025 demonstrates the operational difference between Backup Device and Backup File

For the full executable script, see:
03-backup-and-restore/scripts/Q0025-sql-backup-device-vs-backup-file.sql
*/
