/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-19
Version     : 1.0
Task        : PROC-Q0001 - Stored Procedure Metadata Objects
Object      : Script
Description : The queries below are useful for quick investigation of stored
              procedures in a SQL Server database.
              They help inspect metadata, definitions, parameters,
              dependencies, properties, and configuration details
Notes       : notes/A0013-programming-objects-stored-procedures.md
Examples    : scripts/Q0011-sql-procedures.sql
Tools       : -
Location    : -
===============================================================================
INDEX
1  - List all stored procedures in the current database
2  - List stored procedures by schema
3  - Stored procedure definition
4  - Stored procedure definition using sp_helptext
5  - Procedure parameters
6  - Procedure parameters using INFORMATION_SCHEMA
7  - Count parameters per procedure
8  - Objects referenced by the stored procedure
9  - Objects that depend on the stored procedure
10 - Check procedure properties
11 - Check if the procedure is encrypted
12 - Check startup procedures
13 - Creation and last modification date
14 - Search stored procedures by name
15 - Search text inside procedure definitions
16 - Managing Stored Procedures (DROP)
===============================================================================
*/

USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - List all stored procedures in the current database
-------------------------------------------------------------------------------
/*
 Returns all stored procedures from the current database with creation and last 
 modification dates
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
p.create_date AS CreateDate,
p.modify_date AS ModifyDate
FROM sys.procedures AS p
ORDER BY SchemaName, ProcedureName;
GO

-------------------------------------------------------------------------------
-- 2 - List stored procedures by schema
-------------------------------------------------------------------------------
/*
→ Filters stored procedures by schema name
→ Useful when investigating procedures from a specific functional area
*/

SELECT
s.name AS SchemaName,
p.name AS ProcedureName,
p.create_date AS CreateDate,
p.modify_date AS ModifyDate
FROM sys.procedures AS p
INNER JOIN sys.schemas AS s
    ON p.schema_id = s.schema_id
WHERE s.name = 'HumanResources'
ORDER BY p.name;
GO


-------------------------------------------------------------------------------
-- 3 - Stored procedure definition
-------------------------------------------------------------------------------
/*
→ Returns the T-SQL definition stored in sys.sql_modules
→ Useful to inspect the procedure source code directly
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
m.definition AS ProcedureDefinition
FROM sys.procedures AS p
INNER JOIN sys.sql_modules AS m
    ON p.object_id = m.object_id
WHERE p.name = 'uspGetEmployeeManagers';
GO

-------------------------------------------------------------------------------
-- 4 - Stored procedure definition using sp_helptext
-------------------------------------------------------------------------------

/*
→ Displays the procedure definition in text format
→ Useful for quick inspection of the procedure source code.
*/

EXEC sp_helptext 'dbo.uspGetEmployeeManagers';
GO

-------------------------------------------------------------------------------
-- 5 - Procedure parameters
-------------------------------------------------------------------------------

/*
→ Returns parameter metadata such as name, data type, length, precision, scale, 
  and whether the parameter is OUTPUT
*/

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS ProcedureName,
prm.parameter_id AS ParameterID,
prm.name AS ParameterName,
TYPE_NAME(prm.user_type_id) AS DataType,
prm.max_length AS MaxLength,
prm.precision AS [Precision],
prm.scale AS Scale,
prm.is_output AS IsOutput
FROM sys.objects AS o
INNER JOIN sys.parameters AS prm
    ON o.object_id = prm.object_id
WHERE o.type = 'P' AND o.name = 'uspGetEmployeeManagers'
ORDER BY prm.parameter_id;
GO

-------------------------------------------------------------------------------
-- 6 - Procedure parameters using INFORMATION_SCHEMA
-------------------------------------------------------------------------------

/*
  INFORMATION_SCHEMA
→ Follows ANSI SQL standards and is supported by multiple database systems
→ Returns parameter metadata using ANSI-standard views
→ This makes queries more portable across different platforms (SQL Server,
  PostgreSQL, MySQL)
→ It provides less detailed information than SQL Server-specific catalog views 
  such as sys.parameters
*/

SELECT
SPECIFIC_SCHEMA AS SchemaName,
SPECIFIC_NAME AS ProcedureName,
ORDINAL_POSITION AS ParameterPosition,
PARAMETER_NAME AS ParameterName,
DATA_TYPE AS DataType,
CHARACTER_MAXIMUM_LENGTH AS CharacterMaxLength,
NUMERIC_PRECISION AS NumericPrecision,
NUMERIC_SCALE AS NumericScale,
PARAMETER_MODE AS ParameterMode
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_NAME = 'uspGetEmployeeManagers'
ORDER BY ORDINAL_POSITION;
GO

-------------------------------------------------------------------------------
-- 7 - Count parameters per procedure
-------------------------------------------------------------------------------

/*
→ Counts how many parameters each stored procedure has
→ Useful for quick analysis of procedure complexity
*/

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS ProcedureName,
COUNT(prm.parameter_id) AS ParameterCount
FROM sys.objects AS o
LEFT JOIN sys.parameters AS prm
    ON o.object_id = prm.object_id
