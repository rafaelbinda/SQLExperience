/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-27
Version     : 1.0
Task        : Q0004 - SQL data querying
Databases   : AdventureWorks
Object      : Script
Description : Examples demonstrating data retrieval using SELECT, filtering, 
              grouping, and joins in SQL Server. 
Notes       : A0009-sql-data-querying.md
===============================================================================
INDEX

1 - SELECT
1.1 - Simple SELECT
1.2 - SELECT with vertical filter (column list)			
1.3 - SELECT with column alias							
1.4 - SELECT with horizontal filter (WHERE clause)		
1.5 - SELECT with comparison operator					
1.6 - SELECT with DISTINCT								
1.7 - SELECT with ORDER BY								
1.8 - SELECT with TOP									
1.9 - LIKE (starts with)									
1.10 - LIKE (contains)										
1.11 - AND (multiple conditions)							
1.12 - OR (either condition)								
1.13 - Greater than (>)
1.14 - Less than (<)
1.15 - IN (multiple values)
1.16 - BETWEEN (inclusive range)
1.17 - IS NULL (returns only NULL values)
1.18 - IS NOT NULL
1.19 - DISTINCT

2 - GROUP BY 
2.1 - GROUP BY with COUNT
2.2 - GROUP BY with SUM
2.3 - GROUP BY with multiple columns
2.4 - WHERE before GROUP BY
2.5 - HAVING after GROUP BY
2.6 - GROUP BY with AVG
2.7 - Common GROUP BY Mistakes
	Mistake 1: Column in SELECT not included in GROUP BY
	Mistake 2: Using aggregate function in WHERE
	Mistake 3: Filtering aggregated column in WHERE
	Mistake 4: GROUP BY changes granularity unexpectedly

3 - INNER JOIN (only matching rows)
4 - LEFT JOIN (all rows from left table)
4.1 - LEFT JOIN that naturally produces NULLs (SalesPersonID can be NULL)
5 - RIGHT JOIN producing NULLs on the left side
6 - Controlled example: create unmatched rows using VALUES
7 - FULL OUTER JOIN
8 - CROSS JOIN (Cartesian Product)
9 - Common JOIN Mistakes
	Mistake 1: Missing JOIN condition (Cartesian product)
	Mistake 2: Filtering RIGHT table in WHERE after LEFT JOIN
	Mistake 3: Using wrong join column
	Mistake 4: Forgetting table aliases in multi-table queries

===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE AdventureWorks;
GO

-------------------------------------------------------------------------------
-- 1 - SELECT
-------------------------------------------------------------------------------  
-------------------------------------------------------------------------------
-- 1.1  - Basic SELECT
-------------------------------------------------------------------------------

SELECT *
FROM Person.Person;

/*
Result: 
19.972 rows (may vary depending on version)
*/


-------------------------------------------------------------------------------
-- 1.2  - Column selection (vertical filter)
-------------------------------------------------------------------------------

SELECT FirstName, LastName
FROM Person.Person;

/*
Returns only the specified columns (vertical filtering)
*/

-------------------------------------------------------------------------------
-- 1.3 - SELECT with column alias
-------------------------------------------------------------------------------

SELECT 
FirstName AS First_Name,
LastName  AS Last_Name
FROM Person.Person;

/*
Improves readability of the result set
*/

-------------------------------------------------------------------------------
-- 1.4 - SELECT with horizontal filter (WHERE clause)
-------------------------------------------------------------------------------

SELECT FirstName, LastName, PersonType
FROM Person.Person
WHERE PersonType = 'EM'; --EM = Employee (non-sales)

/*
Filters rows before returning the result (horizontal filtering)

Primary type of person: 
SC = Store Contact, 
IN = Individual (retail) customer, 
SP = Sales person, 
EM = Employee (non-sales), 
VC = Vendor contact, 
GC = General contact

*/

-------------------------------------------------------------------------------
-- 1.5 - SELECT with comparison operator
-------------------------------------------------------------------------------

SELECT SalesOrderID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 23153.2339;

/*
Returns only orders where TotalDue is greater than 23153.2339
*/

-------------------------------------------------------------------------------
-- 1.6 - SELECT with DISTINCT
-------------------------------------------------------------------------------

SELECT DISTINCT JobTitle
FROM HumanResources.Employee;

/*
Removes duplicate values from the result set
*/

