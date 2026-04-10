# A0024 - Recovery and Restore Fundamentals
>**Author:** Rafael Binda  
>**Created:** 2026-04-09  
>**Version:** 1.0  

---

## Descrição

Este material apresenta os conceitos fundamentais de recuperação de dados no SQL Server, incluindo recovery models, estratégias de restore e recuperação point-in-time

---

## 1 - Recovery Models

Define como o transaction log será gerenciado

### SIMPLE

No recovery model SIMPLE, o SQL Server realiza o truncamento automático do transaction log a cada CHECKPOINT  
Isso significa que o log não mantém histórico completo das transações, apenas o necessário para garantir a consistência do banco

---

### Características

- Truncamento automático do transaction log  
- Não permite backup de log  
- Estrutura de log mais simples e com menor crescimento  
- Menor complexidade de gerenciamento  

---

### Funcionamento

- O SQL Server reutiliza o espaço do transaction log automaticamente  
- Após um CHECKPOINT, a parte inativa do log é liberada  
- Não há retenção contínua das transações  

---

### Impacto na recuperação

- Não permite Point-in-Time Restore  
- A recuperação é limitada ao último backup FULL ou diferencial  
- Todas as transações após o último backup serão perdidas em caso de falha  

---

### Exemplo prático

Cenário:

- Backup FULL às 00:00  
- Falha ocorre às 10:00  

Resultado:

- Todos os dados entre 00:00 e 10:00 serão perdidos  

---

### Quando utilizar

- Ambientes de desenvolvimento  
- Ambientes de teste  
- Sistemas onde a perda de dados recente é aceitável  
- Bancos com baixa criticidade  

---

### Vantagens

- Menor uso de espaço em disco  
- Menor necessidade de gerenciamento de backups de log  
- Configuração simples  

---

### Desvantagens

- Alto risco de perda de dados  
- Sem recuperação ponto no tempo  
- Não atende ambientes críticos  

---

### Observações importantes

- Alterar de SIMPLE para FULL exige um novo backup FULL para iniciar a cadeia de log  
- Mesmo no modelo SIMPLE, backups FULL e diferencial continuam sendo necessários  

---

### Resumo

O modelo SIMPLE prioriza simplicidade e baixo gerenciamento, porém com limitação significativa na recuperação de dados, sendo indicado apenas para ambientes onde a perda de dados é aceitável

---

### FULL

No recovery model FULL, o SQL Server mantém o histórico completo das transações no transaction log até que seja realizado um backup de log  
Isso permite a recuperação do banco de dados até qualquer ponto específico no tempo (point-in-time)

---

### Características

- Mantém histórico completo do transaction log  
- Permite backup de log  
- Suporte a Point-in-Time Restore  
- Controle total sobre recuperação  

---

### Funcionamento

- Todas as transações são registradas no transaction log  
- O log não é truncado automaticamente  
- O truncamento ocorre somente após backup de log  
- Enquanto não houver backup de log, o arquivo de log continuará crescendo  

---

### Impacto na recuperação

- Permite recuperação até qualquer momento específico  
- Possibilita restaurar o banco imediatamente antes de uma falha  
- Minimiza perda de dados  

---

### Exemplo prático

Cenário:

- Backup FULL às 00:00  
- Backups de log a cada 15 minutos  
- Falha ocorre às 10:07  

Resultado:

- É possível restaurar o banco até 10:06:59  
- Perda de dados praticamente zero  

---

### Quando utilizar

- Ambientes de produção    
- Sistemas críticos  
- Aplicações que não toleram perda de dados  
- Cenários que exigem recuperação granular  

---

### Vantagens

- Alta capacidade de recuperação  
- Minimiza perda de dados  
- Permite recuperação ponto no tempo  
- Maior controle sobre o ambiente  

---

### Desvantagens

- Maior uso de espaço em disco (log)  
- Necessidade de gerenciamento de backups de log  
- Maior complexidade operacional  

---

### Observações importantes

- É obrigatório realizar backups de log regularmente  
- Se não houver backup de log, o arquivo de log crescerá continuamente  
- A cadeia de backups deve ser mantida íntegra (LSN)  
- Alterar de SIMPLE para FULL exige um novo backup FULL para iniciar a cadeia  

---

### Resumo

O modelo FULL oferece o maior nível de proteção de dados, sendo o padrão recomendado para ambientes críticos que exigem recuperação precisa e mínima perda de dados

---

### BULK_LOGGED

Modelo intermediário entre SIMPLE e FULL

#### Quando utilizar

Deve ser utilizado temporariamente em cenários específicos como:
- Carga massiva de dados (ETL)
- Importação de grandes volumes
- Rebuild de índices grandes

---

#### Estratégia recomendada
1.  Alterar para BULK_LOGGED
2.  Executar operação pesada
3.  Realizar backup de log
4.  Voltar para FULL

---

#### Minimal Logging

No modelo BULK_LOGGED, algumas operações utilizam logging mínimo  

Isso significa:
- Nem todas as alterações são registradas detalhadamente no log  
- Apenas informações essenciais são armazenadas  

