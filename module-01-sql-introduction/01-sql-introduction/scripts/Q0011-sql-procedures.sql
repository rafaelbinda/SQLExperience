/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-16
Version     : 1.0
Task        : Q0011 - Sql Server Programming Objects - STORED PROCEDURES
Databases   : AventureWorks 
Object      : Script
Description : Examples of SQL Server stored procedures
Notes       : notes/A0012-sql-server-programming-objects.md
=============================================================================== 
INDEX
1 - Simple Stored Procedure
2 - Stored Procedure with Parameters
3 - Stored Procedure with Multiple Parameters
4 - Stored Procedure with Output Parameter
5 - Stored Procedure with Conditional Logic
6 - Stored Procedure with Error Handling
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
-- 7 - Stored Procedure with Error Handling
-------------------------------------------------------------------------------