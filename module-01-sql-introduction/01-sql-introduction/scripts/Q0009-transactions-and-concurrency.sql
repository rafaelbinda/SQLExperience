/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-09
Version     : 1.0
Task        : Q0009-transactions-and-concurrency.sql
Databases   : ExamplesDB 
Object      : Script
Description : Examples demonstrating transactions and concurrency SQL Server
Notes       : A0011-transactions-and-concurrency.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- 1 - INSERT 
-------------------------------------------------------------------------------
CREATE TABLE dbo.Example_Insert
(
    Id INT IDENTITY(1,1),
    CustomerName VARCHAR(100),
    City VARCHAR(100)
);
GO
 
INSERT INTO dbo.Example_Insert (CustomerName, City)
VALUES ('Rafael', 'Chapecó');
GO

--Viewing the inserted record
SELECT *
FROM dbo.Example_Insert;
GO

/*
Result:
Id	CustomerName	City
1	Rafael	        Chapecó
*/

--INSERT using DEFAULT value
CREATE TABLE dbo.Example_Insert_Default
(
    Id INT IDENTITY(1,1),
    CreatedAt DATETIME DEFAULT GETDATE(),
    Description VARCHAR(100)
);
GO

--Inserting record without specifying the DEFAULT column
INSERT INTO dbo.Example_Insert_Default (Description)
VALUES ('First record');
GO

--Viewing the inserted record
SELECT *
FROM dbo.Example_Insert_Default;
GO

/*
Result:         
Id	CreatedAt	                Description
1	2026-03-09 20:24:53.923	    First record
*/

-------------------------------------------------------------------------------
-- 2 - SELECT INTO 
-------------------------------------------------------------------------------
--SELECT INTO creates the table automatically based on the result set structure

CREATE TABLE dbo.Example_SelectInto_Source
(
    Id INT IDENTITY(1,1),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);

INSERT INTO dbo.Example_SelectInto_Source (ProductName, Price)
VALUES 
('Notebook', 3500.00),
('Mouse', 80.00),
('Keyboard', 150.00);
GO

SELECT *
FROM dbo.Example_SelectInto_Source;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
3	Keyboard	    150.00
*/

SELECT *
INTO dbo.Example_SelectInto_Backup
FROM dbo.Example_SelectInto_Source;
GO

--Viewing the new table created with SELECT INTO
SELECT *
FROM dbo.Example_SelectInto_Backup;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
3	Keyboard	    150.00
*/

-------------------------------------------------------------------------------
-- 3 - UPDATE
-------------------------------------------------------------------------------

