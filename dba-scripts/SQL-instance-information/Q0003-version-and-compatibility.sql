/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-11
Version     : 2.0
Task        : Q0003 - Version and compatibility
Object      : Script
Description : Queries to identify database version and compatibility
Notes       : notes\A0006-sql-server-version.md
===============================================================================
*/

SET NOCOUNT ON;
GO 

-------------------------------------------------------------------------------
--Identify the exact version (main mapping)
-------------------------------------------------------------------------------

SELECT @@VERSION AS FullVersionString;
GO

-------------------------------------------------------------------------------
--Complete instance information
-------------------------------------------------------------------------------

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
GO

/*
ProductVersion          → Exact build
ProductUpdateLevel      → Displays the installed Cumulative Update (CU)
ProductUpdateReference  → KB update / KB article number
EngineEdition           → Engine type (Express, Standard, Enterprise, Azure)
ProductLevel            → RTM / SP1 / SP2
*/

-------------------------------------------------------------------------------
--Check whether it is Azure SQL or on-premises
-------------------------------------------------------------------------------

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
GO

-------------------------------------------------------------------------------
--Check exact build number (for auditing and vulnerability assessment)
-------------------------------------------------------------------------------

SELECT
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 4) AS Major,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 3) AS Minor,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 2) AS Build,
PARSENAME(CONVERT(VARCHAR(50), SERVERPROPERTY('ProductVersion')), 1) AS Revision;
GO

/*
-------------------------------------------------------------------------------
Major (17) 
-------------------------------------------------------------------------------
→ It is the main product version.

-------------------------------------------------------------------------------
Minor (0)
-------------------------------------------------------------------------------
→ Indicates the baseline version. 
→ It is normally 0 in modern RTM versions.
→ Historically it could change with Service Packs (legacy model)

-------------------------------------------------------------------------------
Build (4236)
-------------------------------------------------------------------------------
It shows:
→ Which CU is installed
→ If a security fix exists
→ If it contains a specific bug fix

It is the number used to:
→ Compare with the official build table
→ Verify the CVE (Common Vulnerabilities and Exposures)
*/

-------------------------------------------------------------------------------
--Check database compatibility level (not the engine version) 
-------------------------------------------------------------------------------
SELECT
name,
compatibility_level
FROM sys.databases;
GO

/*
→ LSCL -> Latest Supported Compatibility Level
→ MSL  -> Minimum Supported Level
----------------------------------------------------------------------------------------------------------------------------|
| SQL Server Instance (Major) | LSCL  | MSL   | Observations / Features                                                     |
----------------------------------------------------------------------------------------------------------------------------|
| 8 – SQL Server 2000         | 80    | 80    | Only classic T‑SQL; does not support modern features                        |
| 9 – SQL Server 2005         | 90    | 80    | Introduces XML datatype, TRY…CATCH, basic indexed views                     |
| 10 – SQL Server 2008        | 100   | 80    | Table partitioning, sparse columns, date/time types                         |
| 10.5 – SQL Server 2008 R2   | 100   | 80    | Support for sequence objects and integrated reporting services              |
| 11 – SQL Server 2012        | 110   | 90    | Columnstore indexes, TRY_PARSE, THROW, sequences    						|
| 12 – SQL Server 2014        | 120   | 100   | In-memory OLTP (Hekaton), buffer pool extensions    						|
| 13 – SQL Server 2016        | 130   | 100   | Query Store, temporal tables, JSON support          						|
| 14 – SQL Server 2017        | 140   | 100   | Linux support, graph tables, automatic plan         						| 
| 15 – SQL Server 2019        | 150   | 110   | Big Data Clusters, enhanced Intelligent Query Processing                    |
| 16 – SQL Server 2022        | 160   | 110   | Ledger tables, vector-based query processing, enhanced Query Store          |
| 17 – SQL Server 2025        | 170   | 110   | Integrated AI, native vector datatype, modern T-SQL, streaming optimizations|
----------------------------------------------------------------------------------------------------------------------------|
*/