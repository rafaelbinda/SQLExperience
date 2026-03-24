# A0001 – Arquitetura dos bancos de dados  
> **Author:** Rafael Binda  
> **Created:** 2026-03-23  
> **Version:** 2.0  

---

## Descrição  

Este material apresenta os conceitos fundamentais da arquitetura de bancos de dados no SQL Server, abordando estrutura de arquivos, organização interna, métricas de I/O, funcionamento do transaction log, checkpoint, recovery process e recovery models

Esses conceitos formam a base para os módulos seguintes, especialmente nas áreas de administração, desempenho, backup e recuperação de dados

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

### Arquivo secundário (.NDF)

- Arquivo adicional de dados  
- Utilizado para:
  - expansão de armazenamento  
  - distribuição de carga (I/O)  
  - organização por filegroups  

### Quando usar múltiplos arquivos de dados  

#### 1º Cenário: Desempenho (paralelismo de I/O)

- O SQL Server pode executar operações de leitura e escrita em paralelo entre arquivos diferentes  
- Quando distribuídos em discos distintos, há melhor aproveitamento de I/O  

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

### Funcionamento básico

O SQL Server utiliza o modelo **Write-Ahead Logging (WAL)**:

1. A alteração é registrada no log  
2. A alteração ocorre em memória  
3. Posteriormente é gravada no arquivo de dados  

### Escrita sequencial

- O SQL Server grava sempre no final do log  
- Não existe escrita aleatória  

Consequências:

- Escrita eficiente  
- Alta dependência de disco rápido  
- Sensibilidade à latência  

### Informações registradas

- Operações DML  
- Operações DDL  
- Controle de transações  
- Dados necessários para REDO e UNDO  

### Múltiplos arquivos de log

- Não existe paralelismo de escrita  
- Apenas um arquivo é utilizado por vez  

### Impacto prático

Problemas no log afetam diretamente:

- Tempo de COMMIT  
- Performance de escrita  
- Consistência do banco  

---

## Métricas de I/O (Disco)

O desempenho do SQL Server depende diretamente da capacidade de I/O do disco  
Essas métricas são fundamentais para entender comportamento de leitura e escrita

### Throughput

- Quantidade de dados transferidos por segundo (MB/s)  
- Importante para operações sequenciais (log)  

### Latência

- Tempo de resposta do disco (ms)  
- Impacta diretamente o tempo de COMMIT  

### IOPS

- Número de operações por segundo  
- Importante para acesso aleatório (dados)  

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

A menor unidade de armazenamento no SQL Server é a página, com tamanho fixo de **8 KB (8192 bytes)**.

As páginas são a base de toda a estrutura de armazenamento: tabelas, índices e demais objetos são organizados internamente como conjuntos de páginas.

Cada página é composta por:

- Page Header (cabeçalho)  
  Contém metadados essenciais para o gerenciamento da página, como:

  - Identificação da página (Page ID)  
  - Tipo da página (data, index, etc.)  
  - Informações de alocação  
  - LSN da última modificação  
  
  O LSN armazenado no header permite ao SQL Server:
  - Identificar se a página está atualizada em relação ao transaction log  
  - Determinar se é necessário aplicar REDO durante o recovery  
  Esse mecanismo é fundamental para garantir consistência após falhas

- Área de dados

- Slot array (estrutura de controle que mantém os ponteiros para as linhas dentro da página)  

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

### Fluxo em ordem cronológica

1. Execução do comando  
   - Uma operação é iniciada (ex: INSERT, UPDATE, DELETE)  
   - O SQL Server inicia o processamento da transação  

2. Alteração em memória (Buffer Cache)  
   - A página de dados é carregada para a memória (se ainda não estiver)  
   - A modificação é realizada diretamente na memória, não no disco  

3. Dirty Page  
   - A página modificada é marcada como *dirty page*  
   - Isso indica que o conteúdo da página em memória está diferente do que está no disco  

