/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0013 - Tail Log and Recovery Investigation
Object      : Script
Description : Queries to investigate recovery model, recent backup activity,
              last log backup time, and tail log recovery readiness
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
Examples    : 03-backup-and-restore/scripts/Q0022-sql-tail-log-backup.sql
===============================================================================

INDEX
1 - Check database recovery model and state
2 - View latest FULL, DIFFERENTIAL, and LOG backups
3 - Measure elapsed time since last LOG backup
4 - Review log reuse and recovery-related status
5 - View recent backup history for the database
6 - Evaluate tail log recovery readiness
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Check database recovery model and state
-------------------------------------------------------------------------------
/*
→ Shows whether the database is online and whether the recovery model supports
  tail log strategy

Interpretation:
- FULL and BULK_LOGGED are the relevant recovery models for tail log backup
- SIMPLE does not support the same tail log recovery strategy
- state_desc helps identify whether the database is currently accessible
*/

SELECT
d.name,
d.state_desc,
d.recovery_model_desc,
d.log_reuse_wait_desc,
d.user_access_desc,
d.is_in_standby
FROM sys.databases AS d
WHERE d.name = N'ExamplesDB_BackupRestore';
GO

-------------------------------------------------------------------------------
-- 2 - View latest FULL, DIFFERENTIAL, and LOG backups
-------------------------------------------------------------------------------
/*
→ Shows the most recent backup of each relevant type

Interpretation:
- FULL     -> restore starting point
- DIFF     -> optional acceleration step
- LOG      -> determines how current the chain is before a failure
*/

SELECT
bs.database_name,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE bs.type
END AS backup_type_desc,
MAX(bs.backup_finish_date) AS latest_backup_finish_date
FROM msdb.dbo.backupset AS bs
WHERE bs.database_name = N'ExamplesDB_BackupRestore'
  AND bs.type IN ('D', 'I', 'L')
GROUP BY
bs.database_name,
bs.type
ORDER BY bs.type;
GO

-------------------------------------------------------------------------------
-- 3 - Measure elapsed time since last LOG backup
-------------------------------------------------------------------------------
/*
→ Measures the time gap between the latest LOG backup and now

Interpretation:
- A larger interval may represent greater potential data loss
- In a failure scenario, this helps justify tail log backup
*/

;WITH LatestLogBackup AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_BackupRestore'
    AND type = 'L'
    ORDER BY backup_finish_date DESC
)
SELECT
N'ExamplesDB_BackupRestore' AS database_name,
llb.backup_finish_date AS last_log_backup_finish_date,
DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
DATEDIFF(HOUR, llb.backup_finish_date, GETDATE()) AS hours_since_last_log_backup
FROM LatestLogBackup AS llb;
GO

-------------------------------------------------------------------------------
-- 4 - Review log reuse and recovery-related status
-------------------------------------------------------------------------------
/*
→ Shows current log file information and reuse wait reason

Interpretation:
- log_reuse_wait_desc may indicate why inactive log space is not being reused
- Log file metadata helps assess operational context before recovery actions
*/

SELECT
d.name,
d.recovery_model_desc,
d.log_reuse_wait_desc,
mf.name AS logical_file_name,
mf.physical_name,
mf.type_desc,
mf.size * 8 / 1024 AS size_mb,
mf.max_size
FROM sys.databases AS d
INNER JOIN sys.master_files AS mf
    ON d.database_id = mf.database_id
WHERE d.name = N'ExamplesDB_BackupRestore'
AND mf.type_desc = 'LOG';
GO

-------------------------------------------------------------------------------
-- 5 - View recent backup history for the database
-------------------------------------------------------------------------------
/*
→ Shows recent backup history with LSN and media information

Interpretation:
- Useful to verify how close the last LOG backup is to the failure moment
- Helps confirm whether the backup chain is active and recent
*/

SELECT TOP (20)
bs.database_name,
bs.backup_start_date,
bs.backup_finish_date,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE bs.type
END AS backup_type_desc,
bs.first_lsn,
bs.last_lsn,
bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'ExamplesDB_BackupRestore'
ORDER BY bs.backup_finish_date DESC;
GO

-------------------------------------------------------------------------------
-- 6 - Evaluate tail log recovery readiness
-------------------------------------------------------------------------------
/*
→ Provides a quick operational interpretation for tail log decision-making

Summary:
- This script does not execute BACKUP LOG ... WITH NO_TRUNCATE
- It helps the DBA evaluate whether a tail log backup should be considered
- Final decision depends on the failure scenario and database accessibility
*/

;WITH DbInfo AS
(
    SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.log_reuse_wait_desc
    FROM sys.databases AS d
    WHERE d.name = N'ExamplesDB_BackupRestore'
),
LatestLogBackup AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_BackupRestore'
    AND type = 'L'
    ORDER BY backup_finish_date DESC
)
SELECT
di.name AS database_name,
di.state_desc,
di.recovery_model_desc,
llb.backup_finish_date AS last_log_backup_finish_date,
DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
CASE
    WHEN di.recovery_model_desc = 'SIMPLE' 
    THEN 'TAIL LOG NOT APPLICABLE'
        
    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
    AND di.state_desc = 'ONLINE'
    AND llb.backup_finish_date IS NOT NULL
    THEN 'READY TO CONSIDER TAIL LOG BACKUP'
        
    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
            AND llb.backup_finish_date IS NULL
    THEN 'CHECK LOG BACKUP STRATEGY BEFORE RECOVERY'
        
    ELSE 'CHECK DATABASE ACCESSIBILITY AND FAILURE SCENARIO'
END AS recovery_readiness
FROM DbInfo AS di
LEFT JOIN LatestLogBackup AS llb
ON 1 = 1;
GO