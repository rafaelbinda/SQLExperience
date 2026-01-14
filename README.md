# 📊 SQL Scripts Repository

![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Azure](https://img.shields.io/badge/Azure-0089D6?style=for-the-badge&logo=microsoft-azure&logoColor=white)

Este repositório reúne scripts SQL referentes aos meus estudos diários e práticas de administração de banco de dados.
*This repository contains SQL scripts from my daily studies and database administration practices.*

---

## 🎯 Objetivos | Objectives

* **Organização:** Centralizar scripts de estudo de forma estruturada.
* **Referência:** Servir de base para consultas rápidas no desenvolvimento de atividades.
* **Compartilhamento:** Disseminar conhecimento sobre o ecossistema Microsoft SQL.

---

## 🛠️ Escopo Técnico | Technical Scope

O conteúdo é focado exclusivamente em:
* **Microsoft SQL Server On-Premises**
* **Azure SQL Database / Managed Instance**

---

## 📂 Estrutura do Repositório | Repository Structure

O repositório está organizado em **05 módulos principais**, com divisões por tarefas (`#task`) em ordem cronológica.

```text
Module01_sql_on_premises/
├── 01_network/                 # Configurações e troubleshooting de rede
├── 02_sql_introduction/        # Fundamentos e instalação
├── 03_administration/          # Administração de instâncias e serviços
├── 04_backup_and_restore/      # Planos de manutenção e recuperação
├── 05_recovery_databases/      # Modelos de recuperação (Full, Simple, Bulk-Logged)
├── 06_tables_and_indexes/      # Design de tabelas e estratégias de indexação
├── 07_security/                # Logins, Users, Roles e Auditoria
├── 08_in_memory_oltp/          # Otimização de tabelas em memória
├── 09_automating_tasks/        # SQL Server Agent e Jobs
├── 10_monitoring_sql_server/   # Performance Counters e DMVs
├── 11_concurrency_control/     # Locks, Blocking e Isolation Levels
├── 12_highavailability/        # AlwaysOn, Mirroring e Failover Cluster
└── 13_Replication/             # Replicação Snapshot, Transactional e Merge

Module02_azure_infrastructure/  # Infraestrutura em nuvem
Module03_azure_sqlserver/       # Azure SQL Database e Managed Instance
Module04_sql_language/          # T-SQL Avançado (DML/DDL)
Module05_query_tuning/          # Otimização de consultas e execução de planos
