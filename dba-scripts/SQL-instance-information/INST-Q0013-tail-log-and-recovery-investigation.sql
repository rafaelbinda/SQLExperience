/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 2.0
Task        : INST-Q0013 - Tail Log and Recovery Investigation
Object      : Script
Description : Queries to evaluate whether a tail log backup should be considered
              before restore operations, based on database state, recovery model,
              latest FULL backup, latest LOG backup, and transaction log status.
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
Examples    : 03-backup-and-restore/scripts/Q0022-sql-tail-log-backup.sql
Related     : INST-Q0012 - Backup Chain and Restore Sequence Inspection
===============================================================================

INDEX
1 - Define target database and base recovery context
2 - Check database recovery model and state
3 - Identify latest FULL and LOG backups
4 - Measure exposure since last LOG backup
5 - Review log reuse and log file status
6 - Evaluate tail log backup applicability
7 - Review tail log backup command examples
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Define target database and base recovery context
-------------------------------------------------------------------------------
/*
→ Defines the target database and identifies the latest FULL backup.

Interpretation:
- @DATABASE centralizes the database name used by the script
- @LASTFULL is used only as recovery context for Tail Log evaluation
- Full backup chain validation is intentionally outside this script
- Use INST-Q0012 for complete backup chain, LSN continuity, differential base,
  and restore readiness analysis
*/

DECLARE @DATABASE SYSNAME = N'ExamplesDB_BackupRestore';
DECLARE @RECOVERY_MODEL VARCHAR(20);
DECLARE @LASTFULL DATETIME2;

SELECT @RECOVERY_MODEL = TRIM(d.recovery_model_desc)
FROM sys.databases AS d
WHERE d.name = @DATABASE;

SELECT @LASTFULL = MAX(bs.backup_start_date)
FROM msdb.dbo.backupset AS bs
WHERE bs.database_name = @DATABASE
AND bs.type = 'D';

SELECT
@DATABASE AS database_name,
@RECOVERY_MODEL AS recovery_model_desc,
@LASTFULL AS latest_full_backup_start_date,
CASE
    WHEN @RECOVERY_MODEL IS NULL
    THEN 'DATABASE NOT FOUND'
    WHEN @RECOVERY_MODEL NOT IN ('FULL', 'BULK_LOGGED')
    THEN 'TAIL LOG STRATEGY NOT APPLICABLE FOR THIS RECOVERY MODEL'
    WHEN @LASTFULL IS NULL
    THEN 'NO FULL BACKUP FOUND - VALIDATE BACKUP STRATEGY FIRST'
    ELSE 'BASE CONTEXT IDENTIFIED'
END AS base_context_status;

-------------------------------------------------------------------------------
-- 2 - Check database recovery model and state
-------------------------------------------------------------------------------
/*
→ Shows whether the database is accessible and whether the recovery model supports
  a tail log backup strategy.

Interpretation:
- FULL and BULK_LOGGED are the relevant recovery models for tail log backup
- SIMPLE does not support the same tail log recovery strategy
- state_desc helps identify whether the database is currently accessible
- log_reuse_wait_desc helps understand current transaction log behavior
*/

SELECT
d.name AS database_name,
d.state_desc,
d.recovery_model_desc,
d.log_reuse_wait_desc,
d.user_access_desc,
d.is_in_standby
FROM sys.databases AS d
WHERE d.name = @DATABASE;

-------------------------------------------------------------------------------
-- 3 - Identify latest FULL and LOG backups
-------------------------------------------------------------------------------
/*
→ Shows only the minimum backup context needed for Tail Log decision-making.

Interpretation:
- Latest FULL is the most recent base backup available in msdb
- Latest LOG indicates the last protected point in the log backup chain
- This section does not replace full backup chain validation from INST-Q0012
*/

;WITH BackupContext AS
(
    SELECT
    bs.database_name,
    bs.type,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.first_lsn,
    bs.last_lsn,
    bs.checkpoint_lsn,
    ROW_NUMBER() OVER
    (
        PARTITION BY bs.type
        ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC
    ) AS rn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type IN ('D', 'L')
)
SELECT
bc.database_name,
bc.type,
CASE bc.type
    WHEN 'D' THEN 'FULL'
    WHEN 'L' THEN 'LOG'
    ELSE bc.type
END AS backup_type_desc,
bc.backup_start_date,
bc.backup_finish_date,
bc.first_lsn,
bc.last_lsn,
bc.checkpoint_lsn
FROM BackupContext AS bc
WHERE bc.rn = 1
ORDER BY bc.type;

-------------------------------------------------------------------------------
-- 4 - Measure exposure since last LOG backup
-------------------------------------------------------------------------------
/*
→ Measures the time gap between the latest LOG backup and now.

Interpretation:
- This does not calculate exact data loss
- It estimates the time window that may depend on a tail log backup
- The longer the interval, the more relevant the tail log decision becomes
*/

;WITH LatestLogBackup AS
(
    SELECT TOP (1)
    backup_start_date,
    backup_finish_date,
    first_lsn,
    last_lsn
    FROM msdb.dbo.backupset
    WHERE database_name = @DATABASE
    AND type = 'L'
    ORDER BY backup_finish_date DESC, backup_set_id DESC
)
SELECT
@DATABASE AS database_name,
llb.backup_start_date AS last_log_backup_start_date,
llb.backup_finish_date AS last_log_backup_finish_date,
DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
DATEDIFF(HOUR, llb.backup_finish_date, GETDATE()) AS hours_since_last_log_backup,
CASE
    WHEN llb.backup_finish_date IS NULL
    THEN 'NO LOG BACKUP FOUND'
    WHEN DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) <= 15
    THEN 'LOW TIME EXPOSURE'
    WHEN DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) <= 60
    THEN 'MODERATE TIME EXPOSURE'
    ELSE 'HIGH TIME EXPOSURE'
