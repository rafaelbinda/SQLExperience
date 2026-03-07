/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-06
Version     : 1.0
Task        : Q0008-sql-date-and-time-data-types.sql
Databases   : ExamplesDB 
Object      : Script
Description : Examples demonstrating special data types in SQL Server
Notes       : A0010-sql-data-types.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- 1 - UNIQUEIDENTIFIER
-------------------------------------------------------------------------------
/*
→ Best Practices for UNIQUEIDENTIFIER:

→ Avoid using `NEWID()` as a default value for clustered primary keys because it
  generates random values and can cause index fragmentation
  Example: PRIMARY KEY UNIQUEIDENTIFIER DEFAULT NEWID()

→ Prefer `NEWSEQUENTIALID()` when using `UNIQUEIDENTIFIER` as a primary key. 
  Sequential values reduce fragmentation and improve insert performance.
  Example: PRIMARY KEY UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID()

→ Consider using `INT IDENTITY` when global uniqueness is not required. 
  It is smaller (4 bytes) and more efficient for indexing.
  Example: INT IDENTITY

→ Remember that `UNIQUEIDENTIFIER` always uses **16 bytes of storage**, which is 
  larger than most numeric keys.

→ Avoid excessive use of GUIDs in frequently indexed tables due to increased storage
  and index size.
*/

CREATE TABLE Example_UniqueIdentifier
(
    Id UNIQUEIDENTIFIER,
    Description VARCHAR(50)
);
GO

INSERT INTO Example_UniqueIdentifier (Id, Description)
VALUES
(NEWID(), 'First record'),
(NEWID(), 'Second record'),
(NEWID(), 'Third record');
GO

SELECT *
FROM Example_UniqueIdentifier;
GO

/*
Result:
Id	                                    Description
4F1CCC09-E3AB-4C1C-99E4-2E60CC64CF40	First record
BB6DC92D-CECA-449C-9D25-DCC6379326C4	Second record
3357057E-586C-4E04-B6DB-168F822FC706	Third record
*/

SELECT 
Id,
DATALENGTH(Id) AS BytesStored
FROM Example_UniqueIdentifier;
GO

/*
Result:

→ The UNIQUEIDENTIFIER always occupies: 16 bytes

Id	                                    BytesStored
4F1CCC09-E3AB-4C1C-99E4-2E60CC64CF40	    16
BB6DC92D-CECA-449C-9D25-DCC6379326C4	    16
3357057E-586C-4E04-B6DB-168F822FC706	    16
*/

--1.1 - Comparing NEWID() and NEWSEQUENTIALID()
-- → NEWSEQUENTIALID() generates sequential GUIDs, which are better for indexes

CREATE TABLE Example_UniqueIdentifier_Sequential
(
    Id UNIQUEIDENTIFIER DEFAULT NEWSEQUENTIALID(),
    Description VARCHAR(50)
);
GO

INSERT INTO Example_UniqueIdentifier_Sequential (Description)
VALUES
('Record 1'),
('Record 2'),
('Record 3');
GO


INSERT INTO Example_UniqueIdentifier_Sequential (Description)
VALUES
('Record 4'),
('Record 5'),
('Record 6');
GO

SELECT *
FROM Example_UniqueIdentifier_Sequential;
GO

/*
Result:
Id	                                    Description
42F370B2-C019-F111-B1AE-00155D006C05	Record 1
43F370B2-C019-F111-B1AE-00155D006C05	Record 2
44F370B2-C019-F111-B1AE-00155D006C05	Record 3
A58D31CD-C019-F111-B1AE-00155D006C05	Record 4
A68D31CD-C019-F111-B1AE-00155D006C05	Record 5
A78D31CD-C019-F111-B1AE-00155D006C05	Record 6
*/

-------------------------------------------------------------------------------
-- 2 - ROWVERSION / TIMESTAMP
-------------------------------------------------------------------------------
/*
→ TIMESTAMP is a deprecated synonym for ROWVERSION in SQL Server and should not 
 be used in new development
→ ROWVERSION automatically changes every time the row is updated
→ ROWVERSION always uses 8 bytes of storage
*/

CREATE TABLE dbo.Example_RowVersion
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2),
    RowVer ROWVERSION
);
GO

INSERT INTO dbo.Example_RowVersion (ProductName, Price)
VALUES ('Keyboard', 100.00);
GO

