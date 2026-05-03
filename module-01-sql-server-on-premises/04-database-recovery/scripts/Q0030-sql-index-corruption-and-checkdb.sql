/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-05-03
Version     : 1.0
Task        : Q0030 - SQL Index Corruption and DBCC CHECKDB
Object      : Script
Description : Creates a dedicated lab database to demonstrate nonclustered
              index page corruption detection using PAGE_VERIFY, DBCC IND,
              DBCC PAGE, DBCC WRITEPAGE, suspect_pages and DBCC CHECKDB repair
              options
Notes       : 04-database-recovery/notes/A0030-database-corruption-and-dbcc-checkdb.md
===============================================================================
INDEX
1  - Important warning
2  - Create lab database
3  - Create lab table
4  - Insert sample data
5  - Create nonclustered index
6  - Configure PAGE_VERIFY CHECKSUM
7  - Create initial backups
8  - Review database files and PAGE_VERIFY
9  - Review index metadata
10 - List table pages with DBCC IND
11 - Identify a nonclustered index page
12 - Inspect a nonclustered index page with DBCC PAGE
13 - Corrupt a nonclustered index page with DBCC WRITEPAGE
14 - Force page read from disk
15 - Validate index corruption
16 - Review suspect_pages
17 - Run DBCC CHECKDB for index corruption
18 - Repair index corruption with REPAIR_ALLOW_DATA_LOSS
19 - Validate table after index repair
20 - Validate indexes after repair
21 - Cleanup lab database
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

This hands-on demonstrates corruption in a nonclustered index page

The goal is to show how DBCC CHECKDB identifies index corruption and how repair
may rebuild or remove the damaged index structure

Even when the corruption is limited to a nonclustered index, repair operations
must be treated carefully

The preferred production strategy is always based on valid backups, root cause
analysis and controlled recovery planning
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 2 - Create lab database
-------------------------------------------------------------------------------

IF DB_ID('ExamplesDB_IndexCorruption') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_IndexCorruption SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_IndexCorruption;
END;
GO

CREATE DATABASE ExamplesDB_IndexCorruption;
GO

ALTER DATABASE ExamplesDB_IndexCorruption SET RECOVERY FULL;
GO

USE ExamplesDB_IndexCorruption;
GO

-------------------------------------------------------------------------------
-- 3 - Create lab table
-------------------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.Customer;
GO

CREATE TABLE dbo.Customer
(
    CustomerID INT NOT NULL,
    FullName CHAR(900) NOT NULL,
    PhoneNumber VARCHAR(20) NOT NULL,
    CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED (CustomerID)
);
GO

-------------------------------------------------------------------------------
-- 4 - Insert sample data
-------------------------------------------------------------------------------

/*
The row size is intentionally large to make the page structure easier to inspect
with DBCC IND and DBCC PAGE
*/

INSERT INTO dbo.Customer
(
    CustomerID,
    FullName,
    PhoneNumber
)
VALUES
(1,  'Jose',   '1111-1111'),
(2,  'Maria',  '2222-2222'),
(3,  'Ana',    '3333-3333'),
(4,  'Paula',  '4444-4444'),
(5,  'Marcio', '5555-5555'),
(6,  'Erick',  '6666-6666'),
(7,  'Luana',  '7777-7777'),
(8,  'Mario',  '8888-8888'),
(9,  'Carla',  '9999-9999'),
(10, 'Marina', '0000-0000');
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
CustomerID	FullName	PhoneNumber
1	        Jose        1111-1111
2	        Maria       2222-2222
3	        Ana         3333-3333
4	        Paula       4444-4444
5	        Marcio      5555-5555
6	        Erick       6666-6666
7	        Luana       7777-7777
8	        Mario       8888-8888
9	        Carla       9999-9999
10	        Marina      0000-0000
*/

-------------------------------------------------------------------------------
-- 5 - Create nonclustered index
-------------------------------------------------------------------------------

/*
This lab corrupts a page that belongs to the nonclustered index
The clustered index contains the table data
The nonclustered index contains a separate index structure based on FullName
*/

