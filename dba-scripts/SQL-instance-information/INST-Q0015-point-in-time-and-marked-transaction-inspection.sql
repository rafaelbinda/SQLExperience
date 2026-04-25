/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 2.0
Task        : INST-Q0015 - Point-in-Time and Marked Transaction Inspection
Object      : Script
Description : Queries to evaluate point-in-time restore readiness, LOG backup
              availability, marked transaction history, and restore planning
              context for a specific database
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
              03-backup-and-restore/notes/A0026-point-in-time-restore.md
Examples    : 03-backup-and-restore/scripts/Q0023-sql-point-in-time-restore-and-marked-transactions.sql
Related     : INST-Q0012 - Backup Chain and Restore Sequence Inspection
===============================================================================

INDEX
1 - Define target database and identify latest FULL backup
2 - Check database recovery model and state
3 - Evaluate point-in-time restore applicability
4 - View latest LOG backup interval since latest FULL
5 - View marked transaction history for the database
6 - Identify databases with marked transactions
7 - Review point-in-time restore planning summary
8 - Reference point-in-time restore examples
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Define target database and identify latest FULL backup
-------------------------------------------------------------------------------
/*
→ Change @DATABASE according to the database being investigated
→ @LASTFULL limits backup-related checks to the current restore base
→ Full LOG chain validation is covered by INST-Q0012
*/

DECLARE @DATABASE SYSNAME = N'ExamplesDB_PointInTime';
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
    WHEN @RECOVERY_MODEL = 'SIMPLE'
    THEN 'POINT-IN-TIME RESTORE NOT APPLICABLE'
    WHEN @RECOVERY_MODEL IN ('FULL', 'BULK_LOGGED')
         AND @LASTFULL IS NULL
    THEN 'NO FULL BACKUP FOUND - VALIDATE BACKUP STRATEGY FIRST'
    WHEN @RECOVERY_MODEL IN ('FULL', 'BULK_LOGGED')
         AND @LASTFULL IS NOT NULL
    THEN 'BASE CONTEXT IDENTIFIED'
    ELSE 'REVIEW RECOVERY MODEL'
END AS base_context_status;

-------------------------------------------------------------------------------
-- 2 - Check database recovery model and state
-------------------------------------------------------------------------------
/*
→ Point-in-time restore requires FULL or BULK_LOGGED recovery model
→ SIMPLE does not support point-in-time recovery
→ state_desc helps evaluate whether the database is currently accessible
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
-- 3 - Evaluate point-in-time restore applicability
-------------------------------------------------------------------------------
/*
Interpretation:
- FULL + LOG is the minimum backup strategy for point-in-time restore
- DIFFERENTIAL is optional and can reduce restore time
- This section does not validate full LOG chain continuity
- Use INST-Q0012 for complete backup chain, LSN continuity and restore readiness
*/

;WITH BackupSummary AS
(
    SELECT
    MAX(CASE WHEN bs.type = 'D' THEN 1 ELSE 0 END) AS has_full,
    MAX(CASE WHEN bs.type = 'I' THEN 1 ELSE 0 END) AS has_diff,
    MAX(CASE WHEN bs.type = 'L' THEN 1 ELSE 0 END) AS has_log
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
),
DbInfo AS
(
    SELECT
    d.name,
    d.recovery_model_desc,
    d.state_desc
    FROM sys.databases AS d
    WHERE d.name = @DATABASE
)
SELECT
di.name AS database_name,
di.state_desc,
di.recovery_model_desc,
@LASTFULL AS restore_base_full_backup_start_date,
bs.has_full,
bs.has_diff,
bs.has_log,
CASE
    WHEN di.recovery_model_desc = 'SIMPLE'
    THEN 'POINT-IN-TIME NOT APPLICABLE'

    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
         AND bs.has_full = 1
         AND bs.has_log = 1
    THEN 'POINT-IN-TIME RESTORE MAY BE APPLICABLE'

    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
         AND bs.has_full = 1
         AND bs.has_log = 0
    THEN 'FULL EXISTS BUT LOG BACKUP IS MISSING SINCE LATEST FULL'

    WHEN bs.has_full = 0
    THEN 'NO FULL BACKUP BASE FOUND'

    ELSE 'CHECK BACKUP STRATEGY'
END AS point_in_time_readiness
FROM DbInfo AS di
CROSS JOIN BackupSummary AS bs;

-------------------------------------------------------------------------------
-- 4 - View latest LOG backup interval since latest FULL
-------------------------------------------------------------------------------
/*
→ Shows the latest LOG backup after the current FULL restore base
→ Helps estimate the gap between the latest LOG backup and the current moment
→ In a failure scenario, this may help justify a Tail Log Backup decision
*/

;WITH LatestLogBackup AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.first_lsn,
    bs.last_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'L'
    AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
    ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC
)
SELECT
@DATABASE AS database_name,
@LASTFULL AS restore_base_full_backup_start_date,
llb.backup_start_date AS last_log_backup_start_date,
llb.backup_finish_date AS last_log_backup_finish_date,
llb.first_lsn,
llb.last_lsn,
DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
DATEDIFF(HOUR, llb.backup_finish_date, GETDATE()) AS hours_since_last_log_backup,
CASE
    WHEN llb.backup_finish_date IS NULL
    THEN 'NO LOG BACKUP FOUND SINCE LATEST FULL'

    WHEN DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) <= 15
    THEN 'LOW TIME EXPOSURE'

    WHEN DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) <= 60
    THEN 'MODERATE TIME EXPOSURE'

    ELSE 'HIGH TIME EXPOSURE'
