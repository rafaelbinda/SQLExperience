/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-06
Version     : 2.0
Task        : INST-Q0011 - Resource Governor Overview
Object      : Script
Description : The queries below are useful for quick investigation of
              Resource Governor configuration, setup workflow, pools,
              workload groups, classifier function, session classification,
              active requests, and current resource usage
Notes       : notes/A0021-resource-governor.md
Examples    : scripts/Q0018-resource-governor-configuration.sql
===============================================================================

INDEX
1  - Check whether Resource Governor is enabled
2  - Create Resource Pools
3  - Create Workload Groups
4  - Create the Classifier Function
5  - Bind the Classifier Function to Resource Governor
6  - Apply the Resource Governor configuration
7  - Validate session classification
8  - View classifier function
9  - View stored Resource Pool configuration
10 - View Resource Pool affinity
11 - View current Resource Pool state and statistics
12 - View stored Workload Group configuration
13 - View current Workload Group state and statistics
14 - View user sessions classified by Resource Governor
15 - View active requests by workload group and pool
16 - View memory usage by pool
17 - View sessions assigned to the default group
18 - Cleanup
===============================================================================
*/

USE master
GO

-------------------------------------------------------------------------------
-- 1 - Check whether Resource Governor is enabled
-------------------------------------------------------------------------------
/*
→ Shows whether Resource Governor is currently enabled and whether a classifier
  function is configured
*/
SELECT
is_enabled,
classifier_function_id
FROM sys.resource_governor_configuration
GO

-------------------------------------------------------------------------------
-- 2 - Create Resource Pools
-------------------------------------------------------------------------------
/*
→ Creates dedicated Resource Pools for OLTP and reporting workloads
→ These pools define CPU and memory boundaries for each type of session
*/

CREATE RESOURCE POOL Pool_OLTP
WITH
(
    MAX_CPU_PERCENT = 70,
    MAX_MEMORY_PERCENT = 70
)
GO

CREATE RESOURCE POOL Pool_Report
WITH
(
    MAX_CPU_PERCENT = 30,
    MAX_MEMORY_PERCENT = 30
)
GO

-------------------------------------------------------------------------------
-- 3 - Create Workload Groups
-------------------------------------------------------------------------------
/*
→ Creates Workload Groups and maps them to their respective Resource Pools
*/

CREATE WORKLOAD GROUP Group_OLTP
USING Pool_OLTP
GO

CREATE WORKLOAD GROUP Group_Report
USING Pool_Report
GO

-------------------------------------------------------------------------------
-- 4 - Create the Classifier Function
-------------------------------------------------------------------------------
/*
→ This function classifies incoming sessions based on the application name

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

-------------------------------------------------------------------------------
-- 5 - Bind the Classifier Function to Resource Governor
-------------------------------------------------------------------------------
/*
→ Associates the classifier function with Resource Governor
*/
ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION = dbo.Classify_Workload)
GO

-------------------------------------------------------------------------------
-- 6 - Apply the Resource Governor configuration
-------------------------------------------------------------------------------
/*
→ Applies the configuration so that new connections can be classified
*/
ALTER RESOURCE GOVERNOR RECONFIGURE
GO

SELECT
is_enabled,
classifier_function_id
FROM sys.resource_governor_configuration
GO

-------------------------------------------------------------------------------
-- 7 - Validate session classification
-------------------------------------------------------------------------------
-- Shows pools, groups, and user sessions currently assigned by Resource Governor

--View Resource Pools currently available in Resource Governor
SELECT *
FROM sys.dm_resource_governor_resource_pools
GO

-- View Workload Groups currently available in Resource Governor
SELECT *
FROM sys.dm_resource_governor_workload_groups
GO

--View user sessions and their assigned Workload Group and Resource Pool
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

-------------------------------------------------------------------------------
-- 8 - View classifier function
-------------------------------------------------------------------------------
/*
→ Shows the classifier function currently associated with Resource Governor,
  including its definition when one is configured
*/
SELECT
o.object_id,
s.name AS schema_name,
o.name AS function_name,
o.type_desc,
o.create_date,
o.modify_date,
sm.definition
FROM sys.objects AS o
INNER JOIN sys.schemas AS s
    ON o.schema_id = s.schema_id
LEFT JOIN sys.sql_modules AS sm
    ON o.object_id = sm.object_id
WHERE o.object_id =
(
    SELECT classifier_function_id
    FROM sys.resource_governor_configuration
)
GO

-------------------------------------------------------------------------------
-- 9 - View stored Resource Pool configuration
-------------------------------------------------------------------------------
/*
→ Shows the stored metadata for each Resource Pool
→ This is useful to review configured CPU, memory, and IOPS settings
*/
SELECT
pool_id,
name,
min_cpu_percent,
max_cpu_percent,
min_memory_percent,
max_memory_percent,
cap_cpu_percent,
min_iops_per_volume,
max_iops_per_volume
FROM sys.resource_governor_resource_pools
ORDER BY pool_id
GO

-------------------------------------------------------------------------------
-- 10 - View Resource Pool affinity
-------------------------------------------------------------------------------
/*
→ Shows CPU and NUMA affinity for Resource Pools

Note:
→ Pools using automatic affinity may not return rows here, because there is no
  explicit affinity mapping to display
→ Resource Pool Affinity allows binding a Resource Pool to specific CPUs
  (schedulers) or NUMA nodes

Purpose:
- Control where the workload runs (CPU isolation)
- Reduce contention between workloads

Important:
- Not commonly used in most environments
- SQL Server handles CPU scheduling automatically by default
- Incorrect configuration may reduce performance

Summary:
→ Resource Governor controls how much resource is used, Affinity controls where
  the workload runs
*/
SELECT
pool_id,
processor_group,
scheduler_mask
FROM sys.dm_resource_governor_resource_pool_affinity
ORDER BY pool_id, processor_group
GO

