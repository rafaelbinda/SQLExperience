/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-05-04
Version     : 1.0
Task        : INST-Q0020 - Suspect Pages History Overview
Object      : Script
Description : Queries to evaluate historical suspect page recovery records,
              including restored, repaired and deallocated pages registered in
              msdb.dbo.suspect_pages
Notes       : 04-database-recovery/notes/A0030-database-corruption-and-dbcc-checkdb.md
              04-database-recovery/notes/A0031-page-restore.md
Examples    : 04-database-recovery/scripts/Q0028-sql-successful-page-restore.sql
              04-database-recovery/scripts/Q0029-sql-successful-multiple-page-restore.sql
Related     : INST-Q0019 - Suspect Pages Active Overview
===============================================================================

INDEX
1 - Define filters and historical suspect page context
2 - Review historical suspect pages overview
3 - Review affected database files
4 - Generate DBCC CHECKDB command suggestions
5 - Maintenance examples for suspect_pages
6 - Reference historical suspect page examples
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Define filters and historical suspect page context
-------------------------------------------------------------------------------
/*
→ This script focuses only on historical suspect page recovery records
→ Historical recovery event types are 4, 5 and 7
→ Active suspect page investigation is covered by INST-Q0019
→ Change @DATABASE according to the database being investigated
→ Keep @DATABASE = NULL to review all databases
*/

DECLARE @DATABASE SYSNAME = 'ExamplesDB_MultiplePageRestore';
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
Returns all historical recovery event types

@EVENTTYPE = 4
Returns only restored page records

@EVENTTYPE = 5
Returns only pages repaired by DBCC

@EVENTTYPE = 7
Returns only pages deallocated by DBCC

Historical recovery event types:
4 = Restored
5 = Repaired by DBCC
7 = Deallocated by DBCC
*/

IF @EVENTTYPE IS NOT NULL AND @EVENTTYPE NOT IN (4, 5, 7)
BEGIN
    RAISERROR('@EVENTTYPE must be NULL, 4, 5 or 7 for historical suspect page records', 16, 1);
    RETURN;
END;

SELECT
@DATABASE AS database_filter,
@STARTDATE AS start_date_filter,
@ENDDATE AS end_date_filter,
@EVENTTYPE AS event_type_filter,
COUNT(*) AS historical_suspect_page_count,
MIN(sp.last_update_date) AS first_historical_event_date,
MAX(sp.last_update_date) AS last_historical_event_date,
CASE
    WHEN COUNT(*) = 0
    THEN 'NO HISTORICAL SUSPECT PAGE FOUND FOR THE CURRENT FILTER'
    WHEN COUNT(*) > 0
    THEN 'HISTORICAL SUSPECT PAGE CONTEXT IDENTIFIED'
    ELSE 'REVIEW FILTERS'
END AS historical_suspect_page_context_status
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (4, 5, 7)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE);

-------------------------------------------------------------------------------
-- 2 - Review historical suspect pages overview
-------------------------------------------------------------------------------
/*
→ Reviews historical recovery records in msdb.dbo.suspect_pages
→ These records do not necessarily mean that corruption still exists
→ DBCC CHECKDB is the main validation after recovery

event_type:
4 = Restored
5 = Repaired by DBCC
7 = Deallocated by DBCC
*/

SELECT
'2 - Review historical suspect pages overview' AS section_name,
'Historical recovery events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_address,
sp.event_type,
CASE sp.event_type
    WHEN 4 THEN 'Restored'
    WHEN 5 THEN 'Repaired by DBCC'
    WHEN 7 THEN 'Deallocated by DBCC'
END AS event_type_desc,
'HISTORICAL RECOVERY EVENT' AS investigation_status,
sp.error_count,
sp.last_update_date
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (4, 5, 7)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

-------------------------------------------------------------------------------
-- 3 - Review affected database files
-------------------------------------------------------------------------------
/*
→ Connects historical suspect_pages records to sys.master_files
→ Helps identify which physical file had a restored, repaired or deallocated page
→ Useful for documentation and incident review
*/

SELECT
'3 - Review affected database files' AS section_name,
'Historical recovery events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_address,
sp.event_type,
CASE sp.event_type
    WHEN 4 THEN 'Restored'
    WHEN 5 THEN 'Repaired by DBCC'
    WHEN 7 THEN 'Deallocated by DBCC'
END AS event_type_desc,
'HISTORICAL RECOVERY EVENT' AS investigation_status,
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
WHERE sp.event_type IN (4, 5, 7)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

-------------------------------------------------------------------------------
-- 4 - Generate DBCC CHECKDB command suggestions
-------------------------------------------------------------------------------
/*
→ This section only generates commands
→ Review the generated commands before executing them
→ Historical suspect_pages records do not necessarily mean that corruption still exists
→ DBCC CHECKDB is the main validation after recovery
→ This script does not execute DBCC CHECKDB automatically
*/

