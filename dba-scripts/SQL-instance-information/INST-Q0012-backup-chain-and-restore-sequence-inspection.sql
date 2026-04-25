/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 3.0
Task        : INST-Q0012 - Backup Chain and Restore Sequence Inspection
Object      : Script
Description : Description : Queries to analyze backup chain, restore sequence, LSN continuity,
              differential base, and restore readiness for a database since the
              latest FULL backup
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
              03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
Examples    : 03-backup-and-restore/scripts/Q0019-sql-backup-full-differential-log.sql
              03-backup-and-restore/scripts/Q0020-sql-restore-norecovery-recovery.sql
              03-backup-and-restore/scripts/Q0021-sql-restore-standby.sql
===============================================================================

INDEX
1  - Configure target database
2  - Validate database and recovery model
3  - Identify latest FULL backup
4  - Summarize backup types since latest FULL
5  - List backups since latest FULL with media and size information
6  - Analyze FULL, DIFFERENTIAL, and LOG metadata since latest FULL
7  - Analyze LOG chain continuity since latest FULL
8  - Identify FULL backup base for each DIFFERENTIAL backup
9  - Evaluate restore readiness
10 - Reference restore examples
===============================================================================
*/

USE msdb;
GO

-------------------------------------------------------------------------------
-- 1 - Configure target database
-------------------------------------------------------------------------------
/*
Change this variable to inspect another database.

The script uses the latest FULL backup as the starting point because, in a real
restore scenario, older backup history usually creates noise and may not be part
of the current restore sequence.
*/

DECLARE @DATABASE SYSNAME = N'ExamplesDB_BackupRestore';
DECLARE @RM VARCHAR(20);
DECLARE @LASTFULL DATETIME2;

-------------------------------------------------------------------------------
-- 2 - Validate database and recovery model
-------------------------------------------------------------------------------
/*
→ FULL and BULK_LOGGED recovery models allow LOG backup chains
→ SIMPLE recovery model does not support regular LOG backups
→ If the database is not found, review the @DATABASE variable
*/

SELECT @RM = TRIM(d.recovery_model_desc)
FROM sys.databases AS d
WHERE d.name = @DATABASE;

IF @RM IS NULL
BEGIN
    PRINT 'Database not found.';
END;

IF @RM NOT IN ('FULL', 'BULK_LOGGED')
BEGIN
    PRINT 'WARNING: Database is not in FULL or BULK_LOGGED recovery model. LOG restore chain may not be available.';
END;

SELECT
@DATABASE AS database_name,
@RM AS recovery_model_desc,
CASE
    WHEN @RM IN ('FULL', 'BULK_LOGGED') 
    THEN 'LOG BACKUP CHAIN SUPPORTED'
    WHEN @RM = 'SIMPLE' 
    THEN 'LOG BACKUP CHAIN NOT SUPPORTED'
    WHEN @RM IS NULL 
    THEN 'DATABASE NOT FOUND'
    ELSE 'REVIEW RECOVERY MODEL'
END AS recovery_model_status;

-------------------------------------------------------------------------------
-- 3 - Identify latest FULL backup
-------------------------------------------------------------------------------
/*
→ The latest FULL backup is used as the base point for the current analysis
→ Backups older than this FULL backup are ignored in the following checks
*/

SELECT @LASTFULL = MAX(bs.backup_start_date)
FROM msdb.dbo.backupset AS bs
WHERE bs.database_name = @DATABASE
AND bs.type = 'D';

IF @LASTFULL IS NULL
BEGIN
    PRINT 'No FULL backup found for this database.';
END;

SELECT @DATABASE AS database_name,
@LASTFULL AS latest_full_backup_start,
CASE
    WHEN @LASTFULL IS NOT NULL 
    THEN 'LATEST FULL BACKUP FOUND'
    ELSE 'NO FULL BACKUP FOUND'
END AS latest_full_backup_status;

-------------------------------------------------------------------------------
-- 4 - Summarize backup types since latest FULL
-------------------------------------------------------------------------------
/*
→ Shows how many FULL, DIFFERENTIAL, and LOG backups exist since the latest FULL
→ Useful to quickly understand the available restore path
*/

