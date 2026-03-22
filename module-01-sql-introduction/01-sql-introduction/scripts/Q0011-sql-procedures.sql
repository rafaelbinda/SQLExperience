/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-16
Version     : 2.0
Task        : Q0011 - Sql Server Programming Objects
Databases   : AventureWorks 
Object      : Script
Description : Examples of SQL Server Stored Procedures
Notes       : notes/A0013-programming-objects-stored-procedures.md
=============================================================================== 
INDEX
1  - Simple Stored Procedure
2  - Stored Procedure with Parameters
3  - Stored Procedure with Multiple Parameters
4  - Stored Procedure with Output Parameter
5  - Stored Procedure with Conditional Logic
6  - Stored Procedure with Error Handling
7  - Stored Procedure with Transaction
8  - Stored Procedure with Transaction and Error Handling (Using THROW)
9  - Stored Procedure with Transaction and Error Handling (Using RAISERROR)
10 - Stored Procedure with WHILE Loop
11 - Stored Procedure using Cursor
12 - Output Parameter vs SELECT
13 - Managing Stored Procedures (DROP)
=============================================================================== 
*/

SET NOCOUNT ON;
GO 
 
USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- STORED PROCEDURES 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 1 - Simple Stored Procedure
-------------------------------------------------------------------------------
-- Returns a list of customers

CREATE OR ALTER PROCEDURE Sales.usp_GetCustomers
AS
BEGIN
    SELECT
    CustomerID,
    PersonID,
    StoreID,
    TerritoryID
    FROM Sales.Customer;
END;
GO

--Execution
EXEC Sales.usp_GetCustomers;
GO

/*
Result: 19820 rows

CustomerID	PersonID	StoreID	TerritoryID
1	        NULL	    934	        1
2	        NULL	    1028	    1
3	        NULL	    642     	4
4	        NULL	    932	        4
5	        NULL	    1026	    4
...
*/

-------------------------------------------------------------------------------
-- 2 - Stored Procedure with Parameters
-------------------------------------------------------------------------------
--Returns sales orders for a specific customer

CREATE OR ALTER PROCEDURE Sales.usp_GetSalesOrdersByCustomer
    @CustomerID INT
AS
BEGIN
    SELECT
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID;
END;
GO

--Execution
EXEC Sales.usp_GetSalesOrdersByCustomer
    @CustomerID = 30111;
GO

/*
Result:
CustomerID	SalesOrderID	OrderDate	                TotalDue
30111	    43881	        2005-08-01 00:00:00.000	    43706,8175
30111	    44528	        2005-11-01 00:00:00.000	    122500,6617
30111	    45307	        2006-02-01 00:00:00.000	    32142,9153
30111	    46066	        2006-05-01 00:00:00.000	    113042,7512
*/

-------------------------------------------------------------------------------
-- 3 - Stored Procedure with Multiple Parameters
-------------------------------------------------------------------------------
--Filters orders by customer and date range

CREATE OR ALTER PROCEDURE Sales.usp_GetSalesOrdersByDate
    @CustomerID INT,
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT
    CustomerID,
    SalesOrderID,
    OrderDate,
    TotalDue
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID
    AND OrderDate BETWEEN @StartDate AND @EndDate;
END;
GO

--Execution
EXEC Sales.usp_GetSalesOrdersByDate
    @CustomerID = 30111,
    @StartDate = '2005-08-01',
    @EndDate = '2006-02-01';
GO

/*
Result:
CustomerID	SalesOrderID	OrderDate	                TotalDue
30111	    43881	        2005-08-01 00:00:00.000	    43706,8175
30111	    44528	        2005-11-01 00:00:00.000	    122500,6617
30111	    45307	        2006-02-01 00:00:00.000	    32142,9153
*/

-------------------------------------------------------------------------------
-- 4 - Stored Procedure with Output Parameter
-------------------------------------------------------------------------------
-- Returns the total number of orders for a customer.

CREATE OR ALTER PROCEDURE Sales.usp_GetCustomerOrderCount
    @CustomerID INT,
    @OrderCount INT OUTPUT
AS
BEGIN
    SELECT
    @OrderCount = COUNT(*)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID;
END;
GO
 

