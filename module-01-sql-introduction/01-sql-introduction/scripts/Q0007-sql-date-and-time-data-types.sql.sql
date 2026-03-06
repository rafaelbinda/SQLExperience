/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-05
Version     : 1.0
Task        : Q0007-sql-date-and-time-data-types.sql
Databases   : ExamplesDB
Object      : Script
Description : Examples demonstrating date and time data types in SQL Server
Notes       : A0010-sql-data-types.md
===============================================================================
*/

SET NOCOUNT ON;
GO 
 
USE ExamplesDB;
GO

-------------------------------------------------------------------------------
-- 1 - DATETIME
-------------------------------------------------------------------------------

-- Traditional SQL Server type storing date and time

CREATE TABLE Example_Datetime
(
    Id INT IDENTITY(1,1),
    CreatedAt DATETIME
);
GO

INSERT INTO Example_Datetime (CreatedAt)
VALUES
('1753-01-01 00:00:00'),
(GETDATE()),
('9999-12-31 00:00:00');
GO

SELECT *
FROM Example_Datetime;
GO

/*
Result:
Id	CreatedAt
1	1753-01-01 00:00:00.000
2	2026-03-05 23:01:57.447
3	9999-12-31 00:00:00.000
*/

--1.1 - Checking storage size
SELECT
Id,
CreatedAt,
DATALENGTH(CreatedAt) AS BytesStored
FROM Example_Datetime;
GO

/*
Result:
Id	CreatedAt	                BytesStored
1	1753-01-01 00:00:00.000	    8
2	2026-03-05 23:01:57.447	    8
3	9999-12-31 00:00:00.000	    8
*/

--1.2 - Demonstrating DATETIME rounding (~3.33 ms increments)

CREATE TABLE Example_DatetimeRounding
(
    Id INT IDENTITY(1,1),
    InputValue   VARCHAR(30),
    StoredValue  DATETIME
);
GO

truncate table Example_DatetimeRounding

INSERT INTO Example_DatetimeRounding (InputValue, StoredValue)
VALUES
('2026-03-05 23:27:30.001', '2026-03-05 23:27:30.001'),
('2026-03-05 23:27:30.002', '2026-03-05 23:27:30.002'),
('2026-03-05 23:27:30.003', '2026-03-05 23:27:30.003'),
('2026-03-05 23:27:30.004', '2026-03-05 23:27:30.004'),
('2026-03-05 23:27:30.005', '2026-03-05 23:27:30.005');
GO

SELECT
Id,
InputValue   AS Original_Input,
StoredValue  AS Stored_DATETIME
FROM Example_DatetimeRounding;
GO

/*
Result:
→ DATETIME stores fractions of seconds in increments of approximately 3.33 ms,
which is why inserted values are automatically rounded

Id	Original_Input	            Stored_DATETIME
1	2026-03-05 23:27:30.001	    2026-03-05 23:27:30.000
2	2026-03-05 23:27:30.002	    2026-03-05 23:27:30.003
3	2026-03-05 23:27:30.003	    2026-03-05 23:27:30.003
4	2026-03-05 23:27:30.004	    2026-03-05 23:27:30.003
5	2026-03-05 23:27:30.005	    2026-03-05 23:27:30.007
*/

-------------------------------------------------------------------------------
-- 2 - SMALLDATETIME
-------------------------------------------------------------------------------

--Precision is limited to 1 minute

CREATE TABLE Example_SmallDatetime
(
    Id INT IDENTITY(1,1),
    CreatedAt SMALLDATETIME
);
GO

INSERT INTO Example_SmallDatetime (CreatedAt)
VALUES
('1900-01-01 00:00:00'),
(GETDATE()),
('2079-06-06 00:00:00');
GO

SELECT *
FROM Example_SmallDatetime;
GO

/*
Result:
Id	CreatedAt
1	1900-01-01 00:00:00
2	2026-03-05 23:05:00
3	2079-06-06 00:00:00
*/

--2.1 - Checking storage size
SELECT
Id,
CreatedAt,
DATALENGTH(CreatedAt) AS BytesStored
FROM Example_SmallDatetime;
GO

/*
Result:
Id	CreatedAt	            BytesStored
1	1900-01-01 00:00:00	    4
2	2026-03-05 23:05:00	    4
3	2079-06-06 00:00:00	    4
*/


-------------------------------------------------------------------------------
-- 3 - DATE
-------------------------------------------------------------------------------

--Stores only the date
CREATE TABLE Example_Date
(
    Id INT IDENTITY(1,1),
    OrderDate DATE
);
GO

select cast(getdate() as date) 
select getdate()

INSERT INTO Example_Date (OrderDate)
VALUES
('0001-01-01'),
(CAST(GETDATE() AS DATE)),
('9999-12-31');
GO

SELECT *
FROM Example_Date;
GO

/*
Result:
Id	OrderDate
1	0001-01-01
2	2026-03-05
3	9999-12-31
*/

--3.1 - Checking storage size
SELECT
Id,
OrderDate,
DATALENGTH(OrderDate) AS BytesStored
FROM Example_Date;
GO

/*
Result:
Id	OrderDate	BytesStored
1	0001-01-01	3
2	2026-03-05	3
3	9999-12-31	3
*/


-------------------------------------------------------------------------------
-- 4 - TIME
-------------------------------------------------------------------------------

--Stores only the time

