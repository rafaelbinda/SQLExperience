# A0019 – Database Storage and Performance  
Author: Rafael Binda  
Created: 2026-03-31  
Version: 2.0  

---

## Descrição  

Este material aborda conceitos avançados de gerenciamento de arquivos no SQL Server com foco em desempenho, organização física, TempDB e Instant File Initialization (IFI)

O entendimento desses tópicos é essencial para administração eficiente, otimização de I/O e resolução de problemas em ambientes de produção

---

Hands-on  
[Q0002 – Database creation and file configuration](../../01-sql-introduction/scripts/Q0002-create-database.sql)  
[Q0009 – Transactions and concurrency behavior (TempDB usage)](../../01-sql-introduction/scripts/Q0009-sql-transactions-and-concurrency.sql)  
[Q0016 – TempDB and file configuration](../scripts/Q0016-sql-tempdb-and-file-configuration.sql)  
[CONN-Q0001 – Active connections analysis](../../../dba-scripts/SQL-connections/CONN-Q0001-active-connections.sql)  
[INST-Q0005 – Database files and filegroups overview](../../../dba-scripts/SQL-instance-information/INST-Q0005-database-files-and-filegroups-overview.sql) 
[INST-Q0009 – Database I/O and Performance Metrics](../../../dba-scripts/SQL-instance-information/INST-Q0009-database-io-and-performance-metrics.sql)


---

## 1 – Posicionamento dos Arquivos  

A organização física dos arquivos influencia diretamente o desempenho do SQL Server

### Boas práticas:

- Manter o arquivo de paginação do Windows em disco separado  
- Separar arquivos de dados e log  
- Separar o TempDB dos bancos de usuários  
- Distribuir arquivos em múltiplos discos para melhor throughput  

### Explicação técnica:

- Arquivos de log (LDF) utilizam escrita sequencial (sequential write)  
- Arquivos de dados (MDF/NDF) utilizam leitura e escrita aleatória (random I/O)  
- Misturar ambos no mesmo disco gera contenção de I/O  

### Estrutura recomendada:

1. Windows + Page File  
2. Arquivos de dados (MDF / NDF)  
3. Arquivos de log (LDF)  
4. TempDB  
5. Área de manutenção (backups, importações, ...)  

---

## 2 – Instant File Initialization (IFI)  

Por padrão, ao criar ou expandir arquivos, o SQL Server realiza o processo de **zeroing**, que consiste em preencher com zeros todo o espaço alocado antes de utilizá-lo  
Esse comportamento impacta diretamente o tempo de criação e crescimento dos arquivos, pois envolve operações de I/O síncronas  
O **Instant File Initialization (IFI)** permite que arquivos de dados sejam criados e expandidos sem essa etapa de inicialização, reduzindo significativamente o tempo dessas operações  

### Zeroing (preenchimento com zeros)

Zeroing é o processo no qual o SQL Server inicializa o espaço alocado em disco antes de utilizá-lo  
Esse comportamento ocorre durante:  

- Criação de arquivos  
- Crescimento (autogrowth)  

O objetivo principal do zeroing está relacionado a requisitos de segurança no nível do sistema operacional, garantindo que blocos de disco previamente utilizados sejam inicializados antes de serem reutilizados  

### Consideração sobre segurança no uso de espaço em disco

Quando o SQL Server solicita espaço ao sistema operacional, ele pode receber blocos de disco que já foram utilizados anteriormente por outros arquivos ou processos  
Esses blocos podem conter dados residuais, como:  

- Informações de arquivos previamente removidos  
- Dados de outros bancos de dados  
- Conteúdos gerados por outros processos do sistema  

O processo de zeroing garante que todo o espaço seja inicializado antes do uso, atendendo a requisitos de segurança do sistema operacional  
É importante destacar que, mesmo sem zeroing (com IFI habilitado), o SQL Server mantém controle lógico sobre as páginas alocadas, garantindo que dados não inicializados não sejam acessados por consultas  

### Funcionamento do IFI

O IFI atua diretamente na criação e crescimento dos arquivos de dados:  

