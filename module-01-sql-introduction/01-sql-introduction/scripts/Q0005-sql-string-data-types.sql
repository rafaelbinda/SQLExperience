/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-04
Version     : 1.0
Task        : Q0005-sql-string-data-types.sql
Databases   : ExamplesDB
Object      : Script
Description : Examples demonstrating string data types in SQL Server
Notes       : A0010-sql-data-types.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- 1 - Example with CHAR (fixed length)
-------------------------------------------------------------------------------
 
CREATE TABLE Example_CHAR (
    Code CHAR(5)
);
GO

INSERT INTO Example_CHAR VALUES ('A1');
INSERT INTO Example_CHAR VALUES ('ABCDE');

SELECT 
Code,
LEN(Code) AS LogicalLength,
DATALENGTH(Code) AS PhysicalBytes
FROM Example_CHAR;
GO

/*
Result: 
Code	LogicalLength	PhysicalBytes
A1   	    2	            5
ABCDE	    5	            5

→ Even storing 'A1', CHAR(5) will occupy 5 bytes because it has a fixed length

*/
-------------------------------------------------------------------------------
-- 2 - Example with VARCHAR (variable length)
-------------------------------------------------------------------------------
 
CREATE TABLE Example_VARCHAR (
    Description VARCHAR(50)
);
GO

INSERT INTO Example_VARCHAR VALUES ('Notebook');
INSERT INTO Example_VARCHAR VALUES ('Mouse');

SELECT 
Description,
LEN(Description) AS LogicalLength,
DATALENGTH(Description) AS PhysicalBytes
FROM Example_VARCHAR;
GO

/*
Result:
Description	LogicalLength	PhysicalBytes
Notebook	    8	            8
Mouse	        5	            5

→ VARCHAR stores only the required data + 2 bytes for length information
*/

-------------------------------------------------------------------------------
-- 3 - Example with NCHAR (fixed Unicode)
-------------------------------------------------------------------------------

CREATE TABLE Example_NCHAR (
    CountryCode NCHAR(3)
);
GO

INSERT INTO Example_NCHAR VALUES ('BR');
INSERT INTO Example_NCHAR VALUES ('USA');

SELECT 
    CountryCode,
    LEN(CountryCode) AS LogicalLength,
    DATALENGTH(CountryCode) AS PhysicalBytes
FROM Example_NCHAR;
GO

/*
Result:
CountryCode	LogicalLength	PhysicalBytes
BR 	            2	            6
USA	            3	            6

→ NCHAR uses 2 bytes per character because it stores Unicode data
*/

-------------------------------------------------------------------------------
-- 4 - Example with NVARCHAR (variable Unicode)
-------------------------------------------------------------------------------
 
CREATE TABLE Example_NVARCHAR (
    ProductName NVARCHAR(100)
);
GO

INSERT INTO Example_NVARCHAR VALUES (N'Coffee');
INSERT INTO Example_NVARCHAR VALUES (N'Computer');

SELECT 
ProductName,
LEN(ProductName) AS LogicalLength,
DATALENGTH(ProductName) AS PhysicalBytes
FROM Example_NVARCHAR;
GO

/*
Result:
ProductName	LogicalLength	PhysicalBytes
Coffee	        6	            12
Computer	    8	            16

→ The N prefix indicates that the string literal is Unicode
*/

-------------------------------------------------------------------------------
-- 5 - Example with VARCHAR(MAX)
-------------------------------------------------------------------------------
 
CREATE TABLE Example_VARCHAR_MAX (
    Notes VARCHAR(MAX)
);
GO

INSERT INTO Example_VARCHAR_MAX
VALUES ('This is a long text stored using VARCHAR(MAX)');

SELECT 
Notes,
LEN(Notes) AS LogicalLength
FROM Example_VARCHAR_MAX;
GO

/*
Result:
Notes	                                        LogicalLength
This is a long text stored using VARCHAR(MAX)	    45
*/

