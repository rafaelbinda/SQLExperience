/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : Q0023 - Point-in-Time Restore and Marked Transactions
Object      : Script
Description : Demonstrates point-in-time restore using STOPAT, STOPATMARK,
              STOPBEFOREMARK, and tail log backup in comparative scenarios
Notes       : 03-backup-and-restore/notes/A0026-point-in-time-restore.md
===============================================================================

INDEX
1  - Clean previous lab objects
2  - Create lab database and configure recovery model
3  - Create test table and insert initial data
4  - Execute FULL backup
5  - Generate pre-mark transactions
6  - Capture STOPAT reference time
7  - Create marked transaction
8  - Generate post-mark transaction
9  - Execute regular LOG backup
10 - Execute tail log backup
11 - Validate marked transaction history
12 - Capture logical file names from backup
13 - Restore scenario 1 - STOPAT
14 - Validate STOPAT result
15 - Restore scenario 2 - STOPATMARK
16 - Validate STOPATMARK result
17 - Restore scenario 3 - STOPBEFOREMARK
18 - Validate STOPBEFOREMARK result
19 - Optional cleanup
===============================================================================

Note:
- Point-in-Time Restore requires FULL or BULK_LOGGED recovery model
- STOPAT, STOPATMARK, and STOPBEFOREMARK are applied to a LOG restore step
- FULL and DIFFERENTIAL backups are snapshots; 
- LOG backup contains the sequence of changes required to stop at an exact point 
  in time
- Tail log backup is recommended before restore when the source database is still 
  accessible
*/

-------------------------------------------------------------------------------
-- 1 - Clean previous lab objects
-------------------------------------------------------------------------------

USE master;
GO

IF DB_ID(N'ExamplesDB_PointInTime') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ExamplesDB_PointInTime;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopAt') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopAt
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ExamplesDB_PointInTime_StopAt;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopAtMark') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopAtMark
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ExamplesDB_PointInTime_StopAtMark;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopBeforeMark') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopBeforeMark
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE ExamplesDB_PointInTime_StopBeforeMark;
END
GO

IF OBJECT_ID(N'tempdb.dbo.PointInTimeLabControl', N'U') IS NOT NULL
BEGIN
    DROP TABLE tempdb.dbo.PointInTimeLabControl;
END
GO

CREATE TABLE tempdb.dbo.PointInTimeLabControl
(
    StopAtTime DATETIME2(0) NOT NULL
);
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-22T20:37:37.3061609-03:00
*/

-------------------------------------------------------------------------------
-- 2 - Create lab database and configure recovery model
-------------------------------------------------------------------------------

CREATE DATABASE ExamplesDB_PointInTime;
GO

ALTER DATABASE ExamplesDB_PointInTime SET RECOVERY FULL;
GO

SELECT
name,
recovery_model_desc,
state_desc
FROM sys.databases
WHERE name = N'ExamplesDB_PointInTime';
GO

/*
Result:
name	                recovery_model_desc	    state_desc
ExamplesDB_PointInTime	FULL	                ONLINE
*/

-------------------------------------------------------------------------------
-- 3 - Create test table and insert initial data
-------------------------------------------------------------------------------

USE ExamplesDB_PointInTime;
GO