-------------------------------------------------------------------------------
-- 1.7 - SELECT with ORDER BY
-------------------------------------------------------------------------------

SELECT SalesOrderID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY SalesOrderID DESC;

/*
Sorts the result set in descending order
*/

-------------------------------------------------------------------------------
-- 1.8 - SELECT with TOP
-------------------------------------------------------------------------------

SELECT TOP (10) SalesOrderID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue DESC;

SELECT TOP (10) SalesOrderID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
ORDER BY TotalDue;

/*
→ Returns only the first 10 rows after sorting
→ In the first example, I used ORDER BY TotalDue with DESC explicitly.
→ In the second example, I used ORDER BY TotalDue without explicitly setting DESC.
→ The default sorting order is ASC.
→ ASC (ascending) is the default behavior
→ DESC (descending) must be explicitly specified
*/


-------------------------------------------------------------------------------
-- 1.9 - LIKE (starts with)
-------------------------------------------------------------------------------

SELECT TOP (5)
BusinessEntityID,
FirstName,
LastName
FROM Person.Person
WHERE LastName LIKE 'Sm%'
ORDER BY LastName, FirstName;

/*
Returns last names starting with 'Sm'

Result:
BusinessEntityID	FirstName	LastName
12032	            Abigail	    Smith
3155	            Adriana	    Smith
18069	            Alexander	Smith
11294	            Alexandra	Smith
11990	            Alexis	    Smith
*/

-------------------------------------------------------------------------------
-- 1.10 - LIKE (contains)
-------------------------------------------------------------------------------

SELECT TOP (5)
Name,
ProductNumber
FROM Production.Product
WHERE Name LIKE '%Road%'
ORDER BY Name;

/*
Returns products whose Name contains 'Road'

Result:
Name	                    ProductNumber
HL Road Frame - Black, 44	FR-R92B-44
HL Road Frame - Black, 48	FR-R92B-48
HL Road Frame - Black, 52	FR-R92B-52
HL Road Frame - Black, 58	FR-R92B-58
HL Road Frame - Black, 62	FR-R92B-62
*/

-------------------------------------------------------------------------------
-- 1.11 - AND (multiple conditions)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
Status,
TotalDue
FROM Sales.SalesOrderHeader
WHERE Status = 5 AND TotalDue > 1000
ORDER BY TotalDue DESC;

/*
Both conditions must be true

Result:
SalesOrderID	Status	TotalDue
51131	        5	    187487,825
55282	        5	    182018,6272
46616	        5	    170512,6689
46981	        5	    166537,0808
47395	        5	    165028,7482
*/

-------------------------------------------------------------------------------
-- 1.12 - OR (either condition)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
Status,
TotalDue
FROM Sales.SalesOrderHeader
WHERE Status = 5 OR TotalDue > 5000
ORDER BY TotalDue DESC;

/*
At least one condition must be true

Result:
SalesOrderID	Status	TotalDue
51131	        5	    187487,825
55282	        5	    182018,6272
46616	        5	    170512,6689
46981	        5	    166537,0808
47395	        5	    165028,7482
*/

-------------------------------------------------------------------------------
-- 1.13 - Greater than (>)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue > 5000
ORDER BY TotalDue;

/*
Returns orders with TotalDue greater than 5000

Result:
SalesOrderID	TotalDue
61221	        5001,7686
46352	        5010,5622
49862	        5033,7347
57113	        5038,6715
51730	        5042,725
*/

-------------------------------------------------------------------------------
-- 1.14 - Less than (<)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue < 50
ORDER BY TotalDue ASC;

/*
Returns orders with TotalDue lower than 50

Result:
SalesOrderID	TotalDue
51782	        1,5183
51885	        2,5305
51886	        2,5305
52031	        2,5305
52371	        2,5305
*/

-------------------------------------------------------------------------------
-- 1.15 - IN (multiple values)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
Status,
TotalDue
FROM Sales.SalesOrderHeader
WHERE Status IN (1, 5)
ORDER BY OrderDate DESC;

/*
Equivalent to: Status = 1 OR Status = 5

Result:
SalesOrderID	Status	TotalDue
75084	        5	    132,60
75085	        5	    18,7187
75086	        5	    8,7848
75087	        5	    38,664
75088	        5	    125,9258
*/