-------------------------------------------------------------------------------
-- 6 - Compare LEN() X DATALENGTH()
-------------------------------------------------------------------------------
 
SELECT 
LEN('SQL Server ') AS LEN_Result,
DATALENGTH('SQL Server ') AS DATALENGTH_Result;
GO

/*
Result:
LEN_Result	DATALENGTH_Result
10	            11

→ LEN() returns the number of characters (ignores trailing spaces)
→ DATALENGTH() returns the number of bytes used to store the value
*/

-------------------------------------------------------------------------------
-- 7 - Removing spaces
-------------------------------------------------------------------------------
 
SELECT 
LTRIM('   SQL') AS LeftTrim,
RTRIM('SQL   ') AS RightTrim,
TRIM('   SQL Server   ') AS TrimResult;
GO

/*
Result:
LeftTrim    = SQL
RightTrim   = SQL
TrimResult  = SQL Server
*/

-------------------------------------------------------------------------------
-- 8 - Searching with LIKE
-------------------------------------------------------------------------------
  
CREATE TABLE Example_LIKE (
    Name VARCHAR(50)
);
GO

INSERT INTO Example_LIKE VALUES ('Notebook');
INSERT INTO Example_LIKE VALUES ('Netbook');
INSERT INTO Example_LIKE VALUES ('Mouse');
GO

SELECT *
FROM Example_LIKE
WHERE Name LIKE 'Net%';
GO

/*
Result:
Name    =   Netbook
*/

-------------------------------------------------------------------------------
-- 9 - String concatenation
-------------------------------------------------------------------------------
  
SELECT 'SQL' + ' ' + 'Server' AS ConcatenationExample;
GO

/*
Result:
ConcatenationExample    =   SQL Server
*/

-------------------------------------------------------------------------------
-- 10 - Converting values to strings
-------------------------------------------------------------------------------

SELECT 
CAST(123 AS VARCHAR(10)) AS CastExample,
CONVERT(VARCHAR(10), GETDATE(), 120) AS DateToString;
GO  

/*
Result:
CastExample	    DateToString
123	            2026-03-04
*/

-------------------------------------------------------------------------------
-- 11 - Comparison between CHAR and VARCHAR
-------------------------------------------------------------------------------

-- 11.1 - Creating an example table
CREATE TABLE Example_Char_Varchar
(
    Code_CHAR    CHAR(10),
    Code_VARCHAR VARCHAR(10)
);
GO

-- 11.2 - Inserting data
INSERT INTO Example_Char_Varchar
VALUES ('SQL', 'SQL');

INSERT INTO Example_Char_Varchar
VALUES ('DATABASE', 'DATABASE');
GO

-- 11.3 Comparing LEN() vs DATALENGTH()

SELECT
Code_CHAR,
LEN(Code_CHAR) AS LEN_CHAR,
DATALENGTH(Code_CHAR) AS BYTES_CHAR,

Code_VARCHAR,
LEN(Code_VARCHAR) AS LEN_VARCHAR,
DATALENGTH(Code_VARCHAR) AS BYTES_VARCHAR
FROM Example_Char_Varchar;
GO

/*
Result:
Code_CHAR	LEN_CHAR	BYTES_CHAR	Code_VARCHAR	LEN_VARCHAR	BYTES_VARCHAR
SQL       	    3	        10	    SQL	                3	        3
DATABASE  	    8	        10	    DATABASE	        8	        8

*/

-------------------------------------------------------------------------------
-- 12 - Demonstrating padding
-------------------------------------------------------------------------------

SELECT 
'SQL' + 'X'        AS NormalConcat,
Code_CHAR + 'X'    AS CHAR_Concat,
Code_VARCHAR + 'X' AS VARCHAR_Concat
FROM Example_Char_Varchar;
GO

/*
Result:
NormalConcat	CHAR_Concat	    VARCHAR_Concat
SQLX	        SQL       X	    SQLX
SQLX	        DATABASE  X	    DATABASEX
*/