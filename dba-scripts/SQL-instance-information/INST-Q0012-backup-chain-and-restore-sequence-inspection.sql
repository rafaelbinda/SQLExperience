/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0012 - Backup Chain and Restore Sequence Inspection
Object      : Script
Description : Queries to analyze backup chain, restore sequence, LSN continuity,
              differential base, and restore readiness for a database
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
              03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
Examples    : 03-backup-and-restore/scripts/Q0019-sql-backup-full-differential-log.sql
              03-backup-and-restore/scripts/Q0020-sql-restore-norecovery-recovery.sql
===============================================================================

INDEX
1  - List all backups for the database
2  - Summarize backup types
3  - Analyze FULL, DIFFERENTIAL, and LOG metadata
4  - Analyze LOG chain continuity
5  - Identify differential base
6  - View backup media information
7  - Evaluate restore readiness
===============================================================================
*/

USE msdb;
GO

-------------------------------------------------------------------------------
-- 1 - List all backups for the database
-------------------------------------------------------------------------------

SELECT
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
END AS backup_type_desc,
bs.first_lsn,
bs.last_lsn,
bs.database_backup_lsn,
bs.differential_base_lsn,
bs.backup_size,
bs.compressed_backup_size,
bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'ExamplesDB_BackupRestore' 
ORDER BY bs.backup_start_date;
GO

-------------------------------------------------------------------------------
-- 2 - Summarize backup types
-------------------------------------------------------------------------------
 
SELECT
database_name,
COUNT(CASE WHEN type = 'D' THEN 1 END) AS full_backups,
COUNT(CASE WHEN type = 'I' THEN 1 END) AS differential_backups,
COUNT(CASE WHEN type = 'L' THEN 1 END) AS log_backups
FROM msdb.dbo.backupset
WHERE database_name = N'ExamplesDB_BackupRestore'
GROUP BY database_name;
GO

-------------------------------------------------------------------------------
-- 3 - Analyze FULL, DIFFERENTIAL, and LOG metadata
-------------------------------------------------------------------------------
/*
→ FULL backups are independent starting points
→ DIFFERENTIAL backups depend on a FULL backup via differential_base_lsn
→ LOG backups form a sequential chain through LSN continuity
*/

SELECT
database_name,
backup_start_date,
type,
CASE type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE type
END AS backup_type_desc,
first_lsn,
last_lsn,
database_backup_lsn,
differential_base_lsn
FROM msdb.dbo.backupset
WHERE database_name = N'ExamplesDB_BackupRestore'
AND type IN ('D', 'I', 'L')
ORDER BY backup_start_date;
GO
 
-------------------------------------------------------------------------------
-- 4 - Analyze LOG chain continuity
-------------------------------------------------------------------------------
/*
→ CONTIGUOUS        -> the next LOG backup appears to continue the chain
→ POSSIBLE GAP      -> investigate missing or out-of-order LOG backup
→ LAST LOG IN CHAIN -> final available LOG backup in msdb history
*/ 

WITH LogBackups AS
(
    SELECT
    backup_set_id,
    backup_start_date,
    backup_finish_date,
    first_lsn,
    last_lsn,
    LEAD(first_lsn) OVER (ORDER BY backup_start_date, backup_set_id) AS next_first_lsn,
    LEAD(backup_start_date) OVER (ORDER BY backup_start_date, backup_set_id) AS next_backup_start_date
    FROM msdb.dbo.backupset
    WHERE database_name = N'ExamplesDB_BackupRestore'
    AND type = 'L'
)
SELECT
backup_start_date AS current_backup_start,
backup_finish_date AS current_backup_finish,
first_lsn,
last_lsn,
next_backup_start_date,
next_first_lsn,
CASE
    WHEN next_first_lsn IS NULL THEN 'LAST LOG IN CHAIN'
    WHEN last_lsn = next_first_lsn THEN 'CONTIGUOUS'
    ELSE 'POSSIBLE GAP'
END AS chain_status
FROM LogBackups
ORDER BY current_backup_start;
GO

-------------------------------------------------------------------------------
-- 5 - Identify FULL backup base for each DIFFERENTIAL backup
-------------------------------------------------------------------------------
/* 
→ Each DIFFERENTIAL backup should point to a FULL backup base
→ differential_base_lsn should match the checkpoint_lsn of the FULL backup
→ If FULL BASE NOT FOUND appears, investigate backup history retention or chain
  inconsistency
*/
 
