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
→ SQL Server allows UPDATE statements using JOINs to update data based on  
  values from another table
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


-------------------------------------------------------------------------------
-- 6 - Transactions
-------------------------------------------------------------------------------

-- 6.1 - Basic transaction

CREATE TABLE dbo.Example_Transaction
(
    Id INT IDENTITY(1,1),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

--Viewing current transaction count
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/

--Starting a transaction
BEGIN TRAN;

INSERT INTO dbo.Example_Transaction (ProductName, Price)
VALUES ('Monitor', 900.00);

--Checking open transactions
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       1
*/

--Committing the transaction
COMMIT;
GO

--Checking transaction count again
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/

--Viewing inserted data
SELECT *
FROM dbo.Example_Transaction;
GO

/*
Result:
Id	ProductName	    Price
1	Monitor	        900.00
*/


-- 6.2 - Implicit transaction 
/*
What this example demonstrates:
→ The session enables implicit transactions using SET IMPLICIT_TRANSACTIONS ON
→ A transaction is automatically started when a data modification statement is 
  executed
→ @@TRANCOUNT is used to verify that a transaction was opened automatically
→ The transaction remains open until it is explicitly finalized
→ The transaction is completed using COMMIT
*/

--Enabling implicit transactions
SET IMPLICIT_TRANSACTIONS ON;
GO

--Checking current transaction count
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/


--Executing a statement that starts a transaction
INSERT INTO dbo.Example_Transaction (ProductName, Price)
VALUES ('Keyboard', 150.00);
GO

/*
Result
Commands completed successfully.
Completion time: 2026-03-09T22:17:02.3364807-03:00
*/

--Checking transaction count again
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       1
*/

--Finalizing transaction
COMMIT;
GO

--Disabling implicit transactions
SET IMPLICIT_TRANSACTIONS OFF;
GO

--Checking transaction count again
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       1
*/


-- 6.3 - Explicit transaction
/*
What this example demonstrates:
→ A transaction is started manually using BEGIN TRAN
→ One or more operations are executed inside the transaction
→ @@TRANCOUNT is used to verify the number of open transactions
→ The transaction is finalized explicitly using COMMIT
→ After the COMMIT, @@TRANCOUNT returns to 0, indicating that no transactions
  remain open
*/

CREATE TABLE dbo.Example_ExplicitTransaction
(
    Id INT IDENTITY(1,1),
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

--Checking transaction count before starting
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/


--Starting explicit transaction
BEGIN TRAN;

INSERT INTO dbo.Example_ExplicitTransaction (ProductName, Price)
VALUES ('Headset', 250.00);

/*
Result:
Commands completed successfully.
Completion time: 2026-03-09T22:19:51.8555532-03:00
*/

--Checking transaction count inside the transaction
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       1
*/

--Committing transaction
COMMIT;
GO


--Checking transaction count after commit
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/


--Viewing inserted data
SELECT *
FROM dbo.Example_ExplicitTransaction;
GO

/*
Result:
Id	ProductName	    Price
1	Headset	        250.00
*/


-- 6.4 - Transaction without error handling
/*
What this example demonstrates:
→ Start of a transaction with BEGIN TRAN
→ Execution of a valid operation
→ An error occurs during the second operation
→ Absence of error handling
*/
CREATE TABLE dbo.Example_Transaction_NoErrorHandling
(
    Id INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_Transaction_NoErrorHandling (Id, ProductName, Price)
VALUES
(1, 'Notebook', 3500.00),
(2, 'Mouse', 80.00);
GO

--Viewing original data
SELECT *
FROM dbo.Example_Transaction_NoErrorHandling;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/

-- STEP 1 -  Execute the transaction statements below

--Starting transaction
BEGIN TRAN;

--First operation (valid)
UPDATE dbo.Example_Transaction_NoErrorHandling
SET Price = 3600.00
WHERE Id = 1;

--Second operation (will generate error - duplicate primary key)
INSERT INTO dbo.Example_Transaction_NoErrorHandling (Id, ProductName, Price)
VALUES (1, 'Keyboard', 150.00);
GO

/*
Result:
Msg 2627, Level 14, State 1, Line 626
Violation of PRIMARY KEY constraint 'PK__Example___3214EC07E9B383C7'.
Cannot insert duplicate key in object 'dbo.Example_Transaction_NoErrorHandling'. 
The duplicate key value is (1).
The statement has been terminated.
Completion time: 2026-03-09T22:32:37.8700010-03:00
*/
 
-- STEP 2 - Execute the queries below and observe the results

--Check if the transaction is still open
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       1
*/

--Viewing table data
SELECT *
FROM dbo.Example_Transaction_NoErrorHandling;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3600.00
2	Mouse	        80.00
*/

-- STEP 3 - Rollback the transaction

ROLLBACK;
GO

-- STEP 4 - Verify that the changes were reverted 

SELECT @@TRANCOUNT AS OpenTransactions;

/*
Result:
OpenTransactions
       0
*/

--Viewing table data
SELECT *
FROM dbo.Example_Transaction_NoErrorHandling;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/


-- 6.5 - Transaction with error handling 
/*
What this example demonstrates:
→ The error occurs during the second operation
→ The CATCH block captures the error
→ The ROLLBACK undoes the entire transaction
→ @@TRANCOUNT returns to 0
→ The valid UPDATE is also reverted
*/

CREATE TABLE dbo.Example_Transaction_WithErrorHandling
(
    Id INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_Transaction_WithErrorHandling (Id, ProductName, Price)
VALUES
(1, 'Notebook', 3500.00),
(2, 'Mouse', 80.00);
GO

SELECT *
FROM dbo.Example_Transaction_WithErrorHandling;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/


-- STEP 1 - Execute the block below 

BEGIN TRY

    BEGIN TRAN;

    --First operation (valid)
    UPDATE dbo.Example_Transaction_WithErrorHandling
    SET Price = 3600.00
    WHERE Id = 1;

    --Second operation (will generate error - duplicate primary key)
    INSERT INTO dbo.Example_Transaction_WithErrorHandling (Id, ProductName, Price)
    VALUES (1, 'Keyboard', 150.00);

    COMMIT;

END TRY
BEGIN CATCH

    --Rollback transaction if it is still open
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    --Return error information
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
ErrorNumber     =   2627	
ErrorSeverity   =   14
ErrorState	    =   1
ErrorLine	    =   12
ErrorMessage    =   Violation of PRIMARY KEY constraint 'PK__Example___3214EC07278D3CB5'. 
Cannot insert duplicate key in object 'dbo.Example_Transaction_WithErrorHandling'. 
The duplicate key value is (1).
*/


-- STEP 2 - Check transaction count and table data 

--Verify that no transaction remains open
SELECT @@TRANCOUNT AS OpenTransactions;
GO

/*
Result:
OpenTransactions
       0
*/

--Verify final table data
SELECT *
FROM dbo.Example_Transaction_WithErrorHandling;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/


-------------------------------------------------------------------------------
-- 7 - Blocking Session
-------------------------------------------------------------------------------

CREATE TABLE dbo.Example_Blocking
(
    Id INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_Blocking (Id, ProductName, Price)
VALUES
(1, 'Notebook', 3500.00),
(2, 'Mouse', 80.00);
GO

SELECT *
FROM dbo.Example_Blocking;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/

--  7.1 - Shared Lock (S) example
/*
What this example demonstrates:
→ A SELECT statement can acquire a Shared Lock (S) when reading data
→ Shared Locks allow multiple sessions to read the same resource simultaneously
→ An UPDATE operation requires an Exclusive Lock (X)
→ Because Shared Locks and Exclusive Locks are incompatible, the UPDATE must wait
→ The HOLDLOCK hint is used to retain the Shared Lock until the end of the 
  transaction for demonstration purposes
→ Under the default isolation level (READ COMMITTED), a SELECT normally releases 
  the Shared Lock immediately after the statement completes
*/

 
CREATE TABLE dbo.Example_SharedLock
(
    Id INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_SharedLock (Id, ProductName, Price)
VALUES
(1, 'Notebook', 3500.00),
(2, 'Mouse', 80.00);
GO

SELECT *
FROM dbo.Example_SharedLock;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        80.00
*/

--Session A
/*
Do not commit the transaction yet
This will keep the lock on the row
*/

BEGIN TRAN;

SELECT *
FROM dbo.Example_SharedLock WITH (HOLDLOCK)
WHERE Id = 1;

/*
→ HOLDLOCK is used here only for demonstration purposes
→ By default, SQL Server releases the Shared Lock immediately
  after the SELECT statement finishes under READ COMMITTED
→ Using HOLDLOCK keeps the Shared Lock until the transaction ends
*/ 

/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
*/


--Session B
--Open a new query window and execute:

UPDATE dbo.Example_SharedLock
SET Price = 3600.00
WHERE Id = 1;

/*
Expected behavior:
→ The UPDATE in Session B will remain waiting
→ This happens because Session A is holding a Shared Lock (S)
→ An UPDATE requires an Exclusive Lock (X)
→ Shared and Exclusive locks are incompatible
*/
 
---------------------------------------------------
--?????????????????  CONTINUE  ?????????????????
---------------------------------------------------


/*====================================================
  Releasing the lock
====================================================*/

--Return to SESSION A and execute:

COMMIT;


-- 7.2 - Exclusive Lock (X) example
/*
What this example demonstrates:
→ A transaction acquires an Exclusive Lock (X) when modifying data
→ Other sessions attempting to access the same resource must wait
→ This waiting state is known as blocking
→ The blocking is released when the transaction is committed or rolled back
*/

--Session A
/*
Do not commit the transaction yet
This will keep the lock on the row
*/

BEGIN TRAN;

UPDATE dbo.Example_Blocking
SET Price = 3600.00
WHERE Id = 1;

/*
Result:
Commands completed successfully.
Completion time: 2026-03-09T22:49:57.5335567-03:00
*/

--Session B
--Open a new query window and execute:

SELECT *
FROM dbo.Example_Blocking
WHERE Id = 1;

/*
Expected behavior:
→ The query in Session B will remain waiting
→ This happens because Session A holds an Exclusive Lock
→ Session B must wait until the resource is released
→ Releasing the lock
*/

--In Session A, execute:
COMMIT;

/*
After that:
→ The lock will be released
→ The query in Session B will continue execution
*/


