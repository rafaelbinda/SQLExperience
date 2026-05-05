/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-05-04
Version     : 1.0
Task        : INST-Q0019 - Suspect Pages Active Overview
Object      : Script
Description : Queries to evaluate active suspect pages, affected database
              files, CHECKDB command suggestions, Page Restore references and
              backup chain context from the latest FULL backup
Notes       : 04-database-recovery/notes/A0030-database-corruption-and-dbcc-checkdb.md
              04-database-recovery/notes/A0031-page-restore.md
Examples    : 04-database-recovery/scripts/Q0028-sql-successful-page-restore.sql
              04-database-recovery/scripts/Q0029-sql-successful-multiple-page-restore.sql
Related     : INST-Q0012 - Backup Chain and Restore Sequence Inspection
===============================================================================

INDEX
1 - Define filters and active suspect page context
2 - Review active suspect pages overview
3 - Review affected database files
4 - Generate DBCC CHECKDB command suggestions
5 - Generate Page Restore reference information
6 - Review backup history from latest FULL backup
7 - Reference corruption and page restore examples
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Define filters and active suspect page context
-------------------------------------------------------------------------------
/*
→ This script focuses only on active suspect page investigation
→ Active suspect page event types are 1, 2 and 3
→ Historical recovery events are covered by INST-Q0020
→ Change @DATABASE according to the database being investigated
→ Keep @DATABASE = NULL to review all databases
*/

DECLARE @DATABASE SYSNAME = NULL;
DECLARE @STARTDATE DATETIME2 = DATEADD(DAY, -30, SYSDATETIME());
DECLARE @ENDDATE DATETIME2 = SYSDATETIME();
DECLARE @EVENTTYPE INT = NULL;

/*
Parameter examples:

@DATABASE = NULL
Returns all databases

@DATABASE = N'ExamplesDB_PageRestore'
Returns only one database

@STARTDATE = DATEADD(DAY, -30, SYSDATETIME())
Returns records from the last 30 days

@STARTDATE = NULL
Does not apply a start date filter

@ENDDATE = SYSDATETIME()
Returns records up to the current date and time

@ENDDATE = NULL
Does not apply an end date filter

@EVENTTYPE = NULL
Returns all active event types

@EVENTTYPE = 1
Returns only 823 or 824 error records other than bad checksum or torn page

@EVENTTYPE = 2
Returns only bad checksum records

@EVENTTYPE = 3
Returns only torn page records

Active event types:
1 = 823 or 824 error other than bad checksum or torn page
2 = Bad checksum
3 = Torn page
*/

IF @EVENTTYPE IS NOT NULL AND @EVENTTYPE NOT IN (1, 2, 3)
BEGIN
    RAISERROR('@EVENTTYPE must be NULL, 1, 2 or 3 for active suspect pages', 16, 1);
    RETURN;
END;

SELECT
@DATABASE AS database_filter,
@STARTDATE AS start_date_filter,
@ENDDATE AS end_date_filter,
@EVENTTYPE AS event_type_filter,
COUNT(*) AS active_suspect_page_count,
MIN(sp.last_update_date) AS first_active_event_date,
MAX(sp.last_update_date) AS last_active_event_date,
CASE
    WHEN COUNT(*) = 0
    THEN 'NO ACTIVE SUSPECT PAGE FOUND FOR THE CURRENT FILTER'

    WHEN COUNT(*) > 0
    THEN 'ACTIVE SUSPECT PAGE CONTEXT IDENTIFIED'

    ELSE 'REVIEW FILTERS'
END AS active_suspect_page_context_status
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (1, 2, 3)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE);

-------------------------------------------------------------------------------
-- 2 - Review active suspect pages overview
-------------------------------------------------------------------------------
/*
→ Reviews active suspect pages registered in msdb.dbo.suspect_pages
→ These records usually require investigation
→ suspect_pages helps identify affected database, file and page
→ DBCC CHECKDB is the main validation after corruption detection

event_type:
1 = 823 or 824 error other than bad checksum or torn page
2 = Bad checksum
3 = Torn page
*/

SELECT
'2 - Review active suspect pages overview' AS section_name,
'Active investigation events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_address,
sp.event_type,
CASE sp.event_type
    WHEN 1 THEN '823 or 824 error other than bad checksum or torn page'
    WHEN 2 THEN 'Bad checksum'
    WHEN 3 THEN 'Torn page'
