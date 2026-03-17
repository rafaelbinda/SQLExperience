# A0013 – Objetos de programação do SQL Server
> **Author:** Rafael Binda  
> **Created:** 2026-03-17  
> **Version:** 1.0 

---

## Descrição  

Este documento apresenta uma visão geral sobre Stored Procedures no SQL Server, incluindo conceitos e uso prático 
 
---

## Hands-on  

[Stored Procedures](../scripts/PROC-Q0001-procedures-metadata.sql)  
[Procedures Metadata Objects](../../../dba-scripts/SQL-programming-objects/PROC-Q0001-procedures-metadata.sql) 

---
## SQL Server Stored Procedures 

**O que é uma Stored Procedure?**

- Uma **Stored Procedure** é um conjunto de comandos escritos em **Transact-SQL (T-SQL)** que são armazenados e executados diretamente no **SQL Server**  
- Ela permite encapsular lógica de banco de dados que pode ser executada sempre que necessário  

As stored procedures podem:  
- Executar múltiplas instruções SQL
- Receber **parâmetros**
- Retornar **resultados**
- Executar **operações administrativas ou de manipulação de dados**

---

###1 - Tipos de Stored Procedures

**1.1 - Stored Procedures de Sistema**

São procedures internas do SQL Server usadas para executar **tarefas administrativas**  
Características:  
- Criadas automaticamente pelo SQL Server
- Possuem prefixo **`sp_`**

Exemplo:

```sql
EXEC sp_helpdb;
```

---

**1.2 - Stored Procedures Estendidas**

São procedures desenvolvidas utilizando **linguagem C ou C++** e carregadas no SQL Server como bibliotecas externas  
Características:  
- Possuem prefixo **`xp_`**
- Executam operações externas ao SQL Server
- Mantidas apenas por **compatibilidade**
- **Não é recomendado utilizar**
- Muitas estão **descontinuadas ou desabilitadas por padrão**

Exemplo:

```sql
EXEC xp_cmdshell 'dir';
```

---

**1.3 - Stored Procedures Locais**

São procedures **criadas pelo próprio desenvolvedor ou DBA**  
Características:  
- Criadas dentro de um banco de dados  
- Podem manipular objetos de **outros bancos de dados**  
- Utilizadas para encapsular regras de negócio ou automações  

Exemplo:

```sql
CREATE PROCEDURE dbo.usp_GetCustomers
AS
BEGIN
    SELECT *
    FROM Sales.Customers;
END;
```

Execução:

```sql
EXEC dbo.usp_GetCustomers;
```

---

**1.4 - Stored Procedures com Parâmetros**

Uma stored procedure pode receber parâmetros para tornar sua execução dinâmica

Exemplo:

```sql
CREATE PROCEDURE dbo.usp_GetCustomerById
    @CustomerID INT
AS
BEGIN
    SELECT *
    FROM Sales.Customers
    WHERE CustomerID = @CustomerID;
END;
```

Execução:

```sql
EXEC dbo.usp_GetCustomerById @CustomerID = 10;
```
---

**1.5 - Stored Procedures Temporárias**

São procedures criadas no banco de dados **`tempdb`**  
Características:  
- Quando o nome começa com **`#`**, a procedure é **temporária local**
- Procedures temporárias locais existem apenas na sessão em que foram criadas
- Quando o nome começa com **`##`**, a procedure é **temporária global**
- Procedures temporárias globais podem ser acessadas por outras sessões enquanto existirem
- Esse recurso é pouco usado no dia a dia 

Exemplo de procedure temporária local:

```sql
CREATE PROCEDURE #usp_TempProcedure
AS
BEGIN
    SELECT 'Temporary procedure' AS Message;
END;
```

Exemplo de execução:

```sql
EXEC #usp_TempProcedure;
```

---

**Resumo dos Tipos de Stored Procedures**
| Tipo | Prefixo / Identificação | Uso |
|---|---|---|
| Sistema | `sp_` | Procedures internas do SQL Server usadas para tarefas administrativas |
| Estendida | `xp_` | Procedures desenvolvidas em C/C++ para executar operações externas (mantidas por compatibilidade, não recomendado) |
| Local | definido pelo usuário | Procedures criadas por desenvolvedores ou DBAs para encapsular lógica de negócio |
| Temporária | `#` (local) / `##` (global) | Criadas no banco **tempdb** para uso temporário; pouco utilizadas na prática |

---

###2 - Vantagens e Benefícios do Uso de Stored Procedures

Algumas **vantagens** de utilizar **Stored Procedures** no SQL Server incluem:

- Reutilização de código
- Melhor organização da lógica do banco de dados
- Maior controle de permissões
- Redução do tráfego entre aplicação e banco
- Execução diretamente no servidor

---

Além dessas vantagens citadas anteriormente, existem alguns **benefícios práticos** importantes no uso de Stored Procedures, sendo possível listar:

**2.1 - Redução no Tráfego de Rede entre a Aplicação e o SQL Server**  

Um dos principais benefícios das Stored Procedures é a **redução da quantidade de comunicação entre a aplicação e o banco de dados**  
Exemplo:  

**2.1.1 - Cenário sem o uso de Stored Procedure**  

Suponhamos que para executar uma regra de negócio na aplicação seja necessário:  
→ Executar **10 consultas SQL**  
→ Analisar os resultados  
→ Realizar um **cálculo para geração de crédito financeiro ao cliente**  

Sem o uso de Stored Procedures, o fluxo seria semelhante a:  
1. A aplicação envia o primeiro `SELECT` ao SQL Server, o comando trafega pela rede e o resultado retorna pela rede  
2. A aplicação envia o segundo `SELECT`, o comando trafega pela rede e o resultado retorna pela rede  
3. A aplicação envia o terceiro `SELECT`, o comando trafega pela rede e o resultado retorna pela rede  
4. O processo continua até o **décimo `SELECT`**, sempre com envio e retorno de dados pela rede
   
**Conclusão:**  
Cada consulta gera **uma nova comunicação entre aplicação e banco de dados** aumentando o tráfego de rede 

**2.1.2 - Cenário com o uso de Stored Procedure**

Considere o mesmo cenário **utilizando uma Stored Procedure**
1. Criamos uma **Stored Procedure** contendo todas as consultas e a lógica de cálculo  
2. A aplicação chama a execução da Stored Procedure passando os parâmetros necessários  

```sql
EXEC dbo.usp_CalculateCustomerCredit @CustomerID = 10352;
```
3. No SQL Server, a Stored Procedure executa todas as consultas internamente  
4. Ao final da execução, o SQL Server retorna **apenas o resultado final** para a aplicação
   
**Conclusão:**  
Utilizando Stored Procedure, o tráfego de rede ocorre apenas em dois momentos:  
→ Primeiro: **Envio da chamada da Stored Procedure**  
→ Segundo: **Recebimento do resultado da execução**  

**Resultado:** Isso reduz significativamente a quantidade de comunicação entre aplicação e banco de dados

---

**2.2 - Compartilhamento de Código Facilita a Manutenção**  

→ Stored Procedures permitem **centralizar regras de negócio no banco de dados**  
→ Isso facilita a manutenção porque:  
- Várias aplicações podem utilizar a mesma procedure
- Alterações na lógica precisam ser feitas apenas em um lugar
- Evita duplicação de código em diferentes aplicações

---

**2.3 - Redução da Complexidade no Acesso ao Banco de Dados**

→ Sem Stored Procedures, a aplicação precisaria executar diversas consultas e manipular os resultados  
→ Aplicações podem executar operações complexas com **apenas uma chamada**  

Exemplo:
```sql
EXEC dbo.usp_ProcessCustomerOrder;
```

---

**2.4 - Aumento da Segurança** 

→ Stored Procedures permitem controlar melhor o acesso aos dados  
→ Em vez de conceder permissões diretamente nas tabelas, é possível conceder permissão apenas na procedure:

Exemplo:
```sql
GRANT EXECUTE ON dbo.usp_GetCustomerData TO AppUser;
```

→ Dessa forma, o usuário pode executar a procedure sem ter acesso direto às tabelas

---

**2.5 - Redução do Risco de SQL Injection**

→ SQL Injection ocorre quando um usuário mal-intencionado insere **código SQL malicioso** em entradas da aplicação  

Exemplo conceitual de código malicioso:
```sql
'; DROP TABLE Customers; --
```

→ Se a aplicação construir consultas SQL dinamicamente usando concatenação de strings, esse código pode ser executado  
→ Stored Procedures ajudam a reduzir esse risco quando utilizadas com **parâmetros**  

Exemplo:

```sql
CREATE PROCEDURE dbo.usp_GetCustomer
    @CustomerID INT
AS
BEGIN
    SELECT *
    FROM Customers
    WHERE CustomerID = @CustomerID;
END;
```

→ Como o parâmetro é tratado separadamente do comando SQL, o risco de injeção é reduzido

---

**2.6 -Possível Melhoria de Desempenho**

→ Stored Procedures podem melhorar o desempenho porque:  
- São **pré-compiladas e armazenadas no servidor**  
- Utilizam **planos de execução reutilizáveis**  
- Reduzem o tráfego de rede entre aplicação e banco

