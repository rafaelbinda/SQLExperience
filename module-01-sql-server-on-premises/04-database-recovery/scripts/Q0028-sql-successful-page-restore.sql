/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-30
Version     : 1.0
Task        : Q0028 - SQL Successful Page Restore
Object      : Script
Description : Creates a dedicated lab database to demonstrate a successful
              Page Restore operation after data page corruption, using a full
              backup, log backup and tail-log backup
Notes       : 04-database-recovery/notes/A0031-page-restore.md
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
9  - Prepare helper tables
10 - List table pages with DBCC IND
11 - Identify data page for Page Restore
12 - Inspect data page with DBCC PAGE
13 - Corrupt data page with DBCC WRITEPAGE
14 - Validate data page corruption
15 - Review suspect_pages
16 - Run DBCC CHECKDB before Page Restore
17 - Execute tail-log backup before Page Restore
18 - Restore damaged page from full backup
19 - Restore log backup
20 - Restore tail-log backup WITH RECOVERY
21 - Validate data after successful Page Restore
22 - Review suspect_pages after Page Restore
23 - Cleanup lab database and helper tables
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Important warning
-------------------------------------------------------------------------------

/*
WARNING

This script is for laboratory use only

It intentionally corrupts a database page using DBCC WRITEPAGE

Do not execute this script in production

Do not execute this script in any database that contains important data

DBCC WRITEPAGE writes directly to database pages
It is not logged as a normal data modification
It does not support rollback
It can permanently damage the database

This hands-on demonstrates a successful Page Restore strategy

The goal is to restore only the damaged page from a valid full backup and then
apply the log chain to bring the page back to a consistent point

This scenario is safer than using DBCC CHECKDB with REPAIR_ALLOW_DATA_LOSS
because it is based on restoring from valid backups
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 2 - Create lab database
-------------------------------------------------------------------------------

IF DB_ID('ExamplesDB_PageRestore') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PageRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PageRestore;
END;
GO

CREATE DATABASE ExamplesDB_PageRestore;
GO

ALTER DATABASE ExamplesDB_PageRestore SET RECOVERY FULL;
GO

USE ExamplesDB_PageRestore;
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
CustomerID	FullName	PhoneNumber
0	        Marina      0000-0000
1	        Jose        1111-1111
2	        Maria       2222-2222
3	        Ana         3333-3333
4	        Paula       4444-4444
5	        Marcio      5555-5555
6	        Erick       6666-6666
7	        Luana       7777-7777
8	        Mario       8888-8888
9	        Carla       9999-9999
*/

-------------------------------------------------------------------------------
-- 5 - Configure PAGE_VERIFY CHECKSUM
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_PageRestore SET PAGE_VERIFY CHECKSUM;
GO

-------------------------------------------------------------------------------
-- 6 - Create initial backups
-------------------------------------------------------------------------------
 
BACKUP DATABASE ExamplesDB_PageRestore
TO DISK = 'C:\Backups\ExamplesDB_PageRestore_FULL.bak'
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
Processed 464 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
BACKUP DATABASE successfully processed 466 pages in 0.035 seconds (103.906 MB/sec).
Completion time: 2026-04-30T23:35:14.8099657-03:00
*/

BACKUP LOG ExamplesDB_PageRestore
TO DISK = 'C:\Backups\ExamplesDB_PageRestore_LOG_001.trn'
WITH FORMAT, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
100 percent processed.
Processed 3 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
BACKUP LOG successfully processed 3 pages in 0.008 seconds (2.929 MB/sec).
Completion time: 2026-04-30T23:35:29.1649122-03:00
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
WHERE name = 'ExamplesDB_PageRestore';
GO

/*
Result:
database_name	        recovery_model_desc	 page_verify_option_desc	state_desc
ExamplesDB_PageRestore	FULL	             CHECKSUM	                ONLINE
*/

SELECT
DB_NAME(database_id) AS database_name,
file_id,
type_desc,
name AS logical_name,
physical_name,
state_desc
FROM sys.master_files
WHERE database_id = DB_ID('ExamplesDB_PageRestore')
ORDER BY file_id;
GO

