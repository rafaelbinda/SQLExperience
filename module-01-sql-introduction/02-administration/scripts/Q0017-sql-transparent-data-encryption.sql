/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-05
Version     : 1.0
Task        : Q0017 - Transparent Data Encryption (TDE)
Object      : Script
Description : Demonstrates how to configure Transparent Data Encryption (TDE)
              in SQL Server, including database creation, certificate backup,
              encryption monitoring, validation, decryption, and cleanup
Notes       : notes/A0020-transparent-data-encryption.md
Examples    : ExamplesDB_TDE
===============================================================================

INDEX
1 - Create database
2 - Create test data
3 - Create Database Master Key
4 - Create certificate
5 - Backup certificate
6 - Create Database Encryption Key (DEK)
7 - Enable TDE
8 - Monitor encryption status
9 - Validate encryption
10 - Backup with encryption
11 - Disable TDE
12 - Monitor decryption status
13 - Drop Database Encryption Key
14 - Drop lab database
15 - Drop certificate
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Create database
-------------------------------------------------------------------------------

CREATE DATABASE ExamplesDB_TDE;
GO

-------------------------------------------------------------------------------
-- 2 - Create test data
-------------------------------------------------------------------------------

USE ExamplesDB_TDE;
GO

CREATE TABLE dbo.CustomerDemo
(
    CustomerID   INT IDENTITY(1,1) PRIMARY KEY,
    ColumnLarge  NCHAR(2000),
    ColumnBigint BIGINT,
    CreatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

SET NOCOUNT ON;
GO

INSERT INTO dbo.CustomerDemo (ColumnLarge, ColumnBigint)
VALUES (N'Test', 12345);
GO 300000


-------------------------------------------------------------------------------
-- 3 - Create Database Master Key
-------------------------------------------------------------------------------
-- Required in master to protect the certificate used by TDE

USE master;
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.symmetric_keys
    WHERE name = N'##MS_DatabaseMasterKey##'
)
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Str0ngP@$$w0rd_2026!';
END
GO

-------------------------------------------------------------------------------
-- 4 - Create certificate
-------------------------------------------------------------------------------
-- This certificate will protect the Database Encryption Key (DEK)

IF NOT EXISTS
(
    SELECT 1
    FROM sys.certificates
    WHERE name = N'ExamplesDB_TDE_Cert'
)
BEGIN
    CREATE CERTIFICATE ExamplesDB_TDE_Cert
    WITH SUBJECT = 'Certificate for TDE lab - ExamplesDB_TDE',
         EXPIRY_DATE = '99991231';
END
GO

SELECT
    name,
    subject,
    expiry_date,
    pvt_key_encryption_type_desc
FROM sys.certificates
WHERE name = N'ExamplesDB_TDE_Cert';
GO

/*
Result:
name	                        =   ExamplesDB_TDE_Cert
subject	                        =   Certificate for TDE lab - ExamplesDB_TDE
expiry_date	                    =   9999-12-31 00:00:00.000
pvt_key_encryption_type_desc    =   ENCRYPTED_BY_MASTER_KEY
*/

-------------------------------------------------------------------------------
-- 5 - Backup certificate
-------------------------------------------------------------------------------
-- Required to restore the database on another server

BACKUP CERTIFICATE ExamplesDB_TDE_Cert
TO FILE = 'C:\Temp\ExamplesDB_TDE_Cert.cer'
WITH PRIVATE KEY
(
    FILE = 'C:\Temp\ExamplesDB_TDE_Cert.key',
    ENCRYPTION BY PASSWORD = 'Str0ngP@$$w0rd_2026!'
);
GO

/*
Result:
Commands completed successfully.
Completion time: 2026-04-05T20:24:19.2221409-03:00
*/

-------------------------------------------------------------------------------
-- 6 - Create Database Encryption Key (DEK)
-------------------------------------------------------------------------------
-- The DEK is created inside the user database and encrypts the data

USE ExamplesDB_TDE;
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE ExamplesDB_TDE_Cert;
GO

-------------------------------------------------------------------------------
-- 7 - Enable TDE
-------------------------------------------------------------------------------

ALTER DATABASE ExamplesDB_TDE
SET ENCRYPTION ON;
GO

-------------------------------------------------------------------------------
-- 8 - Monitor encryption status
-------------------------------------------------------------------------------

