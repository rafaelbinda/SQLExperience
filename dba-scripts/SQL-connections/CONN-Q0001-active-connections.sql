/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-16
Version     : 2.0
Task        : Q0001 - Active Connections
Object      : Script
Description : Query to identify active SQL Server connections
              Includes detection of connections using Named Pipes.
===============================================================================
*/

SET NOCOUNT ON;
GO

-------------------------------------------------------------------------------
-- Active User Connections
-------------------------------------------------------------------------------
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage,
    s.login_time,
    c.net_transport,
    c.client_net_address,
    c.local_net_address,
    c.local_tcp_port,
    c.connect_time
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
WHERE s.is_user_process = 1
ORDER BY c.connect_time DESC;
GO

-------------------------------------------------------------------------------
-- Active Connections Using Named Pipes
-------------------------------------------------------------------------------
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage,
    s.login_time,
    c.net_transport,
    c.client_net_address,
    c.local_net_address,
    c.local_tcp_port,
    c.connect_time
FROM sys.dm_exec_sessions s
JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
WHERE s.is_user_process = 1
AND c.net_transport = 'Named pipe'
ORDER BY c.connect_time DESC;
GO