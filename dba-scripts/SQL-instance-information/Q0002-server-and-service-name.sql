/*
=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-15
@version       1.0
@task          Q0001_server_and_service_name
@object        Script
@environment   DEV
@database      AdventureWorks
@server        SRVSQLSERVER
=====================================================================================================================================================

Histórico                                                                   | History:
1.0 - Criacao do script                                                     | 1.0 - Script creation

Descrição                                                                   | Description:
Consultas para identificar informações a respeito                           | Queries to identify server and instance information
do servidor e instância 


Observações                                                                 | Notes:

=====================================================================================================================================================
*/


USE AdventureWorks;
GO
 
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Nome da instância (Método direto)                                         |   Instance name (Direct Method)
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @@SERVICENAME AS InstanceName;

/*
MSSQLSERVER             → instância padrão (Default Instance)
SQL2022                 → instância nomeada (Named instance)
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Nome do servidor + instância (Método completo)                            |   Server name + Instance name (Complete Method)
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @@SERVERNAME AS ServerName;

/*
SRVSQLSERVER            → Instância padrão                                  |   SRVSQLSERVER            → Default Instance
SRVSQLSERVER\SQL2022    → Instância nomeada                                 |   SRVSQLSERVER\SQL2022    → Named instance          
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Forma mais detalhada                                                      |   Detailed Method
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT  
    SERVERPROPERTY('MachineName')     AS MachineName,
    SERVERPROPERTY('ServerName')      AS ServerName,
    SERVERPROPERTY('InstanceName')    AS InstanceName,
    SERVERPROPERTY('IsClustered')     AS IsClustered;
Explicação:

/*
Se InstanceName retornar NULL, significa que você está conectado na         |   If InstanceName returns NULL, it means that you are connected to the 
Default Instance (MSSQLSERVER).                                             |   Default Instance (MSSQLSERVER).

MachineName     → Nome do servidor Windows                                  |   MachineName   → Windows server name
ServerName      → Nome completo (Servidor\Instância)                        |   ServerName    → Complete name (Server/Instance)
InstanceName    → NULL se for instância padrão                              |   InstanceName  → Null if default instance
IsClustered     → 1 = cluster / 0 = standalone                              |   IsClustered   → 1 - cluster / 0 standalone 

-----------------------------------------------------------------------------------------------------------------------------------------------------
IsClustered = 0 → Standalone
-----------------------------------------------------------------------------------------------------------------------------------------------------
Significa que                                                               |   This means that:
→ O SQL Server está instalado em um único servidor.                         |   → The SQL Server instance is installed on a single server.
→ Se a máquina cair ou der problema no Windows,                             |   → If the machine goes down or a Windows problem occurs, 
  o banco fica indisponível.                                                |     the database will become unavailable.
→ Não há failover automático.                                               |   → Automatic failover is not available.
→ Storage é local (normalmente)                                             |   → Local storage (typically)

-----------------------------------------------------------------------------------------------------------------------------------------------------
IsClustered = 1 → Cluster (Failover Cluster Instance)
-----------------------------------------------------------------------------------------------------------------------------------------------------
Significa que                                                               |   This means that:
→ A instância do SQL Server está instalada como uma Failover                |   → The SQL Server instance is installed as a Failover Cluster 
  Cluster Instance (FCI) em um Windows Server Failover Cluster (WSFC).      |     Instance (FCI) on a Windows Server Failover Cluster (WSFC).
→ Existem pelo menos dois nós                                               |   → There are at least two nodes.
→ Se um nó falhar outro assume automaticamente                              |   → If one node fails, another node automatically assumes control.  
→ O storage é compartilhado (SAN, por exemplo)                              |   → The storage is shared (for example, a SAN)


Microsoft SQL Server 2022           → a instância                           |   Microsoft SQL Server 2022          → the instance
Failover Cluster Instance (FCI)     → tipo de instalação                    |   Failover Cluster Instance (FCI)    → the installation type
Windows Server Failover Clustering  → tecnologia do Windows que suporta o   |   Windows Server Failover Clustering → the Windows technology 
                                      cluster                                   that supports the cluster
                                    
-----------------------------------------------------------------------------------------------------------------------------------------------------
Importante | Important: Cluster ≠ Always On
-----------------------------------------------------------------------------------------------------------------------------------------------------

Failover Cluster Instance (FCI)                                             |   Failover Cluster Instance (FCI) 
→ Compartilha storage                                                       |   → Uses shared storage
→ Só um nó ativo por vez                                                    |   → Only one node is active at a time.
→ IsClustered = 1                                                           |   → IsClustered = 1

Always On Availability Groups                                               |   Always On Availability Groups
→ Cada nó tem seu próprio storage                                           |   → Each node has its own storage.
→ Replicação entre servidores                                               |   → Replication between servers. 
→ IsClustered = 0 (na maioria dos casos)                                    |   → IsClustered = 0 (in most cases)                                 

Ou seja:                                                                    |   In other words: 
→ Um servidor pode usar Always On e ainda retornar IsClustered = 0          |   A server can use Always On and still return IsClustered = 0,
  porque Always On não é FCI (Failover Cluster Instance).                   |   because Always On is not a Failover Cluster Instance (FCI).
=====================================================================================================================================================
*/