/*
Result:
database_name	        file_id	type_desc	logical_name	                physical_name	                                    state_desc
ExamplesDB_PageRestore	1	    ROWS	    ExamplesDB_PageRestore	        C:\MSSQLSERVER\DATA\ExamplesDB_PageRestore.mdf	    ONLINE
ExamplesDB_PageRestore	2	    LOG     	ExamplesDB_PageRestore_log	    C:\MSSQLSERVER\LOG\ExamplesDB_PageRestore_log.ldf	ONLINE
*/

-------------------------------------------------------------------------------
-- 8 - Review index metadata
-------------------------------------------------------------------------------

USE ExamplesDB_PageRestore;
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
-- 9 - Prepare helper tables
-------------------------------------------------------------------------------

/*
The helper tables are created in tempdb on purpose

They keep the selected page information available across multiple batches,
including the restore section executed from master

This avoids depending on a local temporary table later in the script
*/

USE tempdb;
GO

DROP TABLE IF EXISTS dbo.Q0028_DBCCIND;
GO

DROP TABLE IF EXISTS dbo.Q0028_PageRestoreTarget;
GO

CREATE TABLE dbo.Q0028_DBCCIND
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

CREATE TABLE dbo.Q0028_PageRestoreTarget
(
    database_name SYSNAME NOT NULL,
    schema_name SYSNAME NOT NULL,
    table_name SYSNAME NOT NULL,
    index_name SYSNAME NULL,
    file_id INT NOT NULL,
    page_id INT NOT NULL,
    page_restore_address VARCHAR(50) NOT NULL,
    page_type TINYINT NOT NULL,
    index_id INT NOT NULL,
    captured_at DATETIME2 NOT NULL DEFAULT SYSDATETIME()
);
GO

-------------------------------------------------------------------------------
-- 10 - List table pages with DBCC IND
-------------------------------------------------------------------------------

/*
DBCC IND lists pages that belong to a table or index

PageType 1  = Data Page
PageType 2  = Index Page
PageType 10 = IAM Page

IndexLevel 0 = leaf level
*/

USE ExamplesDB_PageRestore;
GO

DBCC TRACEON (2588);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-30T23:38:34.0010534-03:00
*/

DBCC TRACEON (3604);
GO

/*
Result:
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-30T23:38:46.5280354-03:00
*/

DBCC HELP ('IND');
GO

/*
Result:
dbcc IND ( { 'dbname' | dbid }, { 'objname' | objid }, { nonclustered indid | 1 | 0 | -1 | -2 } [, partition_number] )
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-30T23:38:57.1736893-03:00
*/

DBCC IND ('ExamplesDB_PageRestore', 'dbo.Customer', -1);
GO

/*
Result:
PageFID	PagePID	IAMFID	IAMPID	ObjectID	IndexID	PartitionNumber	PartitionID	        iam_chain_type	PageType	IndexLevel	NextPageFID	NextPagePID	PrevPageFID	PrevPagePID
1	    156	    NULL	NULL	901578250	1	    1	            72057594045726720	In-row data	    10	        NULL	    0	        0	        0	        0
1	    392	    1	    156	    901578250	1	    1	            72057594045726720	In-row data	    1	        0	        0	        0	        0	        0
1	    162	    NULL	NULL	901578250	2	    1	            72057594045792256	In-row data	    10	        NULL	    0	        0	        0	        0
1	    400	    1	    162	    901578250	2	    1	            72057594045792256	In-row data	    2	        0	        0	        0	        0	        0
*/

INSERT INTO tempdb.dbo.Q0028_DBCCIND
EXEC ('DBCC IND (''ExamplesDB_PageRestore'', ''dbo.Customer'', -1)');
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
FROM tempdb.dbo.Q0028_DBCCIND
ORDER BY IndexID, PageType, PagePID;
GO

/*
Result:
PageFID	PagePID	IAMFID	IAMPID	ObjectID	IndexID	PartitionNumber	PartitionID	        iam_chain_type	PageType	IndexLevel	NextPageFID	NextPagePID	PrevPageFID	PrevPagePID
1	    156	    NULL	NULL	901578250	1	    1	            72057594045726720	In-row data	    10	        NULL	    0	        0	        0	        0
1	    392	    1	    156	    901578250	1	    1	            72057594045726720	In-row data	    1	        0	        0	        0	        0	        0
1	    162	    NULL	NULL	901578250	2	    1	            72057594045792256	In-row data	    10	        NULL	    0	        0	        0	        0
1	    400	    1	    162	    901578250	2	    1	            72057594045792256	In-row data	    2	        0	        0	        0	        0	        0
*/