-------------------------------------------------------------------------------
-- 1.16 - BETWEEN (inclusive range)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
TotalDue
FROM Sales.SalesOrderHeader
WHERE TotalDue BETWEEN 1000 AND 2000
ORDER BY TotalDue DESC;

/*
BETWEEN is inclusive: >= 1000 AND <= 2000

Result:
SalesOrderID	TotalDue
54416	        1998,3373
63537	        1998,3373
55271	        1993,0757
68622	        1988,9448
57576	        1988,4254
*/

-------------------------------------------------------------------------------
-- 1.17 - IS NULL (returns only NULL values)
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NULL
ORDER BY SalesOrderID;

/*
Returns rows where SalesPersonID is NULL

Result:
SalesOrderID	SalesPersonID
43697	        NULL
43698	        NULL
43699	        NULL
43700	        NULL
43701	        NULL
*/

-- "= NULL" (returns nothing - incorrect comparison)

SELECT TOP (5)
SalesOrderID,
SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID = NULL
ORDER BY SalesOrderID;

/*
Result: 0 rows (always)

Reason:
→ NULL means "unknown".
→ Any comparison using = NULL evaluates to UNKNOWN, not TRUE
→ Use IS NULL instead
*/

-------------------------------------------------------------------------------
-- 1.18 - IS NOT NULL
-------------------------------------------------------------------------------

SELECT TOP (5)
SalesOrderID,
SalesPersonID
FROM Sales.SalesOrderHeader
WHERE SalesPersonID IS NOT NULL
ORDER BY SalesOrderID;

/*
Returns rows where SalesPersonID has a value

Result:
SalesOrderID	SalesPersonID
43659	        279
43660	        279
43661	        282
43662	        282
43663	        276
*/

-------------------------------------------------------------------------------
-- 1.19 - DISTINCT
-------------------------------------------------------------------------------

SELECT DISTINCT TOP (5)
PersonType
FROM Person.Person
ORDER BY PersonType;

/*
Returns unique values

Result:
PersonType
EM
GC
IN
SC
SP
*/
 


-------------------------------------------------------------------------------
-- 2 - GROUP BY 
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 2.1 - GROUP BY with COUNT
-------------------------------------------------------------------------------

SELECT PersonType, COUNT(*) AS TotalPersons
FROM Person.Person
GROUP BY PersonType;

/*
Groups rows by PersonType
Returns the total number of records for each type

Expression        Counts                         Difference
COUNT(*)          All rows                       None
COUNT(1)          All rows                       None
COUNT(column)     Only non-NULL values           Can change the result

Result:
PersonType	TotalPersons
IN	        18484
EM	        273
SP	        17
SC	        753
VC	        156
GC	        289
*/

-------------------------------------------------------------------------------
-- 2.2 - GROUP BY with SUM
-------------------------------------------------------------------------------

SELECT CustomerID, SUM(TotalDue) AS TotalAmount
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY TotalAmount DESC;

/*
Calculates total sales amount per customer
Sorts the result set of the SUM aggregation by TotalAmount in descending order

Result:
CustomerID	TotalAmount
29818	    989184,082
29715	    961675,8596
29722	    954021,9235
30117	    919801,8188
... + 19115 rows
*/

-------------------------------------------------------------------------------
-- 2.3 - GROUP BY with multiple columns
-------------------------------------------------------------------------------

SELECT CustomerID, YEAR(OrderDate) AS OrderYear, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
GROUP BY CustomerID, YEAR(OrderDate)
ORDER BY OrderYear, TotalOrders DESC;

/*
Creates groups based on CustomerID and OrderYear
Each unique combination forms a group
Sorts the result set first by OrderYear in ascending order and then by the 
aggregated TotalAmount in descending order

Result:
CustomerID	OrderYear	TotalOrders
29614	    2005	    2
29963	    2005	    2
29892	    2005	    2
29880	    2005	    2
29702	    2005	    2
... + 26013 rows

*/

-------------------------------------------------------------------------------
-- 2.4 - WHERE before GROUP BY
-------------------------------------------------------------------------------

SELECT CustomerID, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
WHERE Status = 5
GROUP BY CustomerID
ORDER BY TotalOrders DESC;

/*
WHERE filters rows first
Only records with Status = 5 are grouped
Sorts the result set first by the aggregated TotalOrders in descending order

Result:
CustomerID	TotalOrders
11176	    28
11091	    28
11277	    27
11200	    27
11223	    27
... + 19115 rows

*/

