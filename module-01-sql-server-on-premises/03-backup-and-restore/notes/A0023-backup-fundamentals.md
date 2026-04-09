# A0023 - Fundamentos de Backup e Conceitos de Recuperação
>**Author:** Rafael Binda  
>**Created:** 2026-04-08  
>**Version:** 2.0  

---

## Descrição

Este material apresenta os conceitos fundamentais de backup no SQL Server, incluindo tipos de backup, funcionamento interno, dependências entre backups e conceitos críticos como RPO, RTO e cadeia de backup

---

## 1 - Visão geral de Backup

O SQL Server permite diferentes tipos de backup que podem ser combinados para atender requisitos de negócio

- Backup é online (não bloqueia uso do banco)
- Pode ser executado durante operações normais
- Tipos de backup são complementares

---

## 2 - Planejamento de Backup (RPO e RTO)

**A definição de RPO e RTO não é responsabilidade exclusiva do DBA**, ela deve ser feita em conjunto com:
- Gestor da aplicação 
- Áreas de negócio 

---

### Linha do tempo

```
Tempo -------------------------------------------------------------->

Backup realizado        Falha ocorre                Sistema restaurado
       |                     |                              |
       |------ RPO ---------|<----------- RTO ------------->|
```

### RPO -- Recovery Point Objective
- Intervalo entre o último backup e a falha
- Representa a quantidade de dados que pode ser perdida
- Devemos perguntar quantos dados é aceitável perder?

### RTO -- Recovery Time Objective
- Tempo máximo para recuperação
- Representa o tempo de indisponibilidade do sistema
- Devemos perguntar quanto tempo podemos aguardar para que o restore seja finalizado?

---

## 3 – Requisitos de armazenamento e operação  

Uma estratégia de backup eficiente não se resume à execução dos comandos de backup  
Ela envolve planejamento de armazenamento, validação contínua e processos operacionais bem definidos  
A ausência desses controles pode comprometer completamente a recuperação do ambiente em caso de falha  

---

### Armazenamento  

O armazenamento deve ser planejado considerando desempenho, custo e confiabilidade

- Avaliar onde os backups serão armazenados:
  - Disco local
  - Storage dedicado
  - Nuvem

- Considerar custos envolvidos:
  - Armazenamento (volume de dados)
  - Transferência de dados
    - Egress em cloud: para enviar não tem custo mas para download é cobrado tráfego de saída
- Evitar manter backups apenas no mesmo servidor do banco  
  - Falha física pode comprometer banco e backup simultaneamente  

- Sempre que possível:
  - Manter cópias em locais distintos (offsite)
  - Utilizar estratégias de redundância  

---

### Política de retenção  

A retenção define por quanto tempo os backups serão mantidos antes de serem descartados  
- Deve ser maior que a frequência de execução do DBCC CHECKDB  
- O DBCC CHECKDB identifica corrupção lógica e física no banco  
- Caso a retenção seja menor, existe o risco de todos os backups disponíveis já estarem corrompidos  

---

#### Exemplo prático

- DBCC CHECKDB executado a cada 7 dias  
- Retenção configurada para 5 dias  

Se ocorrer uma corrupção logo após a execução do CHECKDB, ela só será detectada na próxima execução  
Nesse momento, todos os backups válidos podem já ter sido sobrescritos

---

### Testes de restore  

Backup sem teste de restore não garante recuperação

- Deve existir um processo periódico de validação de restore  
- Testes devem incluir:
  - Restore completo
  - Restore com diferencial
  - Restore com log (quando aplicável)

- Validar:
  - Integridade do backup
  - Tempo de recuperação (RTO)
  - Consistência dos dados restaurados  

---

### Monitoramento  

A execução dos backups deve ser monitorada continuamente

- Validar sucesso das rotinas de backup  
- Configurar alertas para falhas  
- Verificar:
  - Tamanho dos backups
  - Tempo de execução
  - Frequência esperada  

