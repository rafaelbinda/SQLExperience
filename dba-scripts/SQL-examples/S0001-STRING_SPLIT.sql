/*
=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-19
@version       1.0
@task          S0001_STRING_SPLIT
@object        Script
@environment   DEV
@database      EXAMPLES
@server        SRVSQLSERVER
=====================================================================================================================================================

Histórico                                                                   |   History:
1.0 - Criacao do script                                                     |   1.0 - Script creation

Descrição                                                                   |   Description:
Demonstrar como utilizar STRING_SPLIT para tratar                           |   Demonstrate how to use STRING_SPLIT to handle values 
valores armazenados em formato concatenado (EX1;EX2;EX3)                    |   stored in concatenated format (EX1;EX2;EX3)

Observações:                                                                |   Notes:
                                                                            |   
=====================================================================================================================================================
*/

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Criando o banco de dados                                                  |   Creating the database
-----------------------------------------------------------------------------------------------------------------------------------------------------

CREATE DATABASE EXAMPLES;
GO

USE EXAMPLES;
GO
 
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Criação da tabela de exemplo                                              |   Creating the example table
-----------------------------------------------------------------------------------------------------------------------------------------------------

-- A coluna Forms armazenará múltiplos valores separados por ";"            |   The column Forms will store multiple values separated by ";" 
CREATE TABLE PaymentExample
(
    Id INT IDENTITY(1,1) PRIMARY KEY,   -- Identificador único
    Forms VARCHAR(100) NOT NULL         -- Valores concatenados
);
GO

-- Inserindo registro com valores concatenados                              |   Inserting records with concatenated values
 
INSERT INTO PaymentExample (Forms)
VALUES ('FPY0;FPY1;FPY2;FPY3;FPY4;FPY5;FPY6;FPY7;FPY8;FPY9');
GO
INSERT INTO PaymentExample (Forms)
VALUES ('FPYA;FPYB;FPYC;FPYD;FPYE;FPYF;FPYG;FPYH;FPYY;FPYJ');
GO
INSERT INTO PaymentExample (Forms)
VALUES ('FPYK;FPYL;FPYM;FPYN;FPYO;FPYP;FPYQ;FPYR;FPYS;FPYT');
GO

-- Visualizado os dados originais                                           |   Viewing the original data
SELECT * 
FROM PaymentExample;
GO

-- Separando os valores                                                     |   Separating values
SELECT 
value AS SplitValue
FROM PaymentExample
CROSS APPLY STRING_SPLIT(Forms, ';');


-- Verificando se contém a informação                                       |   Checking if the information exists 
SELECT Id, 
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM STRING_SPLIT(Forms, ';')
            WHERE value = 'EX2'
        )
        THEN 1
        ELSE 0
    END AS ContainsEX2,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM STRING_SPLIT(Forms, ';')
            WHERE value IN ('FPY5','FPYT')
        )
        THEN 1
        ELSE 0
    END AS ContainsFPY5_FPYT
FROM PaymentExample;