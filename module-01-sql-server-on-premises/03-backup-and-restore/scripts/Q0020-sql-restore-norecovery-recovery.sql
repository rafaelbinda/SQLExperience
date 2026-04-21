/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-21
Version     : 1.0
Task        : Q0020 - Restore with NORECOVERY / RECOVERY
Object      : Script
Description : Demonstrates restore sequence using FULL, DIFFERENTIAL and LOG
              backups with NORECOVERY and RECOVERY options
Notes       : 03-backup-and-restore/notes/A0024-recovery-and-restore-fundamentals.md
===============================================================================

INDEX
1 - Validate backup content
2 - Simulate failure
3 - Restore FULL (NORECOVERY)
4 - Restore DIFFERENTIAL (NORECOVERY)
5 - Restore LOG (RECOVERY)
6 - Validate restored data
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Validate backup content
-------------------------------------------------------------------------------

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate 	        BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	                BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	    TimeZone	        CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    4481024	    39000000099200001	39000000101600001	39000000099200001	39000000055200001	2026-04-20 21:36:58.000	    2026-04-20 21:36:58.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        NULL	                NULL	                                Database	            EFC40A6A-7BDA-4AED-895E-43FBCA3CA616	634810	                0	        NULL	        NULL	            NULL	        NULL	                    120	                MS_XPRESS
NULL	    NULL	            5	        NULL	        1	        2	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    1003520	    39000000112000001	39000000114400001	39000000112000001	39000000099200001	2026-04-20 21:38:20.000	    2026-04-20 21:38:20.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	2560	D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        39000000099200001	    EFC40A6A-7BDA-4AED-895E-43FBCA3CA616	Database Differential	1BAAA715-C8ED-4415-AB88-3B3CEDC95E12	95581	                0	        NULL	        NULL	            NULL	        NULL	                    64	                MS_XPRESS
NULL	    NULL	            2	        NULL	        1	        3	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-20 19:46:40.000	    339968	    39000000055200001	39000000115200001	39000000112000001	39000000099200001	2026-04-20 21:40:46.000	    2026-04-20 21:40:46.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    D6550A01-9E62-4EBD-8A35-F762A5ED9FC7	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        1	            0	                    0	            0	        FF4290A0-2F46-44FD-BC58-1E1D73F0602F	NULL	        FULL	        NULL	                NULL	                                Transaction Log	        4956B312-803E-400F-A2A4-CEF0E36FB8A8	40361	                0	        NULL	        NULL	            NULL	        2026-04-20 21:40:13.000     -12             	MS_XPRESS
*/


-------------------------------------------------------------------------------
-- 2 - Simulate failure
-------------------------------------------------------------------------------

USE master;
GO

IF DB_ID(N'ExamplesDB_BackupRestore') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_BackupRestore SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_BackupRestore;
END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T11:12:45.4223728-03:00
*/

-------------------------------------------------------------------------------
-- 3 - Restore FULL (NORECOVERY)
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
RESTORE DATABASE successfully processed 538 pages in 0.032 seconds (131.225 MB/sec).
Completion time: 2026-04-21T11:13:08.2582869-03:00
*/

-------------------------------------------------------------------------------
-- 4 - Restore DIFFERENTIAL (NORECOVERY)
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
RESTORE DATABASE successfully processed 114 pages in 0.024 seconds (36.946 MB/sec).
Completion time: 2026-04-21T11:13:26.6072896-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Restore LOG (RECOVERY)
-------------------------------------------------------------------------------

RESTORE LOG ExamplesDB_BackupRestore
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore.bak'
WITH 
    FILE = 3,
    RECOVERY,
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
RESTORE LOG successfully processed 38 pages in 0.003 seconds (97.656 MB/sec).
Completion time: 2026-04-21T11:13:51.3458374-03:00

*/

-------------------------------------------------------------------------------
-- 6 - Validate restored data
-------------------------------------------------------------------------------

USE ExamplesDB_BackupRestore;
GO

SELECT COUNT(*) AS TotalRows FROM dbo.Customers;
GO

/*
Result:
TotalRows
100
*/

-------------------------------------------------------------------------------
-- Additional validation
-------------------------------------------------------------------------------

SELECT 
name,
state_desc,
recovery_model_desc
FROM sys.databases
WHERE name = N'ExamplesDB_BackupRestore';
GO

/*
Result:
name	                    state_desc	recovery_model_desc
ExamplesDB_BackupRestore	ONLINE	    FULL
*/