/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-02
Version     : 1.0
Task        : INST-Q0009 - Database I/O and Performance Metrics
Object      : Script
Description : Queries for inspecting database file I/O activity, TempDB usage,
              and wait statistics related to storage performance in SQL Server
Notes       : notes/A0019-database-storage-and-performance.md
===============================================================================

INDEX
1 - Database file I/O statistics
2 - TempDB session space usage
3 - I/O related wait statistics
===============================================================================
*/

SET NOCOUNT ON;
GO

-------------------------------------------------------------------------------
-- 1 - Database file I/O statistics
-------------------------------------------------------------------------------
/*
→ Returns cumulative I/O statistics per database file since SQL Server service
  start 
→ Useful for identifying read/write activity and accumulated stall time
*/

USE master;
GO

SELECT
database_name               = DB_NAME(vfs.database_id),
file_id                     = vfs.file_id,
logical_file_name           = mf.name,
file_type                   = mf.type_desc,
physical_name               = mf.physical_name,
num_of_reads                = vfs.num_of_reads,
num_of_writes               = vfs.num_of_writes,
num_of_bytes_read_mb        = CAST(vfs.num_of_bytes_read / 1024.0 / 1024.0 AS DECIMAL(18,2)),
num_of_bytes_written_mb     = CAST(vfs.num_of_bytes_written / 1024.0 / 1024.0 AS DECIMAL(18,2)),
io_stall_read_ms            = vfs.io_stall_read_ms,
io_stall_write_ms           = vfs.io_stall_write_ms,
io_stall_total_ms           = vfs.io_stall,
sample_ms                   = vfs.sample_ms
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
INNER JOIN sys.master_files AS mf
    ON vfs.database_id = mf.database_id
   AND vfs.file_id = mf.file_id
WHERE vfs.database_id > 4
ORDER BY io_stall_total_ms DESC, database_name, file_id;
GO

-------------------------------------------------------------------------------
-- 2 - TempDB session space usage
-------------------------------------------------------------------------------
/*
→ Shows TempDB space usage by active session
→ Helpful for identifying sessions consuming TempDB for internal or user objects
*/

SELECT
session_id                  = s.session_id,
login_name                  = s.login_name,
host_name                   = s.host_name,
program_name                = s.program_name,
status                      = s.status,
database_name               = DB_NAME(r.database_id),
internal_objects_alloc_mb   = tsu.internal_objects_alloc_page_count * 8.0 / 1024,
internal_objects_dealloc_mb = tsu.internal_objects_dealloc_page_count * 8.0 / 1024,
user_objects_alloc_mb       = tsu.user_objects_alloc_page_count * 8.0 / 1024,
user_objects_dealloc_mb     = tsu.user_objects_dealloc_page_count * 8.0 / 1024,
open_transaction_count      = s.open_transaction_count,
command                     = r.command,
wait_type                   = r.wait_type,
wait_time_ms                = r.wait_time,
blocking_session_id         = r.blocking_session_id
FROM sys.dm_db_session_space_usage AS tsu
INNER JOIN sys.dm_exec_sessions AS s
    ON tsu.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests AS r
    ON tsu.session_id = r.session_id
WHERE s.is_user_process = 1
ORDER BY
    (tsu.internal_objects_alloc_page_count + tsu.user_objects_alloc_page_count) DESC,
    s.session_id;
GO

-------------------------------------------------------------------------------
-- 3 - I/O related wait statistics
-------------------------------------------------------------------------------
/*
→ Returns wait statistics commonly associated with storage bottlenecks
→ These values are cumulative since SQL Server service start
*/

SELECT
wait_type,
waiting_tasks_count,
wait_time_ms,
signal_wait_time_ms,
resource_wait_time_ms       = wait_time_ms - signal_wait_time_ms
FROM sys.dm_os_wait_stats
WHERE wait_type IN
(
    'PAGEIOLATCH_SH',
    'PAGEIOLATCH_EX',
    'PAGEIOLATCH_UP',
    'WRITELOG',
    'IO_COMPLETION',
    'ASYNC_IO_COMPLETION'
)
AND wait_time_ms > 0
ORDER BY wait_time_ms DESC;
GO