CREATE TABLE dbo.Example_Update
(
    Id INT IDENTITY(1,1),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_Update (ProductName, Price)
VALUES
('Monitor', 900.00),
('Keyboard', 150.00),
('Mouse', 80.00);
GO

SELECT *
FROM dbo.Example_Update;
GO

/*
Result:
Id	ProductName	    Price
1	Monitor	        900.00
2	Keyboard	    150.00
3	Mouse	        80.00
*/

--Updating a specific record
UPDATE dbo.Example_Update
SET Price = 950.00
WHERE ProductName = 'Monitor';
GO

--Viewing updated data
SELECT *
FROM dbo.Example_Update;
GO

/*
Result:
Id	ProductName	    Price
1	Monitor	        950.00
2	Keyboard	    150.00
3	Mouse	        80.00
*/


-- 3.1 - UPDATE WITHOUT WHERE
UPDATE dbo.Example_Update
SET Price = 333.33; 
GO

--Viewing updated data
SELECT *
FROM dbo.Example_Update;
GO

/*
Result:
Id	ProductName	    Price
1	Monitor	        333.33
2	Keyboard	    333.33
3	Mouse	        333.33
*/

-- 3.2 - UPDATE with JOIN
/*
SQL Server allows UPDATE statements using JOINs to update data based on values 
from another table
*/

--Creating Customers table
CREATE TABLE dbo.Example_UpdateJoin_Customers
(
    Id INT IDENTITY(1,1),
    CustomerName VARCHAR(100),
    City VARCHAR(100)
);
GO

--Creating Addresses table
CREATE TABLE dbo.Example_UpdateJoin_Addresses
(
    CustomerId INT,
    City VARCHAR(100)
);
GO
 
--Inserting sample data into Customers
INSERT INTO dbo.Example_UpdateJoin_Customers (CustomerName, City)
VALUES
('Rafael', 'Unknown'),
('Danieli', 'Unknown'),
('Larissa', 'Unknown');
GO

--Viewing original data
SELECT *
FROM dbo.Example_UpdateJoin_Customers;
GO

/*
Result:
Id	CustomerName	City
1	Rafael	        Unknown
2	Danieli	        Unknown
3	Larissa	        Unknown
*/ 

--Inserting sample data into Addresses
INSERT INTO dbo.Example_UpdateJoin_Addresses (CustomerId, City)
VALUES
(1, 'Chapecó'),
(2, 'Curitiba'),
(3, 'Florianópolis');
GO

--Viewing original data
SELECT *
FROM dbo.Example_UpdateJoin_Addresses;
GO

/*
Result: 
CustomerId	City
1	        Chapecó
2	        Curitiba
3	        Florianópolis
*/

--Updating Customers table using JOIN


UPDATE C
SET C.City = A.City
FROM dbo.Example_UpdateJoin_Customers C
INNER JOIN dbo.Example_UpdateJoin_Addresses A
    ON C.Id = A.CustomerId;
GO

--Viewing updated data
SELECT *
FROM dbo.Example_UpdateJoin_Customers;
GO

/*
Result:
Id	CustomerName	City
1	Rafael	        Chapecó
2	Danieli	        Curitiba
3	Larissa	        Florianópolis
*/

-------------------------------------------------------------------------------
-- 4 - DELETE
-------------------------------------------------------------------------------

CREATE TABLE dbo.Example_Delete
(
    Id INT IDENTITY(1,1),
    CustomerName VARCHAR(100),
    City VARCHAR(100)
);
GO

INSERT INTO dbo.Example_Delete (CustomerName, City)
VALUES
('Rafael', 'Chapecó'),
('Danieli', 'Curitiba'),
('Larissa', 'Florianópolis');
GO

SELECT *
FROM dbo.Example_Delete;
GO

/*
Result:
Id	CustomerName	City
1	Rafael	        Chapecó
2	Danieli	        Curitiba
3	Larissa	        Florianópolis
*/

--Deleting a specific record
DELETE FROM dbo.Example_Delete
WHERE CustomerName = 'Danieli';
GO

--Viewing remaining data
SELECT *
FROM dbo.Example_Delete;
GO

/*
Result:
Id	CustomerName	City
1	Rafael	        Chapecó
3	Larissa	        Florianópolis
*/

-- 4.1 - DELETE without WHERE 

DELETE FROM dbo.Example_Delete;
GO

/*
Result:
Id	CustomerName	City

DELETE without WHERE will remove all rows from the table
*/

-------------------------------------------------------------------------------
-- 5 - Error handling in older versions of SQL Server (legacy approach)
-------------------------------------------------------------------------------

--Simulating an error (division by zero)
SELECT 100 / 0;

--Checking if an error occurred
IF @@ERROR <> 0
    GOTO ErrorHandler;

PRINT 'Operation completed successfully';
GOTO EndProcess;

ErrorHandler:
PRINT 'An error occurred during execution';

EndProcess:
PRINT 'End of process';
GO

/*
Result:

Msg 8134, Level 16, State 1, Line 342
Divide by zero error encountered.
An error occurred during execution
End of process

Completion time: 2026-03-09T21:39:42.4914894-03:00
*/

-- 5.1 - Error handling in current versions of SQL Server


BEGIN TRY
    SELECT 100 / 0;
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER()   AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE()    AS ErrorState,
        ERROR_LINE()     AS ErrorLine,
        ERROR_MESSAGE()  AS ErrorMessage;

END CATCH;
GO

/*
Result:
ErrorNumber	ErrorSeverity	ErrorState	ErrorLine	ErrorMessage
8134	    16	            1	        2	        Divide by zero error encountered.
*/



