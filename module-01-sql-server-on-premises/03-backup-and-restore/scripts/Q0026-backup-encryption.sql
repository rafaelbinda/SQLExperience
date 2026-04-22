/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-21
Version     : 1.0
Task        : Q0026 - Backup Encryption
Object      : Script
Description : Demonstrates backup encryption and restore scenarios, including
              failure without certificate and successful restore after import
Notes       : 03-backup-and-restore/notes/A0029-backup-encryption.md
===============================================================================

INDEX
1 - Create (or validate) master key in master
2 - Create certificate for backup encryption
3 - Export certificate
4 - Execute encrypted backup (ExamplesDB_TDE)
5 - Validate backup structure (HEADERONLY / FILELISTONLY)
6 - Capture logical file names from backup
7 - Restore without certificate (expected failure)
8 - Import certificate on target instance
9 - Restore with certificate (success)
10 - Validate restored database
11 - Optional cleanup
===============================================================================

Note:
- Backup encryption is independent from TDE
- A database encrypted with TDE does not guarantee encrypted backups
- Backup encryption must be explicitly configured

Reference:
01-sql-server-on-premisses/notes/A0020-transparent-data-encryption.md
01-sql-server-on-premisses/scripts/Q0017-sql-transparent-data-encryption.sql
*/

-------------------------------------------------------------------------------
-- 1 - Create (or validate) master key in master
-------------------------------------------------------------------------------

USE master;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword_2026!';
END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T18:47:53.1664864-03:00
*/

-------------------------------------------------------------------------------
-- 2 - Create certificate for backup encryption
-------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'BackupEncCert'
)
BEGIN
    CREATE CERTIFICATE BackupEncCert
    WITH SUBJECT = 'Certificate for Backup Encryption',
         EXPIRY_DATE = '99991231';
END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T18:48:07.5399400-03:00
*/

-------------------------------------------------------------------------------
-- 3 - Export certificate (CRITICAL for restore in another instance)
-------------------------------------------------------------------------------

BACKUP CERTIFICATE BackupEncCert
TO FILE = 'C:\Certificados\BackupEncCert.cer'
WITH PRIVATE KEY
(
    FILE = 'C:\Certificados\BackupEncCert.key',
    ENCRYPTION BY PASSWORD = 'StrongPassword_2026!'
);
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T18:49:56.3594467-03:00
*/

-------------------------------------------------------------------------------
-- 4 - Execute encrypted backup (ExamplesDB_TDE)
-------------------------------------------------------------------------------

BACKUP DATABASE ExamplesDB_TDE
TO DISK = 'C:\Backups\ExamplesDB_TDE_Encrypted.bak'
WITH
    INIT,
    COMPRESSION,
    STATS = 10,
    ENCRYPTION
    (
        ALGORITHM = AES_256,
        SERVER CERTIFICATE = BackupEncCert
    );
GO

