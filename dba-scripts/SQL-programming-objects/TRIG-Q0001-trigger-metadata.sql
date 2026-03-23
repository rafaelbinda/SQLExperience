/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-21
Version     : 1.0
Task        : TRIG-Q0001 - Trigger Metadata Objects
Object      : Script
Description : The queries below are useful for quick investigation of triggers
              in a SQL Server database
              They help inspect metadata, definitions, dependencies, and
              configuration details
Notes       : notes/A0015-programming-objects-triggers.md
Examples    : scripts/Q0013-sql-triggers.sql
Tools       : -
Location    : -
===============================================================================
INDEX
1 - List all triggers in the current database
2 - Trigger definition
3 - Trigger parent object
4 - Trigger events
5 - Check if the trigger is disabled
6 - Trigger execution properties
7 - Objects referenced by the trigger
8 - Objects that depend on the trigger
9 - Search triggers by name
10 - Search text inside trigger definitions
11 - Managing Triggers (DROP)
===============================================================================
*/

USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - List all triggers in the current database
-------------------------------------------------------------------------------
-- Returns trigger name, type, parent object, and creation/modification dates

SELECT
t.name AS TriggerName,
t.type_desc AS TriggerType,
OBJECT_NAME(t.parent_id) AS ParentObject,
t.create_date AS CreateDate,
t.modify_date AS ModifyDate
FROM sys.triggers AS t
ORDER BY TriggerName;
GO

-------------------------------------------------------------------------------
-- 2 - Trigger definition
-------------------------------------------------------------------------------
-- Returns the T-SQL definition stored in sys.sql_modules

SELECT
t.name AS TriggerName,
OBJECT_NAME(t.parent_id) AS ParentObject,
m.definition AS TriggerDefinition
FROM sys.triggers AS t
INNER JOIN sys.sql_modules AS m
    ON t.object_id = m.object_id
WHERE t.name = 'uPurchaseOrderDetail';
GO

-------------------------------------------------------------------------------
-- 3 - Trigger parent object
-------------------------------------------------------------------------------
-- Returns the object (table or database) to which the trigger is attached

SELECT
t.name AS TriggerName,
OBJECT_NAME(t.parent_id) AS ParentObject,
t.parent_class_desc AS ParentType
FROM sys.triggers AS t
WHERE t.name = 'uPurchaseOrderDetail';
GO

-------------------------------------------------------------------------------
-- 4 - Trigger events
-------------------------------------------------------------------------------
-- Returns the events that fire the trigger (INSERT, UPDATE, DELETE, etc.)

SELECT
t.name AS TriggerName,
te.type_desc AS EventType
FROM sys.triggers AS t
INNER JOIN sys.trigger_events AS te
    ON t.object_id = te.object_id
WHERE t.name = 'uPurchaseOrderDetail';
GO

-------------------------------------------------------------------------------
-- 5 - Check if the trigger is disabled
-------------------------------------------------------------------------------
-- Returns whether the trigger is enabled or disabled

SELECT
t.name AS TriggerName,
t.is_disabled AS IsDisabled
FROM sys.triggers AS t
WHERE t.name = 'uPurchaseOrderDetail';
GO

-------------------------------------------------------------------------------
-- 6 - Trigger execution properties
-------------------------------------------------------------------------------
-- Returns trigger execution properties such as instead of trigger

SELECT
t.name AS TriggerName,
OBJECTPROPERTY(t.object_id, 'ExecIsInsteadOfTrigger') AS IsInsteadOfTrigger,
OBJECTPROPERTY(t.object_id, 'ExecIsTriggerDisabled') AS IsDisabled
FROM sys.triggers AS t
WHERE t.name = 'uPurchaseOrderDetail';
GO

-------------------------------------------------------------------------------
-- 7 - Objects referenced by the trigger
-------------------------------------------------------------------------------
-- Returns objects used by the trigger (tables, views, etc.)
-- This is a table-valued function (DMF), so the object name is passed as a
-- parameter and no WHERE clause is required

SELECT
referenced_schema_name AS ReferencedSchema,
referenced_entity_name AS ReferencedObject,
referenced_minor_name AS ReferencedColumn,
referenced_class_desc AS ReferencedClass
FROM sys.dm_sql_referenced_entities ('Purchasing.uPurchaseOrderDetail', 'OBJECT');
GO

-------------------------------------------------------------------------------
-- 8 - Objects that depend on the trigger
-------------------------------------------------------------------------------
-- Returns objects that reference the trigger
-- Note: May return no rows if no objects depend on the trigger

SELECT
referencing_schema_name AS ReferencingSchema,
referencing_entity_name AS ReferencingObject,
referencing_class_desc AS ReferencingClass
FROM sys.dm_sql_referencing_entities ('Purchasing.uPurchaseOrderDetail', 'OBJECT');
GO

-------------------------------------------------------------------------------
-- 9 - Search triggers by name
-------------------------------------------------------------------------------
-- Searches triggers by partial name

SELECT
t.name AS TriggerName,
OBJECT_NAME(t.parent_id) AS ParentObject,
t.create_date AS CreateDate,
t.modify_date AS ModifyDate
FROM sys.triggers AS t
WHERE t.name LIKE '%Purchase%'
ORDER BY TriggerName;
GO

-------------------------------------------------------------------------------
-- 10 - Search text inside trigger definitions
-------------------------------------------------------------------------------
-- Searches for text inside trigger definitions

SELECT
t.name AS TriggerName,
OBJECT_NAME(t.parent_id) AS ParentObject
FROM sys.triggers AS t
INNER JOIN sys.sql_modules AS m
    ON t.object_id = m.object_id
WHERE m.definition LIKE '%INSERT%'
ORDER BY TriggerName;
GO

-------------------------------------------------------------------------------
-- 11 - Managing Triggers (DROP)
-------------------------------------------------------------------------------
-- Demonstrates how to remove triggers from the database
-- Dropping a trigger permanently removes it

-- Always verify dependencies before dropping triggers
-- Use dependency queries to avoid breaking other objects

DROP TRIGGER IF EXISTS Purchasing.uPurchaseOrderDetail;
GO
