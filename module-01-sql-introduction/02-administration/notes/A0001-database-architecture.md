# A0001 – Arquitetura dos bancos de dados  
> **Author:** Rafael Binda  
> **Created:** 2026-03-23  
> **Version:** 1.0 

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

## Métricas de I/O (Disco)

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

- Log → throughput + latência  
- Dados → IOPS + latência (acesso aleatório)

---

## Arquivo de log (.LDF)

- Escrita sequencial  
- Operações registradas em ordem  
- Cada operação recebe um LSN (Log Sequence Number)

O LSN representa a sequência lógica das operações e é fundamental para recuperação.

---

## 2.0 - Arquitetura interna de dados  

---

### Pages (8 KB)

A menor unidade de armazenamento no SQL Server é a página, com tamanho fixo de **8 KB (8192 bytes)**

Cada página é composta por:

- **Header (cabeçalho)**  
- **Área de dados**  
- **Slot array (controle de linhas)**  

#### Page Header (informações importantes)

O header contém metadados da página, como:

- Page ID  
- Tipo da página (data, index, etc.)  
- Informações de alocação  
- **LSN da última modificação da página**  

Esse LSN é essencial para o processo de recovery, pois permite ao SQL Server identificar se uma página precisa ser atualizada (REDO) ou revertida (UNDO)

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

Um extent é composto por **8 páginas de 8 KB**, totalizando **64 KB**

- É a unidade de alocação de espaço no SQL Server  
- O crescimento de arquivos ocorre em múltiplos de extent  

---

### Tipos de extent

#### Extent Misto

- As 8 páginas podem pertencer a objetos diferentes  
- Utilizado para objetos pequenos  
- Evita desperdício de espaço  

---

#### Extent Uniforme

- Todas as páginas pertencem ao mesmo objeto  
- Utilizado quando o objeto cresce  
- Melhora desempenho e organização  

---

## 3.0 - CHECKPOINT  

Processo responsável por persistir dados da memória no disco

---

### Fluxo de funcionamento

1. Execução de comando  
2. Alteração em memória (Buffer Cache)  
3. Página marcada como dirty page  
4. Registro no log  
5. Confirmação da transação  
6. CHECKPOINT grava no disco  

---

### Importante

- Dados podem estar atualizados no log, mas não no MDF  
- O log é sempre a fonte mais confiável  

---

## Recovery Process  

Quando ocorre falha:

---

### Etapas

#### 1) Analysis
- Identifica transações ativas no momento da falha  

#### 2) REDO (roll forward)
- Reaplica operações já confirmadas  
- Garante que alterações persistam no banco  

#### 3) UNDO (rollback)
- Desfaz transações não confirmadas  
- Garante consistência dos dados  

---

### Resultado

- Banco retorna a um estado consistente  

---

## 4.0 - Transaction Log Internals  

---

### VLF (Virtual Log Files)

- Divisões internas do log  

---

### Problemas com muitos VLF

- Recovery lento  
- Restore lento  
- Startup lento  

---

## LSN e MINLSN  

- LSN identifica operações  
- MINLSN define o ponto mínimo necessário para recovery  

---

### Porções do log

- Inativa → pode ser reutilizada  
- Ativa → necessária para recuperação  

---

## 5.0 - Recovery Model  

---

### SIMPLE

- Truncamento automático do log  
- Não permite backup de log  

Uso recomendado:

- ambientes de desenvolvimento  
- testes  
- bancos não críticos  

---

### FULL

- Exige backup de log  
- Permite recuperação ponto no tempo  

Características:

- Maior controle sobre dados  
- Maior segurança  

Recomendação:

- ambientes de produção  
- sistemas críticos  

---

### BULK LOGGED

- Semelhante ao FULL  
- Otimiza operações em massa  

Exemplos:

- BULK INSERT  
- SELECT INTO  

Limitação:

- Pode comprometer recuperação detalhada  

---

## Observações finais  

- Transaction log é o componente mais crítico do SQL Server  
- CHECKPOINT não substitui backup  
- Arquitetura de I/O impacta diretamente desempenho  
- Dimensionamento correto é essencial em produção  