CREATE UNIQUE NONCLUSTERED INDEX IXU_Customer_FullName
ON dbo.Customer (FullName);
GO

-------------------------------------------------------------------------------
-- 6 - Configure PAGE_VERIFY CHECKSUM
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_IndexCorruption SET PAGE_VERIFY CHECKSUM;
GO

-------------------------------------------------------------------------------
-- 7 - Create initial backups
-------------------------------------------------------------------------------
 
BACKUP DATABASE ExamplesDB_IndexCorruption
TO DISK = 'C:\Backups\ExamplesDB_IndexCorruption_FULL.bak'
WITH FORMAT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
40 percent processed.
50 percent processed.
61 percent processed.
71 percent processed.
81 percent processed.
90 percent processed.
100 percent processed.
Processed 480 pages for database 'ExamplesDB_IndexCorruption', file 'ExamplesDB_IndexCorruption' on file 1.
Processed 2 pages for database 'ExamplesDB_IndexCorruption', file 'ExamplesDB_IndexCorruption_log' on file 1.
BACKUP DATABASE successfully processed 482 pages in 0.037 seconds (101.668 MB/sec).
Completion time: 2026-05-03T17:44:42.7219547-03:00
*/

BACKUP LOG ExamplesDB_IndexCorruption
TO DISK = 'C:\Backups\ExamplesDB_IndexCorruption_LOG_001.trn'
WITH FORMAT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
100 percent processed.
Processed 3 pages for database 'ExamplesDB_IndexCorruption', file 'ExamplesDB_IndexCorruption_log' on file 1.
BACKUP LOG successfully processed 3 pages in 0.005 seconds (4.687 MB/sec).
Completion time: 2026-05-03T17:44:55.6128861-03:00
*/

-------------------------------------------------------------------------------
-- 8 - Review database files and PAGE_VERIFY
-------------------------------------------------------------------------------

SELECT
name AS database_name,
recovery_model_desc,
page_verify_option_desc,
state_desc
FROM sys.databases
WHERE name = 'ExamplesDB_IndexCorruption';
GO

/*
Result:
database_name	            recovery_model_desc	page_verify_option_desc	state_desc
ExamplesDB_IndexCorruption	FULL	            CHECKSUM	            ONLINE
*/

SELECT
DB_NAME(database_id) AS database_name,
file_id,
type_desc,
name AS logical_name,
physical_name,
state_desc
FROM sys.master_files
WHERE database_id = DB_ID('ExamplesDB_IndexCorruption')
ORDER BY file_id;
GO

/*
Result:
database_name	            file_id	 type_desc	logical_name	                physical_name	                                        state_desc
ExamplesDB_IndexCorruption	1	     ROWS	    ExamplesDB_IndexCorruption	    C:\MSSQLSERVER\DATA\ExamplesDB_IndexCorruption.mdf	    ONLINE
ExamplesDB_IndexCorruption	2	     LOG	    ExamplesDB_IndexCorruption_log	C:\MSSQLSERVER\LOG\ExamplesDB_IndexCorruption_log.ldf	ONLINE
*/

-------------------------------------------------------------------------------
-- 9 - Review index metadata
-------------------------------------------------------------------------------

USE ExamplesDB_IndexCorruption;
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
index_name	            index_id	type	type_desc	    is_unique	is_primary_key
PK_Customer	            1	        1	    CLUSTERED	    1	        1
IXU_Customer_FullName	2	        2	    NONCLUSTERED	1	        0
*/

-------------------------------------------------------------------------------
-- 10 - List table pages with DBCC IND
-------------------------------------------------------------------------------

/*
DBCC IND lists pages that belong to a table or index

PageType 1  = Data Page
PageType 2  = Index Page
PageType 10 = IAM Page

IndexID 1 = clustered index
IndexID 2 = nonclustered index in this lab

IndexLevel 0 = leaf level
*/

DBCC TRACEON (2588);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-05-03T17:46:32.2100446-03:00
*/

DBCC TRACEON (3604);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-05-03T17:46:46.8056502-03:00
*/

DBCC HELP ('IND');
GO