--Execution
DECLARE @TotalOrders INT;

EXEC Sales.usp_GetCustomerOrderCount
    @CustomerID = 30111,
    @OrderCount = @TotalOrders OUTPUT;

SELECT @TotalOrders AS TotalOrders;
GO

/*
Result:
TotalOrders
    4
*/

-------------------------------------------------------------------------------
-- 5 - Stored Procedure with Conditional Logic
-------------------------------------------------------------------------------
-- Demonstrates basic control flow using IF

CREATE OR ALTER PROCEDURE Sales.usp_GetCustomerStatus
    @CustomerID INT
AS
BEGIN

    DECLARE @TotalOrders INT;

    SELECT
    @TotalOrders = COUNT(*)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID;

    IF @TotalOrders > 10
        BEGIN
            SELECT
            @CustomerID AS CustomerID,
            'Frequent Customer' AS CustomerStatus,
            @TotalOrders AS TotalOrders;
        END
    ELSE
        BEGIN
            SELECT
            @CustomerID AS CustomerID,
            'Regular Customer' AS CustomerStatus,
            @TotalOrders AS TotalOrders;
        END

END;
GO

--Execution
EXEC Sales.usp_GetCustomerStatus @CustomerID = 30111;
GO

/*
Result:
CustomerID	CustomerStatus	    TotalOrders
30111	    Regular Customer	    4
*/

-------------------------------------------------------------------------------
-- 6 - Stored Procedure with Error Handling
-------------------------------------------------------------------------------
--Example using TRY...CATCH

CREATE OR ALTER PROCEDURE dbo.usp_TestErrorHandling
    @Number INT,
    @Divide INT
AS
BEGIN
    BEGIN TRY
        SELECT @Number / @Divide;
    END TRY
    BEGIN CATCH
        SELECT
            ERROR_NUMBER()  AS ErrorNumber,
            ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO

-- Execution
EXEC dbo.usp_TestErrorHandling @Number = 5, @Divide = 0;
GO

/*
Result:
ErrorNumber	    ErrorMessage
    8134	    Divide by zero error encountered.
*/

-------------------------------------------------------------------------------
-- 7 - Stored Procedure with Transaction
-------------------------------------------------------------------------------
 
USE ExamplesDB;
GO

IF OBJECT_ID('dbo.Example_StoredProcedureProducts', 'U') IS NOT NULL
    DROP TABLE dbo.Example_StoredProcedureProducts;
GO

CREATE TABLE dbo.Example_StoredProcedureProducts
(
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100),
    Price       DECIMAL(10,2)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_InsertProductWithTransaction
    @ProductName VARCHAR(100),
    @Price       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    INSERT INTO dbo.Example_StoredProcedureProducts (ProductName, Price)
    VALUES (@ProductName, @Price);

    COMMIT TRANSACTION;
END;
GO

-- Execution
EXEC dbo.usp_Example_InsertProductWithTransaction 
    @ProductName = 'Notebook',
    @Price = 3500.00;
GO

EXEC dbo.usp_Example_InsertProductWithTransaction 
    @ProductName = 'Mouse',
    @Price = 50.00;
GO

EXEC dbo.usp_Example_InsertProductWithTransaction 
    @ProductName = 'Monitor',
    @Price = 799.00;
GO

SELECT * FROM dbo.Example_StoredProcedureProducts;
GO

/*Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
2	        Mouse	        50.00
3	        Monitor	        799.00
*/

-------------------------------------------------------------------------------
-- 8 - Stored Procedure with Transaction and Error Handling (Using THROW)
-------------------------------------------------------------------------------

-- THROW is the modern alternative and provides better error handling

USE ExamplesDB;
GO

IF OBJECT_ID('dbo.Example_StoredProcedureProducts', 'U') IS NOT NULL
    DROP TABLE dbo.Example_StoredProcedureProducts;
GO

CREATE TABLE dbo.Example_StoredProcedureProducts
(
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100),
    Price       DECIMAL(10,2)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW 
    @ProductName VARCHAR(100),
    @Price       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Price <= 0
        BEGIN
            
            /*
            → ";" is required before THROW.
            → Otherwise, SQL Server may return the following error:
              Incorrect syntax near 'THROW'.
              Expecting CONVERSATION, DIALOG, DISTRIBUTED or TRANSACTION.
            */

            ;THROW 50001, 'Price must be greater than zero.', 1;
        
        END;

        INSERT INTO dbo.Example_StoredProcedureProducts (ProductName, Price)
        VALUES (@ProductName, @Price);

        COMMIT TRANSACTION;
    END TRY
     
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO

-- Valid execution
EXEC dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW
    @ProductName = 'Notebook',
    @Price = 3500.00;
GO

EXEC dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW 
    @ProductName = 'Mouse',
    @Price = 50.00;
GO

EXEC dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW 
    @ProductName = 'Monitor',
    @Price = 799.00;
GO

SELECT *
FROM dbo.Example_StoredProcedureProducts;
GO

/*Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
2	        Mouse	        50.00
3	        Monitor	        799.00
*/

-- Invalid execution
EXEC dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW
    @ProductName = 'Mouse',
    @Price = -50.00;
GO

/*
Result:
Msg 50001, Level 16, State 1, Procedure dbo.usp_Example_InsertProduct_ErrorHandling_with_THROW, 
Line 22 [Batch Start Line 384]
Price must be greater than zero.

Completion time: 2026-03-18T20:26:15.2491664-03:00
*/


-------------------------------------------------------------------------------
-- 9 - Stored Procedure with Transaction and Error Handling (Using RAISERROR)
-------------------------------------------------------------------------------

-- RAISERROR is a legacy feature and is kept for backward compatibility

USE ExamplesDB;
GO

IF OBJECT_ID('dbo.Example_StoredProcedureProducts', 'U') IS NOT NULL
    DROP TABLE dbo.Example_StoredProcedureProducts;
GO

CREATE TABLE dbo.Example_StoredProcedureProducts
(
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100),
    Price       DECIMAL(10,2)
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_InsertProductWith_Raiserror
    @ProductName VARCHAR(100),
    @Price       DECIMAL(10,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Price <= 0
        BEGIN
            RAISERROR ('Price must be greater than zero.', 16, 1);
            RETURN;
        END;

        INSERT INTO dbo.Example_StoredProcedureProducts (ProductName, Price)
        VALUES (@ProductName, @Price);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        -- Re-throw the error
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END;
GO

-- Valid execution
EXEC dbo.usp_Example_InsertProductWith_Raiserror
    @ProductName = 'Notebook',
    @Price = 3500.00;
GO

EXEC dbo.usp_Example_InsertProductWith_Raiserror 
    @ProductName = 'Mouse',
    @Price = 50.00;
GO

EXEC dbo.usp_Example_InsertProductWith_Raiserror 
    @ProductName = 'Monitor',
    @Price = 799.00;
GO

SELECT *
FROM dbo.Example_StoredProcedureProducts;
GO

/*
Result:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
2	        Mouse	        50.00
3	        Monitor	        799.00
*/

-- Invalid execution
EXEC dbo.usp_Example_InsertProductWith_Raiserror
    @ProductName = 'Mouse',
    @Price = -50.00;
GO

/*
Result:
Msg 50000, Level 16, State 1, Procedure dbo.usp_Example_InsertProductWith_Raiserror, 
Line 32 [Batch Start Line 495]
Price must be greater than zero.

Completion time: 2026-03-18T20:32:30.1286570-03:00
*/

-------------------------------------------------------------------------------
-- 10 - Stored Procedure with WHILE Loop
-------------------------------------------------------------------------------

-- WHILE loop executes repeatedly while the condition is TRUE

USE ExamplesDB;
GO

IF OBJECT_ID('dbo.Example_StoredProcedureCounter', 'U') IS NOT NULL
    DROP TABLE dbo.Example_StoredProcedureCounter;
GO

CREATE TABLE dbo.Example_StoredProcedureCounter
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    CounterValue INT
);
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_InsertCounterValues
    @MaxValue INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Counter INT = 1;

    WHILE @Counter <= @MaxValue
    BEGIN
        INSERT INTO dbo.Example_StoredProcedureCounter (CounterValue)
        VALUES (@Counter);

        SET @Counter = @Counter + 1 * 15;
    END;
END;
GO