CREATE TABLE dbo.TestData
(
    RowID        INT IDENTITY(1,1) PRIMARY KEY,
    Description  VARCHAR(100) NOT NULL,
    CreatedAt    DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
GO

INSERT INTO dbo.TestData (Description)
VALUES (N'Initial Data');
GO

SELECT *
FROM dbo.TestData;
GO

/*
Note:
One initial row exists before any log-driven scenario starts

Result:
RowID	Description 	CreatedAt
1	    Initial Data	2026-04-22 20:39:24
*/

-------------------------------------------------------------------------------
-- 4 - Execute FULL backup
-------------------------------------------------------------------------------

BACKUP DATABASE ExamplesDB_PointInTime
TO DISK = N'C:\Backups\ExamplesDB_PointInTime.bak'
WITH
    INIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Note:
This FULL backup is the base for all restore scenarios in this lab

Result:
10 percent processed.
21 percent processed.
30 percent processed.
41 percent processed.
50 percent processed.
60 percent processed.
71 percent processed.
80 percent processed.
91 percent processed.
100 percent processed.
Processed 456 pages for database 'ExamplesDB_PointInTime', file 'ExamplesDB_PointInTime' on file 1.
Processed 2 pages for database 'ExamplesDB_PointInTime', file 'ExamplesDB_PointInTime_log' on file 1.
BACKUP DATABASE successfully processed 458 pages in 0.037 seconds (96.600 MB/sec).
Completion time: 2026-04-22T20:39:53.0320285-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Generate pre-mark transactions
-------------------------------------------------------------------------------

INSERT INTO dbo.TestData (Description)
VALUES (N'Transaction A');
GO

WAITFOR DELAY '00:00:02';

INSERT INTO dbo.TestData (Description)
VALUES (N'Transaction B');
GO

WAITFOR DELAY '00:00:02';

/*
Result:
(1 row affected)
(1 row affected)
Completion time: 2026-04-22T20:40:39.0055402-03:00
*/

-------------------------------------------------------------------------------
-- 6 - Capture STOPAT reference time
-------------------------------------------------------------------------------

INSERT INTO tempdb.dbo.PointInTimeLabControl (StopAtTime)
VALUES (SYSDATETIME());
GO

PRINT 'STOPAT reference captured after Transaction B';
GO

SELECT
StopAtTime AS StopAtCapturedTime
FROM tempdb.dbo.PointInTimeLabControl;
GO

/*
Note:
The value returned above is intentionally captured after Transaction B
STOPAT restore should include Transaction B and exclude the marked transaction

Result:
StopAtCapturedTime
2026-04-22 20:41:49
*/ 

-------------------------------------------------------------------------------
-- 7 - Create marked transaction
-------------------------------------------------------------------------------

BEGIN TRAN Deploy_V1 WITH MARK N'Deploy_V1';
    INSERT INTO dbo.TestData (Description)
    VALUES (N'Marked Transaction');
COMMIT TRAN Deploy_V1;
GO

/*
Note:
This is the transaction used by STOPATMARK and STOPBEFOREMARK

Result:
(1 row affected)
Completion time: 2026-04-22T20:44:13.1078722-03:00
*/


-------------------------------------------------------------------------------
-- 8 - Generate post-mark transaction
-------------------------------------------------------------------------------

INSERT INTO dbo.TestData (Description)
VALUES (N'Post-Mark Transaction');
GO

/*
Result:
(1 row affected)
Completion time: 2026-04-22T20:44:45.2861700-03:00
*/

SELECT *
FROM dbo.TestData
ORDER BY RowID;
GO

/*
Result:
RowID	Description	            CreatedAt
1	    Initial Data	        2026-04-22 20:39:24
2	    Transaction A	        2026-04-22 20:40:35
3	    Transaction B	        2026-04-22 20:40:37
4	    Marked Transaction	    2026-04-22 20:44:13
5	    Post-Mark Transaction	2026-04-22 20:44:45
*/

-------------------------------------------------------------------------------
-- 9 - Execute regular LOG backup
-------------------------------------------------------------------------------

BACKUP LOG ExamplesDB_PointInTime
TO DISK = N'C:\Backups\ExamplesDB_PointInTime.trn'
WITH
    INIT,
    COMPRESSION,
    STATS = 10;
GO

/*
Note:
This regular LOG backup contains the sequence used by the restore scenarios

Result:
100 percent processed.
Processed 5 pages for database 'ExamplesDB_PointInTime', file 'ExamplesDB_PointInTime_log' on file 1.
BACKUP LOG successfully processed 5 pages in 0.006 seconds (6.510 MB/sec).
Completion time: 2026-04-22T20:45:57.8038487-03:00
*/

-------------------------------------------------------------------------------
-- 10 - Execute tail log backup
-------------------------------------------------------------------------------
/*
Note
Tail log is not required for point-in-time restore, but it is critical for
complete data recovery in real-world scenarios
*/

INSERT INTO dbo.TestData (Description)
VALUES (N'Post-Bakckup Transaction');
GO

/*
Result:
(1 row affected)
Completion time: 2026-04-22T20:47:12.7861952-03:00
*/

SELECT *
FROM dbo.TestData
ORDER BY RowID;
GO

/*
Result:
RowID	Description         	    CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
4	    Marked Transaction	        2026-04-22 20:44:13
5	    Post-Mark Transaction	    2026-04-22 20:44:45
6	    Post-Bakckup Transaction	2026-04-22 20:47:13
*/

BACKUP LOG ExamplesDB_PointInTime
TO DISK = N'C:\Backups\ExamplesDB_PointInTime_Tail.trn'
WITH
    NO_TRUNCATE,
    COMPRESSION,
    STATS = 10;
GO

/*
Note:
Tail log backup captures transactions after the last regular LOG backup when needed
In this lab, it is included to demonstrate the recommended real-world flow

Result:
100 percent processed.
Processed 3 pages for database 'ExamplesDB_PointInTime', file 'ExamplesDB_PointInTime_log' on file 1.
BACKUP LOG successfully processed 3 pages in 0.006 seconds (3.906 MB/sec).
Completion time: 2026-04-22T20:48:58.2055247-03:00
*/

-------------------------------------------------------------------------------
-- 11 - Validate marked transaction history
-------------------------------------------------------------------------------
/*
Note:
Marked transactions are recorded in msdb.dbo.logmarkhistory
*/

SELECT
database_name,
mark_name,
description,
lsn,
mark_time
FROM msdb.dbo.logmarkhistory
WHERE database_name = N'ExamplesDB_PointInTime'
ORDER BY mark_time DESC;
GO

/*
Result:
database_name	        mark_name	description	lsn	                mark_time
ExamplesDB_PointInTime	Deploy_V1	Deploy_V1	39000000072800003	2026-04-22 20:44:13.083
*/

-------------------------------------------------------------------------------
-- 12 - Capture logical file names from backup
-------------------------------------------------------------------------------

DECLARE @BackupFile      NVARCHAR(4000) = N'C:\Backups\ExamplesDB_PointInTime.bak';
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
EXEC (N'RESTORE FILELISTONLY FROM DISK = ''' + @BackupFile + N'''');

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
data_logical_name	        log_logical_name
ExamplesDB_PointInTime	    ExamplesDB_PointInTime_log
*/

-------------------------------------------------------------------------------
-- 13 - Restore scenario 1 - STOPAT
-------------------------------------------------------------------------------

DECLARE @StopAtTime       DATETIME2(0);
DECLARE @DataLogicalName1 SYSNAME;
DECLARE @LogLogicalName1  SYSNAME;
DECLARE @Sql              NVARCHAR(MAX);

SELECT @StopAtTime = StopAtTime
FROM tempdb.dbo.PointInTimeLabControl;

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
EXEC (N'RESTORE FILELISTONLY FROM DISK = ''C:\Backups\ExamplesDB_PointInTime.bak''');

SELECT @DataLogicalName1 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName1 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SET @Sql = N'
RESTORE DATABASE [ExamplesDB_PointInTime_StopAt]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.bak''
WITH
    MOVE N''' + @DataLogicalName1 + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopAt.mdf'',
    MOVE N''' + @LogLogicalName1  + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopAt.ldf'',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopAt]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.trn''