- Aplicável apenas aos arquivos de dados (MDF / NDF)  
- Permite que esses arquivos sejam criados ou expandidos sem a etapa de zeroing  
- O espaço é alocado rapidamente, reduzindo o impacto de operações de crescimento  

Esse comportamento melhora significativamente o desempenho em cenários onde há criação ou expansão frequente de arquivos

### Comportamento dos arquivos de log

Os arquivos de log (LDF) possuem um funcionamento diferente:  

- Continuam exigindo zeroing para garantir a integridade da sequência de gravação das transações  
- Esse comportamento é essencial para o funcionamento correto do mecanismo de recovery (REDO/UNDO)  

### Diferença entre versões

- Em versões anteriores ao SQL Server 2022:
  - O IFI não se aplica aos arquivos de log  
  - Todo crescimento do log envolve zeroing  
  - Pode haver impacto perceptível de desempenho em cenários de crescimento frequente  

- A partir do SQL Server 2022:
  - Foram introduzidas otimizações no crescimento do arquivo de log  
  - Para crescimentos de até 64 MB, o impacto do zeroing é reduzido  
  - Apesar disso, o crescimento do log ainda envolve operações de inicialização (zeroing), não sendo equivalente ao comportamento do IFI aplicado aos arquivos de dados  

### Configuração

- Pode ser habilitado durante a instalação  
- Após instalação: via **Local Security Policy (Windows)**  

#### Passo a passo:

- Abrir o Local Security Policy: `secpol.msc`  
- Acessar:  
  Local Policies → User Rights Assignment  
- Abrir:  
  *Perform volume maintenance tasks*  
- Adicionar a conta de serviço do SQL Server  
- Reiniciar o serviço do SQL Server  

### Verificação

- Consultar o log do SQL Server buscando por:  
  "Instant File Initialization"  

- Consultar a DMV:

```sql
SELECT 
    servicename,
    service_account,
    instant_file_initialization_enabled
FROM sys.dm_server_services;
```

---

### Abordagem prática para dimensionamento de arquivos

Para evitar crescimento frequente e garantir melhor desempenho, recomenda-se definir o tamanho inicial dos arquivos com base no comportamento real do ambiente

#### Passo a passo:

1. Iniciar o SQL Server e monitorar o comportamento do banco  
   - Observar o crescimento dos arquivos durante a operação normal  
   - Identificar até que ponto os arquivos crescem e se estabilizam  

2. Analisar o crescimento observado  
   - Exemplo:
     - Arquivo de dados estabiliza em ~500 MB  
     - Arquivo de log estabiliza em ~100 MB  

3. Ajustar o tamanho inicial (SIZE)  
   - Configurar valores ligeiramente acima do uso observado  
   - Aplicar tanto para arquivos de dados quanto para log  

### Benefícios dessa abordagem

- Evita crescimento sequencial logo após o startup  
- Reduz fragmentação no disco  
- Melhora o desempenho inicial do servidor  
- Diminui overhead causado por autogrowth  

### Boas práticas

- Definir tamanho inicial adequado para arquivos  
- Evitar crescimento por porcentagem  
- Preferir crescimento fixo em MB  
- Planejar crescimento ao invés de depender de autogrowth  
- Em versões anteriores ao SQL Server 2022:
  - Considerar crescimento de log mais conservador devido ao custo de zeroing  

---

## 3 – TempDB  

O TempDB é um banco de sistema crítico utilizado como área temporária pelo SQL Server

### Características:

- Recriado a cada inicialização  
- Utilizado para:
  - Controle de concorrência  
  - Execução de consultas  
  - Triggers  
  - Tabelas temporárias  

### Problema comum: contenção no TempDB  

Em ambientes com alta concorrência, o TempDB pode apresentar gargalos internos devido ao alto volume de operações simultâneas  
Essa contenção é frequentemente identificada através do wait type **PAGELATCH**

### PAGELATCH (explicação)

PAGELATCH é um tipo de espera (wait) relacionado à contenção em memória, não em disco  
Ocorre quando múltiplas sessões tentam acessar simultaneamente estruturas internas do SQL Server, especialmente páginas responsáveis pelo controle de alocação

### Estruturas internas de alocação responsáveis pela contenção

