# A0011 – Transações e Concorrência
> **Author:** Rafael Binda  
> **Created:** 2026-03-07  
> **Version:** 2.0 

---

## Descrição
Este documento apresenta informações a respeito de transações e concorrência no SQL Server

---

## Hands-on  
[Transactions and Concurrency ](../scripts/Q0009-transactions-and-concurrency.sql)  

---

## 1.0 - Comandos para Atualização de Dados
Os comandos de atualização de dados são utilizados para **modificar o conteúdo armazenado nas tabelas** no banco de dados
No SQL Server, os principais comandos são:  

- `INSERT`
- `UPDATE`
- `DELETE`

Esses comandos fazem parte do grupo conhecido como **DML (Data Manipulation Language)** 

---

## INSERT

O comando `INSERT` é utilizado para **inserir novos registros em uma tabela**  
Ele permite adicionar dados explicitamente informados ou utilizar valores padrão definidos na estrutura da tabela  
Entre os cenários comuns de uso estão:  
- Utilização de valores `DEFAULT`
- Inserção baseada em consultas (`INSERT SELECT`)
- Inserção de novos registros em tabelas existentes

Exemplo:  
```sql
INSERT INTO Alunos (Nome, Cidade, Curso)
VALUES ('RAFAEL BINDA', 'CHAPECO', 'MICROSOFT SQL SERVER');
```

---

## SELECT INTO

O comando `SELECT INTO` permite **criar uma nova tabela a partir do resultado de uma consulta**  
Esse recurso é frequentemente utilizado para:  
- Criação rápida de tabelas de backup  
- Criação de tabelas temporárias de trabalho  
- Cópia de estrutura e dados de outra tabela  

Exemplo:
```sql
SELECT *
INTO AlunosBackup
FROM Alunos;
```
---

## UPDATE

O comando `UPDATE` é utilizado para **alterar valores de registros existentes em uma tabela**  
A atualização pode ocorrer:  
- Em um único registro
- Em múltiplos registros
- Utilizando informações de outras tabelas (UPDATE com JOIN)
- Cuidado: Executar **um UPDATE sem cláusula WHERE atualizará todas as linhas da tabela**

Exemplo:  
```sql
UPDATE Alunos
SET Cidade = 'FLORIANOPOLIS'
WHERE Nome = 'RAFAEL BINDA';
```
Exemplo de UPDATE com JOIN  
→ O SQL Server permite atualizar dados utilizando informações de outra tabela  

```sql
UPDATE C
SET C.Cidade = E.Cidade
FROM Clientes C
INNER JOIN Enderecos E
ON C.IdCliente = E.IdCliente;
```

---

## DELETE

O comando `DELETE` é utilizado para **remover registros de uma tabela**  
Assim como no `UPDATE`, é possível remover:  
- Um registro específico
- Um conjunto de registros
- Todos os registros de uma tabela
- Cuidado: Executar **um DELETE sem cláusula WHERE removerá todas as linhas da tabela**

Exemplo:  
```sql
DELETE FROM Alunos
WHERE Nome = 'RAFAEL BINDA';
```
---

### Boas práticas ao modificar dados

Durante operações de atualização ou exclusão de dados, algumas práticas são recomendadas para reduzir o risco de alterações incorretas nos dados:
- Executar primeiro um **SELECT** para validar os registros que serão afetados  
- Confirmar a quantidade de linhas que serão modificadas  
- Evitar executar comandos `UPDATE` ou `DELETE` sem `WHERE`  
- Executar operações críticas dentro de uma **transação (`BEGIN TRAN`)**  
- Utilizar **`TRY...CATCH`** para tratamento de erros quando necessário  
- Validar o número de linhas afetadas utilizando **`@@ROWCOUNT`**

---

## 2.0 - Tratamento de Erro

Durante a execução de comandos SQL podem ocorrer diversos tipos de erros, como:  
- Violação de chave primária
- Divisão por zero
- Tentativa de acesso a objetos inexistentes
- Problemas de conversão de tipos de dados

O tratamento adequado desses erros é importante para evitar inconsistências nos dados e garantir que as operações sejam executadas de forma segura

---

### 2.1 - Tratamento de erro em versões antigas do SQL Server

Até o **SQL Server 2000**, o tratamento de erro era normalmente realizado utilizando:
- `@@ERROR`
- `GOTO`

→ A variável de sistema `@@ERROR` retorna o **código do erro da última instrução executada**  
→ Se o valor retornado for diferente de `0`, significa que ocorreu um erro  
→ Esse método ainda funciona, mas hoje é considerado **legado**  

Exemplo:

