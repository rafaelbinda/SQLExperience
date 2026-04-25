# 03 - Backup and Restore

This module covers SQL Server backup and restore fundamentals, including backup types, restore strategies, failure scenarios, media handling, and backup security.

Each topic includes:

- **Notes** → conceptual explanation  
- **Hands-on** → practice scripts inside this module  
- **DBA** → real-world scripts for investigation and troubleshooting  

---

## Study Material

| # | Topic | Note | Hands-on | DBA |
|---|------|------|----------|-----|
| 1 | Backup Fundamentals | [A0023](notes/A0023-backup-fundamentals.md) | [Q0019](scripts/Q0019-sql-backup-full-differential-log.sql) | [INST-Q0016 - Backup Media and History Analysis](../../dba-scripts/SQL-instance-information/INST-Q0016-backup-media-and-history-analysis.sql) |
| 2 | Recovery and Restore Fundamentals | [A0024](notes/A0024-recovery-and-restore-fundamentals.md) | [Q0020](scripts/Q0020-sql-restore-norecovery-recovery.sql)<br>[Q0021](scripts/Q0021-sql-restore-standby.sql) | [INST-Q0012 - Backup Chain and Restore Sequence Inspection](../../dba-scripts/SQL-instance-information/INST-Q0012-backup-chain-and-restore-sequence-inspection.sql)<br>[INST-Q0013 - Tail Log and Recovery Investigation](../../dba-scripts/SQL-instance-information/INST-Q0013-tail-log-and-recovery-investigation.sql)<br>[INST-Q0014 - Tail Log and Recovery Readiness](../../dba-scripts/SQL-instance-information/INST-Q0014-tail-log-and-recovery-readiness.sql) |
| 3 | Backup and Restore Exercises | [A0025](notes/A0025-backup-and-restore-exercises.md) | [Q0022](scripts/Q0022-sql-tail-log-backup.sql) | — |
| 4 | Point-in-Time Restore and Marked Transactions | [A0026](notes/A0026-point-in-time-restore.md) | [Q0023](scripts/Q0023-sql-point-in-time-restore-and-marked-transactions.sql) | [INST-Q0015 - Point-in-Time and Marked Transaction Inspection](../../dba-scripts/SQL-instance-information/INST-Q0015-point-in-time-and-marked-transaction-inspection.sql) |
| 5 | Backup Options and Media Handling | [A0027](notes/A0027-backup-options-and-media-handling.md) | [Q0024](scripts/Q0024-sql-backup-options-and-media-handling.sql) | — |
| 6 | Backup Device vs Backup File | [A0028](notes/A0028-backup-device-vs-backup-file.md) | [Q0025](scripts/Q0025-sql-backup-device-vs-backup-file.sql) | [INST-Q0017 - Backup Device Inspection](../../dba-scripts/SQL-instance-information/INST-Q0017-backup-device-inspection.sql) |
| 7 | Backup Encryption | [A0029](notes/A0029-backup-encryption.md) | [Q0026](scripts/Q0026-backup-encryption.sql) | [INST-Q0018 - Backup Encryption and Certificate Validation](../../dba-scripts/SQL-instance-information/INST-Q0018-backup-encryption-and-certificate-validation.sql) |

---

## Observations

- Logical progression from fundamentals to advanced scenarios  
- Clear separation between theory and practice  
- Each note is linked to the appropriate hands-on script  
- Designed for real-world DBA learning and certification preparation  
