/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-21
Version     : 1.0
Task        : FUNC-Q0001 - Function Metadata Objects
Object      : Script
Description : The queries below are useful for quick investigation of functions
              in a SQL Server database.
              They help inspect metadata, definitions, dependencies, and
              configuration details
Notes       : notes/A0014-programming-objects-functions.md
Examples    : scripts/Q0012-sql-functions.sql
Tools       : -
Location    : -
===============================================================================
INDEX
1 - List all functions in the current database
2 - List functions by type
3 - Function definition
4 - Function parameters
5 - Objects referenced by the function
6 - Objects that depend on the function
7 - Check if the function is schema-bound
8 - Function columns
9 - Search functions by name
10 - Search text inside function definitions
11 - Managing Functions (DROP)
===============================================================================
*/

USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - List all functions in the current database
-------------------------------------------------------------------------------
-- Returns the schema, function name, type, and creation/modification dates

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
o.type_desc AS FunctionType,
o.create_date AS CreateDate,
o.modify_date AS ModifyDate
FROM sys.objects AS o
WHERE o.type IN ('FN', 'IF', 'TF', 'FS', 'FT')
ORDER BY SchemaName, FunctionName;
GO

/*
FN = Scalar Function
IF = Inline Table-Valued Function
TF = Multi-Statement Table-Valued Function
FS = CLR Scalar Function
FT = CLR Table-Valued Function

FS, FT = CLR functions (not included in definition and dependency analysis)
*/

-------------------------------------------------------------------------------
-- 2 - List functions by type
-------------------------------------------------------------------------------
-- Returns functions filtered by type 
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
o.type AS FunctionCode,
o.type_desc AS FunctionType
FROM sys.objects AS o
WHERE o.type IN ('FN', 'IF', 'TF')
ORDER BY o.type, SchemaName, FunctionName;
GO

-------------------------------------------------------------------------------
-- 3 - Function definition
-------------------------------------------------------------------------------
-- Returns the T-SQL definition stored in sys.sql_modules
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
o.type_desc AS FunctionType,
m.definition AS FunctionDefinition
FROM sys.objects AS o
INNER JOIN sys.sql_modules AS m
    ON o.object_id = m.object_id
WHERE o.type IN ('FN', 'IF', 'TF')
AND o.name = 'ufnGetAccountingStartDate';
GO

-------------------------------------------------------------------------------
-- 4 - Function parameters
-------------------------------------------------------------------------------
-- Returns parameter metadata such as name, data type, length, precision,
-- scale, and whether the parameter is OUTPUT
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
p.parameter_id AS ParameterID,
p.name AS ParameterName,
TYPE_NAME(p.user_type_id) AS DataType,
p.max_length AS MaxLength,
p.precision AS [Precision],
p.scale AS Scale,
p.is_output AS IsOutput
FROM sys.objects AS o
INNER JOIN sys.parameters AS p
    ON o.object_id = p.object_id
WHERE o.type IN ('FN', 'IF', 'TF')
AND o.name = 'ufnGetAccountingStartDate'
ORDER BY p.parameter_id;
GO

-------------------------------------------------------------------------------
-- 5 - Objects referenced by the function
-------------------------------------------------------------------------------
-- Returns objects used by the function
-- Useful for dependency analysis and impact assessment
-- This query may return no rows if the function does not reference any database
-- objects or if dependencies cannot be detected

-- This function has many dependencies
SELECT
referenced_schema_name AS ReferencedSchema,
referenced_entity_name AS ReferencedObject,
referenced_minor_name AS ReferencedColumn,
referenced_class_desc AS ReferencedClass
FROM sys.dm_sql_referenced_entities ('dbo.ufnGetProductStandardCost', 'OBJECT');
GO


-------------------------------------------------------------------------------
-- 6 - Objects that depend on the function
-------------------------------------------------------------------------------
-- Returns objects that reference the function
-- Useful to understand what may be affected if the function is changed or removed
-- This is a table-valued function (DMF), so the object name is passed as a
-- parameter and no WHERE clause is required

SELECT
referencing_schema_name AS ReferencingSchema,
referencing_entity_name AS ReferencingObject,
referencing_class_desc AS ReferencingClass
FROM sys.dm_sql_referencing_entities ('dbo.ufnGetAccountingStartDate', 'OBJECT');
GO

-------------------------------------------------------------------------------
-- 7 - Check if the function is schema-bound
-------------------------------------------------------------------------------
-- Returns whether the function was created WITH SCHEMABINDING
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
OBJECTPROPERTY(o.object_id, 'IsSchemaBound') AS IsSchemaBound
FROM sys.objects AS o
WHERE o.type IN ('FN', 'IF', 'TF')
AND o.name = 'ufnGetAccountingStartDate';
GO

-------------------------------------------------------------------------------
-- 8 - Function columns
-------------------------------------------------------------------------------
-- Returns the columns exposed by table-valued functions
-- This is useful for inline and multi-statement table-valued functions
-- Only table-valued functions (IF, TF) have columns
-- Scalar functions (FN) return a single value and are not included

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
c.column_id AS ColumnID,
c.name AS ColumnName,
t.name AS DataType,
c.max_length AS MaxLength,
c.precision AS [Precision],
c.scale AS Scale
FROM sys.objects AS o
INNER JOIN sys.columns AS c
    ON o.object_id = c.object_id
INNER JOIN sys.types AS t
    ON c.user_type_id = t.user_type_id
WHERE o.type IN ('IF', 'TF')
ORDER BY SchemaName, FunctionName, c.column_id;
GO

-------------------------------------------------------------------------------
-- 9 - Search functions by name
-------------------------------------------------------------------------------
-- Searches functions by partial name
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
o.type_desc AS FunctionType,
o.create_date AS CreateDate,
o.modify_date AS ModifyDate
FROM sys.objects AS o
WHERE o.type IN ('FN', 'IF', 'TF')
  AND o.name LIKE '%Date%'
ORDER BY SchemaName, FunctionName;
GO

-------------------------------------------------------------------------------
-- 10 - Search text inside function definitions
-------------------------------------------------------------------------------
-- Searches for text inside function definitions
-- Useful to find functions containing a table name, column name, keyword,
-- or business rule
-- FN, IF, TF = T-SQL functions

SELECT
SCHEMA_NAME(o.schema_id) AS SchemaName,
o.name AS FunctionName,
o.type_desc AS FunctionType
FROM sys.objects AS o
INNER JOIN sys.sql_modules AS m
    ON o.object_id = m.object_id
WHERE o.type IN ('FN', 'IF', 'TF')
  AND m.definition LIKE '%DATE%'
ORDER BY SchemaName, FunctionName;
GO

-------------------------------------------------------------------------------
-- 11 - Managing Functions (DROP)
-------------------------------------------------------------------------------
-- Demonstrates how to remove functions from the database
-- Dropping a function permanently removes it

-- Always verify dependencies before dropping functions
-- Use dependency queries to avoid breaking other objects

DROP FUNCTION IF EXISTS dbo.ufnGetAccountingStartDate;
GO