END AS time_exposure_status
FROM LatestLogBackup AS llb;

-------------------------------------------------------------------------------
-- 5 - Review log reuse and log file status
-------------------------------------------------------------------------------
/*
→ Shows current transaction log information and reuse wait reason.

Interpretation:
- log_reuse_wait_desc may indicate why inactive log space is not being reused
- Log file metadata helps assess operational context before recovery actions
- This section supports Tail Log evaluation; it is not a restore sequence check
*/

SELECT
d.name AS database_name,
d.recovery_model_desc,
d.state_desc,
d.log_reuse_wait_desc,
mf.name AS logical_file_name,
mf.physical_name,
mf.type_desc,
CAST((mf.size * 8.0) / 1024 AS DECIMAL(18,2)) AS size_mb,
mf.max_size,
mf.growth,
mf.is_percent_growth
FROM sys.databases AS d
INNER JOIN sys.master_files AS mf
    ON d.database_id = mf.database_id
WHERE d.name = @DATABASE
AND mf.type_desc = 'LOG';

-------------------------------------------------------------------------------
-- 6 - Evaluate tail log backup applicability
-------------------------------------------------------------------------------
/*
→ Provides a focused operational interpretation for Tail Log decision-making.

Summary:
- This script does not execute BACKUP LOG
- It helps the DBA evaluate whether a tail log backup should be considered
- Final decision depends on the failure scenario, database accessibility, and
  restore objective
- Use INST-Q0012 to validate the full restore sequence and backup chain
*/

;WITH DbInfo AS
(
    SELECT
    d.name,
    d.state_desc,
    d.recovery_model_desc,
    d.log_reuse_wait_desc
    FROM sys.databases AS d
    WHERE d.name = @DATABASE
),
LatestLogBackup AS
(
    SELECT TOP (1)
    backup_finish_date,
    first_lsn,
    last_lsn
    FROM msdb.dbo.backupset
    WHERE database_name = @DATABASE
    AND type = 'L'
    ORDER BY backup_finish_date DESC, backup_set_id DESC
)
SELECT
    @DATABASE AS database_name,
    di.state_desc,
    di.recovery_model_desc,
    di.log_reuse_wait_desc,
    @LASTFULL AS latest_full_backup_start_date,
    llb.backup_finish_date AS last_log_backup_finish_date,
    DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
    CASE
        WHEN di.name IS NULL
        THEN 'DATABASE NOT FOUND'
        WHEN di.recovery_model_desc = 'SIMPLE'
        THEN 'TAIL LOG NOT APPLICABLE'
        WHEN @LASTFULL IS NULL
        THEN 'NO FULL BACKUP FOUND - VALIDATE BACKUP STRATEGY FIRST'
        WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
        AND llb.backup_finish_date IS NULL
        THEN 'NO LOG BACKUP FOUND - CHECK LOG BACKUP STRATEGY'
        WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
        AND di.state_desc = 'ONLINE'
        AND llb.backup_finish_date IS NOT NULL
        THEN 'READY TO CONSIDER TAIL LOG BACKUP WITH NORECOVERY'
        WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
        AND di.state_desc <> 'ONLINE'
        THEN 'CONSIDER TAIL LOG BACKUP WITH FAILURE-SCENARIO OPTIONS'
        ELSE 'CHECK DATABASE ACCESSIBILITY AND FAILURE SCENARIO'
    END AS tail_log_applicability
FROM DbInfo AS di
LEFT JOIN LatestLogBackup AS llb
    ON 1 = 1;

-------------------------------------------------------------------------------
-- 7 - Review tail log backup command examples
-------------------------------------------------------------------------------
/*
→ These examples are intentionally commented.

Important:
- Validate the restore scenario before executing any command
- Adjust file paths before use
- Use WITH NORECOVERY when the database is online and you want to leave it ready
  for restore
- Use WITH NO_TRUNCATE when the database is damaged but the log file is still
  accessible
- Use CONTINUE_AFTER_ERROR only when required by the failure scenario
*/

/*
-- Scenario 1: Database is online and will be restored after the tail log backup
BACKUP LOG [ExamplesDB_BackupRestore]
TO DISK = 'C:\SQLBackups\ExamplesDB_BackupRestore_TailLog.trn'
WITH NORECOVERY, INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

-- Scenario 2: Database is damaged, but the transaction log is still accessible
BACKUP LOG [ExamplesDB_BackupRestore]
TO DISK = 'C:\SQLBackups\ExamplesDB_BackupRestore_TailLog.trn'
WITH NO_TRUNCATE, INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO

-- Scenario 3: Severe failure scenario, only when necessary
BACKUP LOG [ExamplesDB_BackupRestore]
TO DISK = 'C:\SQLBackups\ExamplesDB_BackupRestore_TailLog.trn'
WITH NO_TRUNCATE, CONTINUE_AFTER_ERROR, INIT, COMPRESSION, CHECKSUM, STATS = 10;
GO
*/
GO
