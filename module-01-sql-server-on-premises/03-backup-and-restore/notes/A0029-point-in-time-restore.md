# A0029 – Point-in-Time Restore and Marked Transactions
>**Author:** Rafael Binda  
>**Created:** 2026-04-21  
>**Version:** 1.0  

---

## Descrição  

Este material aborda a recuperação de banco de dados até um ponto específico no tempo (Point-in-Time Restore) no SQL Server  

São apresentados os pré-requisitos, funcionamento do transaction log, utilização das cláusulas STOPAT, STOPATMARK e STOPBEFOREMARK, além do uso de transações marcadas para controle preciso do ponto de recuperação  

---

## Hands-on  

[Q0026 – Point-in-Time Restore and Marked Transactions](../scripts/Q0026-sql-point-in-time-restore.sql)

---

## 1 – Conceito de Point-in-Time Restore  

O Point-in-Time Restore permite recuperar um banco de dados até um momento específico no tempo  

---

## 2 – Pré-requisitos  

- Recovery Model FULL ou BULK_LOGGED  
- Backup FULL  
- Backup LOG  

---

## 3 – Transaction Log  

- FULL → snapshot  
- DIFF → alterações  
- LOG → histórico completo  

---

## 4 – STOPAT  

RESTORE LOG ExamplesDB  
WITH STOPAT = '2026-04-21 10:30:00', RECOVERY  

---

## 5 – Transações marcadas  

BEGIN TRAN Deploy_V1 WITH MARK 'Deployment version 1';  

---

## 6 – STOPATMARK  

RESTORE LOG ExamplesDB  
WITH STOPATMARK = 'Deploy_V1', RECOVERY  

---

## 7 – STOPBEFOREMARK  

RESTORE LOG ExamplesDB  
WITH STOPBEFOREMARK = 'Deploy_V1', RECOVERY  

---

## 8 – logmarkhistory  

msdb.dbo.logmarkhistory  

---

## Referências  

- A0024  
- A0025  