4. Registro no transaction log  
   - Antes de qualquer gravação no arquivo de dados, a alteração é registrada no log (.LDF)  
   - O log armazena informações suficientes para refazer (REDO) ou desfazer (UNDO) a operação  
   - Cada operação recebe um identificador (LSN), garantindo a ordem das transações  

5. Confirmação da transação (COMMIT)  
   - O SQL Server confirma a operação após garantir que o log foi gravado no disco  
   - Nesse momento, a aplicação já considera a transação concluída  
   - A alteração ainda pode não estar persistida no arquivo de dados  

6. Persistência no disco (CHECKPOINT)  
   - O processo de CHECKPOINT grava as dirty pages no arquivo de dados (.MDF/.NDF)  
   - A página deixa de ser considerada dirty e passa a refletir o estado persistido no disco  

### Importante

- Log é a fonte confiável  
- Dados podem não estar no MDF ainda  

---

## Recovery Process  

O recovery process ocorre quando o SQL Server é reiniciado após uma falha inesperada (queda de energia, crash, etc.)  
Seu objetivo é garantir que o banco de dados volte a um estado consistente, utilizando as informações registradas no transaction log  

---

### Etapas

#### 1 - Analysis
- O SQL Server analisa o transaction log a partir do último CHECKPOINT  
- Identifica:
  - transações que estavam ativas no momento da falha  
  - ponto inicial necessário para recuperação (MINLSN)  
- Reconstrói o estado interno das transações  

#### 2 - REDO (Roll Forward)
- Reaplica todas as operações que já foram confirmadas (COMMIT)  
- Garante que alterações registradas no log sejam refletidas no arquivo de dados  
- Mesmo que a página já esteja atualizada, o SQL valida via LSN se precisa reaplicar  

Objetivo:
- Garantir que nenhuma alteração confirmada seja perdida  

#### 3 - UNDO (Rollback)
- Desfaz todas as transações que não foram confirmadas (sem COMMIT)  
- Utiliza as informações do log para reverter as alterações  
- Executa rollback até o ponto inicial da transação  

Objetivo:
- Garantir consistência lógica do banco  

### 4 - Resultado

- O banco de dados retorna a um estado consistente  
- Todas as transações confirmadas são mantidas  
- Todas as transações não confirmadas são desfeitas  
- O banco é liberado para uso normalmente  

---

## 4.0 - Transaction Log Internals  

O transaction log não é um arquivo contínuo único do ponto de vista interno  
Ele é dividido em partes menores chamadas **VLF (Virtual Log Files)**, que são utilizadas pelo SQL Server para gerenciar gravação, reutilização e recuperação dos dados

---

### VLF (Virtual Log Files)

- São subdivisões internas do arquivo de log (.LDF)  
- Cada VLF possui um intervalo de LSNs  
- O SQL Server grava os dados sequencialmente atravessando os VLFs  

Funcionamento:

- O log começa a gravar no primeiro VLF disponível  
- À medida que enche, passa para o próximo  
- Quando chega ao final, pode voltar ao início (comportamento circular), desde que a porção esteja inativa  

Importante:

- O tamanho e a quantidade de VLFs são definidos automaticamente pelo SQL Server  
- Isso depende do tamanho inicial do log e da configuração de crescimento (autogrowth)  

### Problemas com muitos VLF

Ter muitos VLFs pode causar impacto direto no desempenho do banco.

Principais problemas:

- Tempo maior de inicialização do banco  
- Recovery mais lento após falhas  
- Restore mais demorado  
- Maior tempo para análise do transaction log  

Motivo:

- O SQL Server precisa percorrer diversos VLFs durante o processo de recovery  
- Quanto maior a quantidade, maior o trabalho necessário  

### Causa comum

- Crescimento do log em pequenos incrementos (autogrowth baixo)  
- Expansão frequente do arquivo de log  

### Boas práticas

- Definir um tamanho inicial adequado para o log  
- Evitar crescimento automático em valores muito pequenos  
- Manter uma quantidade controlada de VLFs  

### Conceito importante