USE master;
GO

SELECT
DB_NAME(dek.database_id) AS database_name,
dek.encryption_state,
dek.percent_complete,
dek.key_algorithm,
dek.key_length
FROM sys.dm_database_encryption_keys AS dek
WHERE dek.database_id = DB_ID(N'ExamplesDB_TDE');
GO

/*
Result 1:
database_name	encryption_state	percent_complete	key_algorithm	key_length
ExamplesDB_TDE	      2	                86,96896	    AES	            256

Result 2:
database_name	encryption_state	percent_complete	key_algorithm	key_length
ExamplesDB_TDE	      3	                0	            AES	            256

encryption_state
0 = No database encryption key present
1 = Unencrypted
2 = Encryption in progress
3 = Encrypted
4 = Key change in progress
5 = Decryption in progress
6 = Protection change in progress
*/

-------------------------------------------------------------------------------
-- 9 - Validate encryption
-------------------------------------------------------------------------------

SELECT
d.name,
d.is_encrypted
FROM sys.databases AS d
WHERE d.name = N'ExamplesDB_TDE';
GO

/*
Result:
name	        is_encrypted
ExamplesDB_TDE	      1
*/

SELECT
DB_NAME(database_id) AS database_name,
encryption_state,
percent_complete,
key_algorithm,
key_length
FROM sys.dm_database_encryption_keys
WHERE database_id = DB_ID(N'ExamplesDB_TDE');
GO

/*
Result:
database_name	encryption_state	percent_complete	key_algorithm	key_length
ExamplesDB_TDE	      3	                0	            AES	            256
*/
 
SELECT name, is_encrypted
FROM sys.databases
WHERE name = 'tempdb';

/*
Result:
name	is_encrypted
tempdb	1
 
Note: When TDE is enabled on any database, SQL Server automatically encrypts tempdb 
to prevent exposure of sensitive data during temporary operations
*/

-------------------------------------------------------------------------------
-- 10 - Backup with encryption
-------------------------------------------------------------------------------

BACKUP DATABASE ExamplesDB_TDE to disk = '\\192.168.0.105\dbasqlserver\DATABASE\BACKUPS\ExamplesDB_TDE.bak' with init,compression
go

/*
Result:
Processed 151136 pages for database 'ExamplesDB_TDE', file 'ExamplesDB_TDE' on file 1.
Processed 2 pages for database 'ExamplesDB_TDE', file 'ExamplesDB_TDE_log' on file 1.
BACKUP DATABASE successfully processed 151138 pages in 2.558 seconds (461.595 MB/sec).

Completion time: 2026-04-05T20:40:57.5694501-03:00

*/

-------------------------------------------------------------------------------
-- 11 - Disable TDE
-------------------------------------------------------------------------------
-- Decryption may take time depending on database size

ALTER DATABASE ExamplesDB_TDE
SET ENCRYPTION OFF;
GO

-------------------------------------------------------------------------------
-- 12 - Monitor decryption status
-------------------------------------------------------------------------------

SELECT
DB_NAME(dek.database_id) AS database_name,
dek.encryption_state,
dek.percent_complete,
dek.key_algorithm,
dek.key_length
FROM sys.dm_database_encryption_keys AS dek
WHERE dek.database_id = DB_ID(N'ExamplesDB_TDE');
GO

/*
Result 1:
database_name	encryption_state	percent_complete	key_algorithm	key_length
ExamplesDB_TDE	5	                39,23611	        AES	            256

Result 2:
database_name	encryption_state	percent_complete	key_algorithm	key_length
ExamplesDB_TDE	1	                0	                AES	            256
*/


-------------------------------------------------------------------------------
-- 13 - Drop Database Encryption Key
-------------------------------------------------------------------------------
-- Only run this step after encryption_state returns 1 (Unencrypted)

USE ExamplesDB_TDE;
GO

DROP DATABASE ENCRYPTION KEY;
GO

-------------------------------------------------------------------------------
-- 14 - Drop lab database
-------------------------------------------------------------------------------

USE master;
GO

ALTER DATABASE ExamplesDB_TDE
SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

DROP DATABASE ExamplesDB_TDE;
GO

-------------------------------------------------------------------------------
-- 15 - Drop certificate
-------------------------------------------------------------------------------

DROP CERTIFICATE ExamplesDB_TDE_Cert;
GO
