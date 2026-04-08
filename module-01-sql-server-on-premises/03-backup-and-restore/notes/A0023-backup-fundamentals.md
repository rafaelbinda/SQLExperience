# A0023 -- Fundamentos de Backup e Conceitos de Recuperação

Author : Rafael Binda\
Created : 2026-04-08\
Version : 1.0

------------------------------------------------------------------------

## Descrição

Este material apresenta os conceitos fundamentais de backup no SQL
Server, incluindo tipos de backup, funcionamento interno, dependências
entre backups e conceitos críticos como RPO, RTO e cadeia de backup.

Também aborda cenários práticos e estratégias utilizadas em ambientes
produtivos.

------------------------------------------------------------------------

## 1 -- Visão geral de Backup

O SQL Server permite diferentes tipos de backup que podem ser combinados
para atender requisitos de negócio.

-   Backup é online (não bloqueia uso do banco)\
-   Pode ser executado durante operações normais\
-   Tipos de backup são complementares

------------------------------------------------------------------------

## 2 -- Planejamento de Backup (RPO e RTO)

A definição de RPO e RTO não é responsabilidade exclusiva do DBA.

Ela deve ser feita em conjunto com:\
- Área de negócio\
- Times de aplicação\
- Arquitetura

------------------------------------------------------------------------

### RPO -- Recovery Point Objective

Quantidade máxima de dados que pode ser perdida

### RTO -- Recovery Time Objective

Tempo máximo para recuperação

------------------------------------------------------------------------

### Linha do tempo

    Tempo -------------------------------------------------------------->

    | Último backup | Falha do banco | Banco recuperado |

    <----- RPO -----><---------------------- RTO ----------------------->

------------------------------------------------------------------------

## 3 -- Requisitos de armazenamento e operação

Uma estratégia de backup eficiente vai além da execução dos comandos.

### Custos

-   Backup em nuvem pode ter custo de saída (egress)\
-   Avaliar armazenamento a longo prazo

### Retenção

-   Deve ser maior que frequência do DBCC CHECKDB\
-   Permite identificar corrupção antes de sobrescrever backups

### Testes de restore

-   Backup sem teste de restore não garante recuperação\
-   Deve existir ambiente dedicado para testes periódicos

### Monitoramento

-   Alertas de falha de backup\
-   Validação de integridade dos arquivos

### Versionamento

-   Backups de banco não substituem versionamento de aplicação

------------------------------------------------------------------------

## 4 -- Backup Full

    Tempo -------------------------------------------------------------->

    22:00 --------------------------- 23:00
       Início do backup               Fim do backup

    Ponto de recuperação: 23:00

------------------------------------------------------------------------

## 5 -- Backup Diferencial

    Tempo -------------------------------------------------------------->

    20:00        21:00        22:00
     FULL         DIF          DIF

    Restore necessário:
    FULL + último DIF

------------------------------------------------------------------------

## 6 -- Backup de Log

    Tempo -------------------------------------------------------------->

    FULL → LOG → LOG → LOG

    Restore:
    FULL + todos os LOGs em sequência

------------------------------------------------------------------------

## 7 -- Tail Log Backup

Última tentativa de recuperar dados após falha crítica

------------------------------------------------------------------------

## 8 -- Recovery Models

Define como o transaction log será gerenciado.

### SIMPLE

-   Trunca log automaticamente\
-   Sem backup de log\
-   Sem point-in-time

------------------------------------------------------------------------

### FULL

-   Log completo\
-   Permite recuperação ponto no tempo

------------------------------------------------------------------------

### BULK_LOGGED

Modelo intermediário entre SIMPLE e FULL.

### Quando utilizar

Deve ser utilizado temporariamente em cenários específicos como:\
- Carga massiva de dados (ETL)\
- Importação de grandes volumes\
- Rebuild de índices grandes

------------------------------------------------------------------------

### Benefícios

-   Reduz uso do log\
-   Melhora performance em operações pesadas

------------------------------------------------------------------------

### Limitação importante

Durante operações bulk:\
- Não é possível restaurar ponto exato dentro da operação\
- O restore será até o final do backup de log

------------------------------------------------------------------------

### Estratégia recomendada

1.  Alterar para BULK_LOGGED\
2.  Executar operação pesada\
3.  Realizar backup de log\
4.  Voltar para FULL

------------------------------------------------------------------------

## 9 -- Cadeia de Backup

Backups são interdependentes via LSN

Quebra da cadeia inviabiliza restore completo

------------------------------------------------------------------------

## 10 -- COPY_ONLY

Backup que não interfere na cadeia

------------------------------------------------------------------------

## 11 -- Tipos de falha

-   Falha lógica\
-   Falha física\
-   Falha total

------------------------------------------------------------------------

## 12 -- Estratégias de Backup

-   FULL diário\
-   DIF + LOG conforme necessidade

------------------------------------------------------------------------

## 13 -- Point-in-Time Restore

Permite restaurar banco até momento específico

------------------------------------------------------------------------

## Observações finais

Backup não garante recuperação\
Somente restore testado garante recuperação
