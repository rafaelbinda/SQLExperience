/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-06
Version     : 1.0
Task        : Q0018 - Resource Governor Configuration and Workload Control
Object      : Script
Description : Examples demonstrating how to configure Resource Governor,
              create resource pools, workload groups, classifier function,
              validate session classification, monitor resource usage,
              and remove the configuration
Notes       : notes/A0021-resource-governor.md
Examples    : 
===============================================================================
*/

USE master
GO

/*===============================================================================
INDEX
1  - Check whether Resource Governor is enabled
2  - Create Resource Pools
3  - Create Workload Groups
4  - Create the Classifier Function
5  - Bind the Classifier Function to Resource Governor
6  - Apply the Resource Governor configuration
7  - Step by step test using ExamplesDB
8  - Validate session classification
9 - Adjusting Resource Pool Limits (Stress Scenario)
10 - Monitor behavior after applying limits
11 - Monitor Resource Pool usage
12 - Important behavior notes
13 - Cleanup
===============================================================================*/

-------------------------------------------------------------------------------
-- 1 - Check whether Resource Governor is enabled
-------------------------------------------------------------------------------
SELECT is_enabled
FROM sys.resource_governor_configuration
GO

/*
0 = Disabled
1 = Enabled

Result:
is_enabled
0
*/

-------------------------------------------------------------------------------
-- 2 - Create Resource Pools
-------------------------------------------------------------------------------
-- Pool for OLTP workload
CREATE RESOURCE POOL Pool_OLTP
WITH
(
    MAX_CPU_PERCENT = 70,
    MAX_MEMORY_PERCENT = 70
)
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:53:09.8005966-03:00
*/

-- Pool for reporting workload
CREATE RESOURCE POOL Pool_Report
WITH
(
    MAX_CPU_PERCENT = 30,
    MAX_MEMORY_PERCENT = 30
)
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:53:23.8420857-03:00
*/

-------------------------------------------------------------------------------
-- 3 - Create Workload Groups
-------------------------------------------------------------------------------
CREATE WORKLOAD GROUP Group_OLTP
USING Pool_OLTP
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:53:40.2287550-03:00
*/

CREATE WORKLOAD GROUP Group_Report
USING Pool_Report
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:53:54.5759035-03:00
*/

-------------------------------------------------------------------------------
-- 4 - Create the Classifier Function
-------------------------------------------------------------------------------
/*
This function classifies incoming sessions based on the application name.

Examples:
- Connections using Application Name=OLTP     -> Group_OLTP
- Connections using Application Name=Report   -> Group_Report
- Any other connection                        -> default group
*/
CREATE OR ALTER FUNCTION dbo.Classify_Workload()
RETURNS sysname
WITH SCHEMABINDING
AS
BEGIN

    DECLARE @GroupName sysname

    IF APP_NAME() LIKE '%Report%'
        SET @GroupName = 'Group_Report'
    ELSE IF APP_NAME() LIKE '%OLTP%'
        SET @GroupName = 'Group_OLTP'
    ELSE
        SET @GroupName = 'default'

    RETURN @GroupName

END
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:54:24.2110815-03:00
*/

-------------------------------------------------------------------------------
-- 5 - Bind the Classifier Function to Resource Governor
-------------------------------------------------------------------------------
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION = dbo.Classify_Workload)
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-06T20:54:42.8623474-03:00
*/

-------------------------------------------------------------------------------
-- 6 - Apply the Resource Governor configuration
-------------------------------------------------------------------------------
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

SELECT is_enabled
FROM sys.resource_governor_configuration
GO

/*
Result:
is_enabled
    1
*/

-------------------------------------------------------------------------------
-- 7 - Step by step test using ExamplesDB
-------------------------------------------------------------------------------
/*
Step 1
→ Open a new SSMS connection using: Application Name=OLTP
→ Then run the query below in that session

IMPORTANT:
→ The connection string must be copied as a SINGLE LINE (INLINE)
→ If it is broken into multiple lines, SSMS will not accept it

Before:
Data Source=localhost;Integrated Security=True;Persist Security Info=False;Pooling=False;
MultipleActiveResultSets=False;Encrypt=False;TrustServerCertificate=True;
Application Name="SQL Server Management Studio";Command Timeout=0

After:
Data Source=localhost;Initial Catalog=ExamplesDB;Integrated Security=True;
Persist Security Info=False;Pooling=False;MultipleActiveResultSets=False;
Encrypt=False;TrustServerCertificate=True;Application Name=OLTP;Command Timeout=0
*/

USE ExamplesDB
GO

SELECT TOP (1000)
o.object_id,
o.name,
o.type_desc,
o.create_date
FROM sys.objects AS o
ORDER BY o.name
GO

/*
Step 2
→ Open another SSMS connection using: Application Name=Report
→ Then run the query below in that session
*/

USE ExamplesDB
GO

SELECT
o.type_desc,
COUNT(*) AS total_objects
FROM sys.objects AS o
GROUP BY o.type_desc
ORDER BY total_objects DESC
GO

/*
Step 3
→ Keep both sessions open and validate how they were classified using the queries 
  in section 8
*/

-------------------------------------------------------------------------------
-- 8 - Validate session classification
-------------------------------------------------------------------------------
-- View Resource Pools
SELECT *
FROM sys.dm_resource_governor_resource_pools
GO

/*
Result:
pool_id	    name	        statistics_start_time
1	        internal	    2026-04-05 20:06:16.533
2	        default	        2026-04-05 20:06:16.533
258	        Pool_OLTP	    2026-04-06 20:55:32.647
259	        Pool_Report	    2026-04-06 20:55:32.647
*/


-- View Workload Groups
SELECT *
FROM sys.dm_resource_governor_workload_groups
GO

