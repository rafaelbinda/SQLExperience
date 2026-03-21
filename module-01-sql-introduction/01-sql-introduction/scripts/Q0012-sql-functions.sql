/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-21
Version     : .0
Task        : Q0012 - Sql Server Programming Objects
Databases   : ExamplesDB 
Object      : Script
Description : Examples demonstrating SQL Server Functions, including scalar
              functions, table-valued functions, and usage scenarios
Notes       : notes/A0014-programming-objects-functions.md
=============================================================================== 
INDEX
1 - Scalar Function (Simple)  
2 - Scalar Function with Conditional Logic  
3 - Inline Table-Valued Function  
4 - Multi-Statement Table-Valued Function  
5 - Using Function in SELECT  
6 - Using CROSS APPLY with Table-Valued Function
=============================================================================== 
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

IF OBJECT_ID('dbo.Example_FunctionProducts', 'U') IS NOT NULL
    DROP TABLE dbo.Example_FunctionProducts;
GO

CREATE TABLE dbo.Example_FunctionProducts
(
    ProductID   INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(100),
    Price       DECIMAL(10,2)
);
GO

INSERT INTO dbo.Example_FunctionProducts (ProductName, Price)
VALUES
('Notebook', 3500.00),
('Mouse', 90.00),
('Keyboard', 150.00),
('Monitor', 1200.00);
GO

-------------------------------------------------------------------------------
-- FUNCTIONS
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 1 - Scalar Function (Simple)
-------------------------------------------------------------------------------
--Returns the sum of two numbers
 
CREATE OR ALTER FUNCTION dbo.ufn_Example_AddNumbers
(
    @Number1 INT,
    @Number2 INT
)
RETURNS INT
AS
BEGIN
    RETURN @Number1 + @Number2;
END;
GO

SELECT dbo.ufn_Example_AddNumbers(10, 20) AS Result;
GO

/*
Return:
    Result
      30
*/

-------------------------------------------------------------------------------
-- 2 - Scalar Function with Conditional Logic
-------------------------------------------------------------------------------
--Calculates a discount based on product price

CREATE OR ALTER FUNCTION dbo.ufn_Example_GetDiscount
(
    @Price DECIMAL(10,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Discount DECIMAL(10,2);

    IF @Price > 1000
        SET @Discount = @Price * 0.10;
    ELSE
        SET @Discount = @Price * 0.05;

    RETURN @Discount;
END;
GO

SELECT dbo.ufn_Example_GetDiscount(1500) AS Discount;
GO

/*
Return:
    Discount
     150.00
*/

-------------------------------------------------------------------------------
-- 3 - Inline Table-Valued Function
-------------------------------------------------------------------------------
--Returns products filtered by minimum price

CREATE OR ALTER FUNCTION dbo.ufn_Example_GetProductsAbovePrice
(
    @MinPrice DECIMAL(10,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT *
    FROM dbo.Example_FunctionProducts
    WHERE Price >= @MinPrice
);
GO

SELECT *
FROM dbo.ufn_Example_GetProductsAbovePrice(100);
GO

/*
Return:
ProductID	ProductName	    Price
1	        Notebook	    3500.00
3	        Keyboard	    150.00
4	        Monitor	        1200.00
*/

-------------------------------------------------------------------------------
-- 4 - Multi-Statement Table-Valued Function
-------------------------------------------------------------------------------
--Returns all products with calculated price including tax
--This function returns multiple rows (set-based)

CREATE OR ALTER FUNCTION dbo.ufn_Example_GetProductsWithTax
(
    @TaxRate DECIMAL(5,2)
)
RETURNS @Result TABLE
(
    ProductName VARCHAR(100),
    Price DECIMAL(10,2),
    PriceWithTax DECIMAL(10,2)
)
AS
BEGIN
    INSERT INTO @Result
    SELECT
    ProductName,
    Price,
    Price + (Price * @TaxRate)
    FROM dbo.Example_FunctionProducts;

    RETURN;
END;
GO

SELECT *
FROM dbo.ufn_Example_GetProductsWithTax(0.10);
GO

/*
Result:
ProductName	    Price	    PriceWithTax
Notebook	    3500.00	    3850.00
Mouse	        90.00	    99.00
Keyboard	    150.00	    165.00
Monitor	        1200.00	    1320.00
*/

-------------------------------------------------------------------------------
-- 5 - Using Function in SELECT
-------------------------------------------------------------------------------
--Applies a scalar function to each row in a query

SELECT
ProductName,
Price,
dbo.ufn_Example_GetDiscount(Price) AS Discount
FROM dbo.Example_FunctionProducts;
GO

/*
Result:
ProductName	Price	    Discount
Notebook	3500.00	    350.00
Mouse	    90.00	    4.50
Keyboard	150.00	    7.50
Monitor	    1200.00	    120.00
*/

-------------------------------------------------------------------------------
-- 6 - Using CROSS APPLY with Table-Valued Function
-------------------------------------------------------------------------------
--Returns each product with its calculated price including tax by applying the
--function to each row

-------------------------------------------------------------------------------
-- 6 - Using CROSS APPLY with Table-Valued Function
-------------------------------------------------------------------------------
--Returns each product with its calculated price including tax by applying the
--function to each row
--This function is designed for row-by-row usage with CROSS APPLY

CREATE OR ALTER FUNCTION dbo.ufn_Example_GetProductWithTax
(
    @ProductID INT,
    @TaxRate   DECIMAL(5,2)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
    ProductID,
    ProductName,
    Price,
    Price + (Price * @TaxRate) AS PriceWithTax
    FROM dbo.Example_FunctionProducts
    WHERE ProductID = @ProductID
);
GO

SELECT
p.ProductID,
p.ProductName,
p.Price,
f.PriceWithTax
FROM dbo.Example_FunctionProducts AS p
CROSS APPLY dbo.ufn_Example_GetProductWithTax(p.ProductID, 0.10) AS f;
GO

/*
Result:
ProductID	ProductName	    Price	    PriceWithTax
1	        Notebook	    3500.00	    3850.0000
2	        Mouse	        90.00	    99.0000
3	        Keyboard	    150.00	    165.0000
4	        Monitor	        1200.00	    1320.0000
*/