END AS time_exposure_status
FROM LatestLogBackup AS llb;

-------------------------------------------------------------------------------
-- 5 - View marked transaction history for the database
-------------------------------------------------------------------------------
/*
→ Marked transactions are stored in msdb.dbo.logmarkhistory
→ Useful for STOPATMARK and STOPBEFOREMARK investigation
→ This is the main difference between a generic point-in-time check and a
  marked transaction restore check
*/

SELECT
lmh.database_name,
lmh.mark_name,
lmh.description,
lmh.lsn,
lmh.mark_time
FROM msdb.dbo.logmarkhistory AS lmh
WHERE lmh.database_name = @DATABASE
ORDER BY lmh.mark_time DESC;

-------------------------------------------------------------------------------
-- 6 - Identify databases with marked transactions
-------------------------------------------------------------------------------
/*
→ Useful to discover databases that already use marked transactions
→ This is an environment-level view, not limited to @DATABASE
*/

SELECT
lmh.database_name,
COUNT(*) AS total_marked_transactions,
MIN(lmh.mark_time) AS first_mark_time,
MAX(lmh.mark_time) AS last_mark_time
FROM msdb.dbo.logmarkhistory AS lmh
GROUP BY lmh.database_name
ORDER BY lmh.database_name;

-------------------------------------------------------------------------------
-- 7 - Review point-in-time restore planning summary
-------------------------------------------------------------------------------
/*
→ Final inspection for point-in-time restore planning
→ Shows the current FULL restore base, latest DIFFERENTIAL after that FULL,
  latest LOG backup, and latest marked transaction
→ For complete LOG chain continuity validation, use INST-Q0012
*/

;WITH LatestFull AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.checkpoint_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'D'
    ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC
),
LatestDiff AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.differential_base_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'I'
    AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
    ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC
),
LatestLog AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.first_lsn,
    bs.last_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'L'
    AND (@LASTFULL IS NULL OR bs.backup_start_date >= @LASTFULL)
    ORDER BY bs.backup_finish_date DESC, bs.backup_set_id DESC
),
LatestMark AS
(
    SELECT TOP (1)
    lmh.mark_name,
    lmh.mark_time,
    lmh.lsn
    FROM msdb.dbo.logmarkhistory AS lmh
    WHERE lmh.database_name = @DATABASE
    ORDER BY lmh.mark_time DESC
)
SELECT
@DATABASE AS database_name,
lf.backup_start_date AS latest_full_backup_start,
lf.backup_finish_date AS latest_full_backup_finish,
ld.backup_finish_date AS latest_differential_backup_finish,
ll.backup_finish_date AS latest_log_backup_finish,
lm.mark_name AS latest_mark_name,
lm.mark_time AS latest_mark_time,
lm.lsn AS latest_mark_lsn,
CASE
    WHEN lf.backup_finish_date IS NULL
    THEN 'NO FULL BACKUP FOUND'

    WHEN ll.backup_finish_date IS NULL
    THEN 'NO LOG BACKUP FOUND SINCE LATEST FULL'

    WHEN lm.mark_time IS NULL
    THEN 'NO MARKED TRANSACTION FOUND'

    WHEN lm.mark_time <= ll.backup_finish_date
    THEN 'LATEST MARK APPEARS COVERED BY AVAILABLE LOG BACKUP HISTORY'

    ELSE 'LATEST MARK IS AFTER THE LATEST LOG BACKUP - CONSIDER TAIL LOG SCENARIO'
END AS marked_transaction_restore_context
FROM LatestFull AS lf
LEFT JOIN LatestDiff AS ld
    ON 1 = 1
LEFT JOIN LatestLog AS ll
    ON 1 = 1
LEFT JOIN LatestMark AS lm
    ON 1 = 1;
GO

-------------------------------------------------------------------------------
-- 8 - Reference point-in-time restore examples
-------------------------------------------------------------------------------
/*
→ This script focuses on point-in-time restore readiness analysis
→ It does NOT execute restore commands

For practical execution examples, refer to:

- Q0023 - Point-in-Time Restore and Marked Transactions

Supported restore options:

1. STOPAT
   → Restore to a specific date and time

2. STOPATMARK
   → Restore up to a marked transaction

3. STOPBEFOREMARK
   → Restore to the point immediately before a marked transaction

4. AFTER
   → Used when the same mark name appears more than once

Important:
- Requires FULL or BULK_LOGGED recovery model
- Requires a valid LOG backup chain
- STOPAT, STOPATMARK, STOPBEFOREMARK and AFTER are applied during LOG restore
- Use INST-Q0012 to validate complete backup chain continuity before execution
- Use Q0023 for the executable hands-on restore flow

For the full executable script, see:
03-backup-and-restore/scripts/Q0023-sql-point-in-time-restore-and-marked-transactions.sql
*/