SELECT Id, ProductName, Price, RowVer
FROM dbo.Example_RowVersion;
GO

/*
Result:
Id	ProductName	Price	RowVer
1	Keyboard	100.00	0x0000000000001772
*/

SELECT 
RowVer,
DATALENGTH(RowVer) AS BytesUsed
FROM dbo.Example_RowVersion;

/*
Result:
RowVer	            BytesUsed
0x0000000000001772	    8
*/

-- 2.1 - Optimistic Concurrency Example - SUCCESS

--Step 1 — Read the current rowversion
DECLARE @RowVer BINARY(8);

SELECT @RowVer = RowVer
FROM dbo.Example_RowVersion
WHERE Id = 1;

PRINT @RowVer

--Step 2 — Update using optimistic concurrency
UPDATE dbo.Example_RowVersion
SET Price = 120.00
WHERE Id = 1
AND RowVer = @RowVer;

--Step 3 — Detect concurrency conflict
IF @@ROWCOUNT = 0
BEGIN
    PRINT 'The row was modified by another transaction.';
END
ELSE
BEGIN
    PRINT 'Update successful.';
END

/*
Result:
0x0000000000001772

(1 row affected)
Update successful.

Completion time: 2026-03-06T22:13:02.1505511-03:00
*/

--Checking data
SELECT Id, ProductName, Price, RowVer
FROM dbo.Example_RowVersion;
GO

/*
Result:
Id	ProductName	Price	RowVer
1	Keyboard	120.00	0x0000000000001773
*/
 
-- 2.2 - ROWVERSION and Optimistic Concurrency Example - FAIL

CREATE TABLE dbo.ProductConcurrency
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2),
    RowVer ROWVERSION
);
GO

INSERT INTO dbo.ProductConcurrency (ProductName, Price)
VALUES ('Laptop', 2000.00);
GO

SELECT Id, ProductName, Price, RowVer
FROM dbo.ProductConcurrency;

/*
Result:
Id	ProductName	Price	RowVer
1	Laptop	2000.00	    0x0000000000001774
*/

/*
→ To simulate concurrency, open two query windows in SSMS
*/

-- 2.2.1 - Session A (User 1)
--User 1 reads the row and stores the current ROWVERSION
--Read the row and store the current ROWVERSION

--START BATCH
SET NOCOUNT OFF;
GO 

DECLARE @RowVer BINARY(8);

SELECT @RowVer = RowVer
FROM dbo.ProductConcurrency
WHERE Id = 1;

--This batch will wait for 30 seconds
WAITFOR DELAY '00:00:30';

UPDATE dbo.ProductConcurrency
SET Price = 2050.00
WHERE Id = 1
AND RowVer = @RowVer;

--Detecting a Concurrency Conflict
IF @@ROWCOUNT = 0
BEGIN
    PRINT 'Concurrency conflict detected. The row was modified by another transaction.';
END
ELSE
BEGIN
    PRINT 'Update successful.';
END

--END BATH

/*
Result:
(0 rows affected)
Concurrency conflict detected. The row was modified by another transaction.
----------->  Completion time: 2026-03-06T22:41:05.4430646-03:00 <-----------
*/

-- 2.2.2 - Session B (User 2)
-- Run this command while Session 1 is waiting
-- The database automatically updates the ROWVERSION

UPDATE dbo.ProductConcurrency
SET Price = 2100.00
WHERE Id = 1;

/*
Result:
(1 row affected)
----------->  Completion time: 2026-03-06T22:40:37.8403168-03:00 <-----------
*/

-- 2.2.3 - Final result
SELECT Id, ProductName, Price, RowVer
FROM dbo.ProductConcurrency;

/*Result:
Id	ProductName	    Price	    RowVer
1	Laptop	        2100.00	    0x0000000000001778

*/

-------------------------------------------------------------------------------
-- 3 - BINARY 
-------------------------------------------------------------------------------
/*
→ BINARY(n) stores fixed-length binary data
→ The storage size is always n bytes
→ If the inserted value is smaller than n, SQL Server pads the remaining bytes with 0x00
*/
SET NOCOUNT ON;
GO 

CREATE TABLE dbo.Example_Binary
(
    Id INT IDENTITY(1,1),
    FixedBinary BINARY(5)
);
GO

INSERT INTO dbo.Example_Binary (FixedBinary)
VALUES 
(0x1234),        -- shorter than 5 bytes
(0xABCDEF1234);  -- exactly 5 bytes
GO