```sql
SELECT 100 / 0

IF @@ERROR <> 0
    GOTO TrataErro

PRINT 'Execução concluída com sucesso'

TrataErro:
PRINT 'Ocorreu um erro na execução'
```

---

### 2.2 - Tratamento de erros em versões atuais do SQL Server

A partir das versões mais recentes do SQL Server, o tratamento de erro passou a ser realizado utilizando os blocos:  
- `BEGIN TRY`
- `BEGIN CATCH`

Esse mecanismo permite capturar erros ocorridos durante a execução de um bloco de código e tratá-los de forma estruturada
 
---

**TRY...CATCH**

Regras importantes:
- O código que pode gerar erro deve ficar dentro do bloco `TRY`
- **Não pode existir código entre `END TRY` e `BEGIN CATCH`**
- Se ocorrer um erro dentro do bloco `TRY`, o fluxo de execução é direcionado para o bloco `CATCH`

Exemplo:  
```sql
BEGIN TRY
    -- Código protegido
END TRY
BEGIN CATCH
    -- Código executado em caso de erro
END CATCH
```

---

### 2.2.1 - Funções de erro disponíveis

Dentro do bloco `CATCH`, algumas funções podem ser utilizadas para obter informações detalhadas sobre o erro ocorrido
| Função | Descrição |
|------|------|
| `ERROR_NUMBER()` | Retorna o número do erro |
| `ERROR_SEVERITY()` | Retorna a severidade do erro |
| `ERROR_STATE()` | Retorna o estado do erro |
| `ERROR_LINE()` | Retorna a linha onde o erro ocorreu |
| `ERROR_MESSAGE()` | Retorna a mensagem completa do erro |

**ERROR_SEVERITY() - Faixa de severidade (Error Severity Levels)**  
Existem vários níveis de severity no SQL Server e eles seguem uma escala definida de 0 a 25. Nem todos são usados com frequência.  

| Severity | Significado |
|------|------|
| 0–9  | Mensagens informativas (não são erros reais) |
|10    | Mensagem informativa retornada ao cliente |
|11–16 | Erros causados pelo usuário ou pela consulta|
|17–19 | Problemas de recursos ou limitações do servidor|
|20–25 |Erros graves que podem indicar falha do sistema|


Exemplo:  
```sql
BEGIN TRY
    SELECT 100 / 0
END TRY
BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS NumeroErro,
        ERROR_MESSAGE() AS MensagemErro
END CATCH
```

Nesse exemplo:
- Ocorre uma divisão por zero
- O erro é capturado pelo bloco `CATCH`
- As informações do erro são retornadas pela consulta

---

### 2.3 - Importância do tratamento de erro

O uso de tratamento de erro é especialmente importante quando combinado com **transações**, pois permite:
- Evitar inconsistência nos dados
- Realizar **ROLLBACK** quando necessário
- Registrar informações sobre falhas ocorridas

Nos próximos tópicos serão apresentados os conceitos de **transações**, **locks**, **blocking** e **deadlocks**, que estão diretamente relacionados ao controle de concorrência no SQL Server

---

## 3 - Transações no SQL Server

**O que é uma transação?**  
→ Uma **transação** é uma sequência de operações executadas como **uma única unidade lógica de trabalho**, isso significa que todas as operações que fazem parte da transação devem ser concluídas com sucesso para que as alterações sejam efetivamente aplicadas no banco de dados  
→ Caso ocorra algum erro durante a execução, é possível desfazer todas as operações realizadas através de um **ROLLBACK**, garantindo que os dados permaneçam consistentes  

---

### Propriedades de uma transação (ACID)  
As transações em bancos de dados relacionais seguem o conjunto de propriedades conhecido como **ACID**:  
- Atomicidade (Atomicity)
- Consistência (Consistency)
- Isolamento (Isolation)
- Durabilidade (Durability)

---

**Atomicidade (Atomicity)**  
→ Todas as alterações realizadas por uma transação são tratadas como **uma única unidade indivisível**  
→ Isso significa que:  
- ou **todas as operações são executadas**  
- ou **nenhuma delas é aplicada**  
→ Caso ocorra falha durante a execução, todas as alterações são revertidas utilizando **ROLLBACK**  

---

**Consistência (Consistency)**  
→ Ao final da execução de uma transação, o banco de dados deve permanecer em um **estado consistente**  
→ Isso significa que todas as regras de integridade definidas no banco de dados devem continuar sendo respeitadas  

---

**Isolamento (Isolation)**  
→ O isolamento garante que as modificações realizadas por transações simultâneas não interfiram umas nas outras  
→ Esse controle é realizado através de mecanismos de **locks**, que impedem que múltiplas transações modifiquem os mesmos recursos simultaneamente de forma conflitante  