-- Execution
EXEC dbo.usp_Example_InsertCounterValues 
    @MaxValue = 50;
GO

SELECT *
FROM dbo.Example_StoredProcedureCounter;

/*
Result:
Id	CounterValue
1	    1
2	    16
3	    31
4	    46
*/

-------------------------------------------------------------------------------
-- 11 - Stored Procedure using Cursor
-------------------------------------------------------------------------------
 
USE ExamplesDB;
GO

/*
→ Cursors process data row by row (RBAR - Row By Agonizing Row)
→ Use only when set-based operations are not possible
*/

IF OBJECT_ID('dbo.Example_StoredProcedureCursor', 'U') IS NOT NULL
    DROP TABLE dbo.Example_StoredProcedureCursor;
GO

CREATE TABLE dbo.Example_StoredProcedureCursor
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100),
    Price DECIMAL(10,2)
);
GO

-- Populate sample data
INSERT INTO dbo.Example_StoredProcedureCursor (ProductName, Price)
VALUES 
('Notebook', 3500.00),
('Mouse', 50.00),
('Monitor', 799.00);
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_ProcessProductsWithCursor
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductName VARCHAR(100);
    DECLARE @Price DECIMAL(10,2);

    DECLARE ProductCursor CURSOR FOR
        SELECT ProductName, Price
        FROM dbo.Example_StoredProcedureCursor;

    OPEN ProductCursor;

    FETCH NEXT FROM ProductCursor INTO @ProductName, @Price;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Example logic: increase price by 10%
        SET @Price = @Price * 1.10;

        UPDATE dbo.Example_StoredProcedureCursor
        SET Price = @Price
        WHERE ProductName = @ProductName;

        FETCH NEXT FROM ProductCursor INTO @ProductName, @Price;
    END;

    CLOSE ProductCursor;
    DEALLOCATE ProductCursor;
END;
GO

SELECT *
FROM dbo.Example_StoredProcedureCursor;
GO
/*
Result:
Id	ProductName	    Price
1	Notebook	    3500.00
2	Mouse	        50.00
3	Monitor	        799.00
*/

-- Execution
EXEC dbo.usp_Example_ProcessProductsWithCursor;
GO

SELECT *
FROM dbo.Example_StoredProcedureCursor;
GO

/*
Result:
Id	ProductName	    Price
1	Notebook	    3850.00
2	Mouse	        55.00
3	Monitor	        878.90
*/

-------------------------------------------------------------------------------
-- 12 - Output Parameter vs SELECT
-------------------------------------------------------------------------------
 
USE ExamplesDB;
GO

CREATE OR ALTER PROCEDURE dbo.usp_Example_OutputVsSelect
    @Number1 INT,
    @Number2 INT,
    @SumOutput INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- OUTPUT parameter
    SET @SumOutput = @Number1 + @Number2;

    -- SELECT result
    SELECT 
        @Number1 AS Number1,
        @Number2 AS Number2,
        (@Number1 + @Number2) AS SumResult;
END;
GO

-- Execution
DECLARE @Result INT;

EXEC dbo.usp_Example_OutputVsSelect
    @Number1 = 10,
    @Number2 = 20,
    @SumOutput = @Result OUTPUT;

-- OUTPUT value
SELECT @Result AS OutputValue;

/*
Result 1: SELECT returns a result set to the client 
    Number1	    Number2	    SumResult
      10	      20	       30

Result 2: OUTPUT returns a value to a variable
  OutputValue
      30
*/

-------------------------------------------------------------------------------
-- 13 - Managing Stored Procedures (DROP)
-------------------------------------------------------------------------------
--Demonstrates how to remove stored procedures from the database
--Dropping a procedure permanently removes it

DROP PROCEDURE IF EXISTS dbo.usp_Example_SimpleProcedure;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_WithParameters;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_WithMultipleParameters;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_WithOutputParameter;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_WithConditionalLogic;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_WithErrorHandling;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_InsertProductWithTransaction;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_InsertProductWithTransactionAndErrorHandling;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_InsertProductWithTransactionAndErrorHandling_Raiserror;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_InsertCounterValues;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_ProcessProductsWithCursor;
GO

DROP PROCEDURE IF EXISTS dbo.usp_Example_OutputVsSelect;
GO