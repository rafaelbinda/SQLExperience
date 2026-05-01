/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-28
Version     : 2.0
Task        : Q0027 - SQL Data Page Corruption and CHECKDB Repair
Object      : Script
Description : Creates a dedicated lab database to demonstrate data page
              corruption detection using PAGE_VERIFY, DBCC IND, DBCC PAGE,
              DBCC WRITEPAGE, suspect_pages and DBCC CHECKDB repair with
              REPAIR_ALLOW_DATA_LOSS
Notes       : notes/A0030-database-corruption-and-dbcc-checkdb.md
===============================================================================
INDEX
1  - Important warning
2  - Create lab database
3  - Create lab table and indexes
4  - Insert sample data
5  - Configure PAGE_VERIFY CHECKSUM
6  - Create initial backups
7  - Review database files and PAGE_VERIFY
8  - Review index metadata
9  - List table pages with DBCC IND
10 - Inspect a data page with DBCC PAGE
11 - Corrupt a data page with DBCC WRITEPAGE
12 - Validate data page corruption
13 - Review suspect_pages
14 - Run DBCC CHECKDB for data page corruption
15 - Repair data page corruption with REPAIR_ALLOW_DATA_LOSS
16 - Validate complete data loss after repair
17 - Cleanup lab database
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Important warning
-------------------------------------------------------------------------------

/*
WARNING

This script is for laboratory use only

It intentionally corrupts database pages using DBCC WRITEPAGE

Do not execute this script in production

Do not execute this script in any database that contains important data

DBCC WRITEPAGE writes directly to database pages
It is not logged as a normal data modification
It does not support rollback
It can permanently damage the database

This hands-on demonstrates the risk of using DBCC CHECKDB with
REPAIR_ALLOW_DATA_LOSS

In this specific lab, the corrupted page is the only data page of the table

After running DBCC CHECKDB with REPAIR_ALLOW_DATA_LOSS, SQL Server deallocates
the damaged page

As a result, the table remains structurally valid, but all rows are lost

This demonstrates why restore from valid backups is preferred over repair
with data loss
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 2 - Create lab database
-------------------------------------------------------------------------------

IF DB_ID('ExamplesDB_CorruptionCheckDB') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_CorruptionCheckDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_CorruptionCheckDB;
END;
GO

CREATE DATABASE ExamplesDB_CorruptionCheckDB;
GO

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET RECOVERY FULL;
GO

USE ExamplesDB_CorruptionCheckDB;
GO

-------------------------------------------------------------------------------
-- 3 - Create lab table and indexes
-------------------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.Customer;
GO

CREATE TABLE dbo.Customer
(
    CustomerID INT NOT NULL,
    FullName CHAR(15) NOT NULL,
    PhoneNumber VARCHAR(9) NOT NULL,
    CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX IXU_Customer_FullName
ON dbo.Customer (FullName);
GO

-------------------------------------------------------------------------------
-- 4 - Insert sample data
-------------------------------------------------------------------------------

INSERT INTO dbo.Customer
(
    CustomerID,
    FullName,
    PhoneNumber
)
VALUES
(0,  'Marina', '0000-0000'),
(1,  'Jose',   '1111-1111'),
(2,  'Maria',  '2222-2222'),
(3,  'Ana',    '3333-3333'),
(4,  'Paula',  '4444-4444'),
(5,  'Marcio', '5555-5555'),
(6,  'Erick',  '6666-6666'),
(7,  'Luana',  '7777-7777'),
(8,  'Mario',  '8888-8888'),
(9,  'Carla',  '9999-9999');
GO

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer
ORDER BY CustomerID;
GO

/*
Result:
CustomerID  FullName  PhoneNumber
0           Marina    0000-0000
1           Jose      1111-1111
2           Maria     2222-2222
3           Ana       3333-3333
4           Paula     4444-4444
5           Marcio    5555-5555
6           Erick     6666-6666
7           Luana     7777-7777
8           Mario     8888-8888
9           Carla     9999-9999
*/

-------------------------------------------------------------------------------
-- 5 - Configure PAGE_VERIFY CHECKSUM
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET PAGE_VERIFY CHECKSUM;
GO

-------------------------------------------------------------------------------
-- 6 - Create initial backups
-------------------------------------------------------------------------------