-------------------------------------------------------------------------------
-- 2.5 - HAVING after GROUP BY
-------------------------------------------------------------------------------

SELECT CustomerID, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 24;

/*
HAVING filters groups after aggregation
Only customers with more than 24 orders are returned

Result:
CustomerID	TotalOrders
11091	    28
11176	    28
11185	    27
11200	    27
... + 10 rows
*/

-------------------------------------------------------------------------------
-- 2.6 - GROUP BY with AVG
-------------------------------------------------------------------------------

SELECT TerritoryID, AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID
ORDER BY AverageOrderValue DESC;

/*
Calculates average order value per territory
Sorts the result set by AverageOrderValue in descending order

Result:
TerritoryID	AverageOrderValue
3	        23151,4266
2	        22216,5046
5	        18280,0398
6	        4523,956
4	        4362,242
*/

-------------------------------------------------------------------------------
-- 2.7 - Common GROUP BY Mistakes
-- Mistake 1: Column in SELECT not included in GROUP BY
-------------------------------------------------------------------------------

SELECT TerritoryID, OrderDate, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID;

/*
Result:
Msg 8120, Level 16, State 1, Line 294
Column 'Sales.SalesOrderHeader.OrderDate' is invalid in the select list because 
it is not contained in either an aggregate function or the GROUP BY clause.

Reason:
Every column in SELECT must be:
- Aggregated (COUNT, SUM, AVG)
OR
- Included in GROUP BY
*/

-------------------------------------------------------------------------------
-- Mistake 2: Using aggregate function in WHERE
-------------------------------------------------------------------------------

SELECT CustomerID, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
WHERE COUNT(*) > 5
GROUP BY CustomerID;

/*
Error:
Msg 147, Level 15, State 1, Line 317
An aggregate may not appear in the WHERE clause unless it is in a subquery 
contained in a HAVING clause or a select list, and the column being aggregated 
is an outer reference

Reason:
WHERE filters rows before grouping.
Aggregates are calculated after GROUP BY.

Correct approach: Use HAVING.
*/

--Correct version using HAVING 
SELECT CustomerID, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING COUNT(*) > 24 

/*
Result: 
Same result as item 2.5
*/

-------------------------------------------------------------------------------
-- Mistake 3: Filtering aggregated column in WHERE
-------------------------------------------------------------------------------

SELECT TerritoryID, AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader
WHERE AVG(TotalDue) > 5000
GROUP BY TerritoryID;

/*
Error:
Msg 147, Level 15, State 1, Line 352
An aggregate may not appear in the WHERE clause unless it is in a subquery 
contained in a HAVING clause or a select list, and the column being aggregated
is an outer reference

Correct approach: Use HAVING.
*/

--Correct version using HAVING 
SELECT TerritoryID, AVG(TotalDue) AS AverageOrderValue
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID
HAVING AVG(TotalDue) > 5000;

/*
Result:
TerritoryID	AverageOrderValue
3	        23151,4266
5	        18280,0398
2	        22216,5046
*/

-------------------------------------------------------------------------------
-- Mistake 4: GROUP BY changes granularity unexpectedly
-------------------------------------------------------------------------------

SELECT TerritoryID, OrderDate, COUNT(*) AS TotalOrders
FROM Sales.SalesOrderHeader
GROUP BY TerritoryID, OrderDate;

/*
Each unique combination of TerritoryID + OrderDate forms a group

Common issue:
Adding extra columns increases granularity and may produce more rows than expected

Result:
TerritoryID	    OrderDate	                TotalOrders
2	            2005-09-01 00:00:00.000	    6
4	            2006-09-25 00:00:00.000	    1
6	            2007-10-19 00:00:00.000	    5
7	            2007-12-22 00:00:00.000	    6
10	            2005-07-07 00:00:00.000	    1
... + 5826 rows
*/

-------------------------------------------------------------------------------
-- 3 - INNER JOIN (only matching rows)
-------------------------------------------------------------------------------

SELECT 
C.CustomerID,
P.FirstName,
P.LastName
FROM Sales.Customer C
INNER JOIN Person.Person P
    ON C.PersonID = P.BusinessEntityID
WHERE CustomerID >= 30115;

