/*
=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-16
@version       1.0
@task          Q0003_version_and_compatibility
@object        Script
@environment   DEV
@database      AdventureWorks
@server        SRVSQLSERVER
=====================================================================================================================================================

Histórico                                                                   |   History:
1.0 - Criacao do script                                                     |   1.0 - Script creation

Descrição                                                                   |   Description:
Consultas para identificar versão e compatibilidade do banco de dados       |   Queries to identify database version and compatibility 

Observações:                                                                |   Notes:
annotations\A0006_sql_server_version.txt                                    |   annotations\A0006_sql_server_version.txt
=====================================================================================================================================================
*/

Use AdventureWorks;
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Identificar exatamente a versão (mapeamento principal):            		|	Identify the exact version (main mapping)
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT @@VERSION AS FullVersionString;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Informações completas da instância:            						    |	Complete instance information
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
SERVERPROPERTY('MachineName')        AS MachineName,
SERVERPROPERTY('ServerName')         AS ServerName,
SERVERPROPERTY('InstanceName')       AS InstanceName,
SERVERPROPERTY('IsClustered')        AS IsClustered,
SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS PhysicalNetBIOS,
SERVERPROPERTY('EngineEdition')      AS EngineEdition,
SERVERPROPERTY('ProductVersion')     AS ProductVersion,
SERVERPROPERTY('ProductLevel')       AS ProductLevel,
SERVERPROPERTY('ProductUpdateLevel') AS CULevel,
SERVERPROPERTY('ProductUpdateReference') AS CUReference,
SERVERPROPERTY('Edition')            AS Edition;

/*
    ProductVersion          → Build exato                                   | ProductVersion          → Exact build
    ProductUpdateLevel      → mostra a CU instalada/Nome da CU (CU18, CU22…)| ProductUpdateLevel      → Displays the installed Cumulative Update (CU)
    ProductUpdateReference  → KB da atualização/Número do artigo KB         | ProductUpdateReference  → KB update / KB article number
    EngineEdition           → Tipo da engine (Express, Standard, Enterprise,| EngineEdition           → Engine type (Express, Standard, Enterprise, 
                              Azure)                                        |                           Azure)
    ProductLevel            → RTM / SP1 / SP2                               | ProductLevel            → RTM / SP1 / SP2
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Ver se é Azure SQL ou on-premises:            						    | Check whether it is Azure SQL or on-premises
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
CASE SERVERPROPERTY('EngineEdition')
    WHEN 1 THEN 'Personal/Express'
    WHEN 2 THEN 'Standard'
    WHEN 3 THEN 'Enterprise'
    WHEN 4 THEN 'Express'
    WHEN 5 THEN 'Azure SQL Database'
    WHEN 6 THEN 'Azure Synapse'
    WHEN 8 THEN 'Azure SQL Managed Instance'
END AS EditionType;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Ver build exato (para auditoria / vulnerabilidade):            			| Check exact build number (for auditing and vulnerability assessment)
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 4) AS Major,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 3) AS Minor,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 2) AS Build,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 1) AS Revision;

/*
-----------------------------------------------------------------------------------------------------------------------------------------------------
Major (16)             			                                            | Major (16) 
-----------------------------------------------------------------------------------------------------------------------------------------------------
→ É a versão principal do produto.                                          | → It is the main product version.
                                                    | Major | Version            | Year |
                                                    | ----- | ------------------ | ---- |
                                                    | —     | SQL Server 4.2     | 1993 |
                                                    | —     | SQL Server 6.0     | 1995 |
                                                    | —     | SQL Server 6.5     | 1996 |
                                                    | 7     | SQL Server 7.0     | 1998 |
                                                    | 8     | SQL Server 2000    | 2000 |
                                                    | 9     | SQL Server 2005    | 2005 |
                                                    | 10    | SQL Server 2008    | 2008 |
                                                    | 10.5  | SQL Server 2008 R2 | 2010 |
                                                    | 11    | SQL Server 2012    | 2012 |
                                                    | 12    | SQL Server 2014    | 2014 |
                                                    | 13    | SQL Server 2016    | 2016 |
                                                    | 14    | SQL Server 2017    | 2017 |
                                                    | 15    | SQL Server 2019    | 2019 |
                                                    | 16    | SQL Server 2022    | 2022 |
                                                    | 17    | SQL Server 2025    | 2026 |

-----------------------------------------------------------------------------------------------------------------------------------------------------
Minor (0)             			                                            | Minor (0)
-----------------------------------------------------------------------------------------------------------------------------------------------------
→ Indica a linha base da versão.                                            | → Indicates the baseline version. 
→ Normalmente é 0 em versões RTM modernas.                                  | → It is normally 0 in modern RTM versions.
→ Historicamente podia mudar com Service Packs (modelo antigo).             | → Historically it could change with Service Packs (legacy model)


-----------------------------------------------------------------------------------------------------------------------------------------------------
Build (4236)             			                                        | Build (4236)
-----------------------------------------------------------------------------------------------------------------------------------------------------
Ela indica:                                                                 | It shows:
→ Qual CU está instalada                                                    | → Which CU is installed
→ Se já tem correção de segurança                                           | → If a security fix exists
→ Se contém determinado bug fix                                             | → If it contains a specific bug fix

É o número que usado para:                                                  | It is the number used to:
→ Comparar com tabela oficial de builds                                     | → Compare with the official build table
→ Validar CVE (Common Vulnerabilities and Exposures)                        | → Verify the CVE (Common Vulnerabilities and Exposures)
*/


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Compatibilidade das bases (não é versão da engine):            			| Check database compatibility level (not the engine version) 
-----------------------------------------------------------------------------------------------------------------------------------------------------

