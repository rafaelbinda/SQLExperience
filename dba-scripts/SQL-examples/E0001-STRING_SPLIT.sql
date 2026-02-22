/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-16
Version     : 2.0
Task        : E0001 - Example using STRING_SPLIT
Object      : Script
Description : Demonstrate how to use STRING_SPLIT to handle values 
              stored in concatenated format (EX1;EX2;EX3)
===============================================================================
*/

-------------------------------------------------------------------------------
-- Creating the database
-------------------------------------------------------------------------------

CREATE DATABASE EXAMPLES;
GO

USE EXAMPLES;
GO
 
-------------------------------------------------------------------------------
--  Creating the example table
-------------------------------------------------------------------------------

--The column Forms will store multiple values separated by ";" 
CREATE TABLE PaymentExample
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Forms VARCHAR(100) NOT NUL
);
GO

-------------------------------------------------------------------------------
-- Inserting records with concatenated values
-------------------------------------------------------------------------------

INSERT INTO PaymentExample (Forms)
VALUES ('FPY0;FPY1;FPY2;FPY3;FPY4;FPY5;FPY6;FPY7;FPY8;FPY9');
GO
INSERT INTO PaymentExample (Forms)
VALUES ('FPYA;FPYB;FPYC;FPYD;FPYE;FPYF;FPYG;FPYH;FPYY;FPYJ');
GO
INSERT INTO PaymentExample (Forms)
VALUES ('FPYK;FPYL;FPYM;FPYN;FPYO;FPYP;FPYQ;FPYR;FPYS;FPYT');
GO

-------------------------------------------------------------------------------
--Viewing the original data
-------------------------------------------------------------------------------
SELECT * 
FROM PaymentExample;
GO

-------------------------------------------------------------------------------
--Separating values
-------------------------------------------------------------------------------
SELECT 
value AS SplitValue
FROM PaymentExample
CROSS APPLY STRING_SPLIT(Forms, ';');

-------------------------------------------------------------------------------
--Checking if the information exists 
-------------------------------------------------------------------------------
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