SELECT
bs.database_name,
COUNT(CASE WHEN bs.type = 'D' THEN 1 END) AS full_backups,
COUNT(CASE WHEN bs.type = 'I' THEN 1 END) AS differential_backups,
COUNT(CASE WHEN bs.type = 'L' THEN 1 END) AS log_backups
FROM msdb.dbo.backupset AS bs
WHERE bs.database_name = @DATABASE
AND bs.backup_start_date >= @LASTFULL
GROUP BY bs.database_name;

-------------------------------------------------------------------------------
-- 5 - List backups since latest FULL with media and size information
-------------------------------------------------------------------------------
/*
→ Lists backups that are candidates for the current restore sequence
→ Includes backup media, LSN information, compression saving, and readable sizes
*/

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
bs.checkpoint_lsn,
CAST(
    CASE
        WHEN bs.backup_size > 0 AND bs.compressed_backup_size IS NOT NULL
        THEN (1.0 - (CAST(bs.compressed_backup_size AS DECIMAL(18,2)) / CAST(bs.backup_size AS DECIMAL(18,2)))) * 100
        ELSE NULL
    END
    AS DECIMAL(10,2)
) AS compression_saving_percent,
CASE
    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 4)
        THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')
    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 3)
        THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')
    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 2)
        THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')
    WHEN bs.backup_size >= 1024
        THEN CONCAT(CAST(bs.backup_size / CAST(1024 AS FLOAT) AS DECIMAL(18,2)), ' KB')
    ELSE CONCAT(CAST(bs.backup_size AS DECIMAL(18,2)), ' Bytes')
END AS backup_size_formatted,
CASE
    WHEN bs.compressed_backup_size IS NULL
        THEN 'Not available'
    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 4)
        THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')
    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 3)
        THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')
    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 2)
        THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')
    WHEN bs.compressed_backup_size >= 1024
        THEN CONCAT(CAST(bs.compressed_backup_size / CAST(1024 AS FLOAT) AS DECIMAL(18,2)), ' KB')
    ELSE CONCAT(CAST(bs.compressed_backup_size AS DECIMAL(18,2)), ' Bytes')
END AS compressed_backup_size_formatted,
bs.backup_size,
bs.compressed_backup_size,
bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = @DATABASE
AND bs.backup_start_date >= @LASTFULL
ORDER BY bs.backup_start_date;

-------------------------------------------------------------------------------
-- 6 - Analyze FULL, DIFFERENTIAL, and LOG metadata since latest FULL
-------------------------------------------------------------------------------
/*
→ FULL backups are independent starting points
→ DIFFERENTIAL backups depend on a FULL backup via differential_base_lsn
→ LOG backups form a sequential chain through LSN continuity
*/

SELECT
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
bs.database_backup_lsn,
bs.differential_base_lsn,
bs.checkpoint_lsn
FROM msdb.dbo.backupset AS bs
WHERE bs.database_name = @DATABASE
AND bs.backup_start_date >= @LASTFULL
AND bs.type IN ('D', 'I', 'L')
ORDER BY bs.backup_start_date;

-------------------------------------------------------------------------------
-- 7 - Analyze LOG chain continuity since latest FULL
-------------------------------------------------------------------------------
/*
→ CONTIGUOUS        -> the next LOG backup appears to continue the chain
→ POSSIBLE GAP      -> investigate missing or out-of-order LOG backup
→ LAST LOG IN CHAIN -> final available LOG backup in msdb history
*/

WITH LogBackups AS
(
    SELECT
    bs.backup_set_id,
    bs.backup_start_date,
    bs.backup_finish_date,
    bs.first_lsn,
    bs.last_lsn,
    LEAD(bs.first_lsn) OVER (ORDER BY bs.backup_start_date, bs.backup_set_id) AS next_first_lsn,
    LEAD(bs.backup_start_date) OVER (ORDER BY bs.backup_start_date, bs.backup_set_id) AS next_backup_start_date
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.backup_start_date >= @LASTFULL
    AND bs.type = 'L'
)
SELECT
backup_start_date AS current_backup_start,
backup_finish_date AS current_backup_finish,
first_lsn,
last_lsn,
next_backup_start_date,
next_first_lsn,
CASE
    WHEN next_first_lsn IS NULL 
    THEN 'LAST LOG IN CHAIN'
    WHEN last_lsn = next_first_lsn 
    THEN 'CONTIGUOUS'
    ELSE 'POSSIBLE GAP'
END AS chain_status
FROM LogBackups
ORDER BY current_backup_start;

