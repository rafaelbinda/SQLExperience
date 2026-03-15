/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-15
Version     : 1.0
Task        : Q0010 - Sql Server Programming Objects
Databases   : AventureWorkds, ExamplesDB 
Object      : Script
Description : Examples demonstrating Sql Server Programming Objects
Notes       : notes/A0012-sql-server-programming-objects.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - VIEWS 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 1.1 - Simple view
-------------------------------------------------------------------------------
-- Returns basic customer information from Person.Person

CREATE OR ALTER VIEW Person.vw_BasicPersonInfo
AS
SELECT
BusinessEntityID,
FirstName,
MiddleName,
LastName
FROM Person.Person;
GO

SELECT TOP (10) *
FROM Person.vw_BasicPersonInfo
ORDER BY BusinessEntityID ASC;
GO

/*
Result:
BusinessEntityID	FirstName	MiddleName	LastName
1	                Ken	        J	        Sánchez
2	                Terri	    Lee	        Duffy
3	                Roberto	    NULL	    Tamburello
4	                Rob	        NULL	    Walters
5	                Gail	    A	        Erickson
6	                Jossef	    H	        Goldberg
7	                Dylan	    A	        Miller
8	                Diane	    L	        Margheim
9	                Gigi	    N	        Matthew
10	                Michael     NULL	    Raheem
*/

-------------------------------------------------------------------------------
-- 1.2 - View with JOIN
-------------------------------------------------------------------------------
-- Combines customer and person data

CREATE OR ALTER VIEW Sales.vw_CustomerPersonInfo
AS
SELECT
C.CustomerID,
P.BusinessEntityID,
P.FirstName,
P.MiddleName,
P.LastName
FROM Sales.Customer AS C
INNER JOIN Person.Person AS P
    ON C.PersonID = P.BusinessEntityID
WHERE C.PersonID IS NOT NULL;
GO

SELECT TOP (10) *
FROM Sales.vw_CustomerPersonInfo
ORDER BY CustomerID ASC;
GO

/*
Result:
CustomerID	BusinessEntityID	FirstName	MiddleName	LastName
11000	    13531	            Jon 	    V	        Yang
11001	    5454	            Eugene	    L	        Huang
11002	    11269	            Ruben	    NULL	    Torres
11003	    11358	            Christy	    NULL	    Zhu
11004	    11901	            Elizabeth	NULL	    Johnson
11005	    6990	            Julio	    NULL	    Ruiz
11006	    6229	            Janet	    G	        Alvarez
11007	    3878	            Marco	    NULL	    Mehta
11008	    14673	            Rob	        NULL	    Verhoff
11009	    20229	            Shannon	    C	        Carlson
*/

-------------------------------------------------------------------------------
-- 1.3 - View with JOIN and calculated column
-------------------------------------------------------------------------------
-- Shows sales order header data with customer info

CREATE OR ALTER VIEW Sales.vw_SalesOrderSummary
AS
SELECT
SOH.SalesOrderID,
SOH.OrderDate,
SOH.CustomerID,
SOH.SubTotal,
SOH.TaxAmt,
SOH.Freight,
SOH.TotalDue,
P.FirstName + ' ' + P.LastName AS FullName
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Sales.Customer AS C
    ON SOH.CustomerID = C.CustomerID
INNER JOIN Person.Person AS P
    ON C.PersonID = P.BusinessEntityID
WHERE C.PersonID IS NOT NULL;
GO

SELECT TOP (10) *
FROM Sales.vw_SalesOrderSummary
ORDER BY OrderDate DESC;
GO