BACKUP DATABASE ExamplesDB_CorruptionCheckDB
TO DISK = 'C:\Backups\ExamplesDB_CorruptionCheckDB_FULL.bak'
WITH FORMAT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
10 percent processed.
21 percent processed.
31 percent processed.
40 percent processed.
50 percent processed.
61 percent processed.
70 percent processed.
80 percent processed.
91 percent processed.
100 percent processed.
Processed 464 pages for database 'ExamplesDB_CorruptionCheckDB', file 'ExamplesDB_CorruptionCheckDB' on file 1.
Processed 2 pages for database 'ExamplesDB_CorruptionCheckDB', file 'ExamplesDB_CorruptionCheckDB_log' on file 1.
BACKUP DATABASE successfully processed 466 pages in 0.037 seconds (98.289 MB/sec).
Completion time: 2026-04-28T20:43:33.9257493-03:00
*/

BACKUP LOG ExamplesDB_CorruptionCheckDB
TO DISK = 'C:\Backups\ExamplesDB_CorruptionCheckDB_LOG_001.trn'
WITH FORMAT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
100 percent processed.
Processed 3 pages for database 'ExamplesDB_CorruptionCheckDB', file 'ExamplesDB_CorruptionCheckDB_log' on file 1.
BACKUP LOG successfully processed 3 pages in 0.005 seconds (4.687 MB/sec).
Completion time: 2026-04-28T20:43:51.3836677-03:00
*/

-------------------------------------------------------------------------------
-- 7 - Review database files and PAGE_VERIFY
-------------------------------------------------------------------------------

SELECT
name AS database_name,
recovery_model_desc,
page_verify_option_desc,
state_desc
FROM sys.databases
WHERE name = 'ExamplesDB_CorruptionCheckDB';
GO

/*
Result:
database_name                  recovery_model_desc  page_verify_option_desc  state_desc
ExamplesDB_CorruptionCheckDB   FULL                 CHECKSUM                 ONLINE
*/

SELECT
DB_NAME(database_id) AS database_name,
file_id,
type_desc,
name AS logical_name,
physical_name,
state_desc
FROM sys.master_files
WHERE database_id = DB_ID('ExamplesDB_CorruptionCheckDB')
ORDER BY file_id;
GO

/*
Result:
database_name                  file_id  type_desc  logical_name                      physical_name                                            state_desc
ExamplesDB_CorruptionCheckDB   1        ROWS       ExamplesDB_CorruptionCheckDB      C:\MSSQLSERVER\DATA\ExamplesDB_CorruptionCheckDB.mdf     ONLINE
ExamplesDB_CorruptionCheckDB   2        LOG        ExamplesDB_CorruptionCheckDB_log  C:\MSSQLSERVER\LOG\ExamplesDB_CorruptionCheckDB_log.ldf  ONLINE
*/

-------------------------------------------------------------------------------
-- 8 - Review index metadata
-------------------------------------------------------------------------------

USE ExamplesDB_CorruptionCheckDB;
GO

SELECT
i.name AS index_name,
i.index_id,
i.type,
i.type_desc,
i.is_unique,
i.is_primary_key
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('dbo.Customer')
ORDER BY i.index_id;
GO

/*
Result:
index_name              index_id  type  type_desc     is_unique  is_primary_key
PK_Customer             1         1     CLUSTERED     1          1
IXU_Customer_FullName   2         2     NONCLUSTERED  1          0
*/

-------------------------------------------------------------------------------
-- 9 - List table pages with DBCC IND
-------------------------------------------------------------------------------

/*
DBCC IND lists pages that belong to a table or index

PageType 1  = Data Page
PageType 2  = Index Page
PageType 10 = IAM Page

IndexLevel 0 = leaf level
*/

DBCC TRACEON (2588);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-28T20:47:02.8323606-03:00
*/

DBCC HELP ('IND');
GO

/*
Result:
dbcc IND ( { 'dbname' | dbid }, { 'objname' | objid }, { nonclustered indid | 1 | 0 | -1 | -2 } [, partition_number] )
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-28T20:47:23.7714553-03:00
*/

DBCC IND ('ExamplesDB_CorruptionCheckDB', 'dbo.Customer', -1);
GO

/*
Result:
PageFID PagePID IAMFID IAMPID ObjectID  IndexID PartitionNumber PartitionID         iam_chain_type PageType IndexLevel NextPageFID NextPagePID PrevPageFID PrevPagePID
1       156     NULL   NULL   901578250 1       1               72057594045726720  In-row data    10       NULL       0           0           0           0
1       392     1      156    901578250 1       1               72057594045726720  In-row data    1        0          0           0           0           0
1       162     NULL   NULL   901578250 2       1               72057594045792256  In-row data    10       NULL       0           0           0           0
1       400     1      162    901578250 2       1               72057594045792256  In-row data    2        0          0           0           0           0
*/

