/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-02-21
Version     : 1.0
Task        : Q0002 - Create Database
Object      : Script
Description : Queries using create database 
Notes       : -
===============================================================================
*/

SET NOCOUNT ON;
GO 


-------------------------------------------------------------------------------
--The minimum code to create a database
-------------------------------------------------------------------------------

DROP DATABASE IF EXISTS ExamplesDB;
GO

CREATE DATABASE [ExamplesDB]

/*
In this case, the Microsoft SQL Server:
→ Doesn't create the database from scratch
→ Creates the database based on the MODEL database

→ Internal flow:
MODEL  →  sctructure copy  →  ExamplesDB

→ If you create a table in MODEL, it will appear in every new database
*/

-------------------------------------------------------------------------------
--The minimum code do you need understand to create a database
-------------------------------------------------------------------------------

use master;
go

DROP DATABASE IF EXISTS ExamplesDB;
GO

CREATE DATABASE [ExamplesDB]
ON PRIMARY
(
    NAME = N'ExamplesDB',
    FILENAME = N'C:\MSSQLSERVER\DATA\ExamplesDB.mdf',
    SIZE = 256 MB,
    FILEGROWTH = 128 MB,
    MAXSIZE = 10240 MB
)
LOG ON
(
    NAME = N'ExamplesDB_log',
    FILENAME = N'C:\MSSQLSERVER\LOG\ExamplesDB_log.ldf',
    SIZE = 256 MB,
    FILEGROWTH = 128 MB,
    MAXSIZE = 10240 MB
);
GO

/*
ON or ON PRIMARY:
If you do not explicitly declare PRIMARY, SQL Server automatically places the primary file in the PRIMARY filegroup.

NAME        → Logical file name
FILENAME    → Physical path of the data (.mdf) or log (.ldf) file
SIZE        → Initial file size (KB, MB, GB)
FILEGROWTH  → Automatic growth increment (KB, MB, GB)
MAXSIZE     → Maximum file size allowed to grow (Lab = UNLIMITED)

Recommendation:
It is recommended to define a size limit for the log file.

Best Practices:
Avoid percentage (%) autogrowth settings.
Use fixed-size growth instead to:

→ Reduce fragmentation
→ Maintain predictable file growth
→ Prevent I/O latency spikes

Recommended autogrowth size:

Database Size          Recommended Growth
Small (< 10 GB)        MB
Medium (10–500 GB)     Hundreds of MB
Large (> 500 GB)       GB

Important:
If automatic growth is occurring too frequently, this indicates a configuration issue.
*/

-------------------------------------------------------------------------------
--Create a database with additional FILEGROUPS
-------------------------------------------------------------------------------
use master;
go

DROP DATABASE IF EXISTS ExamplesDBFG;
GO

CREATE DATABASE [ExamplesDBFG]
ON PRIMARY
(
    NAME = N'ExamplesDBFG_Primary',
    FILENAME = N'C:\MSSQLSERVER\DATA\ExamplesDBFG_Primary.mdf',
    SIZE = 256MB,
    FILEGROWTH = 128MB
),

FILEGROUP FG_DATA1
(
    NAME = N'ExamplesDBFG_Data1',
    FILENAME = N'C:\MSSQLSERVER\FG_DATA\ExamplesDBFG_Data1.ndf',
    SIZE = 512MB,
    FILEGROWTH = 256MB
),

FILEGROUP FG_DATA2
(
    NAME = N'ExamplesDBFG_Data2',
    FILENAME = N'C:\MSSQLSERVER\FG_DATA\ExamplesDBFG_Data2.ndf',
    SIZE = 512MB,
    FILEGROWTH = 256MB
),


FILEGROUP FG_INDEX
(
    NAME = N'ExamplesDBFG_Index',
    FILENAME = N'C:\MSSQLSERVER\FG_INDEX\ExamplesDBFG_Index.ndf',
    SIZE = 512MB,
    FILEGROWTH = 256MB
)

LOG ON
(
    NAME = N'ExamplesDBFG_Log',
    FILENAME = N'C:\MSSQLSERVER\LOG\ExamplesDBFG_Log.ldf',
    SIZE = 512MB,
    FILEGROWTH = 256MB
);
GO