- **PFS (Page Free Space)**  
  Controla o espaço livre dentro das páginas  

- **GAM (Global Allocation Map)**  
  Indica quais extents estão livres  

- **SGAM (Shared Global Allocation Map)**  
  Controla extents compartilhados  

Essas estruturas são altamente acessadas em operações no TempDB e podem gerar contenção em cenários de alta concorrência

### Boas práticas:

- Separar o TempDB em disco dedicado  
- Criar múltiplos arquivos de dados  
- Manter arquivos com mesmo tamanho e crescimento  

| CPU | Arquivos recomendados |
|-----|----------------------|
| Até 8 | 1 por CPU |
| Acima de 8 | 1 a cada 4 CPUs |

### Dimensionamento do TempDB

1. Monitorar o comportamento após inicialização  
2. Identificar crescimento estabilizado  
3. Ajustar SIZE com base no uso real  

Exemplo:

- Dados: 500 MB  
- Log: 100 MB  

Configurar valores ligeiramente acima  

### Benefícios:

- Redução de contenção (PAGELATCH)  
- Evita crescimento sequencial após startup  
- Reduz fragmentação  
- Melhora desempenho inicial  

---

## 4 – Autogrowth e Capacity Planning  

O crescimento automático deve ser tratado como exceção, não regra

### Boas práticas:

- Evitar crescimento por porcentagem  
- Preferir crescimento fixo em MB  
- Definir tamanho inicial adequado  

### Problemas comuns:

- Crescimento frequente → impacto de performance  
- Fragmentação de arquivos  
- No log: aumento excessivo de VLFs  

---

## 5 – Pontos de atenção  

- Planejar crescimento dos arquivos  
- TempDB mal configurado gera contenção  
- Log mal dimensionado impacta recovery  

---

## 6 – Monitoramento de I/O e Performance  

Após definir corretamente a arquitetura de storage, dimensionamento de arquivos e configuração do TempDB, é fundamental monitorar o comportamento real do ambiente  

O SQL Server disponibiliza DMVs que permitem analisar o uso de I/O, identificar gargalos e validar se a infraestrutura está adequada para a carga de trabalho  

---

### Objetivo do monitoramento  

- Identificar gargalos de disco  
- Validar decisões de arquitetura de storage  
- Apoiar troubleshooting de performance  
- Correlacionar comportamento do SQL Server com a capacidade do hardware  

---

### Principais fontes de informação  

#### sys.dm_io_virtual_file_stats  

- Retorna estatísticas de I/O por arquivo  
- Permite identificar:

  - Arquivos com maior volume de leitura e escrita  
  - Tempo acumulado de espera (stall)  
  - Diferenças de comportamento entre data files e log files  

Uso prático:

- Identificar arquivos com maior pressão de I/O  
- Detectar possíveis gargalos de disco  
- Avaliar distribuição de carga entre arquivos  

---

#### sys.dm_os_wait_stats  

- Retorna estatísticas de espera do SQL Server  
- Permite identificar onde o servidor está aguardando recursos  

Waits comuns relacionados a I/O:

- PAGEIOLATCH  
→ Indica espera por leitura de páginas em disco  

- WRITELOG  
→ Indica espera por gravação no transaction log  

- IO_COMPLETION  
→ Indica espera por operações de I/O  

Uso prático:

- Identificar pressão de I/O no ambiente  
- Correlacionar waits com problemas de performance  

---

#### sys.dm_db_session_space_usage  

- Retorna uso de espaço no TempDB por sessão  

Uso prático:
- Identificar sessões que consomem muitos recursos temporários  
- Diagnosticar problemas relacionados a consultas que utilizam TempDB  

---

### Interpretação prática  

O monitoramento deve ser analisado em conjunto com o comportamento do ambiente  

Exemplos:

- Alta espera em WRITELOG  
→ Pode indicar problema de latência no disco de log  

- Alta ocorrência de PAGEIOLATCH  
→ Pode indicar gargalo de leitura em disco  

- Arquivos com maior tempo de espera acumulado  
→ Podem indicar distribuição inadequada de I/O  

- Alto consumo de TempDB por sessões  
→ Pode indicar necessidade de ajuste em queries ou configuração  

---