SELECT
d.backup_start_date AS differential_backup_start,
d.first_lsn AS differential_first_lsn,
d.last_lsn AS differential_last_lsn,
d.differential_base_lsn,
f.backup_start_date AS base_full_backup_start,
f.checkpoint_lsn AS base_full_checkpoint_lsn,
CASE
    WHEN f.backup_set_id IS NOT NULL THEN 'MATCHED FULL BASE'
    ELSE 'FULL BASE NOT FOUND'
END AS differential_base_status
FROM msdb.dbo.backupset AS d
LEFT JOIN msdb.dbo.backupset AS f
   ON d.differential_base_lsn = f.checkpoint_lsn
   AND f.database_name = d.database_name
   AND f.type = 'D'
WHERE d.database_name = N'ExamplesDB_BackupRestore'
AND d.type = 'I'
ORDER BY d.backup_start_date;
GO
 
-------------------------------------------------------------------------------
-- 6 - View backup media information
-------------------------------------------------------------------------------

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
bs.compressed_backup_size,
CAST(
    CASE
        WHEN bs.backup_size > 0
        THEN (1.0 - (CAST(bs.compressed_backup_size AS DECIMAL(18,2)) / CAST(bs.backup_size AS DECIMAL(18,2)))) * 100
        ELSE NULL
    END
    AS DECIMAL(10,2)
) AS compression_saving_percent
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'ExamplesDB_BackupRestore'
ORDER BY bs.backup_start_date;
GO

-------------------------------------------------------------------------------
-- 7 - Evaluate restore readiness
-------------------------------------------------------------------------------

DECLARE @DatabaseName SYSNAME = N'ExamplesDB_BackupRestore';

;WITH BackupSummary AS
(
    SELECT
    MAX(CASE WHEN type = 'D' THEN 1 ELSE 0 END) AS has_full,
    MAX(CASE WHEN type = 'I' THEN 1 ELSE 0 END) AS has_diff,
    MAX(CASE WHEN type = 'L' THEN 1 ELSE 0 END) AS has_log
    FROM msdb.dbo.backupset
    WHERE database_name = @DatabaseName
),
LatestFull AS
(
    SELECT TOP (1)
    backup_start_date,
    checkpoint_lsn
    FROM msdb.dbo.backupset
    WHERE database_name = @DatabaseName
    AND type = 'D'
    ORDER BY backup_start_date DESC
),
LatestDiff AS
(
    SELECT TOP (1)
    backup_start_date,
    differential_base_lsn
    FROM msdb.dbo.backupset
    WHERE database_name = @DatabaseName
    AND type = 'I'
    ORDER BY backup_start_date DESC
),
LatestLog AS
(
    SELECT TOP (1)
    backup_start_date,
    first_lsn,
    last_lsn
    FROM msdb.dbo.backupset
    WHERE database_name = @DatabaseName
    AND type = 'L'
    ORDER BY backup_start_date DESC
)
SELECT
@DatabaseName AS database_name,
bs.has_full,
bs.has_diff,
bs.has_log,
lf.backup_start_date AS latest_full_backup,
ld.backup_start_date AS latest_diff_backup,
ll.backup_start_date AS latest_log_backup,
CASE
    WHEN bs.has_full = 1 AND bs.has_log = 1 THEN 'FULL + LOG CHAIN AVAILABLE'
    WHEN bs.has_full = 1 AND bs.has_diff = 1 THEN 'FULL + DIFFERENTIAL AVAILABLE'
    WHEN bs.has_full = 1 THEN 'FULL ONLY AVAILABLE'
    ELSE 'NO VALID BASE BACKUP FOUND'
END AS restore_readiness,
CASE
    WHEN ld.differential_base_lsn = lf.checkpoint_lsn THEN 'LATEST DIFFERENTIAL MATCHES LATEST FULL'
    WHEN ld.differential_base_lsn IS NULL THEN 'NO DIFFERENTIAL TO VALIDATE'
    ELSE 'LATEST DIFFERENTIAL MAY BELONG TO A DIFFERENT FULL BASE'
END AS differential_consistency
FROM BackupSummary AS bs
LEFT JOIN LatestFull AS lf
    ON 1 = 1
LEFT JOIN LatestDiff AS ld
    ON 1 = 1
LEFT JOIN LatestLog AS ll
    ON 1 = 1;
GO