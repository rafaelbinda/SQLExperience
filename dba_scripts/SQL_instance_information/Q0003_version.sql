/*
=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-15
@version       1.0
@task          Q0003_sql_version
@object        Script
@environment   DEV
@database      AdventureWorks
@server        SRVSQLSERVER
=====================================================================================================================================================

Histórico                                                                   |   History:
1.0 - Criacao do script                                                     |   1.0 - Script creation

Descrição                                                                   |   Description:
Consultas para identificar versão do banco de dados                         |   Queries to identify database version

Observações:                                                                |   Notes:
annotations\A0006_sql_server_version.txt                                    |   annotations\A0006_sql_server_version.txt
=====================================================================================================================================================
*/

Use AdventureWorks;
GO

SELECT
    SERVERPROPERTY('ProductVersion') AS ProductVersion,
    SERVERPROPERTY('ProductLevel') AS ProductLevel,
    SERVERPROPERTY('Edition') AS Edition;