-------------------------------------------------------------------------------
-- 11 - Identify data page for Page Restore
-------------------------------------------------------------------------------

/*
The selected page must be a data page from the clustered index

PageType = 1 means Data Page
IndexID  = 1 means clustered index
*/

DELETE FROM tempdb.dbo.Q0028_PageRestoreTarget
WHERE database_name = 'ExamplesDB_PageRestore';
GO

INSERT INTO tempdb.dbo.Q0028_PageRestoreTarget
(
    database_name,
    schema_name,
    table_name,
    index_name,
    file_id,
    page_id,
    page_restore_address,
    page_type,
    index_id
)
SELECT TOP (1)
'ExamplesDB_PageRestore' AS database_name,
'dbo' AS schema_name,
'Customer' AS table_name,
'PK_Customer' AS index_name,
PageFID AS file_id,
PagePID AS page_id,
CAST(PageFID AS VARCHAR(20)) + ':' + CAST(PagePID AS VARCHAR(20)) AS page_restore_address,
PageType AS page_type,
IndexID AS index_id
FROM tempdb.dbo.Q0028_DBCCIND
WHERE PageType = 1
AND IndexID = 1
ORDER BY PagePID;
GO

SELECT
database_name,
schema_name,
table_name,
index_name,
file_id,
page_id,
page_restore_address,
page_type,
index_id,
captured_at
FROM tempdb.dbo.Q0028_PageRestoreTarget
WHERE database_name = 'ExamplesDB_PageRestore';
GO

/*
Result:
database_name	        schema_name	    table_name	index_name	file_id	page_id	    page_restore_address	page_type	index_id	captured_at
ExamplesDB_PageRestore	dbo	            Customer	PK_Customer	1	    392	        1:392	                1	        1	        2026-04-30 23:41:56.0997511
*/

-------------------------------------------------------------------------------
-- 12 - Inspect data page with DBCC PAGE
-------------------------------------------------------------------------------

/*
DBCC PAGE with print option 3 shows the page header and row contents

The selected page address will also be used later by RESTORE DATABASE ... PAGE
*/

DECLARE
@DataPageFID INT,
@DataPagePID INT,
@SQL NVARCHAR(MAX);

SELECT
@DataPageFID = file_id,
@DataPagePID = page_id
FROM tempdb.dbo.Q0028_PageRestoreTarget
WHERE database_name = 'ExamplesDB_PageRestore';

SET @SQL = N'DBCC PAGE (''ExamplesDB_PageRestore'', '
         + CAST(@DataPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@DataPagePID AS NVARCHAR(20))
         + N', 3);';

PRINT(@SQL);
EXEC (@SQL);
GO

