/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-01
Version     : 1.0
Task        : Q0003 - TempDB and File Configuration
Object      : Script
Description : Examples demonstrating Instant File Initialization verification,
              TempDB file validation, size standardization, autogrowth
              configuration and TempDB space usage
Notes       : notes/A0004-database-storage-and-performance.md
===============================================================================

INDEX
1 - Verify Instant File Initialization (IFI)
2 - Inspect current TempDB files
3 - Standardize TempDB data files
4 - Adjust TempDB log file
5 - Validate TempDB configuration after changes
6 - Simulate TempDB usage with temporary object
6.1 - Check TempDB space usage before test
6.2 - Insert rows into temporary object
6.3 - Check rows inserted
6.4 - Check TempDB space usage after test
7 - Clean up temporary object
===============================================================================
*/

USE master
GO

-------------------------------------------------------------------------------
-- 1 - Verify Instant File Initialization (IFI)
-------------------------------------------------------------------------------

SELECT 
servicename,
service_account,
instant_file_initialization_enabled
FROM sys.dm_server_services
GO

/*
Result:
servicename	                                            service_account	            instant_file_initialization_enabled
SQL Server (MSSQLSERVER)	                            .\USRSQLSERVER	                            Y
SQL Server Agent (MSSQLSERVER)	                        .\USRSQLSERVER	                            N
SQL Full-text Filter Daemon Launcher  (MSSQLSERVER)	    NT Service\MSSQLFDLauncher	                N
*/

-------------------------------------------------------------------------------
-- 2 - Inspect current TempDB files
-------------------------------------------------------------------------------

USE tempdb
GO

SELECT 
name,
type_desc,
physical_name,
size * 8 / 1024 AS size_mb,
growth,
is_percent_growth
FROM sys.database_files
ORDER BY type_desc, name
GO

/*
Result:
name	type_desc	physical_name	                                size_mb	growth	is_percent_growth
templog	LOG	        C:\MSSQLSERVER\TEMPDB\LOG\templog.ldf	        100	    12800	        0
temp2	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_2.ndf	100	    12800	        0
temp3	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_3.ndf	100	    12800	        0
temp4	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_4.ndf	100	    12800	        0
tempdev	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb.mdf	        100	    12800	        0

*/

-------------------------------------------------------------------------------
-- 3 - Standardize TempDB data files
-------------------------------------------------------------------------------

USE master
GO

/*
Example:
Adjusting TempDB data files to the same size and FILEGROWTH

Important:
Review logical names and values before running in another environment

Note:
→ The TempDB configuration has been adjusted as part of this hands-on
→ The new values for SIZE and FILEGROWTH will be intentionally maintained after 
  the test
-------------------------------------------------------------------------------
*/ 

ALTER DATABASE tempdb 
MODIFY FILE 
(
    NAME = tempdev,
    SIZE = 256MB,
    FILEGROWTH = 64MB
)
GO

ALTER DATABASE tempdb 
MODIFY FILE 
(
    NAME = temp2,
    SIZE = 256MB,
    FILEGROWTH = 64MB
)
GO

ALTER DATABASE tempdb 
MODIFY FILE 
(
    NAME = temp3,
    SIZE = 256MB,
    FILEGROWTH = 64MB
)
GO

ALTER DATABASE tempdb 
MODIFY FILE 
(
    NAME = temp4,
    SIZE = 256MB,
    FILEGROWTH = 64MB
)
GO

-------------------------------------------------------------------------------
-- 4 - Adjust TempDB log file
-------------------------------------------------------------------------------

/*
Example:
Adjusting TempDB log file size and FILEGROWTH
*/

ALTER DATABASE tempdb 
MODIFY FILE 
(
    NAME = templog,
    SIZE = 128MB,
    FILEGROWTH = 64MB
)
GO

-------------------------------------------------------------------------------
-- 5 - Validate TempDB configuration after changes
-------------------------------------------------------------------------------

USE tempdb
GO

SELECT 
name,
type_desc,
physical_name,
size * 8 / 1024 AS size_mb,
growth,
is_percent_growth
FROM sys.database_files
ORDER BY type_desc, name
GO

/*
Result:
name	type_desc	physical_name	                                size_mb	    growth	is_percent_growth
templog	LOG	        C:\MSSQLSERVER\TEMPDB\LOG\templog.ldf	        128	        8192	        0
temp2	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_2.ndf	256	        8192	        0
temp3	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_3.ndf	256	        8192	        0
temp4	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb_mssql_4.ndf	256	        8192	        0
tempdev	ROWS	    C:\MSSQLSERVER\TEMPDB\DATA\tempdb.mdf	        256	        8192	        0
*/

-------------------------------------------------------------------------------
-- 6 - Simulate TempDB usage with temporary object
-------------------------------------------------------------------------------

-- 6.1 - Check TempDB space usage before test

SELECT 
SUM(user_object_reserved_page_count) * 8 / 1024 AS user_objects_mb,
SUM(internal_object_reserved_page_count) * 8 / 1024 AS internal_objects_mb,
SUM(version_store_reserved_page_count) * 8 / 1024 AS version_store_mb,
SUM(unallocated_extent_page_count) * 8 / 1024 AS free_space_mb
FROM sys.dm_db_file_space_usage
GO

/*
Result:
user_objects_mb         2
internal_objects_mb     0
version_store_mb        0
free_space_mb        1019
*/

CREATE TABLE #TempTest
(
    id INT IDENTITY(1,1),
    data_1 VARCHAR(100),
    data_2 VARCHAR(100),
    data_3 VARCHAR(100),
    data_4 VARCHAR(100)
)

-- 6.2 - Insert rows into temporary object

INSERT INTO #TempTest (data_1, data_2, data_3, data_4)
SELECT TOP 3000000
    'TempDB Test Data 1',
    'TempDB Test Data 2',
    'TempDB Test Data 3',
    'TempDB Test Data 4'
FROM sys.objects a
CROSS JOIN sys.objects b
CROSS JOIN sys.objects c
GO

-- 6.3 - Check rows inserted
SELECT COUNT(*) AS rows_inserted
FROM #TempTest
GO

/*
Note:
→ The final number of inserted rows depends on the number of rows available
  in sys.objects in the current environment

Result:
rows_inserted
2048383
*/

-- 6.4 - Check TempDB space usage after test

SELECT 
SUM(user_object_reserved_page_count) * 8 / 1024 AS user_objects_mb,
SUM(internal_object_reserved_page_count) * 8 / 1024 AS internal_objects_mb,
SUM(version_store_reserved_page_count) * 8 / 1024 AS version_store_mb,
SUM(unallocated_extent_page_count) * 8 / 1024 AS free_space_mb
FROM sys.dm_db_file_space_usage
GO

/*
Result:
user_objects_mb       190
internal_objects_mb     0
version_store_mb        0
free_space_mb         831
*/

-------------------------------------------------------------------------------
-- 7 - Clean up temporary object
-------------------------------------------------------------------------------

DROP TABLE #TempTest
GO 