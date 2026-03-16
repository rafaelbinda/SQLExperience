/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-15
Version     : 1.0
Task        : VIEW-Q0001 - View Metadata Objects
Object      : Script
Description : The queries below are useful for quick investigation of views in 
              a SQL Server database.  
              They help inspect metadata, dependencies, and configuration details
Notes       : notes/A0012-sql-server-programming-objects.md
Examples    : scripts/Q0010-sql-views.sql
Tools       : -
Location    : -
===============================================================================
INDEX
1 - List all views in the current database
2 - View definition
3 - Objects referenced by the view
4 - Objects that depend on the view
5 - Check if the view is schema-bound 
6 - Check if the view has indexes
7 - View columns
===============================================================================
*/

USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - List all views in the current database
-------------------------------------------------------------------------------
-- Returns the schema, view name, and creation/modification dates

SELECT
s.name AS SchemaName,
v.name AS ViewName,
v.create_date,
v.modify_date
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON v.schema_id = s.schema_id
ORDER BY s.name, v.name;
GO

-------------------------------------------------------------------------------
-- 2 - View definition
-------------------------------------------------------------------------------
-- Displays the T-SQL definition used to create the view
DECLARE @SchemaName SYSNAME = 'Sales';
DECLARE @ViewName   SYSNAME = 'vw_CustomerPersonInfo';

IF OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ViewName), 'V') IS NULL
BEGIN
     PRINT 'View not found: ' + @SchemaName + '.' + @ViewName;
    RETURN;
END

SELECT
s.name AS SchemaName,
v.name AS ViewName,
m.definition,
*
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON v.schema_id = s.schema_id
INNER JOIN sys.sql_modules AS m
    ON v.object_id = m.object_id
WHERE v.name = @ViewName;
GO

-------------------------------------------------------------------------------
-- 3 - Objects referenced by the view
-------------------------------------------------------------------------------
-- Shows the tables or objects used inside the view definition

DECLARE @SchemaName SYSNAME = 'Sales';
DECLARE @ViewName   SYSNAME = 'vw_CustomerPersonInfo';

IF OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ViewName), 'V') IS NULL
BEGIN
     PRINT 'View not found: ' + @SchemaName + '.' + @ViewName;
    RETURN;
END

SELECT
OBJECT_SCHEMA_NAME(d.referencing_id) AS ReferencingSchema,
OBJECT_NAME(d.referencing_id) AS ReferencingObject,
d.referenced_schema_name,
d.referenced_entity_name
FROM sys.sql_expression_dependencies AS d
WHERE OBJECT_NAME(d.referencing_id) = @ViewName;
GO

-------------------------------------------------------------------------------
-- 4 - Objects that depend on the view
-------------------------------------------------------------------------------
-- Identifies other database objects that reference the view

DECLARE @SchemaName SYSNAME = 'Sales';
DECLARE @ViewName   SYSNAME = 'vw_CustomerPersonInfo';

IF OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ViewName), 'V') IS NULL
BEGIN
     PRINT 'View not found: ' + @SchemaName + '.' + @ViewName;
    RETURN;
END

SELECT
OBJECT_SCHEMA_NAME(d.referencing_id) AS ReferencingSchema,
OBJECT_NAME(d.referencing_id) AS ReferencingObject,
o.type_desc
FROM sys.sql_expression_dependencies AS d
INNER JOIN sys.objects AS o
    ON d.referencing_id = o.object_id
WHERE d.referenced_entity_name = @ViewName;
GO

-------------------------------------------------------------------------------
-- 5 - Check if the view is schema-bound
-------------------------------------------------------------------------------
/* 
→ Indicates whether the view was created using WITH SCHEMABINDING
→ SCHEMABINDING binds a view to the structure of the underlying tables
→ When a view is created with SCHEMABINDING, SQL Server prevents changes to the
  referenced tables that would break the view definition
*/


SELECT
s.name AS SchemaName,
v.name AS ViewName,
OBJECTPROPERTY(v.object_id, 'IsSchemaBound') AS IsSchemaBound
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON v.schema_id = s.schema_id
ORDER BY s.name, v.name;
GO

-------------------------------------------------------------------------------
-- 6 - Check if the view has indexes
-------------------------------------------------------------------------------
-- Identifies indexed views and their associated indexes.

SELECT
s.name AS SchemaName,
v.name AS ViewName,
i.name AS IndexName,
i.type_desc
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON v.schema_id = s.schema_id
INNER JOIN sys.indexes AS i
    ON v.object_id = i.object_id
WHERE i.index_id > 0
ORDER BY s.name, v.name, i.name;
GO

-------------------------------------------------------------------------------
-- 7 - View columns
-------------------------------------------------------------------------------
-- Lists the columns defined in the selected view.

DECLARE @SchemaName SYSNAME = 'Sales';
DECLARE @ViewName   SYSNAME = 'vw_CustomerPersonInfo';

IF OBJECT_ID(QUOTENAME(@SchemaName) + '.' + QUOTENAME(@ViewName), 'V') IS NULL
BEGIN
     PRINT 'View not found: ' + @SchemaName + '.' + @ViewName;
    RETURN;
END

SELECT
s.name AS SchemaName,
v.name AS ViewName,
c.column_id,
c.name AS ColumnName,
t.name AS DataType,
c.max_length,
c.precision,
c.scale,
c.is_nullable
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON v.schema_id = s.schema_id
INNER JOIN sys.columns AS c
    ON v.object_id = c.object_id
INNER JOIN sys.types AS t
    ON c.user_type_id = t.user_type_id
WHERE v.name = @ViewName
ORDER BY c.column_id;
GO
 