/*
Result:

---------------------------------------------------------------------------------------------
Data page information
---------------------------------------------------------------------------------------------

DBCC PAGE ('ExamplesDB_PageRestore', 1, 392, 3);

PAGE: (1:392)

---------------------------------------------------------------------------------------------
Important page header information
---------------------------------------------------------------------------------------------

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

This page address will be used later by RESTORE DATABASE ... PAGE

---------------------------------------------------------------------------------------------
Full DBCC PAGE output
---------------------------------------------------------------------------------------------

    DBCC PAGE ('ExamplesDB_PageRestore', 1, 392, 3);

    PAGE: (1:392)


    BUFFER:


    BUF @0x000001F789479240

    bpage = 0x000001F61E1AC000          bPmmpage = 0x0000000000000000       bsort_r_nextbP = 0x000001F789479190
    bsort_r_prevbP = 0x0000000000000000 bhash = 0x0000000000000000          bpageno = (1:392)
    bpart = 3                           bstat = 0x109                       breferences = 0
    berrcode = 0                        bUse1 = 20844                       bstat2 = 0x0
    blog = 0x2121cc8a                   bsampleCount = 0                    bIoCount = 0
    resPoolId = 0                       bcputicks = 0                       bReadMicroSec = 977
    bDirtyPendingCount = 0              bDirtyContext = 0x0000000000000000  bDbPageBroker = 0x0000000000000000
    bdbid = 22                          bpru = 0x000001F60EC08040           

    PAGE HEADER:


    Page @0x000001F61E1AC000

    m_pageId = (1:392)                  m_headerVersion = 1                 m_type = 1
    m_typeFlagBits = 0x0                m_level = 0                         m_flagBits = 0x8200
    m_objId (AllocUnitId.idObj) = 222   m_indexId (AllocUnitId.idInd) = 256 Metadata: AllocUnitId = 72057594052476928
    Metadata: PartitionId = 72057594045726720                                Metadata: IndexId = 1
    Metadata: ObjectId = 901578250      m_prevPage = (0:0)                  m_nextPage = (0:0)
    pminlen = 23                        m_slotCnt = 10                      m_freeCnt = 7686
    m_freeData = 486                    m_reservedCnt = 0                   m_lsn = (39:496:70)
    m_xactReserved = 0                  m_xdesId = (0:0)                    m_ghostRecCnt = 0
    m_tornBits = -98654738              DB Frag ID = 1                      

    Allocation Status

    GAM (1:2) = ALLOCATED               SGAM (1:3) = NOT ALLOCATED          PFS (1:1) = 0x40 ALLOCATED   0_PCT_FULL
    DIFF (1:6) = NOT CHANGED            ML (1:7) = NOT MIN_LOGGED           

    Slot 0 Offset 0x60 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E970060

    0000000000000000:   30001700 00000000 4d617269 6e612020 20202020  0.......Marina      
    0000000000000014:   20202003 00000100 27003030 30302d30 303030       .....'.0000-0000

    Slot 0 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 0                      

    Slot 0 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Marina                   

    Slot 0 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 0000-0000             

    Slot 0 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (78d82fa561ac)       

    Slot 1 Offset 0x87 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E970087

    0000000000000000:   30001700 01000000 4a6f7365 20202020 20202020  0.......Jose        
    0000000000000014:   20202003 00000100 27003131 31312d31 313131       .....'.1111-1111

    Slot 1 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 1                      

    Slot 1 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Jose                     

    Slot 1 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 1111-1111             

    Slot 1 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (8194443284a0)       

    Slot 2 Offset 0xae Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E9700AE

    0000000000000000:   30001700 02000000 4d617269 61202020 20202020  0.......Maria       
    0000000000000014:   20202003 00000100 27003232 32322d32 323232       .....'.2222-2222

    Slot 2 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 2                      

    Slot 2 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Maria                    

    Slot 2 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 2222-2222             

    Slot 2 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (61a06abd401c)       

    Slot 3 Offset 0xd5 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E9700D5

    0000000000000000:   30001700 03000000 416e6120 20202020 20202020  0.......Ana         
    0000000000000014:   20202003 00000100 27003333 33332d33 333333       .....'.3333-3333

    Slot 3 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 3                      

    Slot 3 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Ana                      

    Slot 3 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 3333-3333             

    Slot 3 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (98ec012aa510)       

    Slot 4 Offset 0xfc Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E9700FC

    0000000000000000:   30001700 04000000 5061756c 61202020 20202020  0.......Paula       
    0000000000000014:   20202003 00000100 27003434 34342d34 343434       .....'.4444-4444

    Slot 4 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 4                      

    Slot 4 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Paula                    

    Slot 4 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 4444-4444             

    Slot 4 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (a0c936a3c965)       

    Slot 5 Offset 0x123 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E970123

    0000000000000000:   30001700 05000000 4d617263 696f2020 20202020  0.......Marcio      
    0000000000000014:   20202003 00000100 27003535 35352d35 353535       .....'.5555-5555

    Slot 5 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 5                      

    Slot 5 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Marcio                   

    Slot 5 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 5555-5555             

    Slot 5 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (59855d342c69)       

    Slot 6 Offset 0x14a Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E97014A

    0000000000000000:   30001700 06000000 45726963 6b202020 20202020  0.......Erick       
    0000000000000014:   20202003 00000100 27003636 36362d36 363636       .....'.6666-6666

    Slot 6 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 6                      

    Slot 6 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Erick                    

    Slot 6 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 6666-6666             

    Slot 6 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (b9b173bbe8d5)       

    Slot 7 Offset 0x171 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E970171

    0000000000000000:   30001700 07000000 4c75616e 61202020 20202020  0.......Luana       
    0000000000000014:   20202003 00000100 27003737 37372d37 373737       .....'.7777-7777

    Slot 7 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 7                      

    Slot 7 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Luana                    

    Slot 7 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 7777-7777             

    Slot 7 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (40fd182c0dd9)       

    Slot 8 Offset 0x198 Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E970198

    0000000000000000:   30001700 08000000 4d617269 6f202020 20202020  0.......Mario       
    0000000000000014:   20202003 00000100 27003838 38382d38 383838       .....'.8888-8888

    Slot 8 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 8                      

    Slot 8 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Mario                    

    Slot 8 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 8888-8888             

    Slot 8 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (c9fb1da9313f)       

    Slot 9 Offset 0x1bf Length 39

    Record Type = PRIMARY_RECORD        Record Attributes =  NULL_BITMAP VARIABLE_COLUMNS
    Record Size = 39                    
    Memory Dump @0x000000841E9701BF

    0000000000000000:   30001700 09000000 4361726c 61202020 20202020  0...	...Carla       
    0000000000000014:   20202003 00000100 27003939 39392d39 393939       .....'.9999-9999

    Slot 9 Column 1 Offset 0x4 Length 4 Length (physical) 4

    CustomerID = 9                      

    Slot 9 Column 2 Offset 0x8 Length 15 Length (physical) 15

    FullName = Carla                    

    Slot 9 Column 3 Offset 0x1e Length 9 Length (physical) 9

    PhoneNumber = 9999-9999             

    Slot 9 Offset 0x0 Length 0 Length (physical) 0

    KeyHashValue = (30b7763ed433)       


    DBCC execution completed. If DBCC printed error messages, contact your system administrator.

    Completion time: 2026-04-30T23:43:07.0245116-03:00
*/