/*
Result:
dbcc IND ( { 'dbname' | dbid }, { 'objname' | objid }, { nonclustered indid | 1 | 0 | -1 | -2 } [, partition_number] )
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-05-03T17:46:57.9359360-03:00
*/

DBCC IND ('ExamplesDB_IndexCorruption', 'dbo.Customer', -1);
GO

-------------------------------------------------------------------------------
-- 11 - Identify a nonclustered index page
-------------------------------------------------------------------------------

/*
The selected page must belong to the nonclustered index

PageType = 2 means Index Page
IndexID  = 2 means the nonclustered index IXU_Customer_FullName in this lab

The local temporary table #DBCCIND is used only during this session
*/

DROP TABLE IF EXISTS #DBCCIND;
GO

CREATE TABLE #DBCCIND
(
    PageFID TINYINT,
    PagePID INT,
    IAMFID TINYINT NULL,
    IAMPID INT NULL,
    ObjectID INT,
    IndexID INT,
    PartitionNumber INT,
    PartitionID BIGINT,
    iam_chain_type VARCHAR(64),
    PageType TINYINT,
    IndexLevel TINYINT NULL,
    NextPageFID TINYINT,
    NextPagePID INT,
    PrevPageFID TINYINT,
    PrevPagePID INT
);
GO

INSERT INTO #DBCCIND
EXEC ('DBCC IND (''ExamplesDB_IndexCorruption'', ''dbo.Customer'', -1)');
GO

SELECT
PageFID,
PagePID,
IAMFID,
IAMPID,
ObjectID,
IndexID,
PartitionNumber,
PartitionID,
iam_chain_type,
PageType,
IndexLevel,
NextPageFID,
NextPagePID,
PrevPageFID,
PrevPagePID
FROM #DBCCIND
ORDER BY IndexID, PageType, PagePID;
GO

/*
Result:
PageFID	PagePID	IAMFID	IAMPID	ObjectID	IndexID	PartitionNumber	PartitionID	        iam_chain_type	PageType	IndexLevel	NextPageFID	NextPagePID	PrevPageFID	PrevPagePID
1	    392	    1	    156	    901578250	1	    1	            72057594045726720	In-row data	    1	        0	        1	        394	        0	        0
1	    394	    1	    156	    901578250	1	    1	            72057594045726720	In-row data	    1	        0	        0	        0	        1	        392
1	    393	    1	    156	    901578250	1	    1	            72057594045726720	In-row data	    2	        1	        0	        0	        0	        0
1	    156	    NULL	NULL	901578250	1	    1	            72057594045726720	In-row data	    10	        NULL	    0	        0	        0	        0
1	    400	    1	    162	    901578250	2	    1	            72057594045792256	In-row data	    2	        0	        1	        408	        0	        0
1	    408	    1	    162	    901578250	2	    1	            72057594045792256	In-row data	    2	        0	        0	        0	        1	        400
1	    472	    1	    162	    901578250	2	    1	            72057594045792256	In-row data	    2	        1	        0	        0	        0	        0
1	    162	    NULL	NULL	901578250	2	    1	            72057594045792256	In-row data	    10	        NULL	    0	        0	        0	        0
*/

DECLARE
@IndexID INT;

SELECT @IndexID = index_id
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Customer')
AND name = 'IXU_Customer_FullName';

SELECT
i.name AS index_name,
i.index_id,
d.PageFID,
d.PagePID,
d.PageType,
d.IndexLevel,
d.iam_chain_type
FROM #DBCCIND AS d
INNER JOIN sys.indexes AS i
    ON d.IndexID = i.index_id
WHERE i.object_id = OBJECT_ID('dbo.Customer')
AND d.IndexID = @IndexID
ORDER BY d.PageType, d.PagePID;
GO

/*
Result:
index_name	            index_id	PageFID	    PagePID	    PageType	IndexLevel	iam_chain_type
IXU_Customer_FullName	2	        1	        400	        2	        0	        In-row data
IXU_Customer_FullName	2	        1	        408	        2	        0	        In-row data
IXU_Customer_FullName	2	        1	        472	        2	        1	        In-row data
IXU_Customer_FullName	2	        1	        162	        10	        NULL	    In-row data
*/