/*
Result:
10 percent processed.
20 percent processed.
30 percent processed.
40 percent processed.
50 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 151088 pages for database 'ExamplesDB_TDE', file 'ExamplesDB_TDE' on file 1.
Processed 2 pages for database 'ExamplesDB_TDE', file 'ExamplesDB_TDE_log' on file 1.
BACKUP DATABASE successfully processed 151090 pages in 2.850 seconds (414.170 MB/sec).
Completion time: 2026-04-21T19:04:42.1124969-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Validate backup structure (HEADERONLY / FILELISTONLY)
-------------------------------------------------------------------------------

RESTORE HEADERONLY
FROM DISK = 'C:\Backups\ExamplesDB_TDE_Encrypted.bak';
GO

/*
Result:
BackupName	BackupDescription	BackupType	ExpirationDate	Compressed	Position	DeviceType	UserName	                ServerName	    DatabaseName	DatabaseVersion	  DatabaseCreationDate	    BackupSize	FirstLSN	        LastLSN	                CheckpointLSN	    DatabaseBackupLSN	BackupStartDate	         BackupFinishDate	        SortOrder	CodePage	UnicodeLocaleId	  UnicodeComparisonStyle	CompatibilityLevel	SoftwareVendorId	SoftwareVersionMajor	SoftwareVersionMinor	SoftwareVersionBuild	MachineName 	Flags	BindingID	                            RecoveryForkID	                        Collation	                        FamilyGUID                          	HasBulkLoggedData	IsSnapshot	IsReadOnly	IsSingleUser	HasBackupChecksums	IsDamaged	BeginsLogChain	HasIncompleteMetaData	IsForceOffline	IsCopyOnly	FirstRecoveryForkID	                    ForkPointLSN	RecoveryModel	DifferentialBaseLSN	  DifferentialBaseGUID	BackupTypeDescription	BackupSetGUID	                        CompressedBackupSize	Containment	KeyAlgorithm	EncryptorThumbprint	                        EncryptorType	LastValidRestoreTime	TimeZone	CompressionAlgorithm
NULL	    NULL	            1	        NULL	        1	        1	        2	        SRVSQLSERVER\USRSQLSERVER	SRVSQLSERVER	ExamplesDB_TDE	957	              2026-04-21 18:51:41.000	1239516160	105000009304000001	105000009306400001	    105000009304000001	0	                2026-04-21 19:04:38.000  2026-04-21 19:04:42.000	0	        0	        1033	          196611	                160	                4608	            16	                    0	                    4236	                SRVSQLSERVER	512	    C60710A9-410A-45CE-9AAC-03F77D4277C4	F0885264-E095-4B57-AC4F-294B3793EA76	Latin1_General_100_CI_AI_SC_UTF8	F0885264-E095-4B57-AC4F-294B3793EA76	0	                0	        0	        0	            0	                0	        0	            0	                    0	            0	        F0885264-E095-4B57-AC4F-294B3793EA76	NULL	        FULL	        NULL	              NULL	                Database	            7ECFD8E1-AAB0-45B8-830A-843FAFD3B0C0	15523456	            0	        aes_256     	0x29E78C2A370C94D8B176476AE91147A2A1BC694D	CERTIFICATE	    NULL	                48	        MS_XPRESS
*/

RESTORE FILELISTONLY
FROM DISK = 'C:\Backups\ExamplesDB_TDE_Encrypted.bak';
GO

/*
Result:
LogicalName	        PhysicalName	                            Type	FileGroupName	Size	    MaxSize	        FileId	CreateLSN	DropLSN	  UniqueId	                            ReadOnlyLSN	    ReadWriteLSN	BackupSizeInBytes	SourceBlockSize	FileGroupId	LogGroupGUID	DifferentialBaseLSN	DifferentialBaseGUID	                IsReadOnly	IsPresent	TDEThumbprint	SnapshotUrl
ExamplesDB_TDE	    C:\MSSQLSERVER\DATA\ExamplesDB_TDE.mdf	    D	    PRIMARY	        1283457024	35184372080640	1	    0	        0	      34DBBDC3-0EC4-4331-8EFD-2CF3613ECEC9	0	            0	            1237581824	        4096	        1	        NULL	        0	                00000000-0000-0000-0000-000000000000	0	        1	        NULL	        NULL
ExamplesDB_TDE_log	C:\MSSQLSERVER\LOG\ExamplesDB_TDE_log.ldf	L	    NULL	        612368384	2199023255552	2	    0	        0	      B0B12913-BBFE-497B-8367-E42F18DA87F3	0	            0	            0	                4096	        0	        NULL	        0	                00000000-0000-0000-0000-000000000000	0	        1	        NULL	        NULL
*/

-------------------------------------------------------------------------------
-- 6 - Capture logical file names from backup
-------------------------------------------------------------------------------

DECLARE @BackupFile      NVARCHAR(4000) = N'C:\Backups\ExamplesDB_TDE_Encrypted.bak';
DECLARE @DataLogicalName SYSNAME;
DECLARE @LogLogicalName  SYSNAME;

IF OBJECT_ID('tempdb..#FileListOnly') IS NOT NULL
    DROP TABLE #FileListOnly;

CREATE TABLE #FileListOnly
(
    LogicalName           NVARCHAR(128),
    PhysicalName          NVARCHAR(260),
    [Type]                CHAR(1),
    FileGroupName         NVARCHAR(128),
    [Size]                NUMERIC(20,0),
    MaxSize               NUMERIC(20,0),
    FileId                BIGINT,
    CreateLSN             NUMERIC(25,0),
    DropLSN               NUMERIC(25,0),
    UniqueId              UNIQUEIDENTIFIER,
    ReadOnlyLSN           NUMERIC(25,0),
    ReadWriteLSN          NUMERIC(25,0),
    BackupSizeInBytes     BIGINT,
    SourceBlockSize       INT,
    FileGroupId           INT,
    LogGroupGUID          UNIQUEIDENTIFIER,
    DifferentialBaseLSN   NUMERIC(25,0),
    DifferentialBaseGUID  UNIQUEIDENTIFIER,
    IsReadOnly            BIT,
    IsPresent             BIT,
    TDEThumbprint         VARBINARY(32),
    SnapshotURL           NVARCHAR(360)
);

