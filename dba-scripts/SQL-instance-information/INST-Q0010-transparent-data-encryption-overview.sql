/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-05
Version     : 1.0
Task        : INST-Q0010 - Transparent Data Encryption Overview
Object      : Script
Description : Useful commands and queries for configuring and validating
              Transparent Data Encryption (TDE) in SQL Server, including
              encryption hierarchy, monitoring, certificate backup,
              and restore failure scenario
Notes       : notes/A0020-transparent-data-encryption.md
Examples    : scripts/Q0017-sql-transparent-data-encryption.sql
===============================================================================

INDEX
1  - Create Database Master Key
2  - Create certificate
3  - Backup certificate
4  - Create Database Encryption Key (DEK)
5  - Enable TDE
6  - Check encrypted databases
7  - Check TDE status details
8  - Interpret encryption state
9  - Check tempdb encryption status
10 - Check certificates in master
11 - Check database encryption keys
12 - Disable TDE
13 - Drop Database Encryption Key
14 - Restore failure without certificate
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Create Database Master Key
-------------------------------------------------------------------------------
-- Run in master
-- Required to protect the certificate used by TDE

USE master;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword_2026!';
GO

-------------------------------------------------------------------------------
-- 2 - Create certificate
-------------------------------------------------------------------------------
-- Run in master
-- This certificate protects the Database Encryption Key (DEK)

CREATE CERTIFICATE TDE_Server_Cert
WITH SUBJECT = 'Certificate for TDE',
     EXPIRY_DATE = '99991231';
GO

-------------------------------------------------------------------------------
-- 3 - Backup certificate
-------------------------------------------------------------------------------
-- Required for restore on another server

BACKUP CERTIFICATE TDE_Server_Cert
TO FILE = 'C:\Temp\TDE_Server_Cert.cer'
WITH PRIVATE KEY
(
    FILE = 'C:\Temp\TDE_Server_Cert.key',
    ENCRYPTION BY PASSWORD = 'StrongPassword_2026!'
);
GO

-------------------------------------------------------------------------------
-- 4 - Create Database Encryption Key (DEK)
-------------------------------------------------------------------------------
-- Run in user database (example: AdventureWorks)

USE AdventureWorks2022;
GO

CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDE_Server_Cert;
GO

-------------------------------------------------------------------------------
-- 5 - Enable TDE
-------------------------------------------------------------------------------

ALTER DATABASE AdventureWorks2022
SET ENCRYPTION ON;
GO

-------------------------------------------------------------------------------
-- 6 - Check encrypted databases
-------------------------------------------------------------------------------

SELECT
d.name AS database_name,
d.state_desc,
d.recovery_model_desc,
d.is_encrypted
FROM sys.databases AS d
WHERE d.database_id > 4
ORDER BY d.name;
GO

-------------------------------------------------------------------------------
-- 7 - Check TDE status details
-------------------------------------------------------------------------------

SELECT
DB_NAME(dek.database_id) AS database_name,
dek.encryption_state,
dek.percent_complete,
dek.key_algorithm,
dek.key_length,
dek.encryptor_type
FROM sys.dm_database_encryption_keys AS dek
ORDER BY DB_NAME(dek.database_id);
GO

-------------------------------------------------------------------------------
-- 8 - Interpret encryption state
-------------------------------------------------------------------------------

SELECT
DB_NAME(database_id) AS database_name,
encryption_state,
CASE encryption_state
    WHEN 0 THEN 'No database encryption key present'
    WHEN 1 THEN 'Unencrypted'
    WHEN 2 THEN 'Encryption in progress'
    WHEN 3 THEN 'Encrypted'
    WHEN 4 THEN 'Key change in progress'
    WHEN 5 THEN 'Decryption in progress'
    WHEN 6 THEN 'Protection change in progress'
END AS encryption_state_desc,
percent_complete,
key_algorithm,
key_length
FROM sys.dm_database_encryption_keys;
GO

-------------------------------------------------------------------------------
-- 9 - Check tempdb encryption status
-------------------------------------------------------------------------------

SELECT
name AS database_name,
is_encrypted,
state_desc
FROM sys.databases
WHERE name = 'tempdb';
GO

/*
Note:
→ When TDE is enabled on any database, SQL Server automatically encrypts tempdb
  to prevent exposure of sensitive data during temporary operations.
*/

-------------------------------------------------------------------------------
-- 10 - Check certificates in master
-------------------------------------------------------------------------------

USE master;
GO

SELECT
name,
subject,
start_date,
expiry_date,
pvt_key_encryption_type_desc
FROM sys.certificates
ORDER BY name;
GO

-------------------------------------------------------------------------------
-- 11 - Check database encryption keys
-------------------------------------------------------------------------------

SELECT
DB_NAME(database_id) AS database_name,
encryption_state,
percent_complete,
key_algorithm,
key_length,
encryptor_thumbprint,
encryptor_type
FROM sys.dm_database_encryption_keys;
GO

-------------------------------------------------------------------------------
-- 12 - Disable TDE
-------------------------------------------------------------------------------
-- Decryption may take time depending on database size

ALTER DATABASE AdventureWorks2022
SET ENCRYPTION OFF;
GO

-------------------------------------------------------------------------------
-- 13 - Drop Database Encryption Key
-------------------------------------------------------------------------------
-- Only after encryption_state = 1 (Unencrypted)

USE AdventureWorks2022;
GO

DROP DATABASE ENCRYPTION KEY;
GO

-------------------------------------------------------------------------------
-- 14 - Restore failure without certificate
-------------------------------------------------------------------------------
-- Scenario: restoring encrypted database without certificate

RESTORE DATABASE AdventureWorks_TDE
FROM DISK = 'C:\Backup\AdventureWorks_TDE.bak'
WITH
MOVE 'AdventureWorks2022'     TO 'C:\MSSQLSERVER\DATA\AdventureWorks_TDE.mdf',
MOVE 'AdventureWorks2022_log' TO 'C:\MSSQLSERVER\LOG\AdventureWorks_TDE_log.ldf';
GO

/*
Expected error:

Msg 33111
Cannot find server certificate with thumbprint...
Msg 3013
RESTORE DATABASE is terminating abnormally.

Explanation:
→ The certificate used to encrypt the DEK is not available on this instance.
→ Without the certificate and private key, the database cannot be restored.
*/