WITH
    STOPAT = ''' + CONVERT(VARCHAR(19), @StopAtTime, 120) + N''',
    RECOVERY,
    STATS = 10;';

PRINT @Sql;
EXEC (@Sql);
GO

/*
Result:
(2 rows affected)

RESTORE DATABASE [ExamplesDB_PointInTime_StopAt]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.bak'
WITH
    MOVE N'ExamplesDB_PointInTime' TO N'C:\Temp\ExamplesDB_PointInTime_StopAt.mdf',
    MOVE N'ExamplesDB_PointInTime_log' TO N'C:\Temp\ExamplesDB_PointInTime_StopAt.ldf',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopAt]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.trn'
WITH
    STOPAT = '2026-04-22 20:41:49',
    RECOVERY,
    STATS = 10;
10 percent processed.
21 percent processed.
30 percent processed.
41 percent processed.
50 percent processed.
60 percent processed.
71 percent processed.
80 percent processed.
91 percent processed.
100 percent processed.
Processed 456 pages for database 'ExamplesDB_PointInTime_StopAt', file 'ExamplesDB_PointInTime' on file 1.
Processed 2 pages for database 'ExamplesDB_PointInTime_StopAt', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE DATABASE successfully processed 458 pages in 0.030 seconds (119.140 MB/sec).
100 percent processed.
Processed 0 pages for database 'ExamplesDB_PointInTime_StopAt', file 'ExamplesDB_PointInTime' on file 1.
Processed 5 pages for database 'ExamplesDB_PointInTime_StopAt', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE LOG successfully processed 5 pages in 0.002 seconds (19.531 MB/sec).
Completion time: 2026-04-22T20:52:27.1835188-03:00
*/