-------------------------------------------------------------------------------
-- 13 - Corrupt data page with DBCC WRITEPAGE
-------------------------------------------------------------------------------

/*
The next commands intentionally corrupt one data page

The offset value used here is only for lab purposes

The selected page is stored in tempdb.dbo.Q0028_PageRestoreTarget
*/

USE ExamplesDB_PageRestore;
GO

DECLARE
@DataPageFID INT,
@DataPagePID INT,
@SQL NVARCHAR(MAX);

SELECT
@DataPageFID = file_id,
@DataPagePID = page_id
FROM tempdb.dbo.Q0028_PageRestoreTarget
WHERE database_name = 'ExamplesDB_PageRestore';

SELECT
@DataPageFID AS data_page_file_id_to_corrupt,
@DataPagePID AS data_page_id_to_corrupt;

ALTER DATABASE ExamplesDB_PageRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

SET @SQL = N'DBCC WRITEPAGE (''ExamplesDB_PageRestore'', '
         + CAST(@DataPageFID AS NVARCHAR(20))
         + N', '
         + CAST(@DataPagePID AS NVARCHAR(20))
         + N', 4000, 1, 0x45, 1);';

PRINT(@SQL);
EXEC (@SQL);

ALTER DATABASE ExamplesDB_PageRestore SET MULTI_USER WITH NO_WAIT;
GO

/*
Result:
(1 row affected)
DBCC WRITEPAGE ('ExamplesDB_PageRestore', 1, 392, 4000, 1, 0x45, 1);
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Completion time: 2026-04-30T23:46:57.6625137-03:00

data_page_file_id_to_corrupt	data_page_id_to_corrupt
1	                            392
*/

-------------------------------------------------------------------------------
-- 14 - Validate data page corruption
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

USE ExamplesDB_PageRestore;
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
DBCC execution completed. If DBCC printed error messages, contact your system administrator.
Msg 824, Level 24, State 2, Line 999
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xfa1ea5ee; actual: 0xfa1ec1ee). It occurred during a read of page (1:392) in database ID 22 at offset 0x00000000310000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_PageRestore.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-04-30T23:47:54.0858810-03:00
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
Msg 824, Level 24, State 2, Line 1015
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xfa1ea5ee; actual: 0xfa1ec1ee). It occurred during a read of page (1:392) in database ID 22 at offset 0x00000000310000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_PageRestore.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-04-30T23:48:09.6417425-03:00
*/

SELECT
CustomerID,
FullName,
PhoneNumber
FROM dbo.Customer
ORDER BY CustomerID;
GO