-------------------------------------------------------------------------------
-- 10 - Inspect a data page with DBCC PAGE
-------------------------------------------------------------------------------

DBCC TRACEON (3604);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-28T20:49:49.8944775-03:00
*/

DROP TABLE IF EXISTS #DBCCIND;
GO

CREATE TABLE #DBCCIND
(
    PageFID TINYINT,
    PagePID INT,
    IAMFID TINYINT,
    IAMPID INT,
    ObjectID INT,
    IndexID INT,
    PartitionNumber INT,
    PartitionID BIGINT,
    iam_chain_type VARCHAR(64),
    PageType TINYINT,
    IndexLevel TINYINT,
    NextPageFID TINYINT,
    NextPagePID INT,
    PrevPageFID TINYINT,
    PrevPagePID INT
);
GO

INSERT INTO #DBCCIND
EXEC ('DBCC IND (''ExamplesDB_CorruptionCheckDB'', ''dbo.Customer'', -1)');
GO

DECLARE
@DataPageFID INT,
@DataPagePID INT,
@SQL NVARCHAR(MAX);

SELECT TOP (1)
@DataPageFID = PageFID,
@DataPagePID = PagePID
FROM #DBCCIND
WHERE PageType = 1 -- Data Page
ORDER BY PagePID;

SELECT
@DataPageFID AS data_page_file_id,
@DataPagePID AS data_page_id;

SET @SQL = N'DBCC PAGE (''ExamplesDB_CorruptionCheckDB'', '
         + CAST(@DataPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@DataPagePID AS NVARCHAR(20))
         + N', 3);';

PRINT(@SQL);

/*
Result:
(1 row affected)
DBCC PAGE ('ExamplesDB_CorruptionCheckDB', 1, 392, 3);
Completion time: 2026-04-28T20:52:25.4040022-03:00
*/

EXEC (@SQL);
GO

/*
Result:
data_page_file_id  data_page_id
1                  392

---------------------------------------------------------------------------------------------
Original data
---------------------------------------------------------------------------------------------

PageFID PagePID IAMFID IAMPID ObjectID  IndexID PartitionNumber PartitionID         iam_chain_type PageType IndexLevel NextPageFID NextPagePID PrevPageFID PrevPagePID
1       156     NULL   NULL   901578250 1       1               72057594045726720  In-row data    10       NULL       0           0           0           0
1       392     1      156    901578250 1       1               72057594045726720  In-row data    1        0          0           0           0           0

---------------------------------------------------------------------------------------------
Data page information
---------------------------------------------------------------------------------------------

PAGE: (1:392)

Important page header information:

m_pageId = (1:392)
-- Physical page address
-- 1   = file_id
-- 392 = page_id

m_type = 1
-- Page type
-- 1 = Data Page

m_level = 0
-- Index level
-- 0 = Leaf level
-- For a clustered index, the leaf level contains the actual data rows

Metadata: AllocUnitId = 72057594052476928
-- Allocation unit ID
-- Identifies the allocation unit that owns this page

Metadata: PartitionId = 72057594045726720
-- Partition ID
-- Identifies the partition that owns this page

Metadata: IndexId = 1
-- Index ID
-- 1 = Clustered index
-- In this table, IndexId 1 represents PK_Customer

Metadata: ObjectId = 901578250
-- Object ID
-- Identifies the object that owns this page
-- In this lab, this object is dbo.Customer

m_prevPage = (0:0)
-- Previous page in the page chain
-- (0:0) means there is no previous page

m_nextPage = (0:0)
-- Next page in the page chain
-- (0:0) means there is no next page

m_slotCnt = 10
-- Number of slots on the page
-- In this lab, each slot represents one row from dbo.Customer

m_freeCnt = 7686
-- Free bytes available on the page

m_freeData = 486
-- Offset where the free space starts on the page

m_lsn = (39:496:70)
-- Log Sequence Number related to the last change recorded for this page

---------------------------------------------------------------------------------------------
Allocation Status
---------------------------------------------------------------------------------------------

GAM (1:2) = ALLOCATED
-- Global Allocation Map
-- Indicates that the extent containing page (1:392) is allocated

SGAM (1:3) = NOT ALLOCATED
-- Shared Global Allocation Map
-- Indicates that the extent is not marked as a mixed extent with free pages

PFS (1:1) = 0x40 ALLOCATED 0_PCT_FULL
-- Page Free Space
-- Tracks allocation status and approximate free space for the page
-- In this lab, it confirms that page (1:392) is allocated

DIFF (1:6) = NOT CHANGED
-- Differential Changed Map
-- Indicates whether the extent changed since the last full backup
-- This information is used by differential backups

ML (1:7) = NOT MIN_LOGGED
-- Minimal Logging map
-- Indicates whether the extent contains minimally logged changes

---------------------------------------------------------------------------------------------
Rows stored in this page
---------------------------------------------------------------------------------------------

Slot  CustomerID  FullName  PhoneNumber
0     0           Marina    0000-0000
1     1           Jose      1111-1111
2     2           Maria     2222-2222
3     3           Ana       3333-3333
4     4           Paula     4444-4444
5     5           Marcio    5555-5555
6     6           Erick     6666-6666
7     7           Luana     7777-7777
8     8           Mario     8888-8888
9     9           Carla     9999-9999

---------------------------------------------------------------------------------------------
Observation
---------------------------------------------------------------------------------------------

This output confirms that page (1:392) is a data page from the clustered index
and contains all 10 rows from dbo.Customer

PAGE: (1:392)
1   = file_id
392 = page_id

Because all 10 rows are stored in this single page, corrupting this page and
repairing it with REPAIR_ALLOW_DATA_LOSS can cause complete data loss for the
table

The page number may change between executions
*/