CREATE TABLE Example_Time
(
    Id INT IDENTITY(1,1),
    EventTime TIME(7)
);
GO

INSERT INTO Example_Time (EventTime)
VALUES
('00:00:00.0000000'),
(CAST(GETDATE() AS TIME)),
('23:59:59.9999999');
GO

SELECT *
FROM Example_Time;
GO

/*
Result:
Id	EventTime
1	00:00:00.0000000
2	23:11:01.4300000
3	23:59:59.9999999
*/

--4.1 - Checking storage size
SELECT
Id,
EventTime,
DATALENGTH(EventTime) AS BytesStored
FROM Example_Time;
GO

/*
Result:
Id	EventTime	        BytesStored
1	00:00:00.0000000	5
2	23:11:01.4300000	5
3	23:59:59.9999999	5
*/

-------------------------------------------------------------------------------
-- 5 - DATETIME2
-------------------------------------------------------------------------------

--Recommended modern type with higher precision

CREATE TABLE Example_Datetime2
(
    Id INT IDENTITY(1,1),
    CreatedAt DATETIME2(7)
);
GO

INSERT INTO Example_Datetime2 (CreatedAt)
VALUES
('0001-01-01 00:00:00.0000000'),
(SYSDATETIME()),
('9999-12-31 00:00:00.0000000');
GO

SELECT *
FROM Example_Datetime2;
GO

/*
Result:
Id	CreatedAt
1	0001-01-01 00:00:00.0000000
2	2026-03-05 23:12:55.0367388
3	9999-12-31 00:00:00.0000000
*/

--5.1 - Checking storage size
SELECT
Id,
CreatedAt,
DATALENGTH(CreatedAt) AS BytesStored
FROM Example_Datetime2;
GO

/*
Result:
Id	CreatedAt	                    BytesStored
1	0001-01-01 00:00:00.0000000	        8
2	2026-03-05 23:12:55.0367388	        8
3	9999-12-31 00:00:00.0000000	        8
*/


-------------------------------------------------------------------------------
-- 6 - DATETIMEOFFSET
-------------------------------------------------------------------------------

CREATE TABLE Example_DatetimeOffset
(
    Id INT IDENTITY(1,1),
    Location VARCHAR(30),
    EventTime DATETIMEOFFSET
);
GO

INSERT INTO Example_DatetimeOffset (Location, EventTime)
VALUES
('Brazil',      SYSDATETIMEOFFSET() AT TIME ZONE 'E. South America Standard Time'),
('USA (New York)', SYSDATETIMEOFFSET() AT TIME ZONE 'Eastern Standard Time'),
('China',       SYSDATETIMEOFFSET() AT TIME ZONE 'China Standard Time'),
('Dubai',       SYSDATETIMEOFFSET() AT TIME ZONE 'Arabian Standard Time'),
('Greenland',   SYSDATETIMEOFFSET() AT TIME ZONE 'Greenland Standard Time');
GO

SELECT
Id,
Location,
EventTime,
SYSDATETIMEOFFSET() AS CurrentServerTime
FROM Example_DatetimeOffset;
GO

/*Result:
Id	Location	    EventTime	                        CurrentServerTime
1	Brazil	        2026-03-05 23:15:42.3295857 -03:00	2026-03-05 23:16:24.7890977 -03:00
2	USA (New York)	2026-03-05 21:15:43.0045824 -05:00	2026-03-05 23:16:24.7890977 -03:00
3	China	        2026-03-06 10:15:43.0045824 +08:00	2026-03-05 23:16:24.7890977 -03:00
4	Dubai	        2026-03-06 06:15:43.0045824 +04:00	2026-03-05 23:16:24.7890977 -03:00
5	Greenland	    2026-03-06 00:15:43.0045824 -02:00	2026-03-05 23:16:24.7890977 -03:00
*/

--6.1 - Checking storage size
SELECT
Id,
Location,
DATALENGTH(EventTime) AS BytesStored
FROM Example_DatetimeOffset;
GO

/*
Result:
Id	Location	        BytesStored
1	Brazil	            10
2	USA (New York)	    10
3	China	            10
4	Dubai	            10
5	Greenland	        10
*/

--6.2 - Returns all time zones available in the instance
SELECT *
FROM sys.time_zone_info;

/*
Result:
141 rows

name                =   Name of the time zone
current_utc_offset  =   Current difference from UTC
is_currently_dst    =   Indicates whether the time zone is currently in daylight saving time

name	                        current_utc_offset	is_currently_dst
Dateline Standard Time	        -12:00	                0
UTC-11	                        -11:00	                0
Aleutian Standard Time	        -10:00	                0
Hawaiian Standard Time	        -10:00	                0
...
Easter Island Standard Time	    -05:00	                1
...
*/

-------------------------------------------------------------------------------
-- 7 - Comparing current date/time functions
-------------------------------------------------------------------------------

SELECT
GETDATE()           AS GetDate,
SYSDATETIME()       AS SysDateTime,
SYSDATETIMEOFFSET() AS SysDateTimeOffset,
CURRENT_TIMESTAMP   AS CurrentTimestamp;
GO

/*
Result:
GetDate             =   2026-03-05 23:22:00.913
SysDateTime         =   2026-03-05 23:22:00.9160168
SysDateTimeOffset   =   2026-03-05 23:22:00.9160168 -03:00
CurrentTimestamp    =   2026-03-05 23:22:00.913
*/

