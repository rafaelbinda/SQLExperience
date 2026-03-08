/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-04
Version     : 1.0
Task        : Q0006-sql-numeric-and-bit-data-types.sql
Databases   : ExamplesDB
Object      : Script
Description : Examples demonstrating numeric and bit data types in SQL Server
Notes       : A0010-sql-data-types.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- 1 - Integer Types
-------------------------------------------------------------------------------

CREATE TABLE Example_Integers
(
    TinyValue   TINYINT,
    SmallValue  SMALLINT,
    IntValue    INT,
    BigValue    BIGINT
);
GO

-- 1 - Inserting data  
INSERT INTO Example_Integers
VALUES (255, 32767, 2147483647, 9223372036854775807);
GO

SELECT * 
FROM Example_Integers;
GO

/*
Result: 
TinyValue	SmallValue	IntValue	BigValue
255	        32767	    2147483647	9223372036854775807
255	        32767	    2147483647	9223372036854775807
*/ 

--2 - Comparing storage size of iInteger data types
SELECT 
DATALENGTH(TinyValue)  AS TINYINT_Bytes,
DATALENGTH(SmallValue) AS SMALLINT_Bytes,
DATALENGTH(IntValue)   AS INT_Bytes,
DATALENGTH(BigValue)   AS BIGINT_Bytes
FROM Example_Integers; 

/*
Result:
TINYINT_Bytes	SMALLINT_Bytes	INT_Bytes	BIGINT_Bytes
    1	            2	            4	        8
    1	            2	            4	        8
*/

-------------------------------------------------------------------------------
-- 2 - DECIMAL and NUMERIC
-------------------------------------------------------------------------------

CREATE TABLE Example_Decimal
(
    Decimal_5_2  DECIMAL(5,2),
    Decimal_10_2 DECIMAL(10,2),
    Decimal_20_2 DECIMAL(20,2),
    Decimal_30_2 DECIMAL(30,2)
);
GO

-- 1 - Inserting the same data
INSERT INTO Example_Decimal
VALUES (1,1,1,1);
GO

SELECT *
FROM Example_Decimal;
GO

/*
Result:
Decimal_5_2	    Decimal_10_2	Decimal_20_2	Decimal_30_2
    1.00	        1.00	        1.00	        1.00
*/

--2 - Comparing Storage Size of DECIMAL/NUMERIC data types
SELECT
Decimal_5_2,
DATALENGTH(Decimal_5_2)  AS Bytes_5_2,

Decimal_10_2,
DATALENGTH(Decimal_10_2) AS Bytes_10_2,

Decimal_20_2,
DATALENGTH(Decimal_20_2) AS Bytes_20_2,

Decimal_30_2,
DATALENGTH(Decimal_30_2) AS Bytes_30_2
FROM Example_Decimal;
GO

/*
Result:
Decimal_5_2	    Bytes_5_2	Decimal_10_2	Bytes_10_2	Decimal_20_2	Bytes_20_2	Decimal_30_2	Bytes_30_2
    1.00	        5	        1.00	        5	        1.00	        5	        1.00	        5

→ Why did all of them return 5 bytes?
This value is very small, so SQL Server can store it using only the minimum amount of space needed to represent the number.
Internally, SQL Server uses a representation based on groups of digits, so small values may occupy only 5 bytes, even if 
the defined precision allows much larger numbers.
*/

--3 - Next example

UPDATE Example_Decimal
SET
Decimal_5_2  = 999.99,
Decimal_10_2 = 99999999.99,
Decimal_20_2 = 9999999999999999.99,
Decimal_30_2 = 99999999999999999999999999.99;

--Comparing Storage Size of DECIMAL/NUMERIC data types
SELECT
Decimal_5_2,
DATALENGTH(Decimal_5_2)  AS Bytes_5_2,

Decimal_10_2,
DATALENGTH(Decimal_10_2) AS Bytes_10_2,

Decimal_20_2,
DATALENGTH(Decimal_20_2) AS Bytes_20_2,

Decimal_30_2,
DATALENGTH(Decimal_30_2) AS Bytes_30_2
FROM Example_Decimal;
GO

/*
Result:
Decimal_5_2     =   999.99	   
Bytes_5_2	    =   5

Decimal_10_2	=   99999999.99
Bytes_10_2	    =   9
    
Decimal_20_2	=   9999999999999999.99
Bytes_20_2      =   9

Decimal_30_2	=   99999999999999999999999999.99
Bytes_30_2      =   13
*/ 

--DECIMAL storage rule
/*
Precision (p)	Bytes
1–9	            5
10–19	        9
20–28	        13
29–38	        17
*/

-------------------------------------------------------------------------------
-- 3 - Approximate Types (FLOAT and REAL)
-------------------------------------------------------------------------------
 

CREATE TABLE Example_Float
(
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FloatValue FLOAT,
    RealValue  REAL
);
GO

INSERT INTO Example_Float
VALUES
(0.1, 0.1),
(0.2, 0.2);
GO

SELECT * 
FROM Example_Float;
GO

/*
Result:
Id	FloatValue	  RealValue
1	    0,1	        0,1
2	    0,2	        0,2
*/


