/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-29
Version     : 1.0
Task        : Q0001 - SQL Database File Management
Object      : Script
Description : Demonstrates database file growth, file usage analysis, shrink
              operations and transaction log behavior in SQL Server
Notes       : notes/A0003-mantendo-banco-de-dados.md
===============================================================================

INDEX
1  - Recreate test database
2  - Check logical and physical file names
3  - Check initial database file size and usage
4  - Check initial log structure
5  - Create test table
6  - Validate initial row count
7  - Insert data to force database and log growth
8  - Validate row count after insert
9  - Check database file size and usage after growth
10 - Check log structure after growth
11 - Shrink entire database
12 - Validate database file size and usage after SHRINKDATABASE
13 - Check log structure after SHRINKDATABASE
14 - Delete part of the data
15 - Validate row count after delete
16 - Force checkpoint
17 - Shrink data file only
18 - Validate database file size and usage after SHRINKFILE
19 - Check log structure after SHRINKFILE
20 - Optional final SHRINKDATABASE
21 - Final validation
22 - Cleanup
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Recreate test database
-------------------------------------------------------------------------------

DROP DATABASE IF EXISTS ExamplesDB_FileManagement;
GO

CREATE DATABASE ExamplesDB_FileManagement;
GO

ALTER DATABASE ExamplesDB_FileManagement
SET RECOVERY FULL;
GO

-------------------------------------------------------------------------------
-- 2 - Check logical and physical file names
-------------------------------------------------------------------------------

SELECT
name,
physical_name,
type_desc,
size * 8 / 1024.0 AS size_mb
FROM sys.master_files
WHERE database_id = DB_ID(N'ExamplesDB_FileManagement');
GO

/*
Result:
name	                        physical_name	                                        type_desc	size_mb
ExamplesDB_FileManagement	    C:\MSSQLSERVER\DATA\ExamplesDB_FileManagement.mdf	    ROWS	    8.000000
ExamplesDB_FileManagement_log	C:\MSSQLSERVER\LOG\ExamplesDB_FileManagement_log.ldf	LOG	        8.000000
*/

-------------------------------------------------------------------------------
-- 3 - Check initial database file size and usage
-------------------------------------------------------------------------------

USE ExamplesDB_FileManagement;
GO

SELECT
 logical_name   =   name
,type_desc
,size_mb        =   size * 8 / 1024.0 
,space_used_mb  =   FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0
,percent_used   =   CAST(FILEPROPERTY(name, 'SpaceUsed') AS DECIMAL(18,4))
                    / 
                    NULLIF(CAST(size AS DECIMAL(18,4)), 0) * 100  
FROM sys.database_files;
GO

/*
Result:
logical_name	                type_desc	size_mb	    space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    8.000000	3.062500	    38.2812500000000000
ExamplesDB_FileManagement_log	LOG	        8.000000	0.429687	    5.3710937500000000
*/

-------------------------------------------------------------------------------
-- 4 - Check initial log structure
-------------------------------------------------------------------------------

DBCC LOGINFO;
GO

/*
RecoveryUnitId	FileId	FileSize	StartOffset	FSeqNo	Status	Parity	CreateLSN
0	            2	    2031616	    8192	    39	    2	    64	    0
0	            2	    2031616	    2039808	    0	    0	    0	    0
0	            2	    2031616	    4071424	    0	    0	    0	    0
0	            2	    2285568	    6103040	    0	    0	    0	    0

RecoveryUnitId → Identifies the recovery unit. Typically 0 in standard databases.
FileId         → Log file identifier (usually 2, since it refers to the transaction log).
FileSize       → Size of the Virtual Log File (VLF) in bytes.
StartOffset    → Starting position of the VLF within the log file.
FSeqNo         → Logical sequence number indicating the order in which VLFs are used.
Status         → VLF state:
                 0 = Inactive (available for reuse / can be removed by shrink)
                 2 = Active (currently in use / cannot be removed)
Parity         → Internal value used by SQL Server for validation.
CreateLSN      → Log Sequence Number when the VLF was created.

Note:
- The transaction log is divided into multiple VLFs.
- Shrink operations can only remove VLFs with Status = 0 (inactive).
- If active VLFs (Status = 2) are located at the end of the file, the log file 
  cannot be reduced effectively.
*/

-------------------------------------------------------------------------------
-- 5 - Create test table
-------------------------------------------------------------------------------

DROP TABLE IF EXISTS dbo.test_table;
GO

CREATE TABLE dbo.test_table
(
    test_id INT IDENTITY(1,1) NOT NULL
    CONSTRAINT PK_test_table PRIMARY KEY,
    large_column NCHAR(2000),
    bigint_column BIGINT
);
GO

-------------------------------------------------------------------------------
-- 6 - Validate initial row count
-------------------------------------------------------------------------------

SELECT COUNT(*) AS row_count
FROM dbo.test_table;
GO

/*
Result:
row_count
0
*/

-------------------------------------------------------------------------------
-- 7 - Insert data to force database and log growth
-------------------------------------------------------------------------------

SET NOCOUNT ON;

