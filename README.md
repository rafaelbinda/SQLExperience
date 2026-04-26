# 📊 SQL Server DBA Study Repository

![SQL
Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)

------------------------------------------------------------------------

## 📌 Overview

This repository contains structured SQL Server study materials, scripts,
and architectural notes developed during my continuous learning journey.

------------------------------------------------------------------------

## 🎯 Purpose

-   Centralize SQL Server study scripts
-   Maintain structured technical documentation
-   Simulate enterprise database architecture practices
-   Track long-term technical evolution

------------------------------------------------------------------------

## 🏗️ Technical Scope

Focused exclusively on Microsoft ecosystem technologies:

-   Microsoft SQL Server (On-Premises)
-   Azure SQL Database
-   Azure SQL Managed Instance
-   T-SQL Development
-   Query Optimization
-   Storage Architecture
-   Backup & Recovery Strategies
-   High Availability Concepts

------------------------------------------------------------------------

## 📂 Repository Architecture

``` text
dba-scripts/
│
├── SQL-connections/
├── SQL-examples/
├── SQL-instance-information/
├── SQL-programming-objects/
├── SQL-transactions-and-concurrency
│
├── module-01-sql-on-premises/
│   ├── 01-sql-introduction/
│   │   ├── notes/        → Study notes (chronological order)
│   │   ├── scripts/      → SQL scripts
│   │   └── tools/        → Utilities and supporting tools
│   │
│   ├── 02-administration/
│   │   ├── notes/
│   │   ├── scripts/
│   │   └── tools/
│   │
│   ├── 03-backup-and-restore/
│   │   ├── notes/
│   │   ├── scripts/
│   │   └── tools/
│   │
│   ├── 04-database-recovery/
│   ├── 05-tables-and-indexes/
│   ├── 06-security/
│   ├── 07-in-memory-oltp/
│   ├── 08-automating-tasks/
│   ├── 09-monitoring-sql-server/
│   ├── 10-concurrency-control/
│   ├── 11-high-availability/
│   └── 12-replication/
│
├── module-02-azure-infrastructure/
├── module-03-azure-sql-server/
├── module-04-sql-language/
└── module-05-query-tuning/
```

------------------------------------------------------------------------

## 🧩 Naming Convention Standard

``` text
  Prefix     Meaning
  ---------- -------------------------
  A+Number   Notes / Articles
  Q+Number   Queries / Scripts
  E+Number   Examples
  C+Number   Checklists (future use)
  L+Number   Labs (future use)

Example:

    Q0002-Create-Database.sql
    E0001-STRING_SPLIT.sql
    A0007-SQL-Server-Architecture.md
```

---

## 📝 Documentation Header Standard

All SQL scripts follow a standardized header:

``` sql
===============================================================================
Author      : Rafael Binda
Created     : yyyy-mm-dd
Version     : 1.0
Task        : -
Databases   : Databases Name
Object      : Script | Procedure | Function | View | Notes
Description : -
Notes       : -
===============================================================================
```

---

## 🚀 Usage

1.  Navigate to the desired module.
2.  Review notes before executing scripts.
3.  Use scripts as lab references.
4.  Adapt patterns to your own SQL Server test environments.

---

## 📈 Continuous Improvement

This repository is continuously updated as new concepts are studied and
validated in lab environments.

---

**Built with discipline, structured thinking, and a long-term DBA
vision.**