Falhas silenciosas de backup são uma das principais causas de perda de dados em ambientes de produção

---

### Versionamento e dependências  

Backups de banco de dados não substituem controle de versão de aplicações

- Mudanças em estrutura (DDL) devem ser versionadas  
- Scripts de deploy devem ser controlados  
- Dependências entre banco e aplicação devem ser consideradas  

---

### Ambiente de testes  

- Manter ambiente dedicado para testes de restore  
- Simular cenários reais de falha  
- Validar procedimentos operacionais  

Esse processo garante que, em caso de incidente, a recuperação será executada de forma previsível

---

### Considerações finais  

Uma estratégia de backup eficiente deve garantir:

- Disponibilidade dos arquivos de backup  
- Integridade dos dados  
- Capacidade real de recuperação  

*Sem testes, monitoramento e retenção adequada, o backup deixa de ser uma solução confiável*

---

## 4 - Backup Full

- Backup completo do banco de dados
- Leva todo o conteúdo dos arquivos de dados `MDF` e `LDF`
- Leva do arquivo de log apenas a atividade durante o backup full

```
    Tempo -------------------------------------------------------------->
    22:00 --------------------------- 23:00
    Início do backup                  Fim do backup
```

Ponto de recuperação: 23:00

### Funcionamento interno do backup (consistência)

Durante a execução de um backup, o SQL Server utiliza o transaction log para garantir a consistência dos dados

O processo ocorre da seguinte forma:

1. No início do backup, o SQL Server executa um CHECKPOINT  
   - Isso garante que as páginas sujas (dirty pages) sejam gravadas em disco  
   - Nesse momento é registrado um LSN (Log Sequence Number) de referência  

2. Durante o backup, os arquivos de dados são copiados  

3. Ao final do processo, o SQL Server consulta o transaction log  
   - A partir do LSN inicial capturado no CHECKPOINT  
   - Incluindo todas as alterações até o término do backup  

4. No momento do restore:
   - Todas as transações finalizadas (commitadas) são aplicadas  
   - Transações que estavam em andamento são desfeitas (rollback)  

Isso garante que o banco seja restaurado exatamente no estado consistente do momento em que o backup foi concluído

---

## 5 - Backup Diferencial

- Backup dos dados alterados desde o último backup full
- Precisa de um backup full para ser recuperado na sequencia 
- Leva do arquivo de log apenas a atividade durante o backup full 

```
    Tempo -------------------------------------------------------------->
    20:00        21:00        22:00        23:00
    FULL         → DIF1      → DIF2       → DIF3
```

Restore necessário:
FULL + último DIF (DIF3)

- Não é possível fazer restore só de 1 diferencial
Exemplo: FULL + DIF2 

### Funcionamento interno do backup diferencial (consistência)

O backup diferencial utiliza o mesmo mecanismo de consistência baseado no transaction log, porém com foco apenas nas alterações ocorridas desde o último backup full  
O processo ocorre da seguinte forma:

1. Após a execução de um backup full, o SQL Server inicializa um conjunto de páginas internas de controle (mapa de extents modificadas)  
   - Esse mapa registra quais extents sofreram alterações  
   - A partir desse momento, qualquer modificação em uma página marca a extent correspondente como alterada  

2. No início do backup diferencial, o SQL Server executa um CHECKPOINT  
   - Isso garante a consistência das páginas em disco  
   - Um LSN (Log Sequence Number) de referência é capturado  

3. Durante o backup diferencial:
   - O SQL Server consulta o mapa de extents modificadas  
   - Todas as extents alteradas desde o último backup full são copiadas para o backup  

4. Ao final do processo:
   - O SQL Server lê o transaction log a partir do LSN capturado no CHECKPOINT  
   - Inclui todas as alterações até o término do backup  