/*
Result:
SalesOrderID	OrderDate	                CustomerID	SubTotal	TaxAmt	    Freight	    TotalDue	FullName
75084	        2008-07-31 00:00:00.000	    11078	    120,00	    9,60	    3,00	    132,60	    Gina Martin
75085	        2008-07-31 00:00:00.000	    11927	    16,94	    1,3552	    0,4235	    18,7187	    Nicole Murphy
75086	        2008-07-31 00:00:00.000	    28789	    7,95	    0,636	    0,1988	    8,7848	    Elijah Zhang
75087	        2008-07-31 00:00:00.000	    11794	    34,99	    2,7992	    0,8748	    38,664	    Lauren Ross
75088	        2008-07-31 00:00:00.000	    14680	    113,96	    9,1168	    2,849	    125,9258	Marvin Munoz
75089	        2008-07-31 00:00:00.000	    19585	    60,47	    4,8376	    1,5118	    66,8194	    Kristi Fernandez
75090	        2008-07-31 00:00:00.000	    27686	    74,98	    5,9984	    1,8745	    82,8529	    Vincent Zhang
75091	        2008-07-31 00:00:00.000	    20601	    80,47	    6,4376	    2,0118	    88,9194	    Carrie Munoz
75092	        2008-07-31 00:00:00.000	    26564	    49,97	    3,9976	    1,2493	    55,2169	    Franklin Chen
75093	        2008-07-31 00:00:00.000	    16170	    156,59	    12,5272	    3,9148	    173,032	    Juan Rubio
*/


-------------------------------------------------------------------------------
-- 1.4 - View with aggregation
-------------------------------------------------------------------------------
-- Returns total orders and total sales by customer

CREATE OR ALTER VIEW Sales.vw_CustomerSalesTotals
AS
SELECT
SOH.CustomerID,
COUNT(*) AS TotalOrders,
SUM(SOH.TotalDue) AS TotalSales
FROM Sales.SalesOrderHeader AS SOH
GROUP BY SOH.CustomerID;
GO

SELECT TOP (10) *
FROM Sales.vw_CustomerSalesTotals
ORDER BY TotalSales DESC;
GO

/*
Result:
CustomerID	TotalOrders	TotalSales
29818	    12	        989184,082
29715	    12	        961675,8596
29722	    12	        954021,9235
30117	    12	        919801,8188
29614	    12	        901346,856
29639	    12	        887090,4106
29701	    8	        841866,5522
29617	    12	        834475,9271
29994	    12	        824331,7682
29646	    12	        820383,5466
*/


-------------------------------------------------------------------------------
-- 1.5 - View used as an abstraction layer
-------------------------------------------------------------------------------
-- The application can query the view instead of writing
-- the complete JOIN every time
SELECT TOP (10)
    CustomerID,
    FullName,
    TotalDue
FROM Sales.vw_SalesOrderSummary
ORDER BY TotalDue DESC;
GO

-------------------------------------------------------------------------------
/*
Result:
→ The reason we saw two rows for the same customer in CustomerID 29641 is
  because Sales.vw_SalesOrderSummary returns one row per SalesOrder

CustomerID	FullName	    TotalDue
29641	    Raul Casts	    187487,825
29641	    Raul Casts	    182018,6272
29614	    Ryan Calafato	170512,6689
30103	    Mandy Vance	    166537,0808
29701	    Kirk DeGrasse	165028,7482
29998	    Jane McCarty	158056,5449
29957	    Kevin Liu	    145741,8553
29913	    Anton Kirilov	145454,366
29624	    Joseph Cantoni	142312,2199
29940	    Robertson Lee	140042,1209
*/

-------------------------------------------------------------------------------
-- 1.6 - Aggregating data from a view
-------------------------------------------------------------------------------

SELECT TOP (10)
CustomerID,
FullName,
SUM(TotalDue) AS TotalSales
FROM Sales.vw_SalesOrderSummary
GROUP BY CustomerID, FullName
ORDER BY TotalSales DESC;
GO


/*
Result:
CustomerID	FullName	TotalSales
29818	    Roger Harui	        989184,082
29715	    Andrew Dixon	    961675,8596
29722	    Reuben D'sa	        954021,9235
30117	    Robert Vessa	    919801,8188
29614	    Ryan Calafato	    901346,856
29639	    Joseph Castellucio	887090,4106
29701	    Kirk DeGrasse	    841866,5522
29617	    Lindsey Camacho	    834475,9271
29994	    Robin McGuigan	    824331,7682
29646	    Stacey Cereghino	820383,5466
*/

-------------------------------------------------------------------------------
-- 1.7 - Filtering data from a view
-------------------------------------------------------------------------------
-- SQL Server expands the view definition internally

SELECT TOP (10)
SalesOrderID,
OrderDate,
FullName,
TotalDue
FROM Sales.vw_SalesOrderSummary
WHERE TotalDue > 100000
ORDER BY TotalDue DESC;
GO