/*
Result:
group_id	name	        pool_id	    external_pool_id	statistics_start_time
1	        internal	    1	        2	                2026-04-05 20:06:16.533
2	        default	        2	        2	                2026-04-05 20:06:16.533
256	        Group_OLTP	    258	        2	                2026-04-06 20:55:32.647
257	        Group_Report	259	        2	                2026-04-06 20:55:32.647
*/


-- View user sessions and their assigned group and pool
SELECT
s.session_id,
s.login_name,
s.program_name,
wg.name AS workload_group,
rp.name AS resource_pool
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_resource_governor_workload_groups AS wg
    ON s.group_id = wg.group_id
INNER JOIN sys.dm_resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
WHERE s.is_user_process = 1
ORDER BY s.session_id
GO

/*

SSMS = Microsoft SQL Server Management Studio
Result:
session_id	login_name	                program_name	                    workload_group	        resource_pool
51	        SRVSQLSERVER\USRSQLSERVER	SQL Server Management Studio	    default	                default
52	        NT SERVICE\SQLTELEMETRY	    SQLServerCEIP	                    default	                default
56	        SRVSQLSERVER\USRSQLSERVER	SSMS - Query	                    default	                default
57	        SRVSQLSERVER\USRSQLSERVER	SQL Server Management Studio	    default	                default
58	        SRVSQLSERVER\USRSQLSERVER	SSMS - Transact-SQL IntelliSense	default	                default
60	        SRVSQLSERVER\USRSQLSERVER	OLTP	                            Group_OLTP	            Pool_OLTP
61	        SRVSQLSERVER\USRSQLSERVER	OLTP	                            Group_OLTP	            Pool_OLTP
62	        SRVSQLSERVER\USRSQLSERVER	Report	                            Group_Report	        Pool_Report
*/

-------------------------------------------------------------------------------
-- 9 - Adjusting Resource Pool Limits (Stress Scenario)
-------------------------------------------------------------------------------
/*
→ In this step, I reduce the available resources for the reporting workload
  to simulate a constrained environment and make the Resource Governor behavior
  more visible

IMPORTANT:
→ Resource Governor does NOT terminate sessions or drop connections, it only 
  limits resource consumption (CPU and memory)

Expected behavior after applying this change:
- Report sessions become slower
- Increased wait times (runnable / suspended states)
- OLTP workload continues to run with higher priority
*/

ALTER RESOURCE POOL Pool_Report
WITH
(
    MAX_CPU_PERCENT = 5,
    MAX_MEMORY_PERCENT = 5
)
GO

ALTER RESOURCE GOVERNOR RECONFIGURE
GO

-------------------------------------------------------------------------------
-- 10 - Monitor behavior after applying limits
-------------------------------------------------------------------------------
/*
→ Run heavy queries again in Report sessions and observe:
- Slower execution time
- Higher CPU wait
- Sessions may remain in RUNNABLE or SUSPENDED state

→ At the same time, OLTP sessions should continue to execute normally
*/

SELECT
s.session_id,
s.login_name,
s.program_name,
r.status,
r.cpu_time,
r.total_elapsed_time,
r.logical_reads,
wg.name AS workload_group,
rp.name AS resource_pool
FROM sys.dm_exec_sessions AS s
JOIN sys.dm_exec_requests AS r
    ON s.session_id = r.session_id
JOIN sys.dm_resource_governor_workload_groups AS wg
    ON s.group_id = wg.group_id
JOIN sys.dm_resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
WHERE s.is_user_process = 1
ORDER BY r.cpu_time DESC
GO

/*
Result:
session_id	login_name	                program_name	status	    cpu_time	total_elapsed_time	logical_reads	workload_group	resource_pool
81	        SRVSQLSERVER\USRSQLSERVER	Report	        runnable	1469	    11460	            19070	        Group_Report	Pool_Report
59	        SRVSQLSERVER\USRSQLSERVER	Report	        suspended	1168	    8869	            13564	        Group_Report	Pool_Report
62	        SRVSQLSERVER\USRSQLSERVER	Report	        running	    967	        6872	            10580	        Group_Report	Pool_Report
60	        SRVSQLSERVER\USRSQLSERVER	OLTP	        running 	1	        1	                0	            Group_OLTP	    Pool_OLTP
*/

-------------------------------------------------------------------------------
-- 11 - Monitor Resource Pool usage
-------------------------------------------------------------------------------
SELECT
name,
total_cpu_usage_ms,
used_memory_kb 
FROM sys.dm_resource_governor_resource_pools
GO

/*
Result:
name	        total_cpu_usage_ms	used_memory_kb
internal	    89718	            348688
default	        98221	            114848
Pool_OLTP	    29	                22176
Pool_Report	    27135	            7720
*/

-------------------------------------------------------------------------------
-- 12 - Important behavior notes
-------------------------------------------------------------------------------
/*
Resource Governor behavior summary:

- It does NOT kill sessions
- It does NOT cancel queries
- It does NOT drop connections

Instead, it:
- Limits CPU and memory usage
- Slows down execution under contention
- Prioritizes workloads based on configuration

This makes it a workload management tool, not a session control tool.
*/

-------------------------------------------------------------------------------
-- 13 - Cleanup
-------------------------------------------------------------------------------
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION = NULL)
GO

ALTER RESOURCE GOVERNOR RECONFIGURE
GO

DROP FUNCTION dbo.Classify_Workload
GO

DROP WORKLOAD GROUP Group_OLTP
GO

DROP WORKLOAD GROUP Group_Report
GO

DROP RESOURCE POOL Pool_OLTP
GO

DROP RESOURCE POOL Pool_Report
GO

ALTER RESOURCE GOVERNOR DISABLE
GO