O log funciona de forma **circular**:

- VLFs com dados já processados (porção inativa) podem ser reutilizados  
- Caso não seja possível reutilizar, o log cresce  

Esse comportamento está diretamente relacionado ao recovery model e à realização de backup de log

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

O recovery model define como o SQL Server gerencia o transaction log e quais tipos de recuperação são possíveis em caso de falha

Ele impacta diretamente:

- comportamento do transaction log  
- necessidade de backup  
- capacidade de recuperação dos dados  

---

### SIMPLE

No modelo SIMPLE, o SQL Server gerencia automaticamente o transaction log

#### Características

- O log é truncado automaticamente após o CHECKPOINT  
- Não permite backup do transaction log  
- O arquivo de log tende a se manter menor  

#### Funcionamento

- Após o CHECKPOINT, a porção inativa do log é liberada automaticamente  
- O espaço é reutilizado sem necessidade de intervenção manual  

#### Vantagens

- Baixa necessidade de administração  
- Menor crescimento do log  
- Simplicidade de configuração  

#### Limitações

- Não permite recuperação ponto no tempo  
- Em caso de falha, só é possível restaurar até o último backup FULL ou DIFFERENTIAL  

#### Uso recomendado

- Ambientes de desenvolvimento  
- Testes  
- Bancos não críticos  

---

### FULL

No modelo FULL, todas as operações são totalmente registradas no transaction log

#### Características

- Registro completo de todas as operações  
- Permite backup do transaction log  
- Permite recuperação ponto no tempo  

#### Funcionamento

- O log não é truncado automaticamente  
- A porção inativa só é liberada após backup do log  
- Todas as transações são preservadas até serem copiadas em backup  

#### Vantagens

- Máximo controle sobre recuperação  
- Possibilidade de restaurar o banco em qualquer ponto específico no tempo  
- Suporte a cenários avançados (alta disponibilidade, replicação, etc.)  

#### Limitações

- Requer estratégia de backup bem definida  
- Se não houver backup de log, o arquivo cresce indefinidamente  
- Maior volume de dados no log  

#### Uso recomendado

- Ambientes de produção  
- Sistemas críticos  
- Bancos que exigem recuperação precisa  

---

### BULK LOGGED

O modelo BULK LOGGED é uma variação do FULL, focada em melhorar desempenho em operações de grande volume.

#### Características

- Similar ao FULL  
- Algumas operações utilizam registro mínimo (minimal logging)  

#### Operações afetadas

- BULK INSERT  
- SELECT INTO  
- Importações de dados  
- Rebuild de índices  

#### Funcionamento

- Reduz a quantidade de dados registrados no log durante operações em massa  
- Mantém comportamento semelhante ao FULL para as demais operações  

#### Vantagens

- Melhor desempenho em cargas grandes  
- Redução do volume de log gerado  

#### Limitações

- Pode impedir recuperação ponto no tempo durante operações bulk  
- Backup do log pode ficar maior  
- Não é recomendado como modelo padrão permanente  

#### Uso recomendado

- Processos de ETL  
- Cargas massivas de dados  
- Uso temporário em operações específicas  

---

### Comparação resumida

| Modelo       | Backup de Log | Truncamento | Point-in-time | Uso recomendado |
|--------------|--------------|------------|--------------|----------------|
| SIMPLE       | Não          | Automático | Não          | Dev/Teste      |
| FULL         | Sim          | Manual     | Sim          | Produção       |
| BULK LOGGED  | Sim          | Manual     | Parcial      | Cargas massivas|

---

### Observação importante

- O modelo FULL é o padrão recomendado para ambientes de produção  
- O modelo SIMPLE simplifica a gestão, mas limita a recuperação  
- O modelo BULK LOGGED deve ser utilizado com cuidado e, preferencialmente, de forma temporária  
---

## Observações finais  

- Transaction log é crítico  
- CHECKPOINT não substitui backup  
- I/O impacta diretamente desempenho  
- Dimensionamento correto é essencial  
