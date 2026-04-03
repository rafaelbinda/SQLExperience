/*
===============================================================================
Author      : Rafael Binda
Created     : 2026-03-29
Version     : 1.0
Task        : INST-Q0008 - Log VLF Overview
Object      : Script
Description : Returns transaction log VLF information to help inspect log
              structure, active and inactive VLFs, and shrink behavior
Notes       : notes/A0018-database-file-management.md
Examples    : scripts/Q0014-sql-database-file-management.sql
===============================================================================

INDEX
1 - Raw VLF details
2 - DBCC LOGINFO column description
3 - VLF summary by status
===============================================================================
*/

-------------------------------------------------------------------------------
-- 1 - Raw VLF details
-------------------------------------------------------------------------------

DBCC LOGINFO;
GO

-------------------------------------------------------------------------------
-- 2 - DBCC LOGINFO column description
-------------------------------------------------------------------------------
/*
DBCC LOGINFO - Column Description

RecoveryUnitId → Identifies the recovery unit. Typically 0 in standard databases.
FileId         → Log file identifier (usually 2, since it refers to the
                 transaction log).
FileSize       → Size of the Virtual Log File (VLF) in bytes.
StartOffset    → Starting position of the VLF within the log file.
FSeqNo         → Logical sequence number indicating the order in which VLFs
                 are used.
Status         → VLF state:
                 0 = Inactive (available for reuse / can be removed by shrink)
                 2 = Active (currently in use / cannot be removed)
Parity         → Internal value used by SQL Server for validation.
CreateLSN      → Log Sequence Number when the VLF was created.

Note:
- The transaction log is divided into multiple VLFs.
- Shrink operations can only remove VLFs with Status = 0 (inactive).
- If active VLFs (Status = 2) are located at the end of the file,
  the log file cannot be reduced effectively.
*/ 


-------------------------------------------------------------------------------
-- 3 - VLF summary by status
-------------------------------------------------------------------------------
/*
→ Status 0 = Inactive VLF
→ Status 2 = Active VLF
*/

DROP TABLE IF EXISTS #LogInfo;
GO

CREATE TABLE #LogInfo
(
    RecoveryUnitId INT,
    FileId INT,
    FileSize BIGINT,
    StartOffset BIGINT,
    FSeqNo BIGINT,
    [Status] TINYINT,
    Parity TINYINT,
    CreateLSN NUMERIC(25,0)
);
GO

INSERT INTO #LogInfo
EXEC ('DBCC LOGINFO WITH NO_INFOMSGS');
GO

SELECT
CASE [Status]
    WHEN 0 THEN 'Inactive'
    WHEN 2 THEN 'Active'
    ELSE 'Other'
END AS vlf_status,
COUNT(*) AS vlf_count,
SUM(FileSize) / 1024.0 / 1024.0 AS total_size_mb
FROM #LogInfo
GROUP BY [Status]
ORDER BY 
CASE [Status]
    WHEN 2 THEN 1
    WHEN 0 THEN 2
    ELSE 3
END;
GO

SELECT
COUNT(*) AS total_vlf_count,
SUM(CASE WHEN [Status] = 2 THEN 1 ELSE 0 END) AS active_vlf_count,
SUM(CASE WHEN [Status] = 0 THEN 1 ELSE 0 END) AS inactive_vlf_count,
SUM(FileSize) / 1024.0 / 1024.0 AS total_vlf_size_mb,
SUM(CASE WHEN [Status] = 2 THEN FileSize ELSE 0 END) / 1024.0 / 1024.0 AS active_vlf_size_mb,
SUM(CASE WHEN [Status] = 0 THEN FileSize ELSE 0 END) / 1024.0 / 1024.0 AS inactive_vlf_size_mb
FROM #LogInfo;
GO

DROP TABLE IF EXISTS #LogInfo;
GO