/*
Result:
Msg 824, Level 24, State 2, Line 1030
SQL Server detected a logical consistency-based I/O error: incorrect checksum (expected: 0xfa1ea5ee; actual: 0xfa1ec1ee). It occurred during a read of page (1:392) in database ID 22 at offset 0x00000000310000 in file 'C:\MSSQLSERVER\DATA\ExamplesDB_PageRestore.mdf'.  Additional messages in the SQL Server error log or operating system error log may provide more detail. This is a severe error condition that threatens database integrity and must be corrected immediately. Complete a full database consistency check (DBCC CHECKDB). This error can be caused by many factors; for more information, see https://go.microsoft.com/fwlink/?linkid=2252374.
Completion time: 2026-04-30T23:48:22.3226179-03:00
*/

-------------------------------------------------------------------------------
-- 15 - Review suspect_pages
-------------------------------------------------------------------------------

SELECT
DB_NAME(database_id) AS database_name,
file_id,
page_id,
event_type,
error_count,
last_update_date
FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('ExamplesDB_PageRestore')
ORDER BY last_update_date DESC;
GO

/*
Result:
database_name	        file_id	 page_id	event_type	error_count	last_update_date
ExamplesDB_PageRestore	1	     392	    2	        3	        2026-04-30 23:48:22.297
*/

-------------------------------------------------------------------------------
-- 16 - Run DBCC CHECKDB before Page Restore
-------------------------------------------------------------------------------

/*
DBCC CHECKDB should report consistency errors related to the damaged data page

In this lab, the next step is not REPAIR_ALLOW_DATA_LOSS

The next step is Page Restore
*/

DBCC CHECKDB (ExamplesDB_PageRestore) WITH NO_INFOMSGS, TABLERESULTS;
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

RidDbId
-- Database ID related to the referenced row identifier

RidPruId
-- Internal partition/resource unit identifier related to the referenced row

File
-- File ID where the damaged page is located

Page
-- Page ID affected by the consistency error

Slot
-- Slot inside the page related to the consistency error

RefDbId
-- Referenced database ID used internally by CHECKDB

RefPruId
-- Referenced internal partition/resource unit identifier

RefFile
-- Referenced file ID used internally by CHECKDB

RefPage
-- Referenced page ID used internally by CHECKDB

RefSlot
-- Referenced slot used internally by CHECKDB

Allocation
-- Indicates whether the error is related to allocation context

---------------------------------------------------------------------------------------------
DBCC CHECKDB result
---------------------------------------------------------------------------------------------

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8939    16      98      repair_allow_data_loss   0        22     1          901578250    1         72057594045726720  72057594052476928   22       0          1      392    0      22        0          0         0         0         1
MessageText:
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data), page (1:392). Test (IS_OFF (BUF_IOERR, pBUF->bstat)) failed. Values are 133129 and -4.

Error   Level   State   RepairLevel              Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8928    16      1       repair_allow_data_loss   0        22     1          901578250    1         72057594045726720  72057594052476928   22       0          1      392    0      22        0          0         0         0         1
MessageText:
Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data): Page (1:392) could not be processed. See other errors for details.

Error   Level   State   RepairLevel      Status   DbId   DbFragId   ObjectId     IndexId   PartitionId         AllocUnitId          RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8980    16      1       repair_rebuild   0        22     1          901578250    1         72057594045726720  72057594052476928   22       0          1      392    0      22        0          0         0         0         1
MessageText:
Table error: Object ID 901578250, index ID 1, partition ID 72057594045726720, alloc unit ID 72057594052476928 (type In-row data). Index node page (0:0), slot 0 refers to child page (1:392) and previous child (0:0), but they were not encountered.

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId     IndexId   PartitionId   AllocUnitId   RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8990    10      1       NULL          0        22     1          901578250    0         0             0             0        0          0      0       0      0         0          0         0         0         1
MessageText:
CHECKDB found 0 allocation errors and 3 consistency errors in table 'Customer' (object ID 901578250).

Error   Level   State   RepairLevel   Status   DbId   DbFragId   ObjectId   IndexId   PartitionId   AllocUnitId   RidDbId   RidPruId   File   Page   Slot   RefDbId   RefPruId   RefFile   RefPage   RefSlot   Allocation
8989    10      1       NULL          0        22     1          0          0         0             0             0        0          0      0       0      0         0          0         0         0         1
MessageText:
CHECKDB found 0 allocation errors and 3 consistency errors in database 'ExamplesDB_PageRestore'.