/*
Returns only customers that have a related Person record

Result:
CustomerID	FirstName	LastName
30115	    Dora	    Verdad
30116	    Wanda	    Vernon
30117	    Robert	    Vessa
30118	    Caroline	Vicknair
*/

-------------------------------------------------------------------------------
-- 4 - LEFT JOIN (all rows from left table)
-------------------------------------------------------------------------------

SELECT 
C.CustomerID,
SOH.SalesOrderID
FROM Sales.Customer C
LEFT JOIN Sales.SalesOrderHeader SOH
    ON C.CustomerID = SOH.CustomerID

/*
Returns all customers, including those without orders (SalesOrderID will be NULL)

Result:
CustomerID	SalesOrderID
1	        NULL
2	        NULL
3	        NULL
...
699	        NULL
700	        NULL
701	        NULL
11000	    43793
11000	    51522
11000	    57418
11001	    43767
11001	    51493
*/

-------------------------------------------------------------------------------
-- 4.1 - LEFT JOIN that naturally produces NULLs (SalesPersonID can be NULL)
-------------------------------------------------------------------------------
/*
→ Sales.SalesOrderHeader.SalesPersonID is optional (can be NULL)
→ Therefore, some orders are not associated with any salesperson
→ If I join to Sales.SalesPerson, some rows will have NULL values on the
  salesperson side
*/

SELECT
SOH.SalesOrderID,
SOH.SalesPersonID,
SP.BusinessEntityID AS SalesPersonBusinessEntityID
FROM Sales.SalesOrderHeader SOH
LEFT JOIN Sales.SalesPerson SP
    ON SOH.SalesPersonID = SP.BusinessEntityID
WHERE SOH.SalesPersonID IS NULL;

/*
Result:
→ SalesOrderHeader rows without a salesperson
→ Joined columns from SalesPerson will be NULL
*/

-------------------------------------------------------------------------------
-- 5 - RIGHT JOIN producing NULLs on the left side
-------------------------------------------------------------------------------

SELECT
SOH.SalesOrderID,
SOH.SalesPersonID,
SP.BusinessEntityID AS SalesPersonBusinessEntityID
FROM Sales.SalesPerson SP
RIGHT JOIN Sales.SalesOrderHeader SOH
    ON SOH.SalesPersonID = SP.BusinessEntityID
WHERE SOH.SalesPersonID IS NULL;

/*
Result:
→ Keeps all rows from SalesOrderHeader (right table)
→ When SalesPersonID is NULL, SP columns will be NULL
*/

-------------------------------------------------------------------------------
-- 6 - Controlled example: create unmatched rows using VALUES
-------------------------------------------------------------------------------

SELECT
V.CustomerID,
C.AccountNumber
FROM (VALUES (1), (2), (999999)) V(CustomerID)
LEFT JOIN Sales.Customer C
    ON C.CustomerID = V.CustomerID;

/*
Result:
CustomerID	AccountNumber
1	        AW00000001
2	        AW00000002
999999	    NULL
*/

SELECT
V.CustomerID,
C.AccountNumber
FROM (VALUES (1), (2), (999999)) V(CustomerID)
RIGHT JOIN Sales.Customer C
    ON C.CustomerID = V.CustomerID;

/*
Result:
CustomerID	AccountNumber
1	        AW00000001
2	        AW00000002
NULL	    AW00000007
NULL	    AW00000019
NULL	    AW00000020
*/

-------------------------------------------------------------------------------
-- 7 - FULL OUTER JOIN
-------------------------------------------------------------------------------

SELECT  
C.CustomerID,
SOH.SalesOrderID
FROM Sales.Customer C
FULL OUTER JOIN Sales.SalesOrderHeader SOH
    ON C.CustomerID = SOH.CustomerID
ORDER BY C.CustomerID;

/*
Return:
→ Matching rows between the tables
→ Rows without a match on the left table
→ Rows without a match on the right table
→ In the original AdventureWorks database, orphan rows are rare because 
  foreign key constraints enforce referential integrity.

Visual Example (does not contain real data from the AdventureWorks database):
CustomerID	SalesOrderID
11000	    43659
11002	    NULL
NULL	    50000

*/

-------------------------------------------------------------------------------
-- 8 - CROSS JOIN (Cartesian Product)
-------------------------------------------------------------------------------

