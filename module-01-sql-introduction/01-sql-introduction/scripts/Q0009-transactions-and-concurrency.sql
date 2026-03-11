/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-09
Version     : 1.0
Task        : Q0009-transactions-and-concurrency.sql
Databases   : ExamplesDB 
Object      : Script
Description : Examples demonstrating transactions and concurrency SQL Server
Notes       : notes/A0011-transactions-and-concurrency.md
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

-------------------------------------------------------------------------------
-- 3.1 - UPDATE WITHOUT WHERE
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- 3.2 - UPDATE with JOIN
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- 4.1 - DELETE without WHERE 
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- 6.1 - Basic transaction
-------------------------------------------------------------------------------

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

-------------------------------------------------------------------------------
-- 6.2 - Implicit transaction 
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- 6.3 - Explicit transaction
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- 6.4 - Transaction without error handling
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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
 
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- STEP 3 - Rollback the transaction

ROLLBACK;
GO

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
-- 6.5 - Transaction with error handling 
-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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

-------------------------------------------------------------------------------
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
-- 7 - Locking and Blocking
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
Id  ProductName  Price
1   Notebook     3500.00
2   Mouse        80.00
*/

-------------------------------------------------------------------------------
-- 7.1 - Shared Lock (S), Exclusive Lock (X), and Blocking
-------------------------------------------------------------------------------
/*
What this example demonstrates:
→ A SELECT statement acquires a Shared Lock (S) when reading data
→ The HOLDLOCK hint is used only for demonstration purposes to keep the
  Shared Lock until the end of the transaction
→ Under the default isolation level (READ COMMITTED), SQL Server normally
  releases the Shared Lock as soon as the SELECT statement completes
→ An UPDATE operation requires an Exclusive Lock (X)
→ Because Shared Locks and Exclusive Locks are incompatible, the UPDATE must wait
→ This waiting state is known as blocking
→ The blocking is released when the transaction is committed or rolled back
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
Id  ProductName  Price
1   Notebook     3500.00
2   Mouse        80.00
*/

-------------------------------------------------------------------------------
-- STEP 1 - Session A

/*
Do not commit the transaction yet.
This will keep the Shared Lock on the row.
*/

SELECT @@SPID AS SessionA_SPID;
GO

/*
Result:
SessionA_SPID
    58
*/

BEGIN TRAN;

SELECT *
FROM dbo.Example_SharedLock WITH (HOLDLOCK)
WHERE Id = 1;

/*
Notes:
→ HOLDLOCK is used here only for demonstration purposes
→ It keeps the Shared Lock until the transaction ends
→ By default, under READ COMMITTED, SQL Server usually releases
  the Shared Lock right after the SELECT statement completes

Default isolation level example:
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
 
Result:
Id  ProductName  Price
1   Notebook     3500.00
*/


-------------------------------------------------------------------------------
-- STEP 2 - Session B

/*
Open a new query window and execute:
*/

SELECT @@SPID AS SessionB_SPID;
GO

/*
Result:
SessionA_SPID
    60
*/

-------------------------------------------------------------------------------
-- STEP 2.1 - Session B
BEGIN TRAN;

UPDATE dbo.Example_SharedLock
SET Price = 3600.00
WHERE Id = 1;

/*
Expected behavior:
→ The UPDATE in Session B will remain waiting
→ This happens because Session A is holding a Shared Lock (S)
→ An UPDATE requires an Exclusive Lock (X)
→ Shared and Exclusive Locks are incompatible
*/

-------------------------------------------------------------------------------
-- STEP 3 - Session C (Check the lock)

/*
Open a third query window and execute.
Replace <SessionA_SPID> and <SessionB_SPID> with the values returned by @@SPID.
*/

SELECT
tl.request_session_id              AS SessionID,
tl.resource_type                   AS ResourceType,
tl.request_mode                    AS LockMode,
tl.request_status                  AS LockStatus,
tl.resource_associated_entity_id   AS AssociatedEntityID
FROM sys.dm_tran_locks AS tl
WHERE tl.request_session_id IN ('<SessionA_SPID>', '<SessionB_SPID>')
ORDER BY tl.request_session_id, tl.resource_type, tl.request_mode;