-------------------------------------------------------------------------------
-- 12 - Inspect a nonclustered index page with DBCC PAGE
-------------------------------------------------------------------------------

/*
DBCC PAGE with print option 3 shows the page header and page contents
This section identifies the nonclustered index page dynamically from #DBCCIND
*/

DECLARE
@IndexID INT,
@IndexPageFID INT,
@IndexPagePID INT,
@SQL NVARCHAR(MAX);

SELECT @IndexID = index_id
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Customer')
AND name = 'IXU_Customer_FullName';

SELECT TOP (1)
@IndexPageFID = PageFID,
@IndexPagePID = PagePID
FROM #DBCCIND
WHERE IndexID = @IndexID
AND PageType = 2
ORDER BY PagePID;

/*Result:
index_page_file_id	index_page_id
1	                400
*/

SELECT @IndexPageFID AS index_page_file_id,
@IndexPagePID AS index_page_id;

SET @SQL = N'DBCC PAGE (''ExamplesDB_IndexCorruption'', '
         + CAST(@IndexPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@IndexPagePID AS NVARCHAR(20))
         + N', 3);';

PRINT(@SQL);
EXEC (@SQL);
GO

/*
Result:
FileId	PageId	Row	Level	FullName (key)	CustomerID	KeyHashValue	Row Size
1	    400	    0	0	    Ana             3	        (a5992071c6d7)	908
1	    400	    1	0	    Carla           9	        (f1e02f926eca)	908
1	    400	    2	0	    Erick           6	        (d61ed1f0ce10)	908
1	    400	    3	0	    Jose            1	        (f06875ed4e0f)	908
1	    400	    4	0	    Luana           7	        (f6dc16de0fbe)	908
1	    400	    5	0	    Marcio          5	        (8ad73d1b99ab)	908
1	    400	    6	0	    Maria           2	        (cdfb1cf97659)	908
1	    400	    7	0	    Marina          10	        (3ecf8fa69f7d)	908
*/

-------------------------------------------------------------------------------
-- 13 - Corrupt a nonclustered index page with DBCC WRITEPAGE
-------------------------------------------------------------------------------

/*
The next commands intentionally corrupt one nonclustered index page
The offset value used here is only for lab purposes
This lab corrupts the nonclustered index page selected from #DBCCIND
*/

DECLARE
@IndexID INT,
@IndexPageFID INT,
@IndexPagePID INT,
@SQL NVARCHAR(MAX);

SELECT
@IndexID = index_id
FROM sys.indexes
WHERE object_id = OBJECT_ID('dbo.Customer')
AND name = 'IXU_Customer_FullName';

SELECT TOP (1)
@IndexPageFID = PageFID,
@IndexPagePID = PagePID
FROM #DBCCIND
WHERE IndexID = @IndexID
AND PageType = 2
ORDER BY PagePID;

SELECT
@IndexPageFID AS index_page_file_id_to_corrupt,
@IndexPagePID AS index_page_id_to_corrupt;

ALTER DATABASE ExamplesDB_IndexCorruption SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

SET @SQL = N'DBCC WRITEPAGE (''ExamplesDB_IndexCorruption'', '
         + CAST(@IndexPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@IndexPagePID AS NVARCHAR(20))
         + N', 4000, 1, 0x45, 1);';

PRINT(@SQL);
EXEC (@SQL);

/*
Result:
(1 row affected)
DBCC WRITEPAGE ('ExamplesDB_IndexCorruption', 1, 400, 4000, 1, 0x45, 1);
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-05-03T17:51:48.9402772-03:00
*/

ALTER DATABASE ExamplesDB_IndexCorruption SET MULTI_USER WITH NO_WAIT;
GO

-------------------------------------------------------------------------------
-- 14 - Force page read from disk
-------------------------------------------------------------------------------

/*
DBCC DROPCLEANBUFFERS is used only to force the next read to come from disk
This command affects the instance buffer cache
Use only in a laboratory environment
*/

CHECKPOINT;
GO

DBCC DROPCLEANBUFFERS;
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-05-03T17:52:16.7450617-03:00
*/

