/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-10
Version     : 1.0
Task        : Q0001 - Blocking troubleshooting queries
Object      : Script
Description : Queries to detect and analyze SQL Server blocking situations
Notes       : notes/A0011-transactions-and-concurrency.md
Examples    : scripts/Q0009-sql-transactions-and-concurrency.sql
Tools       : sp_WhoIsActive v11.32
Location    : tools/Q0001-sp_whoisactive-v11.32.sql
===============================================================================
INDEX
1 - Check current session ID
2 - Check requests currently executing
3 - Check active user sessions
4 - Check current locks
5 - Detailed blocking investigation
6 - Use sp_WhoIsActive to detect blocking
7 - Use sp_WhoIsActive to find blocking leaders
8 - Use sp_WhoIsActive for deeper blocking analysis
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Check current session ID
-------------------------------------------------------------------------------
/*
Use this to identify the current session.
This is useful when testing blocking between Session A and Session B.
*/

SELECT @@SPID AS CurrentSessionID;
GO

-------------------------------------------------------------------------------
-- 2 - Check requests currently executing
-------------------------------------------------------------------------------
/*
Look for:
→ blocking_session_id
→ wait_type related to locks (LCK_M_*)
→ wait_resource
→ commands currently executing

→ If blocking_session_id > 0, the session is being blocked by another session

LCK_M_* (Lock Wait Types)

→ These wait types indicate that a session is waiting to acquire a lock held 
  by another session
→ This usually means blocking is occurring

Common examples:

LCK_M_S  → Waiting for a Shared Lock (S)
           Happens when a session wants to read data but another session
           holds an incompatible lock (usually X)

LCK_M_X  → Waiting for an Exclusive Lock (X)
           Happens when a session tries to modify data but another
           session is holding a lock on the same resource

LCK_M_U  → Waiting for an Update Lock (U)
           Occurs when SQL Server intends to update a row after reading it

LCK_M_IS → Waiting for an Intent Shared Lock (IS)
           Indicates intent to place Shared Locks at lower levels

LCK_M_IX → Waiting for an Intent Exclusive Lock (IX)
           Indicates intent to place Exclusive Locks at lower levels

In general:
→ LCK_M_* waits indicate that one session is waiting for another session
to release a lock on the same resource

*/

SELECT
session_id,
blocking_session_id,
status,
wait_type,
wait_time,
wait_resource,
database_id,
command
FROM sys.dm_exec_requests
WHERE session_id <> @@SPID;
GO

-------------------------------------------------------------------------------
-- 3 - Check active user sessions
-------------------------------------------------------------------------------
/*
Sessions with open transactions may be holding locks.

Important columns:
→ session_id
→ status
→ open_transaction_count
→ login_name
→ host_name
→ program_name
*/

SELECT
session_id,
login_name,
host_name,
program_name,
status,
open_transaction_count
FROM sys.dm_exec_sessions
WHERE session_id > 50;
GO

-------------------------------------------------------------------------------
-- 4 - Check current locks
-------------------------------------------------------------------------------
/*
Shows active locks and lock hierarchy

Important columns:
→ request_session_id
→ resource_type
→ request_mode
→ request_status

Common values:
→ request_status = GRANT   : lock was granted
→ request_status = WAIT    : session is waiting for the lock
→ request_mode   = S       : Shared Lock
→ request_mode   = X       : Exclusive Lock
→ request_mode   = IS / IX : Intent locks
*/

SELECT
request_session_id              AS SessionID,
resource_type                   AS ResourceType,
request_mode                    AS LockMode,
request_status                  AS LockStatus,
resource_associated_entity_id   AS AssociatedEntityID
FROM sys.dm_tran_locks
ORDER BY
request_session_id,
resource_type,
request_mode;
GO

-------------------------------------------------------------------------------
-- 5 - Detailed blocking investigation
-------------------------------------------------------------------------------
/*
→ Legacy query, but still useful for identifying blocking sessions, open 
  transactions, host, application, and SQL text
*/

SELECT
sp.spid AS SPID,
sp.blocked AS BlockingBy,
sp.waittime / 1000 AS WaitTimeSeconds,
DB_NAME(sp.dbid) AS DatabaseName,
ISNULL(sp.hostname, 'N/A') AS HostName,
sp.loginame AS SqlLogin,
s.program_name AS ApplicationName,
sp.open_tran AS OpenTransactions,
sp.cmd AS CommandType,
sp.last_batch AS LastBatch,
qt.text AS SqlText
FROM sys.sysprocesses AS sp
LEFT JOIN sys.dm_exec_sessions AS s
    ON s.session_id = sp.spid
OUTER APPLY sys.dm_exec_sql_text(sp.sql_handle) AS qt
WHERE sp.spid > 50;
GO

-------------------------------------------------------------------------------
-- 6 - Use sp_WhoIsActive to detect blocking
-------------------------------------------------------------------------------
/*
→ Shows active sessions, locks, waits, and execution plans 
→ Useful for diagnosing blocking in a more readable way
*/

EXEC sp_WhoIsActive
    @get_locks = 1,
    @get_plans = 1;
GO

-------------------------------------------------------------------------------
-- 7 - Use sp_WhoIsActive to find blocking leaders
-------------------------------------------------------------------------------
/*
→ Shows the root blocker more easily 
→ A blocking leader is usually the session causing other sessions to wait
*/

EXEC sp_WhoIsActive
    @find_block_leaders = 1;
GO

-------------------------------------------------------------------------------
-- 8 - Use sp_WhoIsActive for deeper blocking analysis
-------------------------------------------------------------------------------
/*
Recommended when you need:
→ locks
→ plans
→ blocking leaders

→ This is one of the most complete options for blocking analysis
*/

EXEC sp_WhoIsActive
    @get_locks = 1,
    @get_plans = 1,
    @find_block_leaders = 1;
GO

 