SELECT 
FixedBinary 
FROM dbo.Example_Binary;

/*
Result:
FixedBinary
0x1234000000
0xABCDEF1234
*/

SELECT 
FixedBinary,
DATALENGTH(FixedBinary) AS BytesUsed
FROM dbo.Example_Binary;

/*
Result:
FixedBinary	    BytesUsed
0x1234000000	    5
0xABCDEF1234	    5
*/

-------------------------------------------------------------------------------
-- 4 - VARBINARY 
-------------------------------------------------------------------------------
/*
→ VARBINARY(n) stores variable-length binary data
→ The storage size depends on the actual data length
→ SQL Server does not pad unused bytes
→ Maximum size for VARBINARY is 8000 bytes (or VARBINARY(MAX) for larger values)
*/
CREATE TABLE dbo.Example_VarBinary
(
    Id INT IDENTITY(1,1),
    VariableBinary VARBINARY(5)
);
GO

INSERT INTO dbo.Example_VarBinary (VariableBinary)
VALUES
(0x1234),        -- 2 bytes
(0xABCDEF1234);  -- 5 bytes
GO

SELECT
VariableBinary,
DATALENGTH(VariableBinary) AS BytesUsed
FROM dbo.Example_VarBinary;

/*
Result:
VariableBinary	BytesUsed
0x1234	            2
0xABCDEF1234	    5
*/

-------------------------------------------------------------------------------
-- 5 - XML 
-------------------------------------------------------------------------------
/*
→ XML stores structured XML documents
→ XML values can be queried using XQuery expressions
→ The .value() method extracts a single value from the XML
*/
CREATE TABLE dbo.Example_XML
(
    Id INT IDENTITY(1,1),
    ProductData XML
);
GO