-------------------------------------------------------------------------------
-- 15 - Validate index corruption
-------------------------------------------------------------------------------

/*
The query below is intended to use the nonclustered index IXU_Customer_FullName
Depending on the optimizer decision and the corrupted page, the query may fail
with error 824
If the first query does not fail, run DBCC CHECKDB in the next section
*/

USE ExamplesDB_IndexCorruption;
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
Msg 824, Level 24, State 2, Line 591
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xf5e48f08; actual: 0xf5e4ea08). It occurred during a read of page (1:400) in database ID 24 at offset 0x00000000320000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_IndexCorruption.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-05-03T17:52:34.5144630-03:00
*/

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer WITH (INDEX(IXU_Customer_FullName))
WHERE FullName = 'Jose';
GO

/*
Result:
Msg 824, Level 24, State 2, Line 606
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xf5e48f08; actual: 0xf5e4ea08). It occurred during a read of page (1:400) in database ID 24 at offset 0x00000000320000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_IndexCorruption.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-05-03T17:52:49.7766969-03:00
*/

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer WITH (INDEX(IXU_Customer_FullName))
ORDER BY FullName;
GO

/*
Result:
Msg 824, Level 24, State 2, Line 621
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xf5e48f08; actual: 0xf5e4ea08). It occurred during a read of page (1:400) in database ID 24 at offset 0x00000000320000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_IndexCorruption.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-05-03T17:53:04.0093293-03:00
*/

-------------------------------------------------------------------------------
-- 16 - Review suspect_pages
-------------------------------------------------------------------------------

SELECT
DB_NAME(database_id) AS database_name,
file_id,
page_id,
event_type,
error_count,
last_update_date
FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('ExamplesDB_IndexCorruption')
ORDER BY last_update_date DESC;
GO

/*
Result:
database_name	            file_id	    page_id	    event_type	error_count	last_update_date
ExamplesDB_IndexCorruption	1	        400	        2	        3	        2026-05-03 17:53:03.977
*/

-------------------------------------------------------------------------------
-- 17 - Run DBCC CHECKDB for index corruption
-------------------------------------------------------------------------------

/*
DBCC CHECKDB should report consistency errors related to the damaged
nonclustered index page

When corruption is limited to a nonclustered index, the repair operation may
rebuild or remove the damaged index structure

Even in this scenario, REPAIR_ALLOW_DATA_LOSS must be treated as a last resort
*/

DBCC CHECKDB (ExamplesDB_IndexCorruption) WITH NO_INFOMSGS, TABLERESULTS;
GO