/*
Explanation (synthetic)
PRIMARY     → System objects and metadata
FG_DATA1    → User tables (data filegroup 1)
FG_DATA2    → User tables (data filegroup 2)
FG_INDEX    → Nonclustered Indexes
LOG         → Transaction log file
*/

--------------------------------------------------------------------------------
-- After executing the previous script, it is important to define
-- the DEFAULT FILEGROUP
--------------------------------------------------------------------------------

ALTER DATABASE ExamplesDBFG
MODIFY FILEGROUP FG_DATA1 DEFAULT;
GO

-------------------------------------------------------------------------------
-- Create tables in different FILEGROUPS
-------------------------------------------------------------------------------

USE ExamplesDBFG;
GO

-- Table created in FG_DATA1
-- It is NOT mandatory to specify FG_DATA1 because it is the DEFAULT filegroup
CREATE TABLE CustomerFGD1
(
    Id INT,
    FirstName NVARCHAR(30),
    LastName NVARCHAR(30)
)
GO

-- Table created in FG_DATA2
-- It IS mandatory to specify FG_DATA2 because it is not the DEFAULT filegroup
CREATE TABLE CustomerFGD2
(
    Id INT,
    FirstName NVARCHAR(30),
    LastName NVARCHAR(30)
)
ON FG_DATA2;
GO

-------------------------------------------------------------------------------
-- Understand create indexes in this scenario
-------------------------------------------------------------------------------

--Creating a CLUSTERED INDEX in FG_DATA1
CREATE CLUSTERED INDEX icx_CustomerFGD1
ON CustomerFGD1(Id);

/*Result:
Clustered Index → FG_DATA1
Table Data      → FG_DATA1
*/

--Creating NONCLUSTERED INDEX in FG_INDEX
CREATE NONCLUSTERED INDEX NC_CustomerFGD1_LastName
ON CustomerFGD1(LastName)
ON FG_INDEX;

/*Result:
Data            → FG_DATA1
Clustered Index → FG_DATA1
Nonclustered    → FG_INDEX
*/

--Creating a CLUSTERED INDEX in FG_DATA2
CREATE CLUSTERED INDEX icx_CustomerFGD2
ON CustomerFGD2(Id)
ON FG_DATA2;

/*Result:
Clustered Index → FG_DATA2
Table Data      → FG_DATA2
*/

--Creating NONCLUSTERED INDEX in FG_INDEX
CREATE NONCLUSTERED INDEX NC_CustomerFGD2_LastName
ON CustomerFGD2(LastName)
ON FG_INDEX;

/*Result:
Data            → FG_DATA2
Clustered Index → FG_DATA2
Nonclustered    → FG_INDEX
*/

-------------------------------------------------------------------------------
-- My Physical Layout
-------------------------------------------------------------------------------
/*
ExamplesDBFG
│
├── C:\MSSQLSERVER\DATA
│     └── ExamplesDBFG_Primary.mdf
│            └── PRIMARY filegroup
│                 → System metadata / internal objects
│
├── C:\MSSQLSERVER\FG_DATA
│     │
│     ├── ExamplesDBFG_Data1.ndf
│     │        └── FG_DATA1
│     │             → User tables (data filegroup 1)
│     │             → Clustered indexes for tables stored in FG_DATA1
│     │
│     └── ExamplesDBFG_Data2.ndf
│              └── FG_DATA2
│                   → User tables (data filegroup 2)
│                   → Clustered indexes for tables stored in FG_DATA2
│
├── C:\MSSQLSERVER\FG_INDEX
│     └── ExamplesDBFG_Index.ndf
│            └── FG_INDEX
│                 → Nonclustered indexes
│
└── C:\MSSQLSERVER\LOG
      └── ExamplesDBFG_Log.ldf
             → Transaction Log (sequential writes)


Recommended Layout (Best Practice)
Component	Disc
Data Files	D:\
Log Files	L:\
TempDB Data	T:\
TempDB Log	T:\  

*/

-------------------------------------------------------------------------------
-- Why Separate Indexes from Data?
-------------------------------------------------------------------------------
/*
→ Allows distribution of I/O
→ Enables isolated index rebuild operations
→ Supports partial restore
→ Allows moving only indexes to faster storage
→ Reduces disk contention
*/