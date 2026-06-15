# SQL Server DBA Study Repository

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)

---

## Overview

Structured SQL Server study materials — scripts, notes, and architectural
references developed during my continuous DBA learning journey.

---

## Technical Scope

- Microsoft SQL Server (On-Premises)
- Azure SQL Database / Managed Instance
- T-SQL Development and Query Optimization
- Storage Architecture and Backup & Recovery
- High Availability and Replication

---

## Prerequisites

- SQL Server 2019 or later (some scripts use features introduced in 2019+)
- SQL Server Management Studio (SSMS) or Azure Data Studio
- `sysadmin` or equivalent permissions for lab scripts that use DBCC commands

---

## Repository Structure

```text
C:\GitHub\
│
├── dba-scripts/                          ← Reusable monitoring and investigation utilities
│   ├── SQL-connections/
│   ├── SQL-examples/
│   ├── SQL-instance-information/
│   ├── SQL-programming-objects/
│   └── SQL-transactions-and-concurrency/
│
└── module-01-sql-server-on-premises/     ← Hands-on lab exercises
    ├── 01-sql-introduction/
    │   ├── notes/     → Study notes (A####)
    │   ├── scripts/   → Lab scripts (Q####)
    │   └── tools/     → Utilities and supporting tools
    ├── 02-administration/
    ├── 03-backup-and-restore/
    ├── 04-database-recovery/
    ├── 05-tables-and-indexes/      [planned]
    ├── 06-security/                [planned]
    ├── 07-in-memory-oltp/          [planned]
    ├── 08-automating-tasks/        [planned]
    ├── 09-monitoring-sql-server/   [planned]
    ├── 10-concurrency-control/     [planned]
    ├── 11-high-availability/       [planned]
    └── 12-replication/             [planned]

module-02-azure-infrastructure/     [planned]
module-03-azure-sql-server/         [planned]
module-04-sql-language/             [planned]
module-05-query-tuning/             [planned]
```

---

## Naming Convention

### Module scripts (`module-01/`)

| Prefix   | Type             | Example                          |
|----------|------------------|----------------------------------|
| `Q####`  | Lab script       | `Q0029-page-restore.sql`         |
| `A####`  | Study note (.md) | `A0031-page-restore.md`          |

### DBA utility scripts (`dba-scripts/`)

| Prefix       | Category                   | Example                               |
|--------------|----------------------------|---------------------------------------|
| `INST-Q####` | Instance information       | `INST-Q0021-data-page-inspection.sql` |
| `CONN-Q####` | Connections                | `CONN-Q0001-active-connections.sql`   |
| `TRAN-Q####` | Transactions / Concurrency | `TRAN-Q0001-blocking-queries.sql`     |
| `PROC-Q####` | Stored procedures          | `PROC-Q0001-procedures-metadata.sql`  |
| `FUNC-Q####` | Functions                  | `FUNC-Q0001-function-metadata.sql`    |
| `VIEW-Q####` | Views                      | `VIEW-Q0001-view-metadata.sql`        |
| `TRIG-Q####` | Triggers                   | `TRIG-Q0001-trigger-metadata.sql`     |
| `E####`      | Standalone example         | `E0001-STRING_SPLIT.sql`              |

Numbers are always 4-digit zero-padded. `Q####` and `A####` are globally
sequential across all modules.

---

## Script Header Standard

All SQL scripts follow a standardized header:

```sql
/*
===============================================================================
Author      : Rafael Binda
Created     : yyyy-mm-dd
Version     : 1.0
Task        : Q#### - Script Title
Object      : Script
Description : -
Notes       : relative/path/to/notes/A####-topic.md
===============================================================================
*/
```

DBA utility scripts additionally include `Examples :` and `Related :` fields
that cross-reference related scripts and notes.

---

## Continuous Improvement

This repository is continuously updated as new concepts are studied and
validated in lab environments.
