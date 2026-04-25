/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0014 - Tail Log and Recovery Readiness (All Databases)
Object      : Script
Description : Evaluates tail log exposure and recovery risk across all user
              databases based on recovery model and latest LOG backup history
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
Related     : INST-Q0013 - Tail Log and Recovery Investigation
===============================================================================

INDEX
1 - Identify latest LOG backup per database
2 - Evaluate tail log exposure and recovery risk
3 - Highlight potential risk scenarios
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Identify latest LOG backup per database
-------------------------------------------------------------------------------

WITH LatestLogBackup AS
(
    SELECT
    bs.database_name,
    MAX(bs.backup_finish_date) AS last_log_backup_finish_date
    FROM msdb.dbo.backupset bs
    WHERE bs.type = 'L'
    GROUP BY bs.database_name
)

-------------------------------------------------------------------------------
-- 2 - Evaluate tail log exposure and recovery risk
-------------------------------------------------------------------------------

SELECT
d.name AS database_name,
d.state_desc,
d.recovery_model_desc,
llb.last_log_backup_finish_date,
DATEDIFF(MINUTE, llb.last_log_backup_finish_date, GETDATE()) AS minutes_since_last_log_backup,
DATEDIFF(HOUR, llb.last_log_backup_finish_date, GETDATE()) AS hours_since_last_log_backup,

CASE
    WHEN d.database_id <= 4 THEN 'SYSTEM DATABASE'
        
    WHEN d.recovery_model_desc = 'SIMPLE'
    THEN 'TAIL LOG NOT APPLICABLE'

    WHEN d.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
            AND llb.last_log_backup_finish_date IS NULL
    THEN 'NO LOG BACKUP HISTORY'

    WHEN d.recovery_model_desc IN ('FULL', 'BULK_LOGGED')
            AND llb.last_log_backup_finish_date IS NOT NULL
    THEN 'TAIL LOG MAY BE REQUIRED AFTER FAILURE'

    ELSE 'CHECK REQUIRED'
END AS tail_log_recommendation,

CASE
    WHEN d.recovery_model_desc = 'SIMPLE'
    THEN 'LOW (NO POINT-IN-TIME RECOVERY)'

    WHEN llb.last_log_backup_finish_date IS NULL
    THEN 'HIGH RISK (NO LOG CHAIN)'

    WHEN DATEDIFF(HOUR, llb.last_log_backup_finish_date, GETDATE()) > 24
    THEN 'MEDIUM RISK (LOG BACKUP DELAY)'

    ELSE 'LOW RISK'
END AS recovery_risk_level
FROM sys.databases d
LEFT JOIN LatestLogBackup llb
    ON d.name = llb.database_name
WHERE d.database_id > 4
ORDER BY recovery_risk_level DESC, d.name;
GO

-------------------------------------------------------------------------------
-- 3 - Highlight potential risk scenarios
-------------------------------------------------------------------------------

/*
Interpretation:

HIGH RISK
- No LOG backup history in FULL/BULK_LOGGED recovery model
- LOG chain is broken or does not exist
- Point-in-time restore is NOT possible

MEDIUM RISK
- LOG backups exist but are outdated
- Increased exposure to potential data loss
- Recovery window may be larger than expected

LOW RISK
- Recent LOG backups exist
- LOG chain is active and recovery window is controlled

TAIL LOG CONSIDERATION
- Indicates that a Tail Log Backup may be required in case of failure
- Depends on database state at failure time (ONLINE, SUSPECT, OFFLINE)
- Requires transaction log file availability

-------------------------------------------------------------------------------
Scope:

This script provides an all-database overview only.

For detailed investigation of a specific database, use:
- INST-Q0013 - Tail Log and Recovery Investigation

For complete backup chain validation, use:
- INST-Q0012 - Backup Chain and Restore Sequence Inspection
*/