SELECT DISTINCT
'4 - Generate DBCC CHECKDB command suggestions' AS section_name,
'Historical recovery events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
'DBCC CHECKDB ([' + DB_NAME(sp.database_id) + ']) WITH NO_INFOMSGS, TABLERESULTS;' AS checkdb_command
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (4, 5, 7)
AND DB_NAME(sp.database_id) IS NOT NULL
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY
database_name;

-------------------------------------------------------------------------------
-- 5 - Maintenance examples for suspect_pages
-------------------------------------------------------------------------------
/*
→ This section helps review historical suspect_pages records before cleanup
→ Do not delete suspect_pages records without understanding the incident
→ Use cleanup only after documenting the incident
→ Prefer cleaning only old historical records
→ This script does not delete rows automatically

Historical recovery event types:
4 = Restored
5 = Repaired by DBCC
7 = Deallocated by DBCC

Interpretation:
event_type 4 means SQL Server registered that the page was restored
event_type 5 means SQL Server registered that the page was repaired by DBCC
event_type 7 means SQL Server registered that the page was deallocated by DBCC

Important:
The presence of historical records does not necessarily mean that corruption
still exists

After recovery, DBCC CHECKDB is the main validation
*/

SELECT
'5 - Maintenance examples for suspect_pages' AS section_name,
'Historical recovery events only' AS filter_mode,
DB_NAME(sp.database_id) AS database_name,
sp.database_id,
sp.file_id,
sp.page_id,
CAST(sp.file_id AS VARCHAR(20)) + ':' + CAST(sp.page_id AS VARCHAR(20)) AS page_address,
sp.event_type,
CASE sp.event_type
    WHEN 4 THEN 'Restored'
    WHEN 5 THEN 'Repaired by DBCC'
    WHEN 7 THEN 'Deallocated by DBCC'
END AS event_type_desc,
CASE sp.event_type
    WHEN 4 THEN 'PAGE WAS RESTORED'
    WHEN 5 THEN 'PAGE WAS REPAIRED BY DBCC'
    WHEN 7 THEN 'PAGE WAS DEALLOCATED BY DBCC'
END AS recovery_status,
sp.error_count,
sp.last_update_date
FROM msdb.dbo.suspect_pages AS sp
WHERE sp.event_type IN (4, 5, 7)
AND (@DATABASE IS NULL OR sp.database_id = DB_ID(@DATABASE))
AND (@STARTDATE IS NULL OR sp.last_update_date >= @STARTDATE)
AND (@ENDDATE IS NULL OR sp.last_update_date <= @ENDDATE)
AND (@EVENTTYPE IS NULL OR sp.event_type = @EVENTTYPE)
ORDER BY sp.last_update_date DESC,
database_name,
sp.file_id,
sp.page_id;

/*
Example only:
Delete restored, repaired or deallocated pages older than 180 days

DELETE FROM msdb.dbo.suspect_pages
WHERE event_type IN (4, 5, 7)
AND last_update_date < DATEADD(DAY, -180, GETDATE());
*/

-------------------------------------------------------------------------------
-- 6 - Reference historical suspect page examples
-------------------------------------------------------------------------------
/*
→ This script focuses on historical suspect page recovery records
→ It does NOT execute DBCC repair commands
→ It does NOT execute RESTORE commands
→ It does NOT execute DELETE commands against msdb.dbo.suspect_pages

For practical execution examples, refer to:

- Q0028 - SQL Successful Page Restore
- Q0029 - SQL Successful Multiple Page Restore

Supported historical scenarios:

1. Restored page
   → Page registered in msdb.dbo.suspect_pages with event_type 4

2. Repaired page
   → Page registered in msdb.dbo.suspect_pages with event_type 5

3. Deallocated page
   → Page registered in msdb.dbo.suspect_pages with event_type 7

4. Historical recovery validation
   → DBCC CHECKDB should be used to confirm that the database is structurally
     consistent after recovery

5. Incident documentation
   → suspect_pages history helps document when a page was restored, repaired or
     deallocated

Important:
- event_type 4, 5 and 7 are historical recovery events
- historical records do not necessarily mean that corruption still exists
- suspect_pages alone does not replace DBCC CHECKDB
- use INST-Q0019 for active suspect page investigation
- use INST-Q0012 to validate complete backup chain continuity when restore
  planning is required
- do not delete suspect_pages rows without documenting the incident first

For the full executable scripts, see:

04-database-recovery/scripts/Q0028-sql-successful-page-restore.sql
04-database-recovery/scripts/Q0029-sql-successful-multiple-page-restore.sql
*/

GO