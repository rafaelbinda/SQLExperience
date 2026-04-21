/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-21
Version     : 1.0
Task        : Q0022 - Tail Log Backup (NO_TRUNCATE)
Object      : Script
Description : Demonstrates tail log backup (NO_TRUNCATE) in a failure scenario
              and its importance to preserve last transactions
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
              03-backup-and-restore/notes/A0025-backup-and-restore-exercises.md
===============================================================================

INDEX
1 - Insert data not yet protected by backup
2 - Validate current data
3 - Execute tail log backup (NO_TRUNCATE)
4 - Simulate failure
5 - Restore FULL (NORECOVERY)
6 - Restore DIFFERENTIAL (NORECOVERY)
7 - Restore LOG (NORECOVERY)
8 - Restore TAIL LOG (RECOVERY)
9 - Validate recovered data
10 - Optional validation - identity behavior
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Insert data not yet protected by backup
-------------------------------------------------------------------------------

USE ExamplesDB_BackupRestore;
GO

INSERT INTO dbo.Customers (CustName, CustPhone)
VALUES 
    ('Tail Customer 1', '9999-0101'),
    ('Tail Customer 2', '9999-0102'),
    ('Tail Customer 3', '9999-0103');
GO

/*
State:
- These rows are NOT protected by any backup yet
*/

-------------------------------------------------------------------------------
-- 2 - Validate current data
-------------------------------------------------------------------------------

SELECT COUNT(*) AS TotalRows 
FROM dbo.Customers;
GO

/*
Result:
TotalRows
103
*/

SELECT TOP 5 *
FROM dbo.Customers
ORDER BY CustID DESC;
GO

/*
Note: 
See item 10 - Optional validation - identity behavior

Result:
CustID	CustName	        CustPhone
1083	Tail Customer 3	    9999-0103
1082	Tail Customer 2	    9999-0102
1081	Tail Customer 1	    9999-0101
100	    Caitlin Stewart	    277-555-0153
99	    Caitlin Sanders	    506-555-0115
*/

-------------------------------------------------------------------------------
-- 3 - Execute tail log backup (NO_TRUNCATE)
-------------------------------------------------------------------------------

USE master;
GO

BACKUP LOG ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_Tail.trn'
WITH 
    NO_TRUNCATE,
    COMPRESSION,
    STATS = 10;
GO

/*
State:
- Last transactions are now preserved in the tail log backup

Result:
100 percent processed.
Processed 8 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 2.
BACKUP LOG successfully processed 8 pages in 0.007 seconds (8.928 MB/sec).
Completion time: 2026-04-21T13:02:33.2094525-03:00
*/

-------------------------------------------------------------------------------
-- 4 - Simulate failure
-------------------------------------------------------------------------------

IF DB_ID(N'ExamplesDB_BackupRestore') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_BackupRestore 
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ExamplesDB_BackupRestore;
END
GO

/*
Result:
Nonqualified transactions are being rolled back. Estimated rollback completion: 0%.
Nonqualified transactions are being rolled back. Estimated rollback completion: 100%.
Completion time: 2026-04-21T13:02:58.7311063-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Restore FULL (NORECOVERY)
-------------------------------------------------------------------------------

RESTORE DATABASE ExamplesDB_BackupRestore
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    FILE = 1,
    NORECOVERY,
    REPLACE,
    STATS = 10;
GO

/*
Result:
10 percent processed.
21 percent processed.
30 percent processed.
40 percent processed.
51 percent processed.
60 percent processed.
71 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 536 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
RESTORE DATABASE successfully processed 538 pages in 0.041 seconds (102.419 MB/sec).
Completion time: 2026-04-21T13:03:08.1013285-03:00
*/

-------------------------------------------------------------------------------
-- 6 - Restore DIFFERENTIAL (NORECOVERY)
-------------------------------------------------------------------------------

RESTORE DATABASE ExamplesDB_BackupRestore
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    FILE = 2,
    NORECOVERY,
    STATS = 10;
GO

/*
Result:
16 percent processed.
24 percent processed.
32 percent processed.
40 percent processed.
57 percent processed.
65 percent processed.
73 percent processed.
81 percent processed.
97 percent processed.
100 percent processed.
Processed 112 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 2.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 2.
RESTORE DATABASE successfully processed 114 pages in 0.025 seconds (35.468 MB/sec).
Completion time: 2026-04-21T13:03:19.6386305-03:00
*/

-------------------------------------------------------------------------------
-- 7 - Restore LOG (NORECOVERY)
-------------------------------------------------------------------------------

RESTORE LOG ExamplesDB_BackupRestore
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    FILE = 3,
    NORECOVERY,
    STATS = 10;
GO

/*
Result:
21 percent processed.
42 percent processed.
64 percent processed.
85 percent processed.
100 percent processed.
Processed 0 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 3.
Processed 38 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 3.
RESTORE LOG successfully processed 38 pages in 0.007 seconds (41.852 MB/sec).
Completion time: 2026-04-21T13:03:30.9412561-03:00
*/

-------------------------------------------------------------------------------
-- 8 - Restore TAIL LOG (RECOVERY)
-------------------------------------------------------------------------------

RESTORE LOG ExamplesDB_BackupRestore
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_Tail.trn'
WITH 
    RECOVERY,
    STATS = 10;
GO

/*
38 percent processed.
76 percent processed.
100 percent processed.
Processed 0 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 21 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
RESTORE LOG successfully processed 21 pages in 0.007 seconds (23.437 MB/sec).
Completion time: 2026-04-21T13:03:40.1036554-03:00
*/

-------------------------------------------------------------------------------
-- 9 - Validate recovered data
-------------------------------------------------------------------------------

USE ExamplesDB_BackupRestore;
GO

/*
Expected result:
- Tail rows successfully recovered
- No data loss after last LOG backup
*/

SELECT COUNT(*) AS TotalRows 
FROM dbo.Customers;
GO

/*
Result:
TotalRows
103
*/

SELECT TOP 5 *
FROM dbo.Customers
ORDER BY CustID DESC;
GO

/*
Result:
CustID	CustName	        CustPhone
1083	Tail Customer 3	    9999-0103
1082	Tail Customer 2	    9999-0102
1081	Tail Customer 1	    9999-0101
100	    Caitlin Stewart	    277-555-0153
99	    Caitlin Sanders	    506-555-0115
*/

SELECT COUNT(*) AS TailRows
FROM dbo.Customers
WHERE CustName LIKE 'Tail Customer%';
GO

/*
Result:
TailRows
3
*/

-------------------------------------------------------------------------------
-- 10 - Optional validation - identity behavior
-------------------------------------------------------------------------------

SELECT 
IDENT_CURRENT('dbo.Customers') AS current_identity_value,
MAX(CustID) AS max_custid,
COUNT(*) AS total_rows
FROM dbo.Customers;
GO

/*
Result:
current_identity_value	max_custid	total_rows
2080	                1083	    103
*/

DBCC CHECKIDENT ('dbo.Customers');
GO

/*
Result:
Checking identity information: current identity value '2080', current column value '1083'.
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-21T13:04:10.3231438-03:00
*/

/*
Note:
- IDENTITY does not guarantee gap-free values
- Gaps may appear after restart, rollback, restore or internal cache usage
- This behavior does not indicate inconsistency
*/

-- Optional lab action (do not use in normal recovery scenarios)
-- DBCC CHECKIDENT ('dbo.Customers', RESEED, 100);
-- GO