-------------------------------------------------------------------------------
-- 14 - Validate STOPAT result
-------------------------------------------------------------------------------

SELECT *
FROM ExamplesDB_PointInTime_StopAt.dbo.TestData
ORDER BY RowID;
GO

/*
Original data:
RowID	Description         	    CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
4	    Marked Transaction	        2026-04-22 20:44:13
5	    Post-Mark Transaction	    2026-04-22 20:44:45
6	    Post-Bakckup Transaction	2026-04-22 20:47:13


Result:
RowID	Description	                CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
*/

-------------------------------------------------------------------------------
-- 15 - Restore scenario 2 - STOPATMARK
-------------------------------------------------------------------------------

DECLARE @DataLogicalName2 SYSNAME;
DECLARE @LogLogicalName2  SYSNAME;
DECLARE @Sql2             NVARCHAR(MAX);

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
EXEC (N'RESTORE FILELISTONLY FROM DISK = ''C:\Backups\ExamplesDB_PointInTime.bak''');

SELECT @DataLogicalName2 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName2 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SET @Sql2 = N'
RESTORE DATABASE [ExamplesDB_PointInTime_StopAtMark]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.bak''
WITH
    MOVE N''' + @DataLogicalName2 + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopAtMark.mdf'',
    MOVE N''' + @LogLogicalName2  + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopAtMark.ldf'',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopAtMark]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.trn''
WITH
    STOPATMARK = ''Deploy_V1'',
    RECOVERY,
    STATS = 10;';

PRINT @Sql2;
EXEC (@Sql2);
GO

/*
Result:
(2 rows affected)

RESTORE DATABASE [ExamplesDB_PointInTime_StopAtMark]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.bak'
WITH
    MOVE N'ExamplesDB_PointInTime' TO N'C:\Temp\ExamplesDB_PointInTime_StopAtMark.mdf',
    MOVE N'ExamplesDB_PointInTime_log' TO N'C:\Temp\ExamplesDB_PointInTime_StopAtMark.ldf',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopAtMark]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.trn'
WITH
    STOPATMARK = 'Deploy_V1',
    RECOVERY,
    STATS = 10;
10 percent processed.
21 percent processed.
30 percent processed.
41 percent processed.
50 percent processed.
60 percent processed.
71 percent processed.
80 percent processed.
91 percent processed.
100 percent processed.
Processed 456 pages for database 'ExamplesDB_PointInTime_StopAtMark', file 'ExamplesDB_PointInTime' on file 1.
Processed 2 pages for database 'ExamplesDB_PointInTime_StopAtMark', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE DATABASE successfully processed 458 pages in 0.049 seconds (72.943 MB/sec).
100 percent processed.
Processed 0 pages for database 'ExamplesDB_PointInTime_StopAtMark', file 'ExamplesDB_PointInTime' on file 1.
Processed 5 pages for database 'ExamplesDB_PointInTime_StopAtMark', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE LOG successfully processed 5 pages in 0.003 seconds (13.020 MB/sec).
Completion time: 2026-04-22T20:56:10.2067638-03:00
*/

-------------------------------------------------------------------------------
-- 16 - Validate STOPATMARK result
-------------------------------------------------------------------------------

SELECT *
FROM ExamplesDB_PointInTime_StopAtMark.dbo.TestData
ORDER BY RowID;
GO

/*
Original data:
RowID	Description         	    CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
4	    Marked Transaction	        2026-04-22 20:44:13
5	    Post-Mark Transaction	    2026-04-22 20:44:45
6	    Post-Bakckup Transaction	2026-04-22 20:47:13


Result:
RowID	Description	                CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
4	    Marked Transaction	        2026-04-22 20:44:13
*/

-------------------------------------------------------------------------------
-- 17 - Restore scenario 3 - STOPBEFOREMARK
-------------------------------------------------------------------------------

DECLARE @DataLogicalName3 SYSNAME;
DECLARE @LogLogicalName3  SYSNAME;
DECLARE @Sql3             NVARCHAR(MAX);

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
EXEC (N'RESTORE FILELISTONLY FROM DISK = ''C:\Backups\ExamplesDB_PointInTime.bak''');

SELECT @DataLogicalName3 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'D';

