/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-20
Version     : 1.0
Task        : Q0019 - Backup FULL / DIFFERENTIAL / LOG
Object      : Script
Description : Demonstrates the execution and relationship between FULL,
              DIFFERENTIAL and LOG backups using a dedicated lab database
Notes       : 03-backup-and-restore/notes/A0023-backup-fundamentals.md
===============================================================================

INDEX
1 - Create lab database
2 - Create test table
3 - Backup FULL
4 - Backup DIFFERENTIAL
5 - Backup LOG
6 - Validate backup structure
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Create lab database
-------------------------------------------------------------------------------

USE master;
GO

IF DB_ID(N'ExamplesDB_BackupRestore') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_BackupRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_BackupRestore;
END
GO

CREATE DATABASE ExamplesDB_BackupRestore;
GO

ALTER DATABASE ExamplesDB_BackupRestore SET RECOVERY FULL;
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-20T19:46:21.3198409-03:00
*/

-------------------------------------------------------------------------------
-- 2 - Create test table
-------------------------------------------------------------------------------

USE ExamplesDB_BackupRestore;
GO
 
CREATE TABLE dbo.Customers
(
    CustID INT IDENTITY PRIMARY KEY,
    CustName   VARCHAR(50),
    CustPhone  VARCHAR(20)
);
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-20T19:49:46.7278567-03:00
*/

-------------------------------------------------------------------------------
-- 3 - Backup FULL
-------------------------------------------------------------------------------

INSERT INTO dbo.Customers (CustName, CustPhone)
SELECT TOP 50
c.FirstName + ' ' + c.LastName,
ISNULL(p.PhoneNumber, 'N/A')
FROM AdventureWorks.Person.Person c
INNER JOIN AdventureWorks.Person.PersonPhone p
ON c.BusinessEntityID = p.BusinessEntityID
WHERE SUBSTRING(c.FirstName,1,1) = 'A'
ORDER BY 1 ASC

/*
Result:
(50 rows affected)
Completion time: 2026-04-20T19:55:01.9667419-03:00
*/
 
BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    FORMAT,
    COMPRESSION,
    STATS = 10;
GO

/*
Note: 50 rows protected by FULL

Result:
10 percent processed.
20 percent processed.
30 percent processed.
40 percent processed.
50 percent processed.
60 percent processed.
70 percent processed.
81 percent processed.
91 percent processed.
100 percent processed.
Processed 488 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 490 pages in 0.037 seconds (103.357 MB/sec).
Completion time: 2026-04-20T19:55:31.4159373-03:00
*/

-------------------------------------------------------------------------------
-- 4 - Backup DIFFERENTIAL
-------------------------------------------------------------------------------

INSERT INTO dbo.Customers (CustName, CustPhone)
SELECT TOP 30
c.FirstName + ' ' + c.LastName,
ISNULL(p.PhoneNumber, 'N/A')
FROM AdventureWorks.Person.Person c
INNER JOIN AdventureWorks.Person.PersonPhone p
ON c.BusinessEntityID = p.BusinessEntityID
WHERE SUBSTRING(c.FirstName,1,1) = 'B'
ORDER BY 1 ASC

/*Result:
(30 rows affected)
Completion time: 2026-04-20T21:37:44.6221944-03:00
*/

SELECT * FROM dbo.Customers;
GO

BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    NOINIT,
    DIFFERENTIAL,
    COMPRESSION,
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
BACKUP DATABASE WITH DIFFERENTIAL successfully processed 114 pages in 0.025 seconds (35.468 MB/sec).
Completion time: 2026-04-20T21:38:20.6667075-03:00
*/

/*
State:
- Client "A" between 1 and 50 → FULL
- Client "B" between 51 and 80 → DIFFERENTIAL
*/

-------------------------------------------------------------------------------
-- 5 - Backup LOG
-------------------------------------------------------------------------------