INSERT INTO #FileListOnly
EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + '''');

SELECT @DataLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SELECT
@DataLogicalName AS data_logical_name,
@LogLogicalName  AS log_logical_name;
GO

/*
Result:
data_logical_name	log_logical_name
ExamplesDB_TDE	    ExamplesDB_TDE_log
*/

-------------------------------------------------------------------------------
-- 7 - Restore without certificate (expected failure)
-------------------------------------------------------------------------------

/*
Expected error:

Msg 33111
Cannot find server certificate with thumbprint...
*/

-------------------------------------------------------------------------------
-- 7 - Restore without certificate (expected failure)
-------------------------------------------------------------------------------
/*
Note:
- This test only fails if the backup certificate is NOT present in master
- The original certificate used by backup encryption must exist on the target
  instance to allow restore
*/

-- Remove certificate to simulate restore on an instance without the backup certificate
IF EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'BackupEncCert'
)
BEGIN
    DROP CERTIFICATE BackupEncCert;
END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T19:24:56.3157669-03:00
*/

DECLARE @BackupFile      NVARCHAR(4000) = N'C:\Backups\ExamplesDB_TDE_Encrypted.bak';
DECLARE @TargetDataFile  NVARCHAR(4000) = N'C:\Temp\ExamplesDB_TDE_Test.mdf';
DECLARE @TargetLogFile   NVARCHAR(4000) = N'C:\Temp\ExamplesDB_TDE_Test.ldf';
DECLARE @RestoreDbName   SYSNAME        = N'ExamplesDB_TDE_Test';
DECLARE @DataLogicalName SYSNAME;
DECLARE @LogLogicalName  SYSNAME;
DECLARE @Sql             NVARCHAR(MAX);

IF OBJECT_ID('tempdb..#FileListOnly') IS NOT NULL
    DROP TABLE #FileListOnly;

CREATE TABLE #FileListOnly
(
    LogicalName           NVARCHAR(128),
    PhysicalName          NVARCHAR(260),
    [Type]                CHAR(1),
    FileGroupName         NVARCHAR(128),
    [Size]                NUMERIC(20,0),
    MaxSize               NUMERIC(20,0),
    FileId                BIGINT,
    CreateLSN             NUMERIC(25,0),
    DropLSN               NUMERIC(25,0),
    UniqueId              UNIQUEIDENTIFIER,
    ReadOnlyLSN           NUMERIC(25,0),
    ReadWriteLSN          NUMERIC(25,0),
    BackupSizeInBytes     BIGINT,
    SourceBlockSize       INT,
    FileGroupId           INT,
    LogGroupGUID          UNIQUEIDENTIFIER,
    DifferentialBaseLSN   NUMERIC(25,0),
    DifferentialBaseGUID  UNIQUEIDENTIFIER,
    IsReadOnly            BIT,
    IsPresent             BIT,
    TDEThumbprint         VARBINARY(32),
    SnapshotURL           NVARCHAR(360)
);

INSERT INTO #FileListOnly
EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + '''');

SELECT @DataLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SET @Sql = N'
RESTORE DATABASE [' + @RestoreDbName + N']
FROM DISK = N''' + @BackupFile + N'''
WITH
    MOVE N''' + @DataLogicalName + N''' TO N''' + @TargetDataFile + N''',
    MOVE N''' + @LogLogicalName  + N''' TO N''' + @TargetLogFile  + N''',
    STATS = 10;';

PRINT @Sql;
EXEC (@Sql);
GO

/*
Result:
Msg 33111, Level 16, State 3, Line 266
Cannot find server certificate with thumbprint '0x29E78C2A370C94D8B176476AE91147A2A1BC694D'.
Msg 3013, Level 16, State 1, Line 266
RESTORE FILELIST is terminating abnormally.
(0 rows affected)
Completion time: 2026-04-21T19:25:29.1734426-03:00
*/

-------------------------------------------------------------------------------
-- 8 - Import certificate on target instance
-------------------------------------------------------------------------------

IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword_2026!';
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'BackupEncCert'
)
BEGIN
    CREATE CERTIFICATE BackupEncCert
    FROM FILE = 'C:\Certificados\BackupEncCert.cer'
    WITH PRIVATE KEY
    (
        FILE = 'C:\Certificados\BackupEncCert.key',
        DECRYPTION BY PASSWORD = 'StrongPassword_2026!'
    );