-------------------------------------------------------------------------------
-- 11 - Corrupt a data page with DBCC WRITEPAGE
-------------------------------------------------------------------------------

/*
The next commands intentionally corrupt one data page
The offset value used here is only for lab purposes

In this lab, page 1:392 is the only data page for dbo.Customer

After corruption, the repair can deallocate this page and remove all rows from
the table
*/

DECLARE
@DataPageFID INT,
@DataPagePID INT,
@SQL NVARCHAR(MAX);

SELECT TOP (1)
@DataPageFID = PageFID,
@DataPagePID = PagePID
FROM #DBCCIND
WHERE PageType = 1 -- Data Page
ORDER BY PagePID;

SELECT
@DataPageFID AS data_page_file_id_to_corrupt,
@DataPagePID AS data_page_id_to_corrupt;

/*
Result:
data_page_file_id_to_corrupt  data_page_id_to_corrupt
1                             392
*/

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

SET @SQL = N'DBCC WRITEPAGE (''ExamplesDB_CorruptionCheckDB'', '
         + CAST(@DataPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@DataPagePID AS NVARCHAR(20))
         + N', 4000, 1, 0x45, 1);';

PRINT(@SQL);

/*
Printed command:
DBCC WRITEPAGE ('ExamplesDB_CorruptionCheckDB', 1, 392, 4000, 1, 0x45, 1);
*/

EXEC (@SQL);

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET MULTI_USER WITH NO_WAIT;
GO

/*
Result:
(1 row affected)
DBCC WRITEPAGE ('ExamplesDB_CorruptionCheckDB', 1, 392, 4000, 1, 0x45, 1);
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-29T18:25:22.8736726-03:00
*/

-------------------------------------------------------------------------------
-- 12 - Validate data page corruption
-------------------------------------------------------------------------------

/*
DBCC DROPCLEANBUFFERS is used only to force the next read to come from disk

This command affects the instance buffer cache
Use only in a laboratory environment
*/

CHECKPOINT;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-29T18:26:16.2089893-03:00
*/

DBCC DROPCLEANBUFFERS;
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-29T18:26:27.5880002-03:00
*/

USE ExamplesDB_CorruptionCheckDB;
GO

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer
WHERE FullName = 'Jose';
GO

/*
Result:
Msg 824, Level 24, State 2, Line 482
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xfa1ea5ee; actual: 0xfa1ec1ee). 
It occurred during a read of page (1:392) in database ID 21 at offset 0x00000000310000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_CorruptionCheckDB.mdf'.  
Additional messages in the SQL Server error log or operating system error log may provide more detail. 
This is a severe error condition that threatens database integrity and must be corrected immediately. 
Complete a full database consistency check (DBCC CHECKDB). 
This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-04-29T18:27:02.3417334-03:00
*/

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer
WHERE FullName = 'Carla';
GO