INSERT INTO dbo.Customers (CustName, CustPhone)
SELECT TOP 20
c.FirstName + ' ' + c.LastName,
ISNULL(p.PhoneNumber, 'N/A')
FROM AdventureWorks.Person.Person c
INNER JOIN AdventureWorks.Person.PersonPhone p
ON c.BusinessEntityID = p.BusinessEntityID
WHERE SUBSTRING(c.FirstName,1,1) = 'C'
ORDER BY 1 ASC

/*
Result:
(20 rows affected)
Completion time: 2026-04-20T21:40:13.3202896-03:00
*/

SELECT * FROM dbo.Customers;
GO

BACKUP LOG ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    NOINIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Result:
21 percent processed.
42 percent processed.
64 percent processed.
85 percent processed.
100 percent processed.
Processed 38 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 3.
BACKUP LOG successfully processed 38 pages in 0.013 seconds (22.536 MB/sec).
Completion time: 2026-04-20T21:40:46.4242280-03:00
*/

/*
State:
- Client "A" between 1 and 50   → FULL
- Client "B" between 51 and 80  → DIFFERENTIAL
- Client "C" between 81 and 100 → LOG
*/

-------------------------------------------------------------------------------
-- 6 - Validate backup structure
-------------------------------------------------------------------------------

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak';
GO

/*
BackupType reference:
1 = FULL
2 = Transaction log
4 = File
5 = Differential database
6 = Differential file
7 = Partial
8 = Differential partial

Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate 	        BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	                BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	    TimeZone	        CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    4481024	    39000000099200001	39000000101600001	39000000099200001	39000000055200001	2026-04-20 21:36:58.000	    2026-04-20 21:36:58.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        NULL	                NULL	                                Database	            EFC40A6A-7BDA-4AED-895E-43FBCA3CA616	634810	                0	        NULL	        NULL	            NULL	        NULL	                    120	                MS_XPRESS
NULL	    NULL	            5	        NULL	        1	        2	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    1003520	    39000000112000001	39000000114400001	39000000112000001	39000000099200001	2026-04-20 21:38:20.000	    2026-04-20 21:38:20.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	2560	D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        39000000099200001	    EFC40A6A-7BDA-4AED-895E-43FBCA3CA616	Database Differential	1BAAA715-C8ED-4415-AB88-3B3CEDC95E12	95581	                0	        NULL	        NULL	            NULL	        NULL	                    64	                MS_XPRESS
NULL	    NULL	            2	        NULL	        1	        3	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    339968	    39000000055200001	39000000115200001	39000000112000001	39000000099200001	2026-04-20 21:40:46.000	    2026-04-20 21:40:46.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        1	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        NULL	                NULL	                                Transaction Log	        4956B312-803E-400F-A2A4-CEF0E36FB8A8	40361	                0	        NULL	        NULL	            NULL	        2026-04-20 21:40:13.000     -12             	MS_XPRESS
*/

RESTORE FILELISTONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak';
GO

/*
Result:
LogicalName	                    PhysicalName	                                        Type    FileGroupName	Size	MaxSize	        FileId	CreateLSN	DropLSN	    UniqueId	                            ReadOnlyLSN	ReadWriteLSN	BackupSizeInBytes	SourceBlockSize	FileGroupId	LogGroupGUID	DifferentialBaseLSN	DifferentialBaseGUID	                IsReadOnly	IsPresent	TDEThumbprint	SnapshotUrl
ExamplesDB_BackupRestore	    C:\MSSQLSERVER\DATA\ExamplesDB_BackupRestore.mdf	    D	    PRIMARY	        8388608	35184372080640	1	    0	        0	        828874B2-526C-48EF-A302-04267C5C359D	0	        0	            4259840	            4096	        1	        NULL	        39000000055200001	E15CF42B-979A-452E-BBFE-72E26B671E6A	0	        1	        NULL	        NULL
ExamplesDB_BackupRestore_log	C:\MSSQLSERVER\LOG\ExamplesDB_BackupRestore_log.ldf	    L	     NULL	        8388608	2199023255552	2	    0	        0	        99AB8AEF-5FB2-4DE0-AB03-2F1191A41765	0	        0	            0	                4096	        0	        NULL	        0	                00000000-0000-0000-0000-000000000000	0	        1	        NULL	        NULL
*/