---

**Durabilidade (Durability)**  
→ Após a conclusão de uma transação com **COMMIT**, as alterações realizadas tornam-se permanentes  
→ Mesmo que ocorra uma falha no sistema (queda de energia ou falha do servidor), os dados já confirmados permanecerão armazenados  

---
Exemplo:  
Um exemplo clássico de transação ocorre em **operações bancárias**, onde é necessário realizar uma transferência de dinheiro entre duas contas:  
- 1. Debitar o valor da **Conta A**  
- 2. Creditar o valor na **Conta B**  
→ Essas duas operações devem acontecer dentro da mesma transação  
→ Se apenas uma das operações ocorrer, os dados ficarão inconsistentes  
→ Por esse motivo, ambas devem ser executadas como **uma única unidade lógica de trabalho**  

---

## 3.1 - Tipos de transações no SQL Server

No SQL Server existem dois principais tipos de transações:
- **Transações implícitas**
- **Transações explícitas**

Esses dois modos determinam como o SQL Server inicia e finaliza as transações durante a execução dos comandos

---

### 3.1.1 - Transação Implícita  
→ Por padrão, quando abrimos uma sessão no SQL Server (por exemplo no SSMS), os comandos são executados no modo **autocommit**, isso significa que cada comando executado é automaticamente tratado como uma transação individual  
→ Para utilizar **transações implícitas**, é necessário habilitar esse comportamento na sessão utilizando o comando:  

```sql
SET IMPLICIT_TRANSACTIONS ON
```
→ Importante:  
Qualquer comando `SET` altera **apenas a sessão atual**, não modificando o comportamento padrão do servidor nem das demais conexões  

---

**Funcionamento da transação implícita**  
Quando o modo de transações implícitas está habilitado, o SQL Server inicia automaticamente uma nova transação quando determinados comandos são executados. Entre esses comandos estão:  
- `ALTER TABLE`
- `CREATE`
- `DELETE`
- `DROP`
- `FETCH`
- `GRANT`
- `INSERT`
- `OPEN`
- `REVOKE`
- `SELECT`
- `TRUNCATE TABLE`
- `UPDATE`

Após a execução de um desses comandos, uma transação é iniciada automaticamente e permanece aberta até que seja finalizada com `COMMIT` ou `ROLLBACK`  
→ Para verificar se existe alguma transação aberta na sessão, pode-se utilizar:  

```sql
SELECT @@TRANCOUNT
```
---

**Finalizando uma transação implícita**  
Mesmo sendo iniciada automaticamente, a transação precisa ser finalizada manualmente com um dos comandos:  
- `COMMIT`
- `ROLLBACK`

→ Sem essa finalização, a transação permanecerá aberta na sessão  

---

### 3.1.2 - Transação Explícita 

As **transações explícitas** são iniciadas manualmente pelo usuário através do comando:

```sql
BEGIN TRAN
```

Esse tipo de transação oferece **maior controle sobre as operações executadas**, permitindo agrupar múltiplos comandos dentro de uma mesma unidade lógica de trabalho

---

**Estrutura básica**

Uma transação explícita normalmente segue a seguinte estrutura:

```sql
BEGIN TRAN
    -- operações realizadas dentro da transação
COMMIT
```

Caso seja necessário desfazer as alterações realizadas, pode-se utilizar:
```sql
ROLLBACK
```

---

**Uso com tratamento de erro**

Em cenários reais, é comum combinar transações explícitas com **tratamento de erro utilizando TRY...CATCH**
Essa abordagem permite garantir que, caso ocorra algum erro durante a execução, todas as alterações realizadas sejam revertidas

Exemplo conceitual:

```sql
BEGIN TRY
    BEGIN TRAN
        -- operações de atualização de dados
    COMMIT
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION
END CATCH
```

Nesse exemplo:
- A transação é iniciada com `BEGIN TRAN`
- Se todas as operações forem executadas com sucesso, é realizado `COMMIT`
- Caso ocorra algum erro, o bloco `CATCH` executa `ROLLBACK`, desfazendo todas as alterações

---

**Observação importante**

Diferente de alguns sistemas, no SQL Server o **ROLLBACK não é automático**  
Se uma transação for iniciada e não for finalizada corretamente, ela poderá manter **locks ativos**, impactando outras operações no banco de dados  
Por esse motivo, é fundamental garantir que todas as transações sejam corretamente finalizadas com:  

- `COMMIT`
- ou `ROLLBACK`

---

## 4 - Locks