/*
Result:
/*
Result:

---------------------------------------------------------------------------------------------
DBCC CHECKDB result
---------------------------------------------------------------------------------------------

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8939    16      98      repair_allow_data_loss   0        24     1          901578250    2         72057594045792256  72057594052542464   24       0          1      400    0      24        0          0         0         0         1
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data), page (1:400). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 133129 and -4.

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8928    16      1       repair_allow_data_loss   0        24     1          901578250    2         72057594045792256  72057594052542464   24       0          1      400    0      24        0          1         472       0         1
MessageText:
Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data): Page (1:400) could not be processed. See other errors for details.

Error   Level   State   RepairLevel      Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8980    16      1       repair_rebuild   0        24     1          901578250    2         72057594045792256  72057594052542464   24       0          1      400    0      24        0          1         472       0         1
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data). Index node page (1:472), slot 0 refers to child page (1:400) and previous child (0:0), but they were not encountered.

Error   Level   State   RepairLevel      Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8978    16      1       repair_rebuild   0        24     1          901578250    2         72057594045792256  72057594052542464   24       0          1      408    0      24        0          1         400       0         1
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data). Page (1:408) is missing a reference from previous page (1:400). Possible chain linkage problem.

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId     IndexId   PartitionId   AllocUnitId   RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8990    10      1       NULL          0        24     1          901578250    0         0             0             0        0          0      0       0      0         0          0         0         0         1
MessageText:
CHECKDB found 0 allocation errors and 4 consistency errors in table 'Customer' (object ID 901578250).

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId   IndexId   PartitionId   AllocUnitId   RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8989    10      1       NULL          0        24     1          0          0         0             0             0        0          0      0       0      0         0          0         0         0         1
MessageText:
CHECKDB found 0 allocation errors and 4 consistency errors in database 'ExamplesDB_IndexCorruption'.

---------------------------------------------------------------------------------------------
Observation
---------------------------------------------------------------------------------------------

DBCC CHECKDB identified consistency errors related to a damaged nonclustered
index page

The damaged page belongs to ObjectId 901578250 and IndexId 2

In this lab:
Database           = ExamplesDB_IndexCorruption
DbId               = 24
ObjectId 901578250 = dbo.Customer
IndexId 2          = nonclustered index IXU_Customer_FullName
File 1             = data file
Page 400           = damaged nonclustered index page

The minimum repair level reported for the main page errors is
repair_allow_data_loss

The errors 8939 and 8928 point directly to page (1:400)

The error 8980 shows that index node page (1:472) expected to find child page
(1:400), but that child page could not be processed correctly

The error 8978 indicates a page chain linkage problem, because page (1:408) is
missing a reference from previous page (1:400)

The summary messages 8990 and 8989 show that CHECKDB found:

0 allocation errors
4 consistency errors in table dbo.Customer
4 consistency errors in database ExamplesDB_IndexCorruption

In this lab, the corruption is associated with IndexId 2, which represents the
nonclustered index IXU_Customer_FullName

Because this is a nonclustered index corruption scenario, SQL Server may be able
to repair the problem by rebuilding or removing the damaged nonclustered index
structure

Even so, REPAIR_ALLOW_DATA_LOSS must still be treated as a last resort in real
environments
*/
*/

-------------------------------------------------------------------------------
-- 18 - Repair index corruption with REPAIR_ALLOW_DATA_LOSS
-------------------------------------------------------------------------------

/*
When the corruption is limited to a nonclustered index page, SQL Server may be
able to repair the problem by rebuilding or removing the damaged index structure

This is different from corruption in a data page, where the repair can remove
actual table rows

Even so, REPAIR_ALLOW_DATA_LOSS must be treated as a last resort

The preferred production strategy is restore from valid backups or controlled
index rebuild, depending on the corruption scenario and business requirements
*/

ALTER DATABASE ExamplesDB_IndexCorruption SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

/*
Result:
Nonqualified transactions are being rolled back. Estimated rollback completion: 0%.
Nonqualified transactions are being rolled back. Estimated rollback completion: 100%.
Completion time: 2026-05-03T17:54:41.1597902-03:00
*/

DBCC CHECKDB (ExamplesDB_IndexCorruption, REPAIR_ALLOW_DATA_LOSS) WITH NO_INFOMSGS;
GO