/*
Result:
SalesOrderID	OrderDate	                FullName	    TotalDue
51131	        2007-07-01 00:00:00.000	    Raul Casts	    187487,825
55282	        2007-10-01 00:00:00.000	    Raul Casts	    182018,6272
46616	        2006-07-01 00:00:00.000	    Ryan Calafato	170512,6689
46981	        2006-08-01 00:00:00.000	    Mandy Vance	    166537,0808
47395	        2006-09-01 00:00:00.000	    Kirk DeGrasse	165028,7482
47369	        2006-09-01 00:00:00.000	    Jane McCarty	158056,5449
47355	        2006-09-01 00:00:00.000	    Kevin Liu	    145741,8553
51822	        2007-08-01 00:00:00.000	    Anton Kirilov	145454,366
44518	        2005-11-01 00:00:00.000	    Joseph Cantoni	142312,2199
51858	        2007-08-01 00:00:00.000	    Robertson Lee	140042,1209
*/


-------------------------------------------------------------------------------
-- 1.8 - View metadata
-------------------------------------------------------------------------------
-- Shows the stored definition of the view

EXEC sp_helptext 'Sales.vw_SalesOrderSummary';
GO

/*
Result:
Row     Text
1       CREATE   VIEW Sales.vw_SalesOrderSummary  
2       AS  
3       SELECT  
4       SOH.SalesOrderID,  
5       SOH.OrderDate,  
6       SOH.CustomerID,  
7       SOH.SubTotal,  
8       SOH.TaxAmt,  
9       SOH.Freight,  
10      SOH.TotalDue,  
11      P.FirstName + ' ' + P.LastName AS FullName  
12      FROM Sales.SalesOrderHeader AS SOH  
13      INNER JOIN Sales.Customer AS C  
14         ON SOH.CustomerID = C.CustomerID  
15      INNER JOIN Person.Person AS P  
16         ON C.PersonID = P.BusinessEntityID  
17      WHERE C.PersonID IS NOT NULL;  
*/

-------------------------------------------------------------------------------
-- 1.9 - Drop examples (optional)
-------------------------------------------------------------------------------
-- Uncomment only if you want to remove the objects

-- DROP VIEW Person.vw_BasicPersonInfo;
-- DROP VIEW Sales.vw_CustomerPersonInfo;
-- DROP VIEW Sales.vw_SalesOrderSummary;
-- DROP VIEW Sales.vw_CustomerSalesTotals;
-- GO

-------------------------------------------------------------------------------
-- 1.10 - Execution Plan Example — View Expansion
-------------------------------------------------------------------------------

/*
→ This example demonstrates that SQL Server expands the definition of a view 
  internally 
→ A query using a view and a query using the base tables will usually generate 
  the same execution plan 
*/

--Step 1 — Enable Actual Execution Plan in SQL Server Management Studio
--using CTRL + M

--Step 2 — Execute the Query Using the View and execute the equivalent Query 
--Using Base Tables

--2.1 - Query using the view
SELECT TOP (10) *
FROM Sales.vw_CustomerPersonInfo
WHERE LastName LIKE 'A%';
GO
 
---2.2 - Query using base tables
SELECT TOP (10)
C.CustomerID,
P.BusinessEntityID,
P.FirstName,
P.MiddleName,
P.LastName
FROM Sales.Customer AS C
INNER JOIN Person.Person AS P
    ON C.PersonID = P.BusinessEntityID
WHERE C.PersonID IS NOT NULL
AND P.LastName LIKE 'A%';
GO
 
 -------------------------------------------------------------------------------
--Step 3 — Compare Showplan 
/*
Main Comparison

Item                    Using View            Without View 
StatementSubTreeCost    0.105075              0.105075 
Operators               Top                   Top             
Join                    Hash Match            Hash Match 
Table Access            Index Seek            Index Seek 
Table Access            Clustered Index Scan  Clustered Index Scan 

→ In the execution plan it is possible to observe that SQL Server does not access 
  the view object directly 
→ Instead, the optimizer expands the view definition and accesses the base tables
  involved in the query
→ Because of this behavior, a view by itself does not improve performance
→ It mainly serves as an abstraction layer to simplify queries and manage 
  permissions
*/ 