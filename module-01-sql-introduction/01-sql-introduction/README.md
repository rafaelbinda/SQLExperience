
# 01 — SQL Introduction

This section covers the fundamental concepts required to start working with SQL Server

Each topic includes:

- **Notes** → conceptual explanation  
- **Hands-on** → practice scripts inside this module  
- **DBA Scripts** → reusable administrative and troubleshooting scripts

---

# Study Material

| # | Topic | Notes | Hands-on (Module) | DBA Scripts |
|---|------|------|------|------|
| 1 | Study Environment Setup | [A0001](notes/A0001-study-environment-setup.md) | — | — |
| 2 | SQL Server Collation | [A0002](notes/A0002-collation.md) | [SQL Collation Hands-on](../scripts/Q0001-collation.sql) | [SQL Collation – Instance Info](../../../dba-scripts/SQL-instance-information/Q0001-collation.sql) |
| 3 | SQL Server Installation | [A0003](notes/A0003-sql_server-installation.md) | — | — |
| 4 | SQL Server Connectivity Troubleshooting | [A0004](notes/A0004-sql-server-connectivity-troubleshooting.md) | — | — |
| 5 | Network Commands | [A0005](notes/A0005-network-commands.md) | — | — |
| 6 | SQL Server Version | [A0006](notes/A0006-sql-server-version.md) | — | [SQL Version and Compatibility](../../../dba-scripts/SQL-instance-information/Q0003-version-and-compatibility.sql) |
| 7 | SQL Server Architecture | [A0007](notes/A0007-sql-server-architecture.md) | [SQL Server Create Database](../scripts/Q0002-create-database.sql) | [SQL Physical Storage Layout](../../../dba-scripts/SQL-instance-information/Q0004-physical-storage-layout.sql) |
| 8 | SQL Server Fundamentals | [A0008](notes/A0008-sql-fundamentals.md) | [SQL Server Fundamentals](../scripts/Q0003-sql-fundamentals.sql) | — |
| 9 | SQL Server Data Querying | [A0009](notes/A0009-sql-data-querying.md) | [SQL Server Data Querying](../scripts/Q0004-sql-data-querying.sql) | — |
|10 | SQL Server Data Types | [A0010](notes/A0010-sql-data-types.md) | [String Data Types](../scripts/Q0005-sql-string-data-types.sql)<br>[Numeric and Bit Data Types](../scripts/Q0006-sql-numeric-and-bit-data-types.sql)<br>[Date and Time Data Types](../scripts/Q0007-sql-date-and-time-data-types.sql)<br>[Special Data Types](../scripts/Q0008-sql-special-data-types.sql) | — |
|11 | Transactions and Concurrency | [A0011](notes/A0011-sql-transactions-and-concurrency.md) | [Transactions and Concurrency](../scripts/Q0009-sql-transactions-and-concurrency.sql) | [Blocking Troubleshooting Queries](../../../dba-scripts/SQL-transactions-and-concurrency/Q0001-blocking-troubleshooting-queries.sql) |
|12 | SQL Server Programming Objects | [A0012](notes/A0012-sql-server-programming-objects.md) | [Programming Objects](../scripts/Q0010-sql-server-programming-objects.sql) | — |

---

# Tools

Utilities used during environment setup and troubleshooting.

| Tool | Description |
|-----|-----|
| [Enable Hyper-V on Windows Home](../tools/A0001_X_EnableHyperV_Windows_Home.bat) | Enables Hyper-V feature on Windows Home |
| [PortQry](../tools/A0003_X_PortQry.zip) | Network port troubleshooting tool |
| [sp_WhoIsActive](../tools/Q0001-sp_whoisactive-v11.32.sql) | SQL Server activity monitoring tool |