---------------------------------------------------------------------------------------------
Observation
---------------------------------------------------------------------------------------------

DBCC CHECKDB identified consistency errors related to page (1:392)

The damaged page belongs to ObjectId 901578250 and IndexId 1

In this lab:
Database          = ExamplesDB_PageRestore
DbId              = 22
ObjectId 901578250 = dbo.Customer
IndexId 1         = clustered index PK_Customer
File 1            = data file
Page 392          = damaged data page

The minimum repair level reported for the main errors is repair_allow_data_loss

This means SQL Server cannot guarantee a repair without possible data loss

The message for error 8939 points directly to page (1:392)

The message for error 8928 confirms that page (1:392) could not be processed

The message for error 8980 shows that the index structure expected to find
child page (1:392), but the page could not be processed correctly

The summary messages 8990 and 8989 show that CHECKDB found:

0 allocation errors
3 consistency errors in table dbo.Customer
3 consistency errors in database ExamplesDB_PageRestore

Unlike Q0027, this lab should not proceed with REPAIR_ALLOW_DATA_LOSS

The next step is to execute the tail-log backup and start the Page Restore
sequence
*/

-------------------------------------------------------------------------------
-- 17 - Execute tail-log backup before Page Restore
-------------------------------------------------------------------------------

/*
The tail-log backup must be captured before starting the restore sequence

It preserves the final portion of the transaction log that was not backed up yet

BACKUP LOG WITH NORECOVERY leaves the database in restoring state and prevents
new changes while the restore sequence is performed

Important:
BACKUP LOG WITH NORECOVERY requires exclusive access to the database

If there are active sessions using the database, SQL Server can return:

Msg 3101
Exclusive access could not be obtained because the database is in use
To avoid this in the lab, the database is changed to SINGLE_USER before the
tail-log backup
Do not change the database back to MULTI_USER after the tail-log backup
The database must remain in RESTORING state until the Page Restore sequence is
completed
*/

USE master;
GO

ALTER DATABASE ExamplesDB_PageRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

BACKUP LOG ExamplesDB_PageRestore
TO DISK = 'C:\Backups\ExamplesDB_PageRestore_TAIL.trn'
WITH NORECOVERY, CHECKSUM, COMPRESSION, STATS = 10;
GO

/*
Result:
23 percent processed.
46 percent processed.
69 percent processed.
92 percent processed.
100 percent processed.
Processed 35 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
BACKUP LOG successfully processed 35 pages in 0.010 seconds (26.953 MB/sec).
*/

-------------------------------------------------------------------------------
-- 18 - Restore damaged page from full backup
-------------------------------------------------------------------------------

/*
The page address must use the format:

file_id:page_id

Example:
1:280

The page_restore_address was captured before the database entered restoring
state and is stored in tempdb.dbo.Q0028_PageRestoreTarget
*/

USE master;
GO

DECLARE
@PageAddress VARCHAR(50),
@SQL NVARCHAR(MAX);

SELECT
@PageAddress = page_restore_address
FROM tempdb.dbo.Q0028_PageRestoreTarget
WHERE database_name = 'ExamplesDB_PageRestore';