Locks são mecanismos utilizados pelo SQL Server para **controlar o acesso simultâneo aos recursos do banco de dados**  
Eles garantem que múltiplas transações possam acessar os dados de forma segura, evitando inconsistências causadas por modificações concorrentes  
Sempre que uma transação executa operações de leitura ou escrita, o SQL Server aplica automaticamente diferentes tipos de **locks** nos recursos acessados  

---

### 4.1 - Principais tipos de lock

Entre os diversos tipos de locks existentes, os dois mais importantes são:
- Lock de Leitura (Shared Lock – S)
- Lock de Escrita (Exclusive Lock – X)

---
  
**Lock de Leitura (Shared Lock – S)**  
O **Shared Lock** é utilizado durante operações de leitura  

Características:  
- Permite que múltiplas transações leiam o mesmo recurso simultaneamente
- Impede que outras transações realizem modificações naquele recurso enquanto a leitura está ocorrendo

---
**Lock de Escrita (Exclusive Lock – X)**  
O **Exclusive Lock** é utilizado durante operações de modificação de dados  

Características:  
- Bloqueia outras leituras e escritas no recurso
- Apenas uma transação pode possuir esse tipo de lock por vez

---

**Compatibilidade de Locks**  
Alguns tipos de locks são **compatíveis entre si**, enquanto outros não  
Por exemplo:  
- Várias transações podem possuir **Shared Lock (S)** simultaneamente  
- Um **Exclusive Lock (X)** não é compatível com nenhum outro lock  
→ Isso significa que, se uma transação estiver modificando um registro, outras transações precisarão **aguardar** até que a operação seja concluída  

---

## 5 - Blocking

O **blocking** ocorre quando uma transação está aguardando outra liberar um recurso que está bloqueado  

Exemplo conceitual:  
1. Uma transação inicia a leitura de um registro (Shared Lock)  
2. Outra transação tenta modificar o mesmo registro (Exclusive Lock)  
3. Como os locks são incompatíveis, a segunda transação precisa aguardar  

Essa situação é conhecida como **blocking**

---

**Observação importante**

→ Blocking é um comportamento **natural em bancos de dados relacionais**  
→ Ele ocorre para garantir a integridade e consistência dos dados, no entanto, quando o blocking ocorre de forma excessiva, pode causar:  
- Lentidão na aplicação  
- Aumento do tempo de resposta  
- Reclamações dos usuários  

**Nesses casos, o DBA deve investigar a origem do problema**

---

**Como identificar blocking**

No SQL Server Management Studio (SSMS), é possível identificar blocking através do **Activity Monitor**
Caminho:
```
Botão direito na instância → Activity Monitor
```
→ Na coluna **Blocked By**, é possível identificar qual sessão está bloqueando outra

Exemplo:
```
Sessão 75 → Blocked by 81
```
→ Isso significa que a sessão **75** está aguardando a sessão **81** liberar o recurso

---

### Consultas úteis para investigação

Em versões mais antigas do SQL Server:

```sql
EXEC sp_who2
```

Essa procedure retorna diversas informações sobre as sessões ativas, incluindo a coluna **Blocked By**

---

### Visualizar locks

```sql
EXEC sp_lock 75
EXEC sp_lock 81
```

---

### Ver o comando executado pela sessão

```sql
DBCC INPUTBUFFER(75)
DBCC INPUTBUFFER(81)
```

Esses comandos mostram qual instrução SQL está sendo executada pela sessão

---

## 6 - Deadlocks

Um **deadlock** ocorre quando duas ou mais transações ficam presas aguardando recursos que estão bloqueados umas pelas outras

Exemplo conceitual:

1. Transação A bloqueia o **Recurso 1**  
2. Transação B bloqueia o **Recurso 2**  
Depois:  
3. Transação A tenta acessar o **Recurso 2**  
4. Transação B tenta acessar o **Recurso 1**  

Resultado: Nenhuma das duas consegue continuar  

→ Essa situação é chamada de **deadlock**

---

### 6.1 - Como o SQL Server resolve deadlocks

O SQL Server possui um processo interno responsável por identificar situações de deadlock  
Quando isso ocorre, o servidor escolhe automaticamente uma das transações como **vítima do deadlock**  
A transação escolhida é finalizada e recebe o erro:  

```
Erro 1205
Transaction (Process ID ...) was deadlocked on resources with another process
```

Normalmente o SQL Server escolhe finalizar a transação que exigirá **menor custo de rollback**

---

**Observação importante**

Na maioria dos casos, deadlocks são causados por **problemas na lógica da aplicação**, como:
- Acesso às tabelas em ordem diferente
- Transações muito longas
- Falta de índices adequados

**O papel do DBA é investigar o problema e orientar os desenvolvedores na correção da aplicação**