/*
What to look for:
→ Session A should show a Shared Lock (S) with status GRANT
→ Session B may show a waiting request related to the UPDATE
→ ResourceType may appear as KEY, PAGE, OBJECT, or RID
  depending on the execution plan and storage structure

Result:

SessionID	    ResourceType	LockMode	LockStatus	AssociatedEntityID
58	            DATABASE	    S	        GRANT	    0                  
58	            KEY	            S	        GRANT	    72057594049265664
58	            OBJECT	        IS	        GRANT	    370100359        
58	            PAGE	        IS	        GRANT	    72057594049265664     
60	            DATABASE	    S	        GRANT	    0
60	            KEY	            X	        WAIT	    72057594049265664
60	            OBJECT	        IX	        GRANT	    370100359
60	            PAGE	        IX	        GRANT	    72057594049265664

------------------------------------------------------------------------------- 
Lock analysis:

→ Observe that the blocking occurs at the KEY level (row lock)

-----------------------
Session 58 (Session A)
  
1 - ResourceType  LockMode    LockStatus
    DATABASE        S          GRANT
→   The session has a Shared Lock at the database level

2 - ResourceType  LockMode    LockStatus
    OBJECT          IS         GRANT
→   Intent Shared lock on the table
→   This indicates that Shared Locks will be placed at lower levels

3 - ResourceType  LockMode    LockStatus
    PAGE            IS          GRANT
→   Intent Shared lock at the page level

4 - ResourceType  LockMode    LockStatus
    KEY             S           GRANT
→   The actual Shared Lock on the row (Id = 1).
→   This lock is being held because the SELECT was executed with HOLDLOCK

In summary:
→ 1 - Holds a Shared Lock (S) on the row (KEY) due to the SELECT with HOLDLOCK
→ 2 - Intent Shared (IS) locks appear at OBJECT and PAGE levels as part of SQL 
      Server lock hierarchy

-----------------------
Session 60 (Session B)

1 - ResourceType  LockMode    LockStatus
    DATABASE        S           GRANT
→   Normal shared access to the database

2 - ResourceType  LockMode    LockStatus
    OBJECT          IX          GRANT
→   Intent Exclusive lock indicating that the session intends to modify data

3 - ResourceType  LockMode    LockStatus
    PAGE            IX          GRANT
→   Intent Exclusive lock at the page level

4 - ResourceType  LockMode    LockStatus
    KEY             X           WAIT
→   The session is requesting an Exclusive Lock to perform the UPDATE, however, 
    it must wait because Session 58 is holding a Shared Lock (S) on the same row

In summary:
→ 1 - Requests an Exclusive Lock (X) on the row (KEY) to perform the UPDATE
→ 2 - Intent Exclusive (IX) locks appear at OBJECT and PAGE levels, indicating
      the intention to modify data

-----------------------
→ Blocking reason:
Session 58 : KEY  S  GRANT
Session 60 : KEY  X  WAIT

-----------------------
→ Request_status meaning:
GRANT   = lock successfully granted to the session
WAIT    = the session is waiting for the lock
CONVERT = SQL Server is converting an existing lock to another type

→ Shared (S) and Exclusive (X) locks are not compatible

→ Therefore, Session 60 must wait until Session 58 releases the lock
  (by executing COMMIT or ROLLBACK)

*/

-------------------------------------------------------------------------------
-- STEP 4 - Releasing the lock

-- 4.1 - Return to Session A and execute:
COMMIT;

-- 4.2 - Return to Session B and execute:

COMMIT;

 
-------------------------------------------------------------------------------
-- 8 - Deadlock
-------------------------------------------------------------------------------
/*
What this example demonstrates:
→ A deadlock occurs when two sessions hold locks on different resources
  and each session tries to acquire a lock held by the other
→ Neither session can proceed, creating a circular blocking dependency
→ SQL Server automatically detects the deadlock and selects one session
  as the deadlock victim
→ The victim transaction is rolled back so the other transaction can continue
*/

CREATE TABLE dbo.Example_Deadlock
(
    Id INT PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_Deadlock (Id, ProductName, Price)
VALUES
(1, 'Notebook', 3500.00),
(2, 'Mouse', 80.00);
GO

SELECT *
FROM dbo.Example_Deadlock;
GO

/*
Result:
Id  ProductName  Price
1   Notebook     3500.00
2   Mouse        80.00
*/

-------------------------------------------------------------------------------
-- STEP 1 - Session A

/*
→ Open a new query window (Session A) and execute
→ Do not commit the transaction
*/

BEGIN TRAN;

UPDATE dbo.Example_Deadlock
SET Price = 3550.00
WHERE Id = 1;

/*
→ Session A now holds an Exclusive Lock (X) on row Id = 1
*/

WAITFOR DELAY '00:00:10';

UPDATE dbo.Example_Deadlock
SET Price = 90.00
WHERE Id = 2;

WAITFOR DELAY '00:00:10';

COMMIT;

-------------------------------------------------------------------------------
-- STEP 2 - Session B
 
/*
→ Open another query window (Session B) and execute at the same time
→ Do not commit the transaction until the deadlock occurs
*/

BEGIN TRAN;

UPDATE dbo.Example_Deadlock
SET Price = 85.00
WHERE Id = 2;

/*
→ Session B now holds an Exclusive Lock (X) on row Id = 2
*/

WAITFOR DELAY '00:00:10';

UPDATE dbo.Example_Deadlock
SET Price = 3600.00
WHERE Id = 1;

WAITFOR DELAY '00:00:10';

COMMIT;

/*
1 - Expected behavior:
→ Session A locks row Id = 1
→ Session B locks row Id = 2

2 - Then:
→ Session A tries to update Id = 2 (locked by Session B)
→ Session B tries to update Id = 1 (locked by Session A)

3 - This creates a circular dependency:
→ Session A → waiting for Session B
→ Session B → waiting for Session A

4 - SQL Server detects the deadlock and automatically chooses one session as the
    deadlock victim

5 - The victim receives the error:
Msg 1205, Level 13, State 51, Line 13
Transaction (Process ID 65) was deadlocked on lock resources with another process
and has been chosen as the deadlock victim. Rerun the transaction.
Completion time: 2026-03-10T23:14:43.7955378-03:00

→ The other session continues execution
*/

SELECT *
FROM dbo.Example_Deadlock;
GO

/*
Result:
Id	ProductName	Price
1	Notebook	3550.00
2	Mouse	    90.00
*/