---

#### Impacto

- Redução significativa do uso de log  
- Melhor performance em operações massivas  

---

#### Consequência

- Não é possível restaurar para um ponto exato dentro dessas operações  
- O restore só pode ocorrer até o final do backup de log

---

### Impacto dos Recovery Models na recuperação

O recovery model define diretamente quais tipos de restore são possíveis

| Recovery Model | Backup de Log | Point-in-Time | Risco de perda |
|---------------|--------------|--------------|----------------|
| SIMPLE        | Não          | Não          | Alto           |
| FULL          | Sim          | Sim          | Baixo          |
| BULK_LOGGED   | Sim          | Parcial      | Médio          |

- SIMPLE: perda de dados desde o último backup  
- FULL: recuperação até ponto exato no tempo  
- BULK_LOGGED: recuperação limitada durante operações bulk

---

### Troca de recovery model
---

#### SIMPLE → FULL

- Exige um novo backup FULL para iniciar a cadeia de log  
- Antes disso, não é possível fazer backup de log  

---

#### FULL → SIMPLE

- Quebra a cadeia de backup de log  
- Todos os backups de log anteriores deixam de ser úteis  

---

#### FULL → BULK_LOGGED → FULL

- Não quebra a cadeia  
- Porém afeta granularidade de recuperação durante operações bulk  

---

## 2 - Cadeia de Backup

- Backups são interdependentes via LSN
- Quebra da cadeia inviabiliza restore completo

---

## 3 - COPY_ONLY

O backup COPY_ONLY é um tipo especial de backup que não interfere na cadeia de backups existente  
Ele é utilizado quando é necessário realizar um backup pontual sem impactar a estratégia padrão configurada no ambiente  

---

### Objetivo

Permitir a criação de backups sob demanda sem alterar:
- A base de backups diferenciais  
- A sequência de backups de log  

---

### Funcionamento

O comportamento varia conforme o tipo de backup:

#### COPY_ONLY FULL

- Não altera a base para backups diferenciais  
- O próximo backup diferencial continua baseado no último FULL tradicional  

---

#### COPY_ONLY LOG

- Não interfere na sequência da cadeia de backups de log  
- Mantém a continuidade dos LSNs  

---

### Exemplo prático

Cenário:
- Backup FULL diário às 00:00  
- Backups diferenciais ao longo do dia  

Durante o dia, um backup manual é executado:
`BACKUP DATABASE MinhaBase TO DISK = 'backup.bak' WITH COPY_ONLY;`

Resultado:
- Esse backup não passa a ser a nova base do diferencial  
- O próximo diferencial continua baseado no FULL das 00:00  

---

### Quando utilizar

- Antes de testes ou intervenções no ambiente  
- Para envio de backup para outro ambiente  
- Para cópias temporárias de segurança  
- Em atividades de troubleshooting  

---

### Quando NÃO utilizar

- Como estratégia padrão de backup  
- Substituindo backups FULL regulares  

---

## 4 - Point-in-Time Restore

Permite restaurar o banco de dados para um momento específico no tempo, geralmente utilizado em cenários de erro humano, como exclusões ou atualizações indevidas  
O Point-in-Time Restore permite recuperar o banco com alta precisão, reduzindo perda de dados e sendo essencial em ambientes críticos  

---

### Requisitos

- Recovery model FULL ou BULK_LOGGED  
- Backup FULL  
- Backups de LOG em sequência  

Sem esses elementos, não é possível realizar recuperação ponto no tempo

---

### Funcionamento

O Point-in-Time Restore utiliza a cadeia de backups de log para avançar o banco até um momento exato  

O processo ocorre da seguinte forma:

1. Restaurar o backup FULL com NORECOVERY  
2. Restaurar backups diferenciais (se houver) com NORECOVERY  
3. Restaurar backups de LOG em sequência  

4. No último backup de log, aplicar a cláusula STOPAT  

Isso permite interromper a recuperação exatamente no momento desejado  

---

### Exemplo prático

Cenário:
- DELETE acidental às 22:37  
- Último backup de log às 22:30  
- Próximo backup de log às 22:45  

Mesmo sem backup exatamente às 22:37, é possível recuperar:
- Restaurando o log das 22:45  
- Utilizando STOPAT = '22:36:59'  

---

### Observações importantes

- O restore sempre segue a ordem cronológica dos backups  
- A cláusula STOPAT é aplicada apenas no último backup de log  
- Não é possível aplicar STOPAT em backups FULL ou diferencial  

---

### Limitações

- Não funciona no recovery model SIMPLE  
- Em BULK_LOGGED, pode haver limitação durante operações bulk  
- Depende da integridade completa da cadeia de backups  

---

### Uso comum

- Recuperação de erro humano (DELETE/UPDATE incorreto)  
- Reversão de alterações indevidas  
- Recuperação de dados específicos sem necessidade de restore completo para último estado  

---

## 5 - Observações finais

Backup não garante recuperação  
Somente restore testado garante recuperação
