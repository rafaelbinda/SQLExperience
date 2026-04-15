# A0026 – Backup Options and Media Handling

>**Author:** Rafael Binda  
>**Created:** 2026-04-13  
>**Version:** 1.0  

---

## Descrição  

Este conteúdo aborda as principais opções de configuração de backup no SQL Server, com foco no comportamento da mídia de backup, manipulação de backup sets e impacto das opções utilizadas durante a execução  
São apresentados conceitos como INIT, FORMAT, NOINIT, compressão, mirror, checksum e copy_only, além de sua influência na estrutura e reutilização dos arquivos de backup  
O objetivo é compreender como o SQL Server gerencia a mídia de backup e como essas opções impactam diretamente a estratégia de backup e restore  

---

## Hands-on  

---

## Opções para backup  

- Um arquivo de backup pode conter vários backups (backup set)  
- Um backup pode ser dividido em múltiplos arquivos (split backup)  
- É possível realizar backup diretamente para URL (Azure Blob Storage) a partir do SQL Server 2014  
- O histórico de backup e restore é armazenado em tabelas do banco msdb  

Principais tabelas:

- msdb.dbo.backupset  
- msdb.dbo.backupmediafamily  
- msdb.dbo.restorehistory  

Observação:

- Essas tabelas são essenciais para auditoria, troubleshooting e validação da cadeia de backup  

---

## Opções do backup para manipulação de mídia  

### FORMAT  

- Sobrescreve completamente o arquivo de backup  
- Não verifica a validade dos backups existentes  
- Remove todos os backup sets da mídia  
- Reinicializa a estrutura da mídia de backup  

Uso típico:

- Quando se deseja garantir que nenhum backup anterior será mantido  

---

### INIT  

- Sobrescreve o arquivo de backup  
- Verifica a validade da mídia antes de sobrescrever  
- Remove os backup sets existentes mantendo a estrutura da mídia  

Diferença para FORMAT:

- INIT respeita a mídia existente  
- FORMAT recria a mídia  

---

### NOINIT (padrão)  

- Acrescenta o backup ao arquivo existente  
- Mantém todos os backups anteriores  
- É o comportamento padrão do SQL Server  

Impacto:

- Pode gerar arquivos grandes com múltiplos backup sets  
- Exige controle na hora do restore (identificação correta do backup set)  

Exemplo conceitual:

- Execução 1 → arquivo contém 1 backup  
- Execução 2 → arquivo passa a conter 2 backups  
- Execução 3 → arquivo passa a conter 3 backups  

Cada novo backup é adicionado como um novo backup set dentro do mesmo arquivo  

---

### COMPRESSION  

- Compacta os dados durante o backup  
- Reduz uso de disco e I/O  
- Pode melhorar o tempo de execução  

Impacto:

- Reduz tempo de escrita em disco  
- Pode reduzir tempo de restore  

Trade-off:

- Aumenta consumo de CPU durante o backup  

Observação:

- Em ambientes com gargalo de I/O, costuma trazer ganho significativo  

---

### MIRROR TO  

- Permite criar até 4 cópias idênticas do backup  
- As mídias devem ser do mesmo tipo e com desempenho similar  
- Todas as cópias são geradas simultaneamente  

Objetivo:

- Redundância imediata do backup  

Diferença:

- Mirror: cópias completas idênticas  
- Split: divide o backup em múltiplos arquivos  

Exemplo inválido:

- Utilizar mídias de tipos diferentes (ex: DISK e TAPE)  
- Utilizar dispositivos com desempenho muito diferente, pode causar falha na operação  

---

### CHECKSUM  

- Adiciona validação de integridade ao backup  
- Permite detectar corrupção durante backup ou restore  
- Valida páginas durante o processo  

Importante:

- Não corrige erro, apenas detecta  
- Ajuda a evitar restore de backup corrompido  

Impacto:

- Pequeno aumento no uso de CPU durante o backup  
- Pode gerar leve aumento no tempo de execução  
- Impacto geralmente menor que o uso de COMPRESSION  

Boa prática:

- Utilizar sempre que possível em ambiente de produção  

---

### COPY_ONLY  

- Executa backup sem interferir na cadeia de backups  
- Não altera a base dos backups diferenciais  
- Não interfere na sequência de backups de log  

Uso típico:

- Backups ad-hoc (fora da rotina padrão definida) 
- Cópias para testes  
- Entrega de backup para terceiros  

[Mais informações sobre COPY_ONLY – ver item 7](A0023-backup-fundamentals.md)

---
