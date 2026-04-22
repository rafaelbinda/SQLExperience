/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-21
Version     : 1.0
Task        : Q0025 - Backup Device vs Backup File
Object      : Script
Description : Demonstrates the difference between Backup Device and Backup File
              using a dedicated lab database
Notes       : 03-backup-and-restore/notes/A0027-backup-device-vs-backup-file.md
===============================================================================

INDEX
1 - Validate current database state
2 - Drop existing backup device if it exists
3 - Create backup device
4 - Execute backup using backup device
5 - Execute backup using backup file
6 - Validate backup metadata
7 - Validate backup history in msdb
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

/*
Result:
database_name	            total_rows
ExamplesDB_BackupRestore	103
*/

-------------------------------------------------------------------------------
-- 2 - Drop existing backup device if it exists
-------------------------------------------------------------------------------

USE master;
GO

IF EXISTS
(
    SELECT 1
    FROM sys.backup_devices
    WHERE name = N'BackupDevice_ExamplesDB_BackupRestore'
)
BEGIN
    EXEC master.dbo.sp_dropdevice
        @logicalname = N'BackupDevice_ExamplesDB_BackupRestore';
END
GO

-------------------------------------------------------------------------------
-- 3 - Create backup device
-------------------------------------------------------------------------------
/*
Note:
- Backup Device is a logical object registered in master
- It points to a physical backup destination
*/

EXEC master.dbo.sp_addumpdevice
    @devtype = N'disk',
    @logicalname = N'BackupDevice_ExamplesDB_BackupRestore',
    @physicalname = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

SELECT
name,
physical_name,
type_desc
FROM sys.backup_devices
WHERE name = N'BackupDevice_ExamplesDB_BackupRestore';
GO

/*
Result:
name	                                physical_name	                                type_desc
BackupDevice_ExamplesDB_BackupRestore	C:\Backups\ExamplesDB_BackupRestore_Device.bak	DISK
*/

-------------------------------------------------------------------------------
-- 4 - Execute backup using backup device
-------------------------------------------------------------------------------
/*
Note:
- This backup uses the logical device name
- The physical path is resolved through metadata stored in master
*/

BACKUP DATABASE ExamplesDB_BackupRestore
TO BackupDevice_ExamplesDB_BackupRestore
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
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 560 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore' on file 1.
Processed 2 pages for database 'ExamplesDB_BackupRestore', file 'ExamplesDB_BackupRestore_log' on file 1.
BACKUP DATABASE successfully processed 562 pages in 0.034 seconds (129.021 MB/sec).
Completion time: 2026-04-21T18:31:50.8017707-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Execute backup using backup file
-------------------------------------------------------------------------------
/*
Note:
- This backup uses the physical file path directly
- No backup device registration is required
*/

BACKUP DATABASE ExamplesDB_BackupRestore
TO DISK = N'C:\Backups\ExamplesDB_BackupRestore_File.bak'
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
BACKUP DATABASE successfully processed 562 pages in 0.034 seconds (129.021 MB/sec).
Completion time: 2026-04-21T18:32:24.3778367-03:00
*/

-------------------------------------------------------------------------------
-- 6 - Validate backup metadata
-------------------------------------------------------------------------------
/*
Expected result:
- Both methods generate valid backup media
- Device-based backup and file-based backup can be inspected normally
*/

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

RESTORE HEADERONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_File.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	            DatabaseVersion	DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	            CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	            BackupFinishDate	     SortOrder	CodePage	UnicodeLocaleId	  UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName	    Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID	                            HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID                 	ForkPointLSN	RecoveryModel	DifferentialBaseLSN	DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-21 13:03:07.000	    4677632	    39000000232000001	39000000234400001	39000000232000001	39000000208000001	2026-04-21 18:31:50.000	    2026-04-21 18:31:50.000  0	        0	        1033	          196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	            NULL	                Database	            E8A1DB6B-7507-4990-9FE6-C1BEBB186620	716092	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_BackupRestore	957	            2026-04-21 13:03:07.000	    4677632	    39000000244000001	39000000246400001	39000000244000001	39000000232000001	2026-04-21 18:32:24.000	    2026-04-21 18:32:24.000  0	        0	        1033	          196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    558D3E06-CAD7-4929-8402-8C767573B6CB	E1822219-F657-450E-BBB2-9565429D318D	Latin1_General_100_CI_AI_SC_UTF8	FF4290A0-2F46-44FD-BC58-1E1D73F0602F	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        E1822219-F657-450E-BBB2-9565429D318D	NULL	        FULL	        NULL	            NULL	                Database	            F83E29AA-9335-4CE7-AF51-83BB8A14DEBC	716108	                0	        NULL	        NULL	            NULL	        NULL	                0	        MS_XPRESS
*/

RESTORE LABELONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_Device.bak';
GO

RESTORE LABELONLY
FROM DISK = N'C:\Backups\ExamplesDB_BackupRestore_File.bak';
GO

/*
Result:
MediaName	MediaSetId	                            FamilyCount	FamilySequenceNumber	MediaFamilyId	                        MediaSequenceNumber	MediaLabelPresent	MediaDescription	SoftwareName	        SoftwareVendorId	MediaDate	                MirrorCount	IsCompressed
NULL	    65C3852D-5175-42E9-B47D-AF72C1B9C0FA	1	        1	                    64F654D1-0000-0000-0000-000000000000	1	                0	                NULL	            Microsoft SQL Server	4608	            2026-04-21 18:31:50.000	    1	        1
NULL	    D192ED65-D28F-409A-8611-E9DFD801F53A	1	        1	                    783765EE-0000-0000-0000-000000000000	1	                0	                NULL	            Microsoft SQL Server	4608	            2026-04-21 18:32:24.000	    1	        1
*/
-------------------------------------------------------------------------------
-- 7 - Validate backup history in msdb
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
bmf.physical_device_name,
bs.user_name
FROM msdb.dbo.backupset bs
INNER JOIN msdb.dbo.backupmediafamily bmf
    ON bs.media_set_id = bmf.media_set_id
WHERE bs.database_name = N'ExamplesDB_BackupRestore'
AND bmf.physical_device_name IN
(
    N'C:\Backups\ExamplesDB_BackupRestore_Device.bak',
    N'C:\Backups\ExamplesDB_BackupRestore_File.bak'
)
ORDER BY bs.backup_finish_date DESC;
GO

/*
Result:
database_name	            backup_start_date	      backup_finish_date	    type	backup_type_desc	physical_device_name	                        user_name
ExamplesDB_BackupRestore	2026-04-21 18:32:24.000	  2026-04-21 18:32:24.000	D	    FULL	            C:\Backups\ExamplesDB_BackupRestore_File.bak	SRVSQLSERVER\USRSQLSERVER
ExamplesDB_BackupRestore	2026-04-21 18:31:50.000	  2026-04-21 18:31:50.000	D	    FULL	            C:\Backups\ExamplesDB_BackupRestore_Device.bak	SRVSQLSERVER\USRSQLSERVER
*/