SET @SQL = N'RESTORE DATABASE ExamplesDB_PageRestore '
         + N'PAGE = '''
         + @PageAddress
         + N''' '
         + N'FROM DISK = ''C:\Backups\ExamplesDB_PageRestore_FULL.bak'' '
         + N'WITH NORECOVERY;';

PRINT(@SQL);
EXEC (@SQL);
GO

/*
Result:
RESTORE DATABASE ExamplesDB_PageRestore PAGE = '1:392' FROM DISK = 'C:\Backups\ExamplesDB_PageRestore_FULL.bak' WITH NORECOVERY;
Processed 1 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
RESTORE DATABASE ... FILE=<name> successfully processed 3 pages in 0.035 seconds (0.558 MB/sec).
Completion time: 2026-04-30T23:57:09.2055524-03:00
*/

-------------------------------------------------------------------------------
-- 19 - Restore log backup
-------------------------------------------------------------------------------

/*
After restoring the page from the full backup, the log backups must be applied
to bring the restored page forward in the log chain
*/

RESTORE LOG ExamplesDB_PageRestore
FROM DISK = 'C:\Backups\ExamplesDB_PageRestore_LOG_001.trn'
WITH NORECOVERY;
GO

/*
Result:
Processed 0 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore' on file 1.
Processed 3 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
RESTORE LOG successfully processed 3 pages in 0.005 seconds (4.687 MB/sec).
Completion time: 2026-04-30T23:57:40.1897657-03:00
*/

-------------------------------------------------------------------------------
-- 20 - Restore tail-log backup WITH RECOVERY
-------------------------------------------------------------------------------

/*
The tail-log backup is restored last

WITH RECOVERY finalizes the restore sequence
*/

RESTORE LOG ExamplesDB_PageRestore
FROM DISK = 'C:\Backups\ExamplesDB_PageRestore_TAIL.trn'
WITH RECOVERY;
GO

/*
Result:
Processed 0 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore' on file 1.
Processed 35 pages for database 'ExamplesDB_PageRestore', file 'ExamplesDB_PageRestore_log' on file 1.
RESTORE LOG successfully processed 35 pages in 0.010 seconds (26.953 MB/sec).
Completion time: 2026-04-30T23:57:55.7652942-03:00
*/

-------------------------------------------------------------------------------
-- 21 - Validate data after successful Page Restore
-------------------------------------------------------------------------------

USE ExamplesDB_PageRestore;
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
0	        Marina      0000-0000
1	        Jose        1111-1111
2	        Maria       2222-2222
3	        Ana         3333-3333
4	        Paula       4444-4444
5	        Marcio      5555-5555
6	        Erick       6666-6666
7	        Luana       7777-7777
8	        Mario       8888-8888
9	        Carla       9999-9999
*/

SELECT
COUNT(*) AS total_rows_after_page_restore
FROM dbo.Customer;
GO

/*
Result:
total_rows_after_page_restore
10
*/

DBCC CHECKDB (ExamplesDB_PageRestore) WITH NO_INFOMSGS, TABLERESULTS;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-30T23:58:54.4635270-03:00
*/

SELECT
name AS database_name,
state_desc,
recovery_model_desc,
page_verify_option_desc
FROM sys.databases
WHERE name = 'ExamplesDB_PageRestore';
GO

/*
Result:
database_name	        state_desc	recovery_model_desc	 page_verify_option_desc
ExamplesDB_PageRestore	ONLINE	    FULL	             CHECKSUM
*/

-------------------------------------------------------------------------------
-- 22 - Review suspect_pages after Page Restore
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 22 - Review suspect_pages after Page Restore
-------------------------------------------------------------------------------

/*
suspect_pages may still contain historical records of the suspect page

The presence of a historical record does not necessarily mean the page is still
corrupted after a successful restore

DBCC CHECKDB is the main validation after recovery

Important:
Do not use suspect_pages alone to conclude that the database is still corrupted

After a successful Page Restore, suspect_pages may show event_type = 4

event_type = 4 indicates that the page was restored
*/

SELECT
DB_NAME(database_id) AS database_name,
file_id,
page_id,
event_type,
error_count,
last_update_date
FROM msdb.dbo.suspect_pages
WHERE database_id = DB_ID('ExamplesDB_PageRestore')
ORDER BY last_update_date DESC;
GO

/*
Result:
database_name           file_id  page_id  event_type  error_count  last_update_date
ExamplesDB_PageRestore  1        392      4           5            2026-04-30 23:57:09.200

Observation:
The suspect_pages table can keep historical records even after a successful
Page Restore

In this result, event_type = 4 indicates that the page was restored

This means page (1:392) was previously marked as suspect, but SQL Server later
registered that the page was restored during the Page Restore sequence

The error_count value represents the accumulated number of events registered
for that page in msdb.dbo.suspect_pages

The presence of this row does not mean that the page is still corrupted

After Page Restore, DBCC CHECKDB is the main validation to confirm that the
database is structurally consistent
*/

-------------------------------------------------------------------------------
-- 23 - Cleanup lab database and helper tables
-------------------------------------------------------------------------------

/*
Execute this section only if you want to remove the lab database and helper
tables
*/

USE master;
GO

/*
IF DB_ID('ExamplesDB_PageRestore') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PageRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PageRestore;
END;
GO

DROP TABLE IF EXISTS tempdb.dbo.Q0028_DBCCIND;
GO

DROP TABLE IF EXISTS tempdb.dbo.Q0028_PageRestoreTarget;
GO
*/