END AS event_type_desc,
'ACTIVE INVESTIGATION' AS investigation_status,
sp.error_count,
sp.last_update_date
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (1, 2, 3)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY
sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

-------------------------------------------------------------------------------
-- 3 - Review affected database files
-------------------------------------------------------------------------------
/*
→ Connects active suspect_pages records to sys.master_files
→ Helps identify the physical file that contains the affected page
→ Useful for storage, path and file-level investigation
*/

SELECT
'3 - Review affected database files' AS section_name,
'Active investigation events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_address,
sp.event_type,
CASE sp.event_type
    WHEN 1 THEN '823 or 824 error other than bad checksum or torn page'
    WHEN 2 THEN 'Bad checksum'
    WHEN 3 THEN 'Torn page'
END AS event_type_desc,
'ACTIVE INVESTIGATION' AS investigation_status,
sp.error_count,
sp.last_update_date,
mf.type_desc AS file_type_desc,
mf.name AS logical_file_name,
mf.physical_name,
mf.state_desc AS file_state_desc
FROM msdb.dbo.suspect_pages AS sp
LEFT JOIN sys.master_files AS mf
    ON sp.database_id = mf.database_id
    AND sp.file_id = mf.file_id
WHERE sp.event_type IN (1, 2, 3)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY
sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

-------------------------------------------------------------------------------
-- 4 - Generate DBCC CHECKDB command suggestions
-------------------------------------------------------------------------------
/*
→ This section only generates commands
→ Review the generated commands before executing them
→ DBCC CHECKDB is the main validation after corruption detection
→ This script does not execute DBCC CHECKDB automatically
*/

SELECT DISTINCT
'4 - Generate DBCC CHECKDB command suggestions' AS section_name,
'Active investigation events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
'DBCC CHECKDB ([' + DB_NAME(sp.database_id) + ']) WITH NO_INFOMSGS, TABLERESULTS;' AS checkdb_command
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (1, 2, 3)
AND DB_NAME(sp.database_id) IS NOT NULL
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY
database_name;

-------------------------------------------------------------------------------
-- 5 - Generate Page Restore reference information
-------------------------------------------------------------------------------
/*
→ This section generates page address references
→ It does not execute RESTORE commands
→ The page_restore_address value can be used with RESTORE DATABASE ... PAGE
→ Page Restore requires a valid backup chain

Example:

RESTORE DATABASE database_name
PAGE = 'file_id:page_id'
FROM DISK = 'full_backup_file'
WITH NORECOVERY
*/

SELECT
'5 - Generate Page Restore reference information' AS section_name,
'Active investigation events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_restore_address,
sp.event_type,
CASE sp.event_type
    WHEN 1 THEN '823 or 824 error other than bad checksum or torn page'
    WHEN 2 THEN 'Bad checksum'
    WHEN 3 THEN 'Torn page'
END AS event_type_desc,
'POTENTIAL PAGE RESTORE CANDIDATE' AS page_restore_status,
sp.error_count,
sp.last_update_date
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (1, 2, 3)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY
sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

-------------------------------------------------------------------------------
-- 6 - Review backup history from latest FULL backup
-------------------------------------------------------------------------------
/*
→ Shows the relevant backup chain for databases with active suspect pages
→ The result starts from the latest FULL backup
→ Shows only FULL, DIFFERENTIAL, LOG and inferred TAIL-LOG backups
→ Helps evaluate whether Page Restore or full restore may be possible

Important:
SQL Server stores tail-log backups as LOG backups in msdb.dbo.backupset

There is no separate backup type for tail-log backup

In this script, TAIL-LOG is identified by the backup file name when the physical
device name contains the word TAIL

For complete LOG chain continuity validation, use INST-Q0012
*/