-------------------------------------------------------------------------------
-- 8 - Identify FULL backup base for each DIFFERENTIAL backup
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
    WHEN f.backup_set_id IS NOT NULL 
    THEN 'MATCHED FULL BASE'
    ELSE 'FULL BASE NOT FOUND'
END AS differential_base_status
FROM msdb.dbo.backupset AS d
LEFT JOIN msdb.dbo.backupset AS f
    ON d.differential_base_lsn = f.checkpoint_lsn
    AND f.database_name = d.database_name
    AND f.type = 'D'
WHERE d.database_name = @DATABASE
AND d.type = 'I'
ORDER BY d.backup_start_date;

-------------------------------------------------------------------------------
-- 9 - Evaluate restore readiness
-------------------------------------------------------------------------------
/*
→ Indicates whether a basic restore path exists
→ Validates if the latest DIFFERENTIAL belongs to the latest FULL backup
→ This is a readiness indicator, not a replacement for a real restore test
*/

;WITH BackupSummary AS
(
    SELECT
    MAX(CASE WHEN bs.type = 'D' THEN 1 ELSE 0 END) AS has_full,
    MAX(CASE WHEN bs.type = 'I' THEN 1 ELSE 0 END) AS has_diff,
    MAX(CASE WHEN bs.type = 'L' THEN 1 ELSE 0 END) AS has_log
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.backup_start_date >= @LASTFULL
),
LatestFull AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.checkpoint_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'D'
    ORDER BY bs.backup_start_date DESC
),
LatestDiff AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.differential_base_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'I'
    ORDER BY bs.backup_start_date DESC
),
LatestLog AS
(
    SELECT TOP (1)
    bs.backup_start_date,
    bs.first_lsn,
    bs.last_lsn
    FROM msdb.dbo.backupset AS bs
    WHERE bs.database_name = @DATABASE
    AND bs.type = 'L'
    ORDER BY bs.backup_start_date DESC
)
SELECT
    @DATABASE AS database_name,
    bs.has_full,
    bs.has_diff,
    bs.has_log,
    lf.backup_start_date AS latest_full_backup,
    ld.backup_start_date AS latest_diff_backup,
    ll.backup_start_date AS latest_log_backup,
    CASE
        WHEN bs.has_full = 1 AND bs.has_diff = 1 AND bs.has_log = 1 
        THEN 'FULL + DIFFERENTIAL + LOG CHAIN AVAILABLE'
        WHEN bs.has_full = 1 AND bs.has_log = 1 
        THEN 'FULL + LOG CHAIN AVAILABLE'
        WHEN bs.has_full = 1 AND bs.has_diff = 1 
        THEN 'FULL + DIFFERENTIAL AVAILABLE'
        WHEN bs.has_full = 1 
        THEN 'FULL ONLY AVAILABLE'
        ELSE 'NO VALID BASE BACKUP FOUND'
    END AS restore_readiness,
    CASE
        WHEN ld.differential_base_lsn = lf.checkpoint_lsn 
        THEN 'LATEST DIFFERENTIAL MATCHES LATEST FULL'
        WHEN ld.differential_base_lsn IS NULL 
        THEN 'NO DIFFERENTIAL TO VALIDATE'
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

-------------------------------------------------------------------------------
-- 10 - Reference restore examples
-------------------------------------------------------------------------------
/*
→ This script focuses on backup chain inspection and restore readiness analysis
→ It does NOT execute restore operations

For practical restore execution examples, refer to:

- Q0019 - Backup FULL / DIFFERENTIAL / LOG
- Q0020 - Restore with NORECOVERY / RECOVERY
- Q0021 - Restore with STANDBY

Typical restore sequence:

1. RESTORE DATABASE ... WITH NORECOVERY      -- FULL
2. RESTORE DATABASE ... WITH NORECOVERY      -- DIFFERENTIAL (optional)
3. RESTORE LOG ... WITH NORECOVERY           -- LOG sequence
4. RESTORE LOG ... WITH RECOVERY             -- Final step

Important:
- RECOVERY must be executed only at the final step
- Executing RECOVERY prematurely requires restarting the entire restore process
- Use STANDBY when read-only access between restores is required

For full executable scripts, see:
03-backup-and-restore/scripts/Q0019-sql-backup-full-differential-log.sql
03-backup-and-restore/scripts/Q0020-sql-restore-norecovery-recovery.sql
03-backup-and-restore/scripts/Q0021-sql-restore-standby.sql
*/
