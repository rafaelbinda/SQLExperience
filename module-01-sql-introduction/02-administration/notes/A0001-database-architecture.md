# A0001 – Arquitetura dos bancos de dados  
> **Author:** Rafael Binda  
> **Created:** 2026-03-23  
> **Version:** 2.0  

---

## Descrição  

Este material apresenta os conceitos fundamentais da arquitetura de bancos de dados no SQL Server, abordando estrutura de arquivos, organização interna, métricas de I/O, funcionamento do transaction log, checkpoint, recovery process e recovery models

---

## Hands-on  

—  

---

## Arquitetura dos bancos de dados  

Todo banco de dados no SQL Server é composto por dois arquivos principais:

- Arquivo de dados (responsável por armazenar tabelas, índices, procedures e os dados em si)
- Arquivo de log (responsável por registrar todas as alterações realizadas no banco)

---

### Funcionamento geral

- `SELECT` normalmente não gera entrada no log  
- `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `DROP` geram entradas no transaction log  

O transaction log é essencial para garantir:

- Atomicidade  
- Durabilidade  

---

## 1.0 - Arquivo de dados  

- Extensões: `.MDF` e `.NDF`

---

### Arquivo primário (.MDF)

- Existe apenas um por banco  
- Primeiro arquivo criado  
- Também conhecido como arquivo de boot  
- Contém metadata do banco  
- Armazena a localização dos demais arquivos  

---

### Arquivo secundário (.NDF)

- Arquivo adicional de dados  
- Utilizado para:
  - expansão de armazenamento  
  - distribuição de carga (I/O)  
  - organização por filegroups  

---

### Quando usar múltiplos arquivos de dados  

---

#### 1º Cenário: Desempenho (paralelismo de I/O)

- O SQL Server pode executar operações de leitura e escrita em paralelo entre arquivos diferentes  
- Quando distribuídos em discos distintos, há melhor aproveitamento de I/O  

---

#### 2º Cenário: Aumentar a capacidade de armazenamento  

- Criação de novos arquivos (.NDF) em discos com espaço disponível  
- Participam do mesmo filegroup  
- SQL Server distribui novas alocações automaticamente  

Comportamento:

- Uso de **proportional fill**  
- Mais espaço livre → mais gravações  
- Não há redistribuição de dados antigos  

---

## Arquivo de log (.LDF)

- Escrita sequencial  
- Operações registradas em ordem  
- Cada operação recebe um LSN (Log Sequence Number)

O LSN representa a sequência lógica das operações e é fundamental para recuperação

---

### Funcionamento básico

O SQL Server utiliza o modelo **Write-Ahead Logging (WAL)**:

1. A alteração é registrada no log  
2. A alteração ocorre em memória  
3. Posteriormente é gravada no arquivo de dados  

---

### Escrita sequencial

- O SQL Server grava sempre no final do log  
- Não existe escrita aleatória  

Consequências:

- Escrita eficiente  
- Alta dependência de disco rápido  
- Sensibilidade à latência  

---

### Informações registradas

- Operações DML  
- Operações DDL  
- Controle de transações  
- Dados necessários para REDO e UNDO  

---

### Múltiplos arquivos de log

- Não existe paralelismo de escrita  
- Apenas um arquivo é utilizado por vez  

---

### Impacto prático

Problemas no log afetam diretamente:

- Tempo de COMMIT  
- Performance de escrita  
- Consistência do banco  

---

## Métricas de I/O (Disco)

O desempenho do SQL Server depende diretamente da capacidade de I/O do disco  
Essas métricas são fundamentais para entender comportamento de leitura e escrita

---

### Throughput

- Quantidade de dados transferidos por segundo (MB/s)  
- Importante para operações sequenciais (log)  

---

### Latência

- Tempo de resposta do disco (ms)  
- Impacta diretamente o tempo de COMMIT  

---

### IOPS

- Número de operações por segundo  
- Importante para acesso aleatório (dados)  

---

### Impacto no SQL Server

- Arquivo de log:
  - dependente de throughput e latência  
  - escrita sequencial  

- Arquivo de dados:
  - dependente de IOPS e latência  
  - acesso mais aleatório (as operações acessam páginas distribuídas ao longo do arquivo, devido a índices, filtros e joins, sem seguir ordem sequencial)

---

## 2.0 - Arquitetura interna de dados  

---

### Pages (8 KB)

A menor unidade de armazenamento no SQL Server é a página, com tamanho fixo de **8 KB (8192 bytes)**

Cada página é composta por:

- Header (cabeçalho)  
- Área de dados  
- Slot array  

---

### Page Header

Contém metadados importantes, como:

- Identificação da página  
- Tipo da página  
- Informações de alocação  
- LSN da última modificação  

Esse LSN é utilizado no processo de recovery

---

### Tipos principais de páginas

#### Data Page
- Armazena dados das tabelas  

#### Index Page
- Estrutura de índices (B-Tree)  

#### IAM Page
- Mapeia extents de um objeto  

#### PFS
- Indica espaço livre nas páginas  

#### GAM
- Indica extents livres  

#### SGAM
- Indica extents mistos disponíveis  

---

### Extent (64 KB)

- Conjunto de 8 páginas  
- Total de 64 KB  
- Unidade de alocação do SQL Server  

---

### Tipos de extent

#### Misto
- Páginas podem pertencer a objetos diferentes  
- Utilizado para objetos pequenos  

#### Uniforme
- Todas as páginas pertencem ao mesmo objeto  
- Utilizado conforme crescimento do objeto  

---

## 3.0 - CHECKPOINT  

Processo responsável por persistir dados da memória no disco

---

### Fluxo

1. Execução  
2. Alteração em memória  
3. Dirty page  
4. Registro no log  
5. Confirmação  
6. Persistência no disco  

---

### Importante

- Log é a fonte confiável  
- Dados podem não estar no MDF ainda  

---

## Recovery Process  

---

### Etapas

#### Analysis
- Identifica transações ativas  

#### REDO
- Reaplica transações confirmadas  

#### UNDO
- Desfaz transações não confirmadas  

---

### Resultado

- Banco consistente  

---

## 4.0 - Transaction Log Internals  

---

### VLF

- Divisões internas do log  

---

### Problemas

- Muitos VLF → recovery lento  

---

## LSN e MINLSN  

- LSN identifica operações  
- MINLSN define ponto mínimo necessário  

---

### Porções

- Inativa → reutilizável  
- Ativa → necessária  

---

## 5.0 - Recovery Model  

---

### SIMPLE

- Truncamento automático  
- Uso: desenvolvimento  

---

### FULL

- Backup obrigatório  
- Recomendado para produção  
- Permite recuperação ponto no tempo  

---

### BULK LOGGED

- Otimiza operações em massa  
- Pode limitar recuperação  

---

## Observações finais  

- Transaction log é crítico  
- CHECKPOINT não substitui backup  
- I/O impacta diretamente desempenho  
- Dimensionamento correto é essencial  