;WITH ActiveDatabases AS
(
    SELECT DISTINCT
    DB_NAME(sp.database_id) AS database_name
    FROM msdb.dbo.suspect_pages AS sp
    WHERE sp.event_type IN (1, 2, 3)
    AND DB_NAME(sp.database_id) IS NOT NULL
    AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
    AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
    AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
    AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
),
LatestFull AS
(
    SELECT
    bs.database_name,
    MAX(bs.backup_finish_date) AS latest_full_backup_finish_date
    FROM msdb.dbo.backupset AS bs
    INNER JOIN ActiveDatabases AS ad
        ON bs.database_name = ad.database_name
    WHERE bs.type = 'D'
    GROUP BY
    bs.database_name
)
SELECT
'6 - Review backup history from latest FULL backup' AS section_name,
'Active investigation events only' AS filter_mode,
bs.database_name,
bs.backup_start_date,
bs.backup_finish_date,
bs.type AS backup_type,
CASE
    WHEN bs.type = 'D'
    THEN 'FULL'

    WHEN bs.type = 'I'
    THEN 'DIFFERENTIAL'

    WHEN bs.type = 'L'
         AND bmf.physical_device_name LIKE '%TAIL%'
    THEN 'TAIL-LOG'

    WHEN bs.type = 'L'
    THEN 'LOG'

    ELSE bs.type
END AS backup_type_desc,
bs.is_copy_only,
bs.first_lsn,
bs.last_lsn,
bs.database_backup_lsn,
bs.differential_base_lsn,
bs.checkpoint_lsn,
CASE
    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN bs.backup_size >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST(bs.backup_size / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    ELSE CONCAT(CAST(bs.backup_size AS DECIMAL(18,2)), ' bytes')
END AS backup_size_formatted,
CASE
    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 4)
    THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 4) AS DECIMAL(18,2)), ' TB')

    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 3)
    THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 3) AS DECIMAL(18,2)), ' GB')

    WHEN bs.compressed_backup_size >= POWER(CAST(1024 AS BIGINT), 2)
    THEN CONCAT(CAST(bs.compressed_backup_size / POWER(CAST(1024 AS FLOAT), 2) AS DECIMAL(18,2)), ' MB')

    ELSE CONCAT(CAST(bs.compressed_backup_size AS DECIMAL(18,2)), ' bytes')
END AS compressed_backup_size_formatted,
bmf.physical_device_name
FROM msdb.dbo.backupset AS bs
INNER JOIN msdb.dbo.backupmediafamily AS bmf
    ON bs.media_set_id = bmf.media_set_id
INNER JOIN LatestFull AS lf
    ON bs.database_name = lf.database_name
WHERE bs.type IN ('D', 'I', 'L')
AND bs.backup_finish_date >= lf.latest_full_backup_finish_date
ORDER BY
bs.database_name,
bs.backup_start_date,
bs.backup_finish_date,
bs.backup_set_id;

-------------------------------------------------------------------------------
-- 7 - Reference corruption and page restore examples
-------------------------------------------------------------------------------
/*
→ This script focuses on active suspect page investigation
→ It does NOT execute DBCC repair commands
→ It does NOT execute RESTORE commands
→ It does NOT execute DBCC WRITEPAGE

For practical execution examples, refer to:

- Q0028 - SQL Successful Page Restore
- Q0029 - SQL Successful Multiple Page Restore

Supported investigation scenarios:

1. Active suspect pages
   → Pages registered in msdb.dbo.suspect_pages with event_type 1, 2 or 3

2. Bad checksum
   → Usually related to event_type 2 in msdb.dbo.suspect_pages

3. Page Restore candidate
   → A page identified by file_id:page_id that may be restored from backup

4. DBCC CHECKDB validation
   → Used to confirm logical and physical consistency issues

5. Backup chain review
   → Used to validate whether FULL, DIFFERENTIAL, LOG and TAIL-LOG backups
     exist after the latest FULL backup

Important:
- event_type 1, 2 and 3 usually require active investigation
- suspect_pages alone does not replace DBCC CHECKDB
- Page Restore requires a valid backup chain
- Tail-log backup should be evaluated before starting the restore sequence
- REPAIR_ALLOW_DATA_LOSS should be treated as a last resort
- Use INST-Q0012 to validate complete backup chain continuity before execution
- Use Q0028 and Q0029 for executable Page Restore flows

For the full executable scripts, see:

04-database-recovery/scripts/Q0028-sql-successful-page-restore.sql
04-database-recovery/scripts/Q0029-sql-successful-multiple-page-restore.sql
*/

GO