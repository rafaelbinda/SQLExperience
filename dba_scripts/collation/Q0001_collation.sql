

/*
===============================================================================
@author        Rafael Binda
@date          2026-02-11
@version       1.0
@task          Q0001_collation
@object        Script
@environment   DEV
@database      AdventureWorks
@server        SRVSQLSERVER
===============================================================================

Histórico / History:
1.0 - Criacao do script / Script creation

Descrição / Description:
Consultas para identificar collation / Queries to identify collation

Observações / Notes:

===============================================================================
*/

USE AdventureWorks;
GO
 
--Collation do Servidor / Server Collation:

SELECT SERVERPROPERTY('Collation');

--Collation dos Bancos / Database Collation:

SELECT name, collation_name 
FROM sys.databases;

--Collation das Colunas / Column Collation:
SELECT name, collation_name
FROM sys.columns 
WHERE object_id = OBJECT_ID('Person.Person');
 