END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-21T19:26:10.4551248-03:00
*/

-------------------------------------------------------------------------------
-- 9 - Restore with certificate (success)
-------------------------------------------------------------------------------

DECLARE @BackupFile      NVARCHAR(4000) = N'C:\Backups\ExamplesDB_TDE_Encrypted.bak';
DECLARE @TargetDataFile  NVARCHAR(4000) = N'C:\Temp\ExamplesDB_TDE_Test.mdf';
DECLARE @TargetLogFile   NVARCHAR(4000) = N'C:\Temp\ExamplesDB_TDE_Test.ldf';
DECLARE @RestoreDbName   SYSNAME        = N'ExamplesDB_TDE_Test';
DECLARE @DataLogicalName SYSNAME;
DECLARE @LogLogicalName  SYSNAME;
DECLARE @Sql             NVARCHAR(MAX);

IF OBJECT_ID('tempdb..#FileListOnly') IS NOT NULL
    DROP TABLE #FileListOnly;

CREATE TABLE #FileListOnly
(
    LogicalName           NVARCHAR(128),
    PhysicalName          NVARCHAR(260),
    [Type]                CHAR(1),
    FileGroupName         NVARCHAR(128),
    [Size]                NUMERIC(20,0),
    MaxSize               NUMERIC(20,0),
    FileId                BIGINT,
    CreateLSN             NUMERIC(25,0),
    DropLSN               NUMERIC(25,0),
    UniqueId              UNIQUEIDENTIFIER,
    ReadOnlyLSN           NUMERIC(25,0),
    ReadWriteLSN          NUMERIC(25,0),
    BackupSizeInBytes     BIGINT,
    SourceBlockSize       INT,
    FileGroupId           INT,
    LogGroupGUID          UNIQUEIDENTIFIER,
    DifferentialBaseLSN   NUMERIC(25,0),
    DifferentialBaseGUID  UNIQUEIDENTIFIER,
    IsReadOnly            BIT,
    IsPresent             BIT,
    TDEThumbprint         VARBINARY(32),
    SnapshotURL           NVARCHAR(360)
);

INSERT INTO #FileListOnly
EXEC ('RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + '''');

SELECT @DataLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SET @Sql = N'
RESTORE DATABASE [' + @RestoreDbName + N']
FROM DISK = N''' + @BackupFile + N'''
WITH
    MOVE N''' + @DataLogicalName + N''' TO N''' + @TargetDataFile + N''',
    MOVE N''' + @LogLogicalName  + N''' TO N''' + @TargetLogFile  + N''',
    STATS = 10,
    RECOVERY;';

PRINT @Sql;
EXEC (@Sql);
GO

/*
Result:
(2 rows affected)
RESTORE DATABASE [ExamplesDB_TDE_Test]
FROM DISK = N'C:\Backups\ExamplesDB_TDE_Encrypted.bak'
WITH
    MOVE N'ExamplesDB_TDE' TO N'C:\Temp\ExamplesDB_TDE_Test.mdf',
    MOVE N'ExamplesDB_TDE_log' TO N'C:\Temp\ExamplesDB_TDE_Test.ldf',
    STATS = 10,
    RECOVERY;
10 percent processed.
20 percent processed.
30 percent processed.
40 percent processed.
50 percent processed.
60 percent processed.
70 percent processed.
80 percent processed.
90 percent processed.
100 percent processed.
Processed 151088 pages for database 'ExamplesDB_TDE_Test', file 'ExamplesDB_TDE' on file 1.
Processed 2 pages for database 'ExamplesDB_TDE_Test', file 'ExamplesDB_TDE_log' on file 1.
RESTORE DATABASE successfully processed 151090 pages in 4.031 seconds (292.827 MB/sec).
*/

-------------------------------------------------------------------------------
-- 10 - Validate restored database
-------------------------------------------------------------------------------

SELECT
name,
state_desc,
recovery_model_desc
FROM sys.databases
WHERE name = N'ExamplesDB_TDE_Test';
GO

/*
Result:
name	            state_desc	recovery_model_desc
ExamplesDB_TDE_Test	ONLINE	    FULL
*/

-------------------------------------------------------------------------------
-- 11 - Optional cleanup
-------------------------------------------------------------------------------

USE master;
GO
IF DB_ID(N'ExamplesDB_TDE_Test') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_TDE_Test SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_TDE_Test;
END
GO