→ Isso pode resultar em execuções mais eficientes em cenários com alto volume de operações  

---

###3 - Estrutura de uma Stored Procedure

Uma **Stored Procedure** no SQL Server possui uma estrutura padrão utilizada para definir:  

- O **nome da procedure**
- O **schema ao qual ela pertence**
- Os **parâmetros de entrada ou saída**
- O **bloco de código SQL que será executado**

A criação normalmente utiliza `CREATE OR ALTER`, que permite criar a procedure caso ela não exista ou alterá-la caso já exista

**3.1 - Estrutura básica**

```sql
CREATE OR ALTER PROCEDURE SchemaName.ProcedureName
    @Parametro1 INT,
    @Parametro2 VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    -- Instruções SQL executadas pela procedure
END;
GO
```

**3.2 - Elementos da estrutura**

- **CREATE OR ALTER PROCEDURE**  
  Cria uma nova Stored Procedure ou altera uma existente

- **SchemaName**  
  Schema ao qual a procedure pertence (ex: `dbo`, `Sales`)

- **ProcedureName**  
  Nome da Stored Procedure

- **@Parametro**  
  Parâmetros utilizados para receber valores de entrada

- **AS**  
  Indica o início da definição do corpo da procedure

- **BEGIN ... END**  
  Delimita o bloco de instruções SQL executadas pela procedure

 - **SET NOCOUNT ON**  
  Evita o retorno de mensagens como `(X rows affected)`, melhorando a performance e reduzindo tráfego desnecessário entre o SQL Server e a aplicação

- **GO**  
  Separador de batches utilizado por ferramentas como **SSMS** e **Azure Data Studio**  

Stored Procedures podem conter praticamente qualquer instrução SQL, incluindo:  
- Consultas (`SELECT`)
- Manipulação de dados (`INSERT`, `UPDATE`, `DELETE`)
- Estruturas de controle (`IF`, `WHILE`)
- Controle de transações
- Tratamento de erros
- Cursores

Os exemplos práticos estão disponíveis no hands-on **scripts de exemplos** do projeto 

---

**Boas práticas:**  

- Utilizar prefixos próprios como **`usp_`** (user stored procedure)  
- Evitar utilizar **`sp_`** em procedures criadas pelo usuário  

**Exemplo recomendado:**  

```sql
CREATE PROCEDURE dbo.usp_UpdateCustomerStatus
AS
BEGIN
    -- lógica da procedure
END;
```
---

### 4 - Parâmetros em Stored Procedures

- Os **parâmetros** permitem que uma Stored Procedure receba valores externos no momento da execução, tornando-a reutilizável e dinâmica  
- Eles funcionam de forma semelhante a parâmetros em funções de linguagens de programação  

**4.1 - Declaração de parâmetros**  
Os parâmetros são definidos logo após o nome da procedure:

```sql
@Parametro1 INT,
@Parametro2 VARCHAR(50)
```

Cada parâmetro possui:

- Um nome (sempre iniciado com `@`)
- Um tipo de dado
- Opcionalmente um valor padrão

---

**4.1 - Tipos de parâmetros**

**4.1.1 - Parâmetros de entrada (Input)**  
São utilizados para enviar valores para dentro da procedure
- São os mais comuns
- Podem ser utilizados em filtros, cálculos e regras de negócio

---

**4.1.2 - Parâmetros com valor padrão**  
Permitem tornar o parâmetro opcional na execução  

```sql
@Status VARCHAR(20) = 'Active'
```

Se nenhum valor for informado, o valor padrão será utilizado  

---

**4.2 - Execução com parâmetros**  
Os parâmetros podem ser passados de duas formas:  

**4.2.1 - Forma posicional**

```sql
EXEC SchemaName.ProcedureName 10, 'Value'
```

**4.2.2 - Forma nomeada (recomendada)**

```sql
EXEC SchemaName.ProcedureName
    @Parametro1 = 10,
    @Parametro2 = 'Value'
```

A forma nomeada é mais segura e legível, principalmente quando há muitos parâmetros

---

**4.2.3 - Boas práticas**

- Utilizar nomes claros e descritivos para os parâmetros
- Evitar excesso de parâmetros na mesma procedure
- Preferir sempre a execução com parâmetros nomeados
- Definir valores padrão quando fizer sentido

---

**Observação**

Os parâmetros são fundamentais para:

- Reutilização de código
- Encapsulamento de regras de negócio
- Segurança (evitando SQL dinâmico desnecessário)

---
