/*
=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-16
@version       1.0
@task          Q0001_active_connections
@object        Script
@environment   DEV
@database      AdventureWorks
@server        SRVSQLSERVER
=====================================================================================================================================================

Histórico                                                                   |   History:
1.0 - Criacao do script                                                     |   1.0 - Script creation

Descrição                                                                   |   Description:
Consulta para ver TODAS as conexões ativas                                  |   Query to identify all active connections
Consulta conexões ativas através de Named Pipes                             |   Query to list active connections using Named Pipes

Observações:                                                                |   Notes:
                                                                            |   
=====================================================================================================================================================
*/


USE AdventureWorks;
GO
 
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Consulta para ver TODAS as conexões ativas                                |    Query to identify all active connections
-----------------------------------------------------------------------------------------------------------------------------------------------------

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
 

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Consulta conexões ativas através de Named Pipes                            |    Query to list active connections using Named Pipes
-----------------------------------------------------------------------------------------------------------------------------------------------------

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
 