INSERT INTO dbo.test_table (large_column, bigint_column)
VALUES (N'Test', 12345);
GO 100000

/*
Result:
Beginning execution loop
Batch execution completed 100000 times.

Completion time: 2026-03-29T20:08:24.9839418-03:00
*/

-------------------------------------------------------------------------------
-- 8 - Validate row count after insert
-------------------------------------------------------------------------------

SELECT COUNT(*) AS row_count
FROM dbo.test_table;
GO

/*
Result:
row_count
100000
*/

-------------------------------------------------------------------------------
-- 9 - Check database file size and usage after growth
-------------------------------------------------------------------------------

SELECT
 logical_name   =   name
,type_desc
,size_mb        =   size * 8 / 1024.0 
,space_used_mb  =   FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0
,percent_used   =   CAST(FILEPROPERTY(name, 'SpaceUsed') AS DECIMAL(18,4))
                    / 
                    NULLIF(CAST(size AS DECIMAL(18,4)), 0) * 100  
FROM sys.database_files;
GO

/*
Result:
logical_name	                type_desc	size_mb	    space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    456.000000	395.937500	    86.8283991228070175
ExamplesDB_FileManagement_log	LOG	        328.000000	175.187500	    53.4108231707317073
*/


-------------------------------------------------------------------------------
-- 10 - Check log structure after growth
-------------------------------------------------------------------------------

DBCC LOGINFO;
GO

/*
Result:
RecoveryUnitId	FileId	FileSize	StartOffset	FSeqNo	Status	Parity	CreateLSN
0	            2	    2031616	    8192	    66	    2	    64	    0
0	            2	    2031616	    2039808	    59	    0	    128	    0
0	            2	    2031616	    4071424	    61	    0	    128	    0
0	            2	    2285568	    6103040	    63	    0	    128	    0
0	            2	    67108864	8388608	    64	    2	    128	    42000000395200029
0	            2	    67108864	75497472	62	    0	    64	    46000000347200002
0	            2	    67108864	142606336	60	    0	    128	    51000000348800001
0	            2	    67108864	209715200	67	    2	    128	    57000000348000005
0	            2	    67108864	276824064	65	    2	    64	    64000013057600002
*/

-------------------------------------------------------------------------------
-- 11 - Shrink entire database
-------------------------------------------------------------------------------
-- Keeps approximately 10% free space

USE master;
GO

DBCC SHRINKDATABASE (N'ExamplesDB_FileManagement', 10);
GO

/*
Result:
DbId	FileId	CurrentSize	MinimumSize	UsedPages	EstimatedPages
12	    1	    56304	    1024	    50672	    50672
12	    2	    9216	    1024	    9216	    1024
*/

-------------------------------------------------------------------------------
-- 12 - Validate database file size after SHRINKDATABASE
-------------------------------------------------------------------------------

USE ExamplesDB_FileManagement;
GO

SELECT
 logical_name   =   name
,type_desc
,size_mb        =   size * 8 / 1024.0 
,space_used_mb  =   FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0
,percent_used   =   CAST(FILEPROPERTY(name, 'SpaceUsed') AS DECIMAL(18,4))
                    / 
                    NULLIF(CAST(size AS DECIMAL(18,4)), 0) * 100  
FROM sys.database_files;
GO

/*
Result:
Before:
logical_name	                type_desc	size_mb	    space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    456.000000	395.937500	    86.8283991228070175
ExamplesDB_FileManagement_log	LOG	        328.000000	175.187500	    53.4108231707317073

After: 
logical_name	                type_desc	size_mb	    space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    439.875000	395.937500	    90.0113668655868144
ExamplesDB_FileManagement_log	LOG	        72.000000	0.421875	    0.5859375000000000
*/

-------------------------------------------------------------------------------
-- 13 - Check log structure after SHRINKDATABASE
-------------------------------------------------------------------------------

DBCC LOGINFO;
GO

/*
Result:
RecoveryUnitId	FileId	FileSize	StartOffset	FSeqNo	Status	Parity	CreateLSN
0	            2	    2031616	    8192	    66	    0	    64	    0
0	            2	    2031616	    2039808	    68	    2	    64	    0
0	            2	    2031616	    4071424	    61	    0	    128	    0
0	            2	    2285568	    6103040	    63	    0	    128	    0
0	            2	    67108864	8388608	    64	    0	    128	    42000000395200029
*/

-------------------------------------------------------------------------------
-- 14 - Delete part of the data
-------------------------------------------------------------------------------

DELETE TOP (50000)
FROM dbo.test_table;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-03-29T20:15:12.6402170-03:00
*/

-------------------------------------------------------------------------------
-- 15 - Validate row count after delete
-------------------------------------------------------------------------------

SELECT COUNT(*) AS row_count
FROM dbo.test_table;
GO

/*
Result:
row_count
50000
*/

-------------------------------------------------------------------------------
-- 16 - Force checkpoint
-------------------------------------------------------------------------------
-- Flushes dirty pages to disk

CHECKPOINT;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-03-29T20:15:50.6130831-03:00
*/