--Viewing the real stored data
SELECT 
Id, 
FloatValue,
CAST(FloatValue AS DECIMAL(38,20)) AS RealFloatStoredValue,
RealValue,
CAST(RealValue AS DECIMAL(38,20))  AS RealRealStoredValue
FROM Example_Float;
GO

/*
Result:
Id	FloatValue  RealFloatStoredValue	RealValue	RealRealStoredValue
1	    0,1	    0.10000000000000000555	    0,1	    0.10000000149011611938
2	    0,2	    0.20000000000000001110	    0,2	    0.20000000298023223877
*/

--3.1 - Demonstrating imprecision with FLOAT

SELECT 
SUM(FloatValue) AS TOTAL_SUM,
CASE 
    WHEN SUM(FloatValue) = 0.3 
    THEN 'TRUE'
    ELSE 'FALSE'
END AS RESULT
FROM Example_Float;
GO

/*
Result:
TOTAL_SUM	RESULT
0,3	        FALSE
*/

--3.2 - Demonstrating imprecision with REAL
SELECT 
SUM(RealValue) AS TOTAL_SUM,
CASE 
    WHEN SUM(RealValue) = 0.3 
    THEN 'TRUE'
    ELSE 'FALSE'
END AS RESULT
FROM Example_Float;
GO

/*
Result:
TOTAL_SUM	        RESULT
0,300000004470348	FALSE
*/


-------------------------------------------------------------------------------
-- 4 - Monetary Data Types
-------------------------------------------------------------------------------

CREATE TABLE Example_Money
(
    Id INT IDENTITY(1,1),
    Price MONEY,
    SmallPrice SMALLMONEY
);
GO

--4.1 - Inserting values at the maximum value
INSERT INTO Example_Money (Price, SmallPrice)
VALUES
(922337203685477.5807, 214748.3647);
GO

SELECT *
FROM Example_Money;
GO

--4.2 - Inserting values at the minimum value
INSERT INTO Example_Money (Price, SmallPrice)
VALUES
(-922337203685477.5808, -214748.3648);
GO

--4.3 - Viewing the stored values
SELECT
Id,
Price,
SmallPrice,
DATALENGTH(Price)      AS Bytes_Money,
DATALENGTH(SmallPrice) AS Bytes_SmallMoney
FROM Example_Money;
GO

/*
Result:
Id	Price	                SmallPrice	    Bytes_Money	    Bytes_SmallMoney
1	922337203685477,5807	214748,3647	        8	            4
2	-922337203685477,5808	-214748,3648	    8	            4
*/


--4.4 - Demonstrating overflow
INSERT INTO Example_Money (Price, SmallPrice)
VALUES
(922337203685478.0000, 300000);
GO

/*
Result:
Msg 8115, Level 16, State 4, Line 292
Arithmetic overflow error converting numeric to data type money.
*/

--4.5 - Scenario: dividing R$ 100.00 into 3 equal parts 

DECLARE @TotalMoney MONEY = 100.00;
DECLARE @Parcels INT = 3;

DECLARE @ParcelMoney MONEY = @TotalMoney / @Parcels;
DECLARE @SumMoney MONEY = @ParcelMoney * @Parcels;
DECLARE @DiffMoney MONEY = @TotalMoney - @SumMoney;

SELECT
@TotalMoney  AS Total_Money,
@Parcels     AS Parcels,
@ParcelMoney AS ParcelValue_Money,
@SumMoney    AS SumParcels_Money,
@DiffMoney   AS Difference_Money;
GO

/*
Result:
Total_Money	Parcels	ParcelValue_Money	SumParcels_Money	Difference_Money
100,00	        3	33,3333	            99,9999	            0,0001
*/

--4.6 - Same logic using DECIMAL with higher precision (more reliable calculation)
--Recommendation: Use DECIMAL for financial values
DECLARE @TotalMoney MONEY = 100.00;
DECLARE @Parcels INT = 3;
DECLARE @TotalDec DECIMAL(38,20) = 100.00;
DECLARE @ParcelDec DECIMAL(38,20) = @TotalDec / @Parcels;
DECLARE @SumDec DECIMAL(38,20) = @ParcelDec * @Parcels;
DECLARE @DiffDec DECIMAL(38,20) = @TotalDec - @SumDec;

SELECT
@TotalDec  AS Total_Decimal,
@Parcels   AS Parcels,
@ParcelDec AS ParcelValue_Decimal,
@SumDec    AS SumParcels_Decimal,
@DiffDec   AS Difference_Decimal;
GO

/*
Result:
Total_Decimal	            Parcels	    ParcelValue_Decimal	        SumParcels_Decimal	        Difference_Decimal
100.00000000000000000000	  3	        33.33333333333333333333	    100.00000000000000000000	0.00000000000000000000
*/

-------------------------------------------------------------------------------
-- 5 - BIT Data Type
-------------------------------------------------------------------------------

CREATE TABLE Example_Bit
(
    IsActive BIT,
    IsPaid   BIT
);
GO

INSERT INTO Example_Bit
VALUES
(1,0),
(0,1),
(NULL,1);
GO

 
SELECT *
FROM Example_Bit;
GO
  
/*
Result:
IsActive	IsPaid
   1	      0
   0	      1
   NULL	      1


→ In SQL Server:
1       = TRUE
0       = FALSE
NULL    = UNKNOWN
*/
 