SELECT
name,
compatibility_level
FROM sys.databases;

/*

→ LSCL -> Latest Supported Compatibility Level
→ MSL  -> Minimum Supported Level

-----------------------------------------------------------------------------------------------------------------------------------------------------|
| SQL Server Instance (Major) | LSCL  | MSL   | Observações / Features                         | Observations / Features                             |
-----------------------------------------------------------------------------------------------------------------------------------------------------|
| 8 – SQL Server 2000         | 80    | 80    | Apenas T‑SQL clássico; não suporta features    | Only classic T‑SQL; does not support modern features|
|                             |       |       | modernas                                       |                                                     |    
| 9 – SQL Server 2005         | 90    | 80    | Introduz XML datatype, TRY…CATCH, indexed views| Introduces XML datatype, TRY…CATCH, basic indexed   |
|                             |       |       | básicas                                        | views                                               |
| 10 – SQL Server 2008        | 100   | 80    | Table partitioning, sparse columns, date/time  | Table partitioning, sparse columns, date/time types |                              
|                             |       |       | types                                          |                                                     |
| 10.5 – SQL Server 2008 R2   | 100   | 80    | Suporte a sequence objects e reporting         | Support for sequence objects and integrated         |
|                             |       |       | services integrados                            | reporting services                                  |
| 11 – SQL Server 2012        | 110   | 90    | Columnstore indexes, TRY_PARSE, THROW,         |                                                     |
|                             |       |       | sequences                                      | Columnstore indexes, TRY_PARSE, THROW, sequences    |
| 12 – SQL Server 2014        | 120   | 100   | In-memory OLTP (Hekaton), buffer pool          | In-memory OLTP (Hekaton), buffer pool extensions    |
|                             |       |       | extensions                                     |                                                     |
| 13 – SQL Server 2016        | 130   | 100   | Query store, temporal tables, JSON support     | Query Store, temporal tables, JSON support          |
| 14 – SQL Server 2017        | 140   | 100   | Linux support, graph tables, automatic plan    | Linux support, graph tables, automatic plan         | 
|                             |       |       | correction                                     |                                                     |
| 15 – SQL Server 2019        | 150   | 110   | Big data clusters, intelligent query processing| Big Data Clusters, enhanced Intelligent Query       | 
|                             |       |       | aprimorado                                     | Processing                                          |
| 16 – SQL Server 2022        | 160   | 110   | Ledger tables, vector-based query processing,  | Ledger tables, vector-based query processing,       | 
|                             |       |       | Query Store aprimorado                         | enhanced Query Store                                |
| 17 – SQL Server 2025        | 170   | 110   | AI integrado, vector datatype nativo,          | Integrated AI, native vector datatype,              |
|                             |       |       | T-SQL moderno, otimizações de streaming        | modern T-SQL, streaming optimizations               |
-----------------------------------------------------------------------------------------------------------------------------------------------------|

=====================================================================================================================================================*/