SELECT 
T.Name  AS TerritoryName,
S.Name  AS ShipMethodName
FROM Sales.SalesTerritory T
CROSS JOIN Purchasing.ShipMethod S 
WHERE S.Name IN ('XRQ - TRUCK GROUND','ZY - EXPRESS','OVERSEAS - DELUXE')
ORDER BY TerritoryName 
/*
→ How it works?
→ Each territory is combined with every shipping method
  If:
  SalesTerritory = 10 rows
  ShipMethod = 5 rows
→ Final Result = 10 × 5 = 50 rows

Note:
→ Even with a WHERE clause, this is still a CROSS JOIN
1º - CROSS JOIN → generates all possible combinations
2º - WHERE      → filters the result afterward

Result:
TerritoryName	ShipMethodName
Australia	    OVERSEAS - DELUXE
Australia	    XRQ - TRUCK GROUND
Australia	    ZY - EXPRESS
Canada	        OVERSEAS - DELUXE
Canada	        XRQ - TRUCK GROUND
Canada	        ZY - EXPRESS
Central	        OVERSEAS - DELUXE
Central	        XRQ - TRUCK GROUND
Central	        ZY - EXPRESS
Canada	        OVERNIGHT J-FAST
Canada	        CARGO TRANSPORT 5
*/

-------------------------------------------------------------------------------
-- 9 - Common JOIN Mistakes
-- Mistake 1: Missing JOIN condition (Cartesian product)
-------------------------------------------------------------------------------

SELECT 
    C.CustomerID,
    SOH.SalesOrderID
FROM Sales.Customer C
JOIN Sales.SalesOrderHeader SOH
    ON 1 = 1;

/*
Problem:
ON 1 = 1 creates a Cartesian product

Result:
→ Each customer is combined with every order
→ Result set grows exponentially
→ Query was canceled by user with 7.656.290 rows
*/

-------------------------------------------------------------------------------
-- Mistake 2: Filtering RIGHT table in WHERE after LEFT JOIN
-------------------------------------------------------------------------------

SELECT 
C.CustomerID,
SOH.SalesOrderID
FROM Sales.Customer C
LEFT JOIN Sales.SalesOrderHeader SOH
    ON C.CustomerID = SOH.CustomerID
WHERE SOH.SalesOrderID IS NOT NULL;

/*
Problem:
The WHERE clause removes NULLs, turning the LEFT JOIN effectively into an INNER JOIN

Result:
31462 rows
*/

-- Correct approach: Filter inside JOIN when needed
select distinct SOH.RevisionNumber  from Sales.SalesOrderHeader SOH

SELECT 
C.CustomerID,
SOH.SalesOrderID
FROM Sales.Customer C
LEFT JOIN Sales.SalesOrderHeader SOH
    ON C.CustomerID = SOH.CustomerID
    AND SOH.RevisionNumber = 3
ORDER BY CustomerID ASC;

/*
Filtering in the ON clause preserves LEFT JOIN behavior

Result: (After 700 rows)
CustomerID	SalesOrderID
701	        NULL
11000	    NULL
11001	    43767
11001	    51493
*/

-------------------------------------------------------------------------------
-- Mistake 3: Using wrong join column
-------------------------------------------------------------------------------

SELECT 
P.BusinessEntityID,
C.CustomerID
FROM Person.Person P
JOIN Sales.Customer C
    ON P.BusinessEntityID = C.CustomerID;

/*
Problem:
→ These columns are not related 
→ Correct relationship is Person.BusinessEntityID = Customer.PersonID
*/

-- Correct relationship
SELECT 
P.BusinessEntityID,
C.CustomerID
FROM Person.Person P
JOIN Sales.Customer C
    ON P.BusinessEntityID = C.PersonID;

-------------------------------------------------------------------------------
-- Mistake 4: Forgetting table aliases in multi-table queries
-------------------------------------------------------------------------------

SELECT 
CustomerID
FROM Sales.Customer
JOIN Sales.SalesOrderHeader
    ON CustomerID = CustomerID;

/*
Problem:
Msg 209, Level 16, State 1, Line 905
Ambiguous column name 'CustomerID'.
Msg 209, Level 16, State 1, Line 905
Ambiguous column name 'CustomerID'.
Msg 209, Level 16, State 1, Line 902
Ambiguous column name 'CustomerID'.

→ SQL Server does not know which CustomerID to use.
→ Always qualify columns with table alias.
*/