/*
Result:

---------------------------------------------------------------------------------------------
Repair summary
---------------------------------------------------------------------------------------------

Repair:
The Nonclustered index was successfully rebuilt for the object
"dbo.Customer, IXU_Customer_FullName" in database "ExamplesDB_IndexCorruption"

Repair:
The page (1:400) was deallocated from:

Object ID    = 901578250
Index ID     = 2
Partition ID = 72057594045792256
AllocUnit ID = 72057594052542464
Type         = In-row data

---------------------------------------------------------------------------------------------
Repaired errors
---------------------------------------------------------------------------------------------

Msg 8945, Level 16, State 1, Line 787
MessageText:
Table error: Object ID 901578250, index ID 2 will be rebuilt

Repair result:
The error has been repaired

Msg 8928, Level 16, State 1, Line 787
MessageText:
Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data): Page (1:400) could not be processed. See other errors for details

Repair result:
The error has been repaired

Msg 8939, Level 16, State 98, Line 787
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data), page (1:400). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 2057 and -4

Repair result:
The error has been repaired

Msg 8980, Level 16, State 1, Line 787
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data). Index node page (1:472), slot 0 refers to child page (1:400) and previous child (0:0), but they were not encountered

Repair result:
The error has been repaired

Msg 8978, Level 16, State 1, Line 787
MessageText:
Table error: Object ID 901578250, index ID 2, partition ID 72057594045792256, alloc unit ID 72057594052542464 (type In-row data). Page (1:408) is missing a reference from previous page (1:400). Possible chain linkage problem

Repair result:
The error has been repaired

---------------------------------------------------------------------------------------------
CHECKDB summary
---------------------------------------------------------------------------------------------

Table:
Customer

Object ID:
901578250

Table result:
CHECKDB found 0 allocation errors and 4 consistency errors in table 'Customer'
CHECKDB fixed 0 allocation errors and 4 consistency errors in table 'Customer'

Database:
ExamplesDB_IndexCorruption

Database result:
CHECKDB found 0 allocation errors and 4 consistency errors in database 'ExamplesDB_IndexCorruption'
CHECKDB fixed 0 allocation errors and 4 consistency errors in database 'ExamplesDB_IndexCorruption'

---------------------------------------------------------------------------------------------
Observation
---------------------------------------------------------------------------------------------

The corruption was associated with IndexId 2

In this lab:
IndexId 2 = nonclustered index IXU_Customer_FullName
Page 400  = damaged nonclustered index page

DBCC CHECKDB repaired the corruption by rebuilding the nonclustered index and
deallocating the damaged page

This differs from the data page corruption scenario, where repairing with
REPAIR_ALLOW_DATA_LOSS caused table data loss

In this index corruption scenario, the table data can remain available because
the damaged structure was related to the nonclustered index, not the clustered
data page

Even so, REPAIR_ALLOW_DATA_LOSS must still be treated as a last resort in real
environments

Completion time:
2026-05-03T17:54:53.8215123-03:00
*/

ALTER DATABASE ExamplesDB_IndexCorruption SET MULTI_USER WITH NO_WAIT;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-05-03T17:56:43.2754663-03:00
*/

-------------------------------------------------------------------------------
-- 19 - Validate table after index repair
-------------------------------------------------------------------------------

USE ExamplesDB_IndexCorruption;
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
CustomerID	FullName	PhoneNumber
1	        Jose        1111-1111
2	        Maria       2222-2222
3	        Ana         3333-3333
4	        Paula       4444-4444
5	        Marcio      5555-5555
6	        Erick       6666-6666
7	        Luana       7777-7777
8	        Mario       8888-8888
9	        Carla       9999-9999
10	        Marina      0000-0000
*/

SELECT
COUNT(*) AS total_rows_after_index_repair
FROM dbo.Customer;
GO

/*
Result:
total_rows_after_index_repair
10
*/

-------------------------------------------------------------------------------
-- 20 - Validate indexes after repair
-------------------------------------------------------------------------------

SELECT
i.name AS index_name,
i.index_id,
i.type,
i.type_desc,
i.is_unique,
i.is_primary_key,
i.is_disabled
FROM sys.indexes AS i
WHERE i.object_id = OBJECT_ID('dbo.Customer')
ORDER BY i.index_id;
GO

/*
Result:
index_name	            index_id	type	type_desc	    is_unique	is_primary_key	is_disabled
PK_Customer	            1	        1	    CLUSTERED	    1	        1	            0
IXU_Customer_FullName	2	        2	    NONCLUSTERED	1	        0	            0
*/

DBCC CHECKDB (ExamplesDB_IndexCorruption) WITH NO_INFOMSGS, TABLERESULTS;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-05-03T17:58:08.3347289-03:00
*/

SELECT
DB_NAME(database_id) AS database_name,
file_id,
page_id,
event_type,
error_count,
last_update_date
FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('ExamplesDB_IndexCorruption')
ORDER BY last_update_date DESC;
GO

/*
Result:
database_name	            file_id	page_id	event_type	error_count	last_update_date
ExamplesDB_IndexCorruption	1	    400	    7	        7	        2026-05-03 17:54:53.753
*/

-------------------------------------------------------------------------------
-- 21 - Cleanup lab database
-------------------------------------------------------------------------------

/*
Execute this section only if you want to remove the lab database
*/

USE master;
GO

/*
IF DB_ID('ExamplesDB_IndexCorruption') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_IndexCorruption SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_IndexCorruption;
END;
GO
*/