INSERT INTO dbo.Example_XML (ProductData)
VALUES
('<product>
    <name>Keyboard</name>
    <price>100</price>
    <category>Accessories</category>
</product>'),
('<product>
    <name>Mouse</name>
    <price>50</price>
    <category>Accessories</category>
</product>');
GO

SELECT *
FROM dbo.Example_XML;
/*
Result:
Id	ProductData
1	<product><name>Keyboard</name><price>100</price><category>Accessories</category></product>
2	<product><name>Mouse</name><price>50</price><category>Accessories</category></product>
*/

-- 5.1 - Example with .value → Returns Scalar value 
--The .value() method extracts a scalar value from an XML element
SELECT 
ProductData.value('(/product/name)[1]', 'VARCHAR(50)')  AS ProductName,
ProductData.value('(/product/price)[1]', 'INT')         AS ProductPrice
FROM dbo.Example_XML;

/*
Result:
ProductName	    ProductPrice
Keyboard	    100
Mouse	        50
*/

-- 5.2 - Example with .query() → Returns XML fragment
--The .exist() method checks whether a specific element exists in the XML
SELECT ProductData.query('/product/price') AS XML_fragment
FROM dbo.Example_XML;

/*
Result:
XML_fragment
<price>100</price>
<price>50</price>
*/

-- 5.3 - Example with .exist() → Returns TRUE / FALSE
--The .exist() method checks whether a specific element exists in the XML
SELECT
Id,
ProductData.exist('/product/category') AS CategoryExists,
ProductData.exist('/product/category/price') AS CategoryNotExists
FROM dbo.Example_XML;
/*
Result:
Id	CategoryExists	CategoryNotExists
1	     1	                0
2	     1	                0
*/

-- 5.3.1 -Filtering rows using .exist()
SELECT
Id,
ProductData.value('(/product/name)[1]', 'VARCHAR(50)')  AS ProductName,
ProductData.value('(/product/price)[1]', 'INT')         AS ProductPrice
FROM dbo.Example_XML
WHERE ProductData.exist('/product[price > 60]') = 1;

/*
Result:
Id	ProductName	ProductPrice
1	Keyboard	100
*/

-- 5.4 - Example using .nodes() → Returns Rowset (table result)
--The .nodes() method converts XML elements into a rowset, allowing each XML node to be processed as a row

SELECT
X.N.value('(name)[1]', 'VARCHAR(50)')       AS ProductName,
X.N.value('(price)[1]', 'INT')              AS ProductPrice,
X.N.value('(category)[1]', 'VARCHAR(50)')   AS ProductCategory
FROM dbo.Example_XML
CROSS APPLY ProductData.nodes('/product') AS X(N);

/*
Result:
ProductName	ProductPrice	ProductCategory
Keyboard	    100	        Accessories
Mouse	        50	        Accessories
*/

-------------------------------------------------------------------------------
-- 6 - SQL_VARIANT 
-------------------------------------------------------------------------------
/*
→ SQL_VARIANT allows storing multiple data types in the same column
→ The original data type is preserved internally
→ The function SQL_VARIANT_PROPERTY() can be used to inspect the stored type
→ Although flexible, SQL_VARIANT is rarely recommended for standard database 
  design
→ SQL_VARIANT values can store up to 8016 bytes, including metadata describing 
  the base data type
*/ 
CREATE TABLE dbo.Example_SQLVariant
(
    Id INT IDENTITY(1,1),
    VariantValue SQL_VARIANT
);
GO

INSERT INTO dbo.Example_SQLVariant (VariantValue)
VALUES
(CAST(100 AS SQL_VARIANT)),             -- INT
(CAST(250.75 AS SQL_VARIANT)),          -- DECIMAL
(CAST('Keyboard' AS SQL_VARIANT)),      -- VARCHAR
(CAST(GETDATE() AS SQL_VARIANT)),       -- DATETIME
(CAST(NEWID() AS SQL_VARIANT));         -- UNIQUEIDENTIFIER
GO

SELECT
VariantValue,
SQL_VARIANT_PROPERTY(VariantValue,'BaseType') AS BaseType
FROM dbo.Example_SQLVariant;

/*
Result:
VariantValue	                        BaseType
100	                                    int
250.75	                                numeric
Keyboard	                            varchar
2026-03-06 23:32:55.790	                datetime
54C99781-C143-4ACF-B1A7-1EA070B43CA8	uniqueidentifier
*/

-------------------------------------------------------------------------------
-- 6 - TABLE 
-------------------------------------------------------------------------------

-- 6.1 - TABLE Variable
/*
→ TABLE variables exist only during the batch execution or procedure
→ They are often used for temporary data storage inside scripts or procedures
→ The variable name must start with @
→ Automatically removed when execution finishes
*/

--START BATCH
DECLARE @Products TABLE
(
    Id INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);

INSERT INTO @Products (Id, ProductName, Price)
VALUES
(1, 'Keyboard', 100.00),
(2, 'Mouse', 50.00),
(3, 'Monitor', 800.00);

SELECT *
FROM @Products;
GO

--END BATCH

/*
Result:
Id	ProductName	    Price
1	Keyboard	    100.00
2	Mouse	        50.00
3	Monitor	        800.00
*/

-- 6.2 - Local Temporary Table
/*
→ A local temporary table exists only for the current session (connection)
→ Automatically dropped when the session ends
→ Stored in tempdb
*/

CREATE TABLE #Products
(
    Id INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);

INSERT INTO #Products
VALUES
(1,'Keyboard',100.00),
(2,'Mouse',50.00),
(3,'Monitor',800.00);

SELECT * FROM #Products;

/*
Result:
Id	ProductName	    Price
1	Keyboard	    100.00
2	Mouse	        50.00
3	Monitor	        800.00

→ If you execute `SELECT * FROM #Products` in a new session, the result will be:
Msg 208, Level 16, State 0, Line 1  
Invalid object name '#Products'.
*/

-- 6.3 - Global Temporary Table
/*
Accessible by all sessions
Exists until the last session referencing it closes
Also stored in tempdb
*/

CREATE TABLE ##ProductsGlobal
(
    Id INT,
    ProductName VARCHAR(50),
    Price DECIMAL(10,2)
);

INSERT INTO ##ProductsGlobal
VALUES
(1,'Keyboard',100.00),
(2,'Mouse',50.00),
(3,'Monitor',800.00);

SELECT * FROM ##ProductsGlobal;

/*
Result:
Id	ProductName 	Price
1	Keyboard	    100.00
2	Mouse	        50.00
3	Monitor	        800.00
*/

/* 6.4 - Comparison
Feature	        TABLE Variable	            #Temp Table	        ##Temp Table
Scope	        Current batch/procedure	    Current session	    All sessions
Name Prefix     @	                        #	                ##
Storage	        tempdb	                    tempdb	            tempdb
Lifetime	    Batch execution	Session     lifetime	        Until last session closes
*/