-------------------------------------------------------------------------------
-- 17 - Shrink data file only
-------------------------------------------------------------------------------
-- ExamplesDB_FileManagement     = data file logical name
-- ExamplesDB_FileManagement_log = log file logical name

DBCC SHRINKFILE (N'ExamplesDB_FileManagement', 250);
GO

/*
Result:
DbId	FileId	CurrentSize	MinimumSize	UsedPages	EstimatedPages
12	    1	    32000	    1024	    25592	    25592
*/

-------------------------------------------------------------------------------
-- 18 - Validate database file size after SHRINKFILE
-------------------------------------------------------------------------------

SELECT
 logical_name   =   name
,type_desc
,size_mb        =   size * 8 / 1024.0 
,space_used_mb  =   FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0
,percent_used   =   CAST(FILEPROPERTY(name, 'SpaceUsed') AS DECIMAL(18,4))
                    / 
                    NULLIF(CAST(size AS DECIMAL(18,4)), 0) * 100  
FROM sys.database_files;
GO

/*
Result:
logical_name	                type_desc	size_mb	        space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    250.000000	    200.000000	    80.0000000000000000
ExamplesDB_FileManagement_log	LOG	        1032.000000	    6.726562	    0.6517986918604651
*/

-------------------------------------------------------------------------------
-- 19 - Check log structure after SHRINKFILE
-------------------------------------------------------------------------------

DBCC LOGINFO;
GO

/*
Result:
RecoveryUnitId	FileId	FileSize	StartOffset	FSeqNo	Status	Parity	CreateLSN
0	            2	    2031616	    8192	    66	    0	    64	    0
0	            2	    2031616	    2039808	    68	    0	    64	    0
0	            2	    2031616	    4071424	    69	    0	    64	    0
0	            2	    2285568	    6103040	    70	    0	    64	    0
0	            2	    67108864	8388608	    71	    0	    64	    42000000395200029
0	            2	    67108864	75497472	72	    0	    64	    71000004345600159
0	            2	    67108864	142606336	73	    0	    64	    71000007712800171
0	            2	    67108864	209715200	74	    0	    64	    71000011077600107
0	            2	    67108864	276824064	75	    0	    64	    72000001429600106
0	            2	    67108864	343932928	76	    0	    64	    72000004830400160
0	            2	    67108864	411041792	77	    0	    64	    72000008090400168
0	            2	    67108864	478150656	78	    2	    64	    72000011437600197
0	            2	    67108864	545259520	0	    0	    0	    73000001849600107
0	            2	    67108864	612368384	0	    0	    0	    73000005059200135
0	            2	    67108864	679477248	0	    0	    0	    73000008471200033
0	            2	    67108864	746586112	0	    0	    0	    73000011864000166
0	            2	    67108864	813694976	0	    0	    0	    74000002041600033
0	            2	    67108864	880803840	0	    0	    0	    74000005460800132
0	            2	    67108864	947912704	0	    0	    0	    74000008960800168
0	            2	    67108864	1015021568	0	    0	    0	    74000012128800199
*/

-------------------------------------------------------------------------------
-- 20 - Optional final SHRINKDATABASE
-------------------------------------------------------------------------------

USE master;
GO

DBCC SHRINKDATABASE (N'ExamplesDB_FileManagement', 10);
GO

/*
Result:
DbId	FileId	CurrentSize	MinimumSize	UsedPages	EstimatedPages
12	    1	    28440	    1024	    25592	    25592
12	    2	    9216	    1024	    9216	    1024
*/

-------------------------------------------------------------------------------
-- 21 - Final validation
-------------------------------------------------------------------------------

USE ExamplesDB_FileManagement;
GO

SELECT
 logical_name   =   name
,type_desc
,size_mb        =   size * 8 / 1024.0 
,space_used_mb  =   FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024.0
,percent_used   =   CAST(FILEPROPERTY(name, 'SpaceUsed') AS DECIMAL(18,4))
                    / 
                    NULLIF(CAST(size AS DECIMAL(18,4)), 0) * 100  
FROM sys.database_files;
GO

/*
Result:
logical_name	                type_desc	size_mb	    space_used_mb	percent_used
ExamplesDB_FileManagement	    ROWS	    222.187500	200.000000	    90.0140646976090014
ExamplesDB_FileManagement_log	LOG     	72.000000	0.421875	    0.5859375000000000
*/


DBCC LOGINFO;
GO

/*
Result:
RecoveryUnitId	FileId	FileSize	StartOffset	FSeqNo	Status	Parity	CreateLSN
0	            2	    2031616	    8192	    79	    2	    128	    0
0	            2	    2031616	    2039808	    68	    0	    64	    0
0	            2	    2031616	    4071424	    69	    0	    64	    0
0	            2	    2285568	    6103040	    70	    0	    64	    0
0	            2	    67108864	8388608	    71	    0	    64	    42000000395200029
*/

-------------------------------------------------------------------------------
-- 22 - Cleanup
-------------------------------------------------------------------------------

USE master;
GO

DROP DATABASE IF EXISTS ExamplesDB_FileManagement;
GO