WHERE o.type = 'P'
GROUP BY SCHEMA_NAME(o.schema_id), o.name
ORDER BY ParameterCount DESC, ProcedureName;
GO

-------------------------------------------------------------------------------
-- 8 - Objects referenced by the stored procedure
-------------------------------------------------------------------------------
/*
→ Returns objects used by the stored procedure (tables, views, functions, etc.)
→ Useful for dependency analysis and impact assessment
*/

SELECT
referenced_schema_name AS ReferencedSchema,
referenced_entity_name AS ReferencedObject,
referenced_minor_name AS ReferencedColumn,
referenced_class_desc AS ReferencedClass
FROM sys.dm_sql_referenced_entities ('dbo.uspGetEmployeeManagers', 'OBJECT');
GO

-------------------------------------------------------------------------------
-- 9 - Objects that depend on the stored procedure
-------------------------------------------------------------------------------

/*
→ Returns objects that reference the stored procedure
→ Useful to understand what may be affected if the procedure is changed or removed
*/

SELECT
referencing_schema_name AS ReferencingSchema,
referencing_entity_name AS ReferencingObject,
referencing_class_desc AS ReferencingClass
FROM sys.dm_sql_referencing_entities  ('dbo.uspGetEmployeeManagers', 'OBJECT');
GO

-------------------------------------------------------------------------------
-- 10 - Check procedure properties
-------------------------------------------------------------------------------

/*
→ Returns selected object properties such as:
  whether the object is a procedure
  whether it is encrypted
  whether it is marked as a startup procedure
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
OBJECTPROPERTY(p.object_id, 'IsProcedure') AS IsProcedure,
OBJECTPROPERTY(p.object_id, 'IsEncrypted') AS IsEncrypted,
OBJECTPROPERTY(p.object_id, 'ExecIsStartup') AS IsStartupProcedure
FROM sys.procedures AS p
WHERE p.name = 'uspGetEmployeeManagers';
GO

-------------------------------------------------------------------------------
-- 11 - Check if the procedure is encrypted
-------------------------------------------------------------------------------

/*
→ Verifies whether the procedure definition is hidden
→ If the procedure is encrypted, the definition in sys.sql_modules may be NULL
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
CASE
    WHEN m.definition IS NULL 
    THEN 'Yes'
    ELSE 'No'
END AS IsEncrypted
FROM sys.procedures AS p
LEFT JOIN sys.sql_modules AS m
    ON p.object_id = m.object_id
WHERE p.name = 'uspGetEmployeeManagers';
GO

-------------------------------------------------------------------------------
-- 12 - Check startup procedures
-------------------------------------------------------------------------------

/*
→ Returns procedures configured to run automatically when SQL Server starts
→ These are rare in normal application databases, but can exist in administrative 
  or maintenance scenarios
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
OBJECTPROPERTY(p.object_id, 'ExecIsStartup') AS IsStartupProcedure
FROM sys.procedures AS p
WHERE OBJECTPROPERTY(p.object_id, 'ExecIsStartup') = 1
ORDER BY SchemaName, ProcedureName;
GO

-------------------------------------------------------------------------------
--13 - Creation and last modification date
-------------------------------------------------------------------------------

/*
→ Returns the creation date and last modification date of the procedure
→ Useful to track recent changes
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
p.create_date AS CreateDate,
p.modify_date AS ModifyDate
FROM sys.procedures AS p
WHERE p.name = 'uspGetEmployeeManagers';
GO

-------------------------------------------------------------------------------
-- 14 - Search stored procedures by name
-------------------------------------------------------------------------------

/*
→ Searches stored procedures by partial name
→ Useful when the exact procedure name is not known
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName,
p.create_date AS CreateDate,
p.modify_date AS ModifyDate
FROM sys.procedures AS p
WHERE p.name LIKE '%Employee%'
ORDER BY SchemaName, ProcedureName;
GO

-------------------------------------------------------------------------------
-- 15 - Search text inside procedure definitions
-------------------------------------------------------------------------------

/*
→ Searches for text inside procedure definitions
→ Useful to find procedures containing a table name, column name, keyword, 
  or business rule
*/

SELECT
SCHEMA_NAME(p.schema_id) AS SchemaName,
p.name AS ProcedureName
FROM sys.procedures AS p
INNER JOIN sys.sql_modules AS m
    ON p.object_id = m.object_id
WHERE m.definition LIKE '%Employee%'
ORDER BY SchemaName, ProcedureName;
GO

-------------------------------------------------------------------------------
-- 16 - Managing Stored Procedures (DROP)
-------------------------------------------------------------------------------
--Demonstrates how to remove stored procedures from the database
--Dropping a procedure permanently removes it

-- Stored procedures may be referenced by other objects (views, functions, jobs)
-- Always check dependencies before dropping

DROP PROCEDURE IF EXISTS schema_name.procedure_name;
GO

