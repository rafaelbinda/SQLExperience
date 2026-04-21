/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-21
Version     : 1.0
Task        : Q0023 - Backup Options and Media Handling
Object      : Script
Description : Demonstrates backup options and media behavior including FORMAT,
              INIT, NOINIT, COMPRESSION, CHECKSUM and COPY_ONLY
Notes       : 03-backup-and-restore/notes/A0026-backup-options-and-media-handling.md
===============================================================================

INDEX
1 - Validate current database state
2 - Backup with FORMAT
3 - Backup with INIT
4 - Backup with NOINIT
5 - Validate backup sets in media
6 - Backup with COMPRESSION and CHECKSUM
7 - Backup with COPY_ONLY
8 - Validate backup history in msdb
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Validate current database state
-------------------------------------------------------------------------------

USE ExamplesDB_BackupRestore;
GO

SELECT 
DB_NAME() AS database_name,
COUNT(*) AS total_rows
FROM dbo.Customers;
GO

/*Result:
database_name	            total_rows
ExamplesDB_BackupRestore	103
*/

-------------------------------------------------------------------------------
-- 2 - Backup with FORMAT
-------------------------------------------------------------------------------
/*
Note:
- FORMAT recreates the backup media
- Previous backup sets in this file are removed
*/
BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak'
WITH
    FORMAT,
    COMPRESSION,
    STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
40 percent processed.
51 percent processed.
61 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 562 pages in 0.037 seconds (118.559 MB/sec).
Completion time: 2026-04-21T16:40:36.9111636-03:00
*/

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4677632	    39000000172000001	39000000174400001	39000000172000001	39000000099200001	2026-04-21 16:40:36.000	    2026-04-21 16:40:36.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            9A642968-76F5-4C1B-B8FB-6CA4D2663034	715480	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
*/


-------------------------------------------------------------------------------
-- 3 - Backup with INIT
-------------------------------------------------------------------------------

/*
Note:
- INIT overwrites existing backup sets
- Media structure is preserved
*/

BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak'
WITH
    INIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
41 percent processed.
51 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 562 pages in 0.037 seconds (118.559 MB/sec).
Completion time: 2026-04-21T16:59:41.6108050-03:00
*/

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak';
GO

/*
First Result (with FORMAT):
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4677632	    39000000172000001	39000000174400001	39000000172000001	39000000099200001	2026-04-21 16:40:36.000	    2026-04-21 16:40:36.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            9A642968-76F5-4C1B-B8FB-6CA4D2663034	715480	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS

Second Result (with INIT):  
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4673536	    39000000184000001	39000000186400001	39000000184000001	39000000172000001	2026-04-21 16:59:41.000	    2026-04-21 16:59:41.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512 	558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            54C81B84-F422-4D85-9B91-653907FB68F2	711405	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
*/


-------------------------------------------------------------------------------
-- 4 - Backup with NOINIT
-------------------------------------------------------------------------------
/*
Note:
- NOINIT appends a new backup set to the existing media
- File size grows as new backup sets are added
*/

BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak'
WITH
    NOINIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
41 percent processed.
51 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 2.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 2.
BACKUP DATABASE successfully processed 562 pages in 0.035 seconds (125.334 MB/sec).
Completion time: 2026-04-21T17:04:22.6172485-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Validate backup sets in media
-------------------------------------------------------------------------------

/*
Expected result:
- HEADERONLY returns one row per backup set
- LABELONLY returns media-level information
*/

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak';
GO

/*
First Result (with FORMAT):
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4677632	    39000000172000001	39000000174400001	39000000172000001	39000000099200001	2026-04-21 16:40:36.000	    2026-04-21 16:40:36.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            9A642968-76F5-4C1B-B8FB-6CA4D2663034	715480	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS

Second Result (with INIT/Position 1) and Third Result (with NOINIT/Position 2):  
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4673536	    39000000184000001	39000000186400001	39000000184000001	39000000172000001	2026-04-21 16:59:41.000	    2026-04-21 16:59:41.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512 	558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            54C81B84-F422-4D85-9B91-653907FB68F2	711405	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
NULL	    NULL	            1	        NULL	        1	        2	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4673536	    39000000196000001	39000000198400001	39000000196000001	39000000184000001	2026-04-21 17:04:22.000	    2026-04-21 17:04:22.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            72483FB3-51D8-4F96-9A02-8583C4AAF561	711345	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS

*/
 

RESTORE LABELONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak';
GO

/*
Result:
MediaName	MediaSetId	                            FamilyCount	FamilySequenceNumber	MediaFamilyId	                        MediaSequenceNumber	MediaLabelPresent	MediaDescription	SoftwareName	        SoftwareVendorId	MediaDate	                MirrorCount  IsCompressed
NULL	    3B36876C-A9CD-4458-B324-D895BA4EC754	1	        1	                    209EB181-0000-0000-0000-000000000000	1	                0	                NULL	            Microsoft SQL Server	4608	            2026-04-21 16:40:36.000	    1	         1
*/

-------------------------------------------------------------------------------
-- 6 - Backup with COMPRESSION and CHECKSUM
-------------------------------------------------------------------------------
/*
Note:
- COMPRESSION reduces backup size and I/O
- CHECKSUM adds validation during backup execution
*/

BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling_Checksum.bak'
WITH
    INIT,
    COMPRESSION,
    CHECKSUM,
    STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
41 percent processed.
51 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 562 pages in 0.035 seconds (125.334 MB/sec).
Completion time: 2026-04-21T17:09:23.6508520-03:00
*/

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling_Checksum.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	DatabaseCreationDate	BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate             BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-21 13:03:07.000	4677632 	39000000208000001	39000000210400001	39000000208000001	39000000196000001	2026-04-21 17:09:23.000	    2026-04-21 17:09:23.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	528	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            1	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	            NULL	                Database	            89AF2EE6-D4ED-4528-888F-A84C56F0092F	715774	                0	        NULL	        NULL	            NULL	        NULL	                32	        MS_XPRESS


Compare data
Second Result   (with INIT) 
Third Result    (with NOINIT)
Fourth Result   (with CHECKSUM

    BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	    UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
2º  NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4673536	    39000000184000001	39000000186400001	39000000184000001	39000000172000001	2026-04-21 16:59:41.000	    2026-04-21 16:59:41.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512 	558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            54C81B84-F422-4D85-9B91-653907FB68F2	711405	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
3º  NULL	    NULL	            1	        NULL	        1	        2	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4673536	    39000000196000001	39000000198400001	39000000196000001	39000000184000001	2026-04-21 17:04:22.000	    2026-04-21 17:04:22.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            72483FB3-51D8-4F96-9A02-8583C4AAF561	711345	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
4º  NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4677632 	39000000208000001	39000000210400001	39000000208000001	39000000196000001	2026-04-21 17:09:23.000	    2026-04-21 17:09:23.000	    0	        0	        1033	            196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	528	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            1	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            89AF2EE6-D4ED-4528-888F-A84C56F0092F	715774	                0	        NULL	        NULL	            NULL	        NULL	                32	        MS_XPRESS

*/

-------------------------------------------------------------------------------
-- 7 - Backup with COPY_ONLY
-------------------------------------------------------------------------------

/*
Note:
- COPY_ONLY does not change the differential base
- Useful for ad-hoc backup scenarios
*/


BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling_CopyOnly.bak'
WITH
    COPY_ONLY,
    INIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
41 percent processed.
51 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 562 pages in 0.032 seconds (137.084 MB/sec).
Completion time: 2026-04-21T17:15:52.0673998-03:00
*/


RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_MediaHandling_CopyOnly.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	    DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID                 	ForkPointLSN	RecoveryModel	DifferentialBaseLSN	    DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	                2026-04-21 13:03:07.000	    4677632	    39000000218400001	39000000220800001	39000000218400001	39000000208000001	2026-04-21 17:15:52.000	    2026-04-21 17:15:52.000	    0	        0	        1033	        196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	1536	558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            1	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	                NULL	                Database	            683F2049-C563-4B20-A90A-53FEE305FE9B	715839	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
*/

-------------------------------------------------------------------------------
-- 8 - Validate backup history in msdb
-------------------------------------------------------------------------------

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
bs.is_copy_only,
bs.user_name,
bmf.physical_device_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'ExamplesDB_BackupRestore'
ORDER BY bs.backup_finish_date DESC;
GO

/*
Result:
database_name	            backup_start_date	        backup_finish_date          type	backup_type_desc	is_copy_only	user_name	                physical_device_name
ExamplesDB_BackupRestore	2026-04-21 17:15:52.000	    2026-04-21 17:15:52.000	    D	    FULL	            1	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_MediaHandling_CopyOnly.bak
ExamplesDB_BackupRestore	2026-04-21 17:09:23.000	    2026-04-21 17:09:23.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_MediaHandling_Checksum.bak
ExamplesDB_BackupRestore	2026-04-21 17:04:22.000	    2026-04-21 17:04:22.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak
ExamplesDB_BackupRestore	2026-04-21 16:59:41.000	    2026-04-21 16:59:41.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak
ExamplesDB_BackupRestore	2026-04-21 16:40:36.000	    2026-04-21 16:40:36.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_MediaHandling.bak
ExamplesDB_BackupRestore	2026-04-21 13:02:33.000	    2026-04-21 13:02:33.000	    L	    LOG	                1	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_Tail.trn
ExamplesDB_BackupRestore	2026-04-21 11:35:36.000	    2026-04-21 11:35:36.000	    L	    LOG	                1	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore_Tail.trn
ExamplesDB_BackupRestore	2026-04-20 21:40:46.000	    2026-04-20 21:40:46.000	    L	    LOG	                0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore.bak
ExamplesDB_BackupRestore	2026-04-20 21:38:20.000	    2026-04-20 21:38:20.000	    I	    DIFFERENTIAL	    0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore.bak
ExamplesDB_BackupRestore	2026-04-20 21:36:58.000	    2026-04-20 21:36:58.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore.bak
ExamplesDB_BackupRestore	2026-04-20 19:55:31.000	    2026-04-20 19:55:31.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore.bak
ExamplesDB_BackupRestore	2026-04-20 19:43:10.000	    2026-04-20 19:43:10.000	    D	    FULL	            0	            SRVSQLSERVER\USRSQLSERVER	C:\Backups\ExamplesDB_BackupRestore.bak
*/

