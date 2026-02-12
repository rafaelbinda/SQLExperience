
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

Histórico:
1.0 - Criacao do script  

Descrição:
Consultas para identificar collation

Observações:

===============================================================================
*/

USE AdventureWorks;
GO
 
--Collation do Servidor:

SELECT SERVERPROPERTY('Collation');

--Collation dos Bancos:

SELECT name, collation_name 
FROM sys.databases;

--Collation das Colunas:
SELECT name, collation_name
FROM sys.columns 
WHERE object_id = OBJECT_ID('Person.Person');
 