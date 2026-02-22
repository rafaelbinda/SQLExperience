/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-15
Version     : 2.0
Task        : Q0001 - Server and Service Name
Object      : Script
Description : Queries to identify server and instance information 
===============================================================================
*/ 

SET NOCOUNT ON;
GO 

-------------------------------------------------------------------------------
--Instance name (Direct Method)
-------------------------------------------------------------------------------
SELECT @@SERVICENAME AS InstanceName;

/*
Default Instance    → MSSQLSERVER
Named instance      → SQL2022
*/

-------------------------------------------------------------------------------
--Server name + Instance name (Complete Method)
-------------------------------------------------------------------------------
SELECT @@SERVERNAME AS ServerName;

/*
Default Instance    → SRVSQLSERVER
Named instance      → SRVSQLSERVER\SQL2022
*/

-------------------------------------------------------------------------------
--Detailed Method
-------------------------------------------------------------------------------
SELECT  
    SERVERPROPERTY('MachineName')     AS MachineName,
    SERVERPROPERTY('ServerName')      AS ServerName,
    SERVERPROPERTY('InstanceName')    AS InstanceName,
    SERVERPROPERTY('IsClustered')     AS IsClustered;

/*
If InstanceName returns NULL, it means that you are connected to the Default Instance (MSSQLSERVER).

MachineName   → Windows server name
ServerName    → Complete name (Server/Instance)
InstanceName  → Null if default instance
IsClustered   → 1 - cluster / 0 standalone 

-------------------------------------------------------------------------------
IsClustered = 0 → Standalone
-------------------------------------------------------------------------------
This means that:
→ The SQL Server instance is installed on a single server.
→ If the machine goes down or a Windows problem occurs, the database will become unavailable.
→ Automatic failover is not available.
→ Local storage (typically)

-------------------------------------------------------------------------------
IsClustered = 1 → Cluster (Failover Cluster Instance)
-------------------------------------------------------------------------------
This means that:
→ The SQL Server instance is installed as a Failover Cluster Instance (FCI) on a Windows Server Failover Cluster (WSFC).
→ There are at least two nodes.
→ If one node fails, another node automatically assumes control.  
→ The storage is shared (for example, a SAN)

Microsoft SQL Server 2022           → the instance
Failover Cluster Instance (FCI)     → the installation type
Windows Server Failover Clustering  → the Windows technology that supports the cluster
                                    
-------------------------------------------------------------------------------
Important: Cluster ≠ Always On
-------------------------------------------------------------------------------

Failover Cluster Instance (FCI) 
→ Uses shared storage
→ Only one node is active at a time.
→ IsClustered = 1

Always On Availability Groups
→ Each node has its own storage.
→ Replication between servers. 
→ IsClustered = 0 (in most cases)                                 

In other words: 
→ A server can use Always On and still return IsClustered = 0, because Always On is not a Failover Cluster Instance (FCI).
*/