SELECT @LogLogicalName3 = LogicalName
FROM #FileListOnly
WHERE [Type] = 'L';

SET @Sql3 = N'
RESTORE DATABASE [ExamplesDB_PointInTime_StopBeforeMark]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.bak''
WITH
    MOVE N''' + @DataLogicalName3 + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopBeforeMark.mdf'',
    MOVE N''' + @LogLogicalName3  + N''' TO N''C:\Temp\ExamplesDB_PointInTime_StopBeforeMark.ldf'',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopBeforeMark]
FROM DISK = N''C:\Backups\ExamplesDB_PointInTime.trn''
WITH
    STOPBEFOREMARK = ''Deploy_V1'',
    RECOVERY,
    STATS = 10;';

PRINT @Sql3;
EXEC (@Sql3);
GO

/*
Result:
(2 rows affected)

RESTORE DATABASE [ExamplesDB_PointInTime_StopBeforeMark]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.bak'
WITH
    MOVE N'ExamplesDB_PointInTime' TO N'C:\Temp\ExamplesDB_PointInTime_StopBeforeMark.mdf',
    MOVE N'ExamplesDB_PointInTime_log' TO N'C:\Temp\ExamplesDB_PointInTime_StopBeforeMark.ldf',
    REPLACE,
    NORECOVERY,
    STATS = 10;

RESTORE LOG [ExamplesDB_PointInTime_StopBeforeMark]
FROM DISK = N'C:\Backups\ExamplesDB_PointInTime.trn'
WITH
    STOPBEFOREMARK = 'Deploy_V1',
    RECOVERY,
    STATS = 10;
10 percent processed.
21 percent processed.
30 percent processed.
41 percent processed.
50 percent processed.
60 percent processed.
71 percent processed.
80 percent processed.
91 percent processed.
100 percent processed.
Processed 456 pages for database 'ExamplesDB_PointInTime_StopBeforeMark', file 'ExamplesDB_PointInTime' on file 1.
Processed 2 pages for database 'ExamplesDB_PointInTime_StopBeforeMark', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE DATABASE successfully processed 458 pages in 0.036 seconds (99.283 MB/sec).
100 percent processed.
Processed 0 pages for database 'ExamplesDB_PointInTime_StopBeforeMark', file 'ExamplesDB_PointInTime' on file 1.
Processed 5 pages for database 'ExamplesDB_PointInTime_StopBeforeMark', file 'ExamplesDB_PointInTime_log' on file 1.
RESTORE LOG successfully processed 5 pages in 0.003 seconds (13.020 MB/sec).
Completion time: 2026-04-22T20:57:59.2366368-03:00
*/

-------------------------------------------------------------------------------
-- 18 - Validate STOPBEFOREMARK result
-------------------------------------------------------------------------------

SELECT *
FROM ExamplesDB_PointInTime_StopBeforeMark.dbo.TestData
ORDER BY RowID;
GO

/*
Original data:
RowID	Description         	    CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
4	    Marked Transaction	        2026-04-22 20:44:13
5	    Post-Mark Transaction	    2026-04-22 20:44:45
6	    Post-Bakckup Transaction	2026-04-22 20:47:13

Result:
Excludes Marked Transaction
Excludes Post-Mark Transaction

RowID	Description	                CreatedAt
1	    Initial Data	            2026-04-22 20:39:24
2	    Transaction A	            2026-04-22 20:40:35
3	    Transaction B	            2026-04-22 20:40:37
*/

-------------------------------------------------------------------------------
-- 19 - Optional cleanup
-------------------------------------------------------------------------------
/*
Optional cleanup:
*/

USE master;
GO

IF DB_ID(N'ExamplesDB_PointInTime') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PointInTime;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopAt') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopAt
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PointInTime_StopAt;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopAtMark') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopAtMark
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PointInTime_StopAtMark;
END
GO

IF DB_ID(N'ExamplesDB_PointInTime_StopBeforeMark') IS NOT NULL
BEGIN
    ALTER DATABASE ExamplesDB_PointInTime_StopBeforeMark
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE ExamplesDB_PointInTime_StopBeforeMark;
END
GO

IF OBJECT_ID(N'tempdb.dbo.PointInTimeLabControl', N'U') IS NOT NULL
BEGIN
    DROP TABLE tempdb.dbo.PointInTimeLabControl;
END
GO