/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0014 - Tail Log and Recovery Readiness (All Databases)
Object      : Script
Description : Evaluates tail log necessity and recovery readiness across all
              user databases based on recovery model and backup history
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
===============================================================================

INDEX
1 - Identify latest LOG backup per database
2 - Evaluate recovery readiness
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
-- 2 - Evaluate recovery readiness
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
- No log backup history in FULL/BULK_LOGGED
- Cannot perform point-in-time restore

MEDIUM RISK
- Log backups exist but are outdated
- Possible data loss window

LOW RISK
- Recent log backups exist
- Recovery window is controlled

TAIL LOG MAY BE REQUIRED
- Indicates that if a failure occurs, tail log backup should be considered
- Depends on database accessibility at failure time
*/