-------------------------------------------------------------------------------
-- 11 - View current Resource Pool state and statistics
-------------------------------------------------------------------------------
/*
→ Shows the current in-memory state and cumulative statistics for each pool
→ Useful for reviewing current CPU usage, memory grant activity, and memory limits
*/
SELECT
pool_id,
name,
statistics_start_time,
total_cpu_usage_ms,
total_memgrant_count,
total_memgrant_timeout_count,
active_memgrant_count,
active_memgrant_kb,
used_memory_kb,
target_memory_kb,
max_memory_kb,
out_of_memory_count,
min_cpu_percent,
max_cpu_percent,
min_memory_percent,
max_memory_percent,
cap_cpu_percent
FROM sys.dm_resource_governor_resource_pools
ORDER BY pool_id
GO

-------------------------------------------------------------------------------
-- 12 - View stored Workload Group configuration
-------------------------------------------------------------------------------
/*
→ Shows the stored configuration of each Workload Group and the pool to which
  it belongs
*/
SELECT
wg.group_id,
wg.name,
rp.name AS pool_name,
wg.importance,
wg.request_max_memory_grant_percent,
wg.request_max_cpu_time_sec,
wg.request_memory_grant_timeout_sec,
wg.max_dop,
wg.group_max_requests
FROM sys.resource_governor_workload_groups AS wg
INNER JOIN sys.resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
ORDER BY wg.group_id
GO

-------------------------------------------------------------------------------
-- 13 - View current Workload Group state and statistics
-------------------------------------------------------------------------------
/*
→ Shows current Workload Group statistics, including requests, CPU usage,
  queue activity, and memory grant behavior
*/
SELECT
wg.group_id,
wg.name,
rp.name AS pool_name,
wg.statistics_start_time,
wg.total_request_count,
wg.total_queued_request_count,
wg.active_request_count,
wg.queued_request_count,
wg.total_cpu_limit_violation_count,
wg.total_cpu_usage_ms,
wg.max_request_cpu_time_ms,
wg.total_reduced_memgrant_count,
wg.max_request_grant_memory_kb,
wg.importance,
wg.request_max_memory_grant_percent,
wg.request_max_cpu_time_sec,
wg.request_memory_grant_timeout_sec,
wg.max_dop,
wg.group_max_requests
FROM sys.dm_resource_governor_workload_groups AS wg
INNER JOIN sys.dm_resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
ORDER BY wg.group_id
GO

-------------------------------------------------------------------------------
-- 14 - View user sessions classified by Resource Governor
-------------------------------------------------------------------------------
/*
→ Shows user sessions and the Workload Group and Resource Pool to which each
  session is currently assigned
*/
SELECT
s.session_id,
s.login_name,
s.host_name,
s.program_name,
s.status,
s.cpu_time,
s.memory_usage,
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

-------------------------------------------------------------------------------
-- 15 - View active requests by workload group and pool
-------------------------------------------------------------------------------
/*
→ Shows currently running requests together with wait information, CPU time,
  reads, writes, and the assigned group and pool
*/
SELECT
s.session_id,
s.login_name,
s.host_name,
s.program_name,
r.status,
r.command,
r.cpu_time,
r.total_elapsed_time,
r.logical_reads,
r.reads,
r.writes,
r.wait_type,
r.wait_time,
wg.name AS workload_group,
rp.name AS resource_pool
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_exec_requests AS r
    ON s.session_id = r.session_id
INNER JOIN sys.dm_resource_governor_workload_groups AS wg
    ON s.group_id = wg.group_id
INNER JOIN sys.dm_resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
WHERE s.is_user_process = 1
ORDER BY r.cpu_time DESC, r.total_elapsed_time DESC
GO

-------------------------------------------------------------------------------
-- 16 - View memory usage by pool
-------------------------------------------------------------------------------
/*
→ Shows memory-related values per pool in KB and MB
→ Useful to compare current usage against target and maximum values
*/
SELECT
name,
used_memory_kb,
CAST(used_memory_kb / 1024.0 AS DECIMAL(18,2)) AS used_memory_mb,
target_memory_kb,
CAST(target_memory_kb / 1024.0 AS DECIMAL(18,2)) AS target_memory_mb,
max_memory_kb,
CAST(max_memory_kb / 1024.0 AS DECIMAL(18,2)) AS max_memory_mb,
active_memgrant_kb,
CAST(active_memgrant_kb / 1024.0 AS DECIMAL(18,2)) AS active_memgrant_mb
FROM sys.dm_resource_governor_resource_pools
ORDER BY used_memory_kb DESC
GO

-------------------------------------------------------------------------------
-- 17 - View sessions assigned to the default group
-------------------------------------------------------------------------------
/*
→ Sessions assigned to the default group are usually connections that did not
  match any custom rule in the classifier function
*/
SELECT
s.session_id,
s.login_name,
s.host_name,
s.program_name,
wg.name AS workload_group,
rp.name AS resource_pool
FROM sys.dm_exec_sessions AS s
INNER JOIN sys.dm_resource_governor_workload_groups AS wg
    ON s.group_id = wg.group_id
INNER JOIN sys.dm_resource_governor_resource_pools AS rp
    ON wg.pool_id = rp.pool_id
WHERE s.is_user_process = 1
  AND wg.name = 'default'
ORDER BY s.session_id
GO

-------------------------------------------------------------------------------
-- 18 - Cleanup
-------------------------------------------------------------------------------
/*
→ Removes the configuration created in this script
*/
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
