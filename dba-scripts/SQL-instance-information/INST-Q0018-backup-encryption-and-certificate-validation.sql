/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-04-22
Version     : 1.0
Task        : INST-Q0018 - Backup Encryption and Certificate Validation
Object      : Script
Description : Queries to validate encrypted backups, certificate availability,
              and restore readiness in encrypted environments
Notes       : 03-backup-and-restore/notes/A0029-backup-encryption.md
Reference   : 02-administration/notes/A0020-transparent-data-encryption.md
              INST-Q0010 - Transparent Data Encryption Overview
===============================================================================

INDEX
1 - Identify encrypted databases
2 - Check encryption status and progress
3 - Validate certificate availability
4 - Identify backups from encrypted databases
5 - Evaluate restore risk without certificate
6 - Validate tempdb encryption behavior
===============================================================================
*/

USE master;
GO

-------------------------------------------------------------------------------
-- 1 - Identify encrypted databases
-------------------------------------------------------------------------------
/*
→ Shows which databases are encrypted
*/

SELECT
name AS database_name,
state_desc,
recovery_model_desc,
is_encrypted
FROM sys.databases
WHERE database_id > 4
ORDER BY name;
GO

-------------------------------------------------------------------------------
-- 2 - Check encryption status and progress
-------------------------------------------------------------------------------
/*
→ Detailed encryption status
*/

SELECT
DB_NAME(database_id) AS database_name,
encryption_state,
percent_complete,
key_algorithm,
key_length,
encryptor_type
FROM sys.dm_database_encryption_keys
ORDER BY database_name;
GO

-------------------------------------------------------------------------------
-- 3 - Validate certificate availability
-------------------------------------------------------------------------------
/*
→ Critical for restore of encrypted backups
*/

SELECT
name AS certificate_name,
subject,
start_date,
expiry_date,
pvt_key_encryption_type_desc
FROM sys.certificates
ORDER BY name;
GO

/*
Interpretation:
- Missing certificate = restore failure
*/

-------------------------------------------------------------------------------
-- 4 - Identify backups from encrypted databases
-------------------------------------------------------------------------------
/*
→ Identifies backups taken from encrypted databases
*/

SELECT
bs.database_name,
bs.backup_start_date,
bs.type,
CASE bs.type
    WHEN 'D' THEN 'FULL'
    WHEN 'I' THEN 'DIFFERENTIAL'
    WHEN 'L' THEN 'LOG'
    ELSE bs.type
END AS backup_type_desc,
bs.is_password_protected,
bs.has_backup_checksums,
bs.encryptor_thumbprint
FROM msdb.dbo.backupset bs
WHERE bs.database_name IN
(
    SELECT name
    FROM sys.databases
    WHERE is_encrypted = 1
)
ORDER BY bs.backup_start_date DESC;
GO

-------------------------------------------------------------------------------
-- 5 - Evaluate restore risk without certificate
-------------------------------------------------------------------------------
/*
→ Simulates risk condition for encrypted backups
*/

SELECT
d.name AS database_name,
d.is_encrypted,
CASE
    WHEN d.is_encrypted = 1
            AND NOT EXISTS
            (
                SELECT 1
                FROM sys.certificates c
            )
    THEN 'HIGH RISK - CERTIFICATE NOT AVAILABLE'
        
    WHEN d.is_encrypted = 1
    THEN 'CERTIFICATE REQUIRED FOR RESTORE'

    ELSE 'NOT ENCRYPTED'
END AS restore_risk
FROM sys.databases d
WHERE d.database_id > 4
ORDER BY d.name;
GO

-------------------------------------------------------------------------------
-- 6 - Validate tempdb encryption behavior
-------------------------------------------------------------------------------
/*
→ tempdb is automatically encrypted when any database uses TDE
*/

SELECT
name AS database_name,
is_encrypted,
state_desc
FROM sys.databases
WHERE name = 'tempdb';
GO

/*
Note:
→ tempdb encryption is a side effect of TDE
→ protects intermediate operations
*/