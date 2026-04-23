/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.1
Task        : INST-Q0015 - Point-in-Time and Marked Transaction Inspection
Object      : Script
Description : Queries to inspect point-in-time recovery readiness, latest log
              backup interval, and marked transaction history for restore analysis
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
              03-backup-and-restore/notes/A0026-point-in-time-restore.md
Examples    : 03-backup-and-restore/scripts/Q0023-sql-point-in-time-restore-and-marked-transactions.sql
===============================================================================

INDEX
1 - Check database recovery model and state
2 - Evaluate point-in-time restore readiness
3 - View latest LOG backup interval
4 - View marked transaction history
5 - Identify databases with marked transactions
6 - Review point-in-time restore summary
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Check database recovery model and state
-------------------------------------------------------------------------------
/*
→ Point-in-Time Restore requires FULL or BULK_LOGGED
→ SIMPLE does not support point-in-time recovery
*/

SELECT
d.name,
d.state_desc,
d.recovery_model_desc,
d.log_reuse_wait_desc,
d.user_access_desc,
d.is_in_standby
FROM sys.databases AS d
WHERE d.name = N'ExamplesDB_PointInTime';
GO

-------------------------------------------------------------------------------
-- 2 - Evaluate point-in-time restore readiness
-------------------------------------------------------------------------------
/*
Interpretation:
- FULL + LOG chain is the minimum base for point-in-time restore
- DIFFERENTIAL is optional, but can reduce restore time
*/

;WITH BackupSummary AS
(
    SELECT
    MAX(CASE WHEN type = 'D' THEN 1 ELSE 0 END) AS has_full,
    MAX(CASE WHEN type = 'I' THEN 1 ELSE 0 END) AS has_diff,
    MAX(CASE WHEN type = 'L' THEN 1 ELSE 0 END) AS has_log
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_PointInTime'
),
DbInfo AS
(
    SELECT
    name,
    recovery_model_desc,
    state_desc
    FROM sys.databases
    WHERE name = N'ExamplesDB_PointInTime'
)
SELECT
di.name AS database_name,
di.state_desc,
di.recovery_model_desc,
bs.has_full,
bs.has_diff,
bs.has_log,
CASE
    WHEN di.recovery_model_desc = 'SIMPLE' THEN 'POINT-IN-TIME NOT APPLICABLE'
    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
            AND bs.has_full = 1
            AND bs.has_log = 1
    THEN 'READY FOR POINT-IN-TIME RESTORE'
    WHEN di.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
            AND bs.has_full = 1
            AND bs.has_log = 0
    THEN 'FULL EXISTS BUT LOG CHAIN IS MISSING'
    ELSE 'CHECK BACKUP STRATEGY'
END AS point_in_time_readiness
FROM DbInfo AS di
CROSS JOIN BackupSummary AS bs;
GO

-------------------------------------------------------------------------------
-- 3 - View latest LOG backup interval
-------------------------------------------------------------------------------
/*
→ Measures the elapsed time since the last LOG backup
→ Useful to estimate the potential data loss window before tail log backup
*/

;WITH LatestLogBackup AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_PointInTime'
    AND type = 'L'
    ORDER BY backup_finish_date DESC
)
SELECT
N'ExamplesDB_PointInTime' AS database_name,
llb.backup_finish_date AS last_log_backup_finish_date,
DATEDIFF(MINUTE, llb.backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
DATEDIFF(HOUR, llb.backup_finish_date, GETDATE()) AS hours_since_last_log_backup
FROM LatestLogBackup AS llb;
GO

-------------------------------------------------------------------------------
-- 4 - View marked transaction history
-------------------------------------------------------------------------------
/*
→ Marked transactions are stored in msdb.dbo.logmarkhistory
→ Useful for STOPATMARK and STOPBEFOREMARK investigation
*/

SELECT
lmh.database_name,
lmh.mark_name,
lmh.description,
lmh.lsn,
lmh.mark_time
FROM msdb.dbo.logmarkhistory AS lmh
WHERE lmh.database_name = N'ExamplesDB_PointInTime'
ORDER BY lmh.mark_time DESC;
GO

-------------------------------------------------------------------------------
-- 5 - Identify databases with marked transactions
-------------------------------------------------------------------------------
/*
→ Useful to discover databases that already use marked transactions
*/

SELECT
lmh.database_name,
COUNT(*) AS total_marked_transactions,
MIN(lmh.mark_time) AS first_mark_time,
MAX(lmh.mark_time) AS last_mark_time
FROM msdb.dbo.logmarkhistory AS lmh
GROUP BY lmh.database_name
ORDER BY lmh.database_name;
GO

-------------------------------------------------------------------------------
-- 6 - Review point-in-time restore summary
-------------------------------------------------------------------------------
/*
→ Final inspection for restore planning
→ Shows latest FULL, latest DIFFERENTIAL, latest LOG, and latest mark
*/

;WITH LatestFull AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_PointInTime'
    AND type = 'D'
    ORDER BY backup_finish_date DESC
),
LatestDiff AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_PointInTime'
    AND type = 'I'
    ORDER BY backup_finish_date DESC
),
LatestLog AS
(
    SELECT TOP (1)
    backup_finish_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_PointInTime'
    AND type = 'L'
    ORDER BY backup_finish_date DESC
),
LatestMark AS
(
    SELECT TOP (1)
    mark_name,
    mark_time
    FROM msdb.dbo.logmarkhistory
    WHERE database_name = N'ExamplesDB_PointInTime'
    ORDER BY mark_time DESC
)
SELECT
N'ExamplesDB_PointInTime' AS database_name,
lf.backup_finish_date AS latest_full_backup,
ld.backup_finish_date AS latest_differential_backup,
ll.backup_finish_date AS latest_log_backup,
lm.mark_name AS latest_mark_name,
lm.mark_time AS latest_mark_time
FROM LatestFull AS lf
LEFT JOIN LatestDiff AS ld
    ON 1 = 1
LEFT JOIN LatestLog AS ll
    ON 1 = 1
LEFT JOIN LatestMark AS lm
    ON 1 = 1;
GO