/*
Result:
Msg 824, Level 24, State 2, Line 497
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xfa1ea5ee; actual: 0xfa1ec1ee). 
It occurred during a read of page (1:392) in database ID 21 at offset 0x00000000310000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_CorruptionCheckDB.mdf'.  
Additional messages in the SQL Server error log or operating system error log may provide more detail. 
This is a severe error condition that threatens database integrity and must be corrected immediately. 
Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; 
for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-04-29T18:27:24.1113683-03:00
*/

-------------------------------------------------------------------------------
-- 13 - Review suspect_pages
-------------------------------------------------------------------------------

SELECT
DB_NAME(database_id) AS database_name,
file_id,
page_id,
event_type,
error_count,
last_update_date
FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('ExamplesDB_CorruptionCheckDB')
ORDER BY last_update_date DESC;
GO

/*
Result:
database_name                  file_id  page_id  event_type  error_count  last_update_date
ExamplesDB_CorruptionCheckDB   1        392      2           2            2026-04-29 18:27:24.107

Observation:
event_type 2 indicates a bad checksum or torn page event

The page_id should match the corrupted page reported by error 824
*/

-------------------------------------------------------------------------------
-- 14 - Run DBCC CHECKDB for data page corruption
-------------------------------------------------------------------------------

DBCC CHECKDB (ExamplesDB_CorruptionCheckDB) WITH NO_INFOMSGS, TABLERESULTS;
GO

/*
Result:

---------------------------------------------------------------------------------------------
Important CHECKDB columns
---------------------------------------------------------------------------------------------

Error
-- Error number returned by DBCC CHECKDB

Level
-- Error severity level

State
-- Internal state of the error

RepairLevel
-- Minimum repair option suggested by DBCC CHECKDB

Status
-- Internal status value returned by DBCC CHECKDB

DbId
-- Database ID where the problem was found

DbFragId
-- Internal database fragment ID

ObjectId
-- Object ID affected by the consistency error

IndexId
-- Index ID affected by the consistency error
-- In this lab, IndexId 1 represents the clustered index PK_Customer

PartitionId
-- Partition ID affected by the consistency error

AllocUnitId
-- Allocation unit ID affected by the consistency error

File
-- File ID where the damaged page is located

Page
-- Page ID affected by the consistency error

Slot
-- Slot inside the page related to the consistency error

Allocation
-- Indicates whether the error is related to allocation context

---------------------------------------------------------------------------------------------
DBCC CHECKDB result
---------------------------------------------------------------------------------------------

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          File   Page   Slot   Allocation
8939    16      98      repair_allow_data_loss   0        21     1          901578250    1         72057594045726720  72057594052476928   1      392    0      1
MessageText:
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data), page (1:392). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 133129 and -4.

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          File   Page   Slot   Allocation
8928    16      1       repair_allow_data_loss   0        21     1          901578250    1         72057594045726720  72057594052476928   1      392    0      1
MessageText:
Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data): Page (1:392) could not be processed. See other errors for details.

Error   Level   State   RepairLevel      Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          File   Page   Slot   Allocation
8980    16      1       repair_rebuild   0        21     1          901578250    1         72057594045726720  72057594052476928   1      392    0      1
MessageText:
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data). Index node page (0:0), slot 0 refers to child page (1:392) and previous child (0:0), but they were not encountered.

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId     IndexId   PartitionId   AllocUnitId   File   Page   Slot   Allocation
8990    10      1       NULL          0        21     1          901578250    0         0             0             0      0       0      1
MessageText:
CHECKDB found 0 allocation errors and 3 consistency errors in table 'Customer' (object ID 901578250).

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId   IndexId   PartitionId   AllocUnitId   File   Page   Slot   Allocation
8989    10      1       NULL          0        21     1          0          0         0             0             0      0       0      1
MessageText:
CHECKDB found 0 allocation errors and 3 consistency errors in database 'ExamplesDB_CorruptionCheckDB'.

---------------------------------------------------------------------------------------------
Observation
---------------------------------------------------------------------------------------------

DBCC CHECKDB identified consistency errors related to page (1:392)

The damaged page belongs to ObjectId 901578250 and IndexId 1

In this lab:
ObjectId 901578250 = dbo.Customer
IndexId 1          = clustered index PK_Customer
File 1             = data file
Page 392           = damaged data page

The minimum repair level reported for the main errors is repair_allow_data_loss

This means SQL Server cannot guarantee a repair without possible data loss

The message for error 8939 points directly to page (1:392)

The message for error 8928 confirms that page (1:392) could not be processed

The message for error 8980 shows that the index structure expected to find
child page (1:392), but the page could not be processed correctly

The summary messages 8990 and 8989 show that CHECKDB found:

0 allocation errors
3 consistency errors in table dbo.Customer
3 consistency errors in database ExamplesDB_CorruptionCheckDB

This result explains why using REPAIR_ALLOW_DATA_LOSS in the next step can
deallocate the damaged page and cause complete data loss for the table
*/

-------------------------------------------------------------------------------
-- 15 - Repair data page corruption with REPAIR_ALLOW_DATA_LOSS
-------------------------------------------------------------------------------

/*
REPAIR_ALLOW_DATA_LOSS can remove damaged data

This is not the preferred production strategy

The preferred strategy is restore from valid backups

In this lab, DBCC CHECKDB deallocates the damaged data page

Because the table data is stored on that page, all rows are lost after repair
*/

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-29T18:31:47.7658138-03:00
*/

DBCC CHECKDB (ExamplesDB_CorruptionCheckDB, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS;
GO

/*
Result:
Repair: The Clustered index successfully rebuilt for the object "dbo.Customer" in database "ExamplesDB_CorruptionCheckDB".
Repair: The page (1:392) has been deallocated from object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data).
Repair: The Nonclustered index successfully rebuilt for the object "dbo.Customer, IXU_Customer_FullName" in database "ExamplesDB_CorruptionCheckDB".
Msg 8945, Level 16, State 1, Line 600
Table error: Object ID 901578250, index ID 1 will be rebuilt.
        The error has been repaired.
Msg 8928, Level 16, State 1, Line 600
Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data): Page (1:392) could not be processed. See other errors for details.
        The error has been repaired.
Msg 8939, Level 16, State 98, Line 600
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data), page (1:392). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 2057 and -4.
        The error has been repaired.
Msg 8980, Level 16, State 1, Line 600
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data). Index node page (0:0), slot 0 refers to child page (1:392) and previous child (0:0), but they were not encountered.
        The error has been repaired.
Msg 8945, Level 16, State 1, Line 600
Table error: Object ID 901578250, index ID 2 will be rebuilt.
        The error has been repaired.
CHECKDB found 0 allocation errors and 3 consistency errors in table 'Customer' (object ID 901578250).
CHECKDB fixed 0 allocation errors and 3 consistency errors in table 'Customer' (object ID 901578250).
CHECKDB found 0 allocation errors and 3 consistency errors in database 'ExamplesDB_CorruptionCheckDB'.
CHECKDB fixed 0 allocation errors and 3 consistency errors in database 'ExamplesDB_CorruptionCheckDB'.

Completion time: 2026-04-29T18:31:59.9327818-03:00
*/

ALTER DATABASE ExamplesDB_CorruptionCheckDB SET MULTI_USER WITH NO_WAIT;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-29T18:32:49.8445069-03:00
*/

-------------------------------------------------------------------------------
-- 16 - Validate complete data loss after repair
-------------------------------------------------------------------------------

USE ExamplesDB_CorruptionCheckDB;
GO

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer
ORDER BY CustomerID;
GO

/*
Result:
CustomerID  FullName  PhoneNumber

Observation:
No rows returned

The table structure still exists, but all rows were lost because the damaged
data page was deallocated during REPAIR_ALLOW_DATA_LOSS
*/

SELECT
COUNT(*) AS total_rows_after_repair
FROM dbo.Customer;
GO

/*
Result:
total_rows_after_repair
0
*/

DBCC CHECKDB (ExamplesDB_CorruptionCheckDB) WITH NO_INFOMSGS, TABLERESULTS;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-29T18:33:20.6438515-03:00

Observation:
The database is now structurally consistent, but the data was lost

This is the main lesson of this hands-on:

REPAIR_ALLOW_DATA_LOSS can make the database consistent again by removing
damaged data

A consistent database after repair does not mean that all original data was
preserved
*/

-------------------------------------------------------------------------------
-- 17 - Cleanup lab database
-------------------------------------------------------------------------------

/*
Execute this section only if you want to remove the lab database
*/

USE master;
GO

/*
IF DB_ID('ExamplesDB_CorruptionCheckDB') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_CorruptionCheckDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_CorruptionCheckDB;
END;
GO
*/