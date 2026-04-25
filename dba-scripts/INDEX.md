# DBA Scripts – Index by Use

Author: Rafael Binda  
Created: 2026-04-07  
Version: 1.0  

---

## Description  

This document groups SQL Server administrative scripts by practical usage (use cases),
providing quick access based on common DBA scenarios.

---

## Troubleshooting  

- [CONN-Q0001 – Active Connections](SQL-connections/CONN-Q0001-active-connections.sql)  
- [TRAN-Q0001 – Blocking Troubleshooting Queries](SQL-transactions-and-concurrency/TRAN-Q0001-blocking-troubleshooting-queries.sql)  
- [INST-Q0009 – Database I/O and Performance Metrics](SQL-instance-information/INST-Q0009-database-io-and-performance-metrics.sql)  

---

## Storage and Files  

- [INST-Q0004 – Physical Storage Layout](SQL-instance-information/INST-Q0004-physical-storage-layout.sql)  
- [INST-Q0005 – Database Files and Filegroups Overview](SQL-instance-information/INST-Q0005-database-files-and-filegroups-overview.sql)  
- [INST-Q0007 – Database Files Space Usage](SQL-instance-information/INST-Q0007-database-files-space-usage.sql)  

---

## Transaction Log  

- [INST-Q0008 – Log VLF Overview](SQL-instance-information/INST-Q0008-log-vlf-overview.sql)  

---

## Backup and Restore (Recovery Engineering)

- [INST-Q0012 – Backup Chain and Restore Sequence Inspection](SQL-instance-information/INST-Q0012-backup-chain-and-restore-sequence-inspection.sql)  
- [INST-Q0013 – Tail Log and Recovery Investigation](SQL-instance-information/INST-Q0013-tail-log-and-recovery-investigation.sql)  
- [INST-Q0014 – Tail Log and Recovery Readiness](SQL-instance-information/INST-Q0014-tail-log-and-recovery-readiness.sql)  
- [INST-Q0015 – Point-in-Time and Marked Transaction Inspection](SQL-instance-information/INST-Q0015-point-in-time-and-marked-transaction-inspection.sql)  
- [INST-Q0016 – Backup Media and History Analysis](SQL-instance-information/INST-Q0016-backup-media-and-history-analysis.sql)  
- [INST-Q0017 – Backup Device Inspection](SQL-instance-information/INST-Q0017-backup-device-inspection.sql)  
- [INST-Q0018 – Backup Encryption and Certificate Validation](SQL-instance-information/INST-Q0018-backup-encryption-and-certificate-validation.sql)

---

## Security  

- [INST-Q0010 – Transparent Data Encryption Overview](SQL-instance-information/INST-Q0010-transparent-data-encryption-overview.sql)  

---

## Resource Management  

- [INST-Q0011 – Resource Governor Overview](SQL-instance-information/INST-Q0011-resource-governor-overview.sql)  

---

## Instance Information  

- [INST-Q0001 – Collation](SQL-instance-information/INST-Q0001-collation.sql)  
- [INST-Q0002 – Server and Service Name](SQL-instance-information/INST-Q0002-server-and-service-name.sql)  
- [INST-Q0003 – Version and Compatibility](SQL-instance-information/INST-Q0003-version-and-compatibility.sql)  
- [INST-Q0006 – Database Properties and Access Modes](SQL-instance-information/INST-Q0006-database-properties-and-access-modes.sql)  

---

## Metadata  

- [VIEW-Q0001 – View Metadata](SQL-programming-objects/VIEW-Q0001-view-metadata.sql)  
- [PROC-Q0001 – Procedures Metadata](SQL-programming-objects/PROC-Q0001-procedures-metadata.sql)  
- [FUNC-Q0001 – Function Metadata](SQL-programming-objects/FUNC-Q0001-function-metadata.sql)  
- [TRIG-Q0001 – Trigger Metadata](SQL-programming-objects/TRIG-Q0001-trigger-metadata.sql)  

---

## Examples  

- [E0001 – STRING_SPLIT](SQL-examples/E0001-STRING_SPLIT.sql)  

---

## Notes  

A single script may belong to more than one category depending on the context of use.
This classification is intended to support quick navigation and practical application.