5. No momento do restore:
   - O backup full é restaurado  
   - Em seguida, o backup diferencial mais recente é aplicado  
   - Todas as transações finalizadas são aplicadas  
   - Transações em andamento são desfeitas (rollback)  

Isso garante que o banco seja recuperado exatamente no estado consistente do momento em que o backup diferencial foi concluído

---

## 6 - Backup de Log

- Não pode estar no modo RECOVERY MODEL SIMPLE
- Realiza o backup de todo o conteúdo do transaction log (ldf)
- Precisa de um backup full para ser recuperado em sequencia 
- No final do backup trunca o log (apaga a porção inativa)

```
    Tempo -------------------------------------------------------------->
    20:00        21:00        22:00        23:00
    FULL        → LOG1       → LOG2       → LOG3
```

Restore:
FULL + LOG1 + LOG2 + LOG3 (todos os LOGs em sequência)

- Um backup do log é dependente do outro 
- Ocorre um controle do SQL Server pelo LSN incial e LSN final 

---

## 7 - Tail Log Backup (NO_TRUNCATE)

O Tail Log Backup é o backup final do transaction log realizado após uma falha, com o objetivo de capturar todas as transações ocorridas desde o último backup de log


- Ele é utilizado para evitar perda de dados em cenários críticos
- É a **ultima tentativa de recuperar dados** após falha crítica
- É a **última oportunidade de preservar dados** antes da recuperação do banco
- Esse backup deve ser a **primeira ação** sempre que houver possibilidade de recuperar o log
- O Tail Log Backup não substitui backups regulares  
- Ele é uma medida emergencial  
- Deve fazer parte do procedimento padrão de recuperação de desastres  
- Sua execução pode ser a diferença entre uma recuperação completa e perda parcial de dados

---

### Objetivo

Capturar a parte final do log (tail of the log), garantindo que todas as transações recentes sejam preservadas antes do processo de restore

---

### Quando utilizar

- Banco em estado SUSPECT  
- Falha nos arquivos de dados (MDF/NDF)  
- Falha inesperada do banco  
- Antes de iniciar um processo de restore  

---

### Funcionamento

- O SQL Server copia todo o conteúdo restante do transaction log  
- Inclui transações ainda não protegidas por backups anteriores  
- Não realiza truncamento do log durante o processo  
- Esse comportamento garante a preservação máxima dos dados disponíveis

---

### Exemplo prático

- Último backup de log realizado às 22:00  
- Falha ocorre às 23:00  

Existe um intervalo de 1 hora de transações que ainda não foram salvas em backup

Sem o Tail Log Backup:
- Essas transações serão perdidas  

Com o Tail Log Backup:
- É possível recuperar o banco até o momento exato da falha  

---

### Processo de recuperação

1. Executar o Tail Log Backup  
2. Restaurar o backup full  
3. Restaurar backups diferenciais (se houver)  
4. Restaurar todos os backups de log  
5. Restaurar o Tail Log Backup  

Isso permite recuperação completa até o último ponto possível

---

### Requisitos

- Banco deve estar em recovery model FULL ou BULK_LOGGED  
- O arquivo de log deve estar íntegro  

---

### Limitações

- Se o arquivo de log estiver corrompido ou inacessível, não será possível realizar o Tail Log Backup  
- Em caso de perda total do storage (disco), não há como recuperar essa porção final  

----

## 8 - Recovery Models

Define como o transaction log será gerenciado

### SIMPLE

-   Trunca log automaticamente
-   Sem backup de log
-   Sem point-in-time

---

### FULL

-   Log completo
-   Permite recuperação ponto no tempo

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

## 9 - Cadeia de Backup

- Backups são interdependentes via LSN
- Quebra da cadeia inviabiliza restore completo

---

## 10 - COPY_ONLY

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

## 11 - Point-in-Time Restore

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

Isso permite interromper a recuperação exatamente no momento desejado.

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

## 12 - Observações finais

Backup não garante recuperação
Somente restore testado garante recuperação
