# A0012 – Objetos de programação do SQL Server
> **Author:** Rafael Binda  
> **Created:** 2026-03-11  
> **Version:** 1.0 

---

## Descrição
 
---

## Hands-on  
 
---

## Observações
 
---

## 1 - VIEWS

**O que é uma View?**
- Uma **View** é uma **consulta armazenada no SQL Server**  
- Para o usuário, a view **aparece como se fosse uma tabela**, porém na realidade ela é apenas um **SELECT armazenado**  
- Quando uma consulta é executada sobre uma view, o SQL Server executa a consulta definida na view  

---

### 1.1 - Benefícios de usar Views
→ Simplificação da administração de permissões  
→ Views ajudam a simplificar a segurança do banco de dados 
→ Facilita desenvolvimento de relatórios e exportações de dados e integrações porque a lógica de consulta pode ficar **centralizada no banco**    

Exemplo:
1. Um relatório precisa exibir informações que exigem **5 JOINs entre tabelas**  
2. Se o acesso for concedido diretamente às tabelas, será necessário liberar permissões em todas elas  
3. Se for criada uma **view com essa consulta**, basta conceder acesso **apenas à view**  

→ Dessa forma, a administração de permissões fica **mais simples e mais segura**  

---

### 1.2 - Camada de abstração

Views criam uma **camada de abstração entre a aplicação e a estrutura das tabelas**  
Isso permite:
- Alterar tabelas internas sem impactar diretamente a aplicação
- Centralizar regras de consulta
- Padronizar acesso aos dados

---

### 1.3 - Características importantes das Views

- Uma view retorna **apenas um conjunto de resultados**
- Pode conter:
  - `JOIN`
  - `LEFT JOIN`
  - `RIGHT JOIN`
  - `UNION`
  - `GROUP BY`
  - `WHERE`
- Apesar disso, o resultado final é sempre **um único SELECT**

---

### 1.4 - Como o SQL Server executa uma View

**1.4.1 - Criação da view**

A view armazena **apenas a definição da consulta**

```sql
CREATE VIEW Sales.vw_CustomersOrders
AS
SELECT ...
FROM ...
JOIN ...
LEFT JOIN ...
```
---

**1.4.2 - Consulta na view**

```sql
SELECT *
FROM Sales.vw_CustomersOrders
```

---

**1.4.3 - Resolução dinâmica da view**

Quando executamos uma consulta na view, o SQL Server **não executa a view separadamente**  

Ele faz o seguinte:

1. Pega o `SELECT` que foi enviado pelo usuário  
2. Junta com a definição da view  
3. Gera **uma única consulta final**  

Ou seja, o SQL Server executa algo equivalente a:  

```sql
SELECT *
FROM (
    SELECT ...
    FROM ...
    JOIN ...
) AS vw
```

→ Esse processo é chamado de **resolução dinâmica da view**  

---

### 1.5 - Desempenho

Uma view **não melhora nem piora o desempenho por si só**  

O desempenho dependerá:

- Da consulta
- Dos índices
- Das tabelas envolvidas
- Do plano de execução

→ Views são principalmente uma **ferramenta de organização e abstração**  

---

### 1.6 - Estudo usando plano de execução

Para visualizar como o SQL Server executa uma consulta com view:

```
Query → Include Actual Execution Plan
CTRL + M
```

→ Depois execute a consulta  

**1.6.1 - Leitura do plano de execução**

O plano de execução deve ser interpretado:

- **da direita para a esquerda**
- **de cima para baixo**

→ Isso representa o fluxo de execução que o SQL Server utiliza para retornar os dados
 
---

## 2 - STORED PROCEDURE

### 2.1 - O que é uma Stored Procedure?

Uma **Stored Procedure** é um conjunto de comandos escritos em **Transact-SQL (T-SQL)** que são armazenados e executados diretamente no **SQL Server**  
Ela permite encapsular lógica de banco de dados que pode ser executada sempre que necessário  
As stored procedures podem:  
- Executar múltiplas instruções SQL
- Receber **parâmetros**
- Retornar **resultados**
- Executar **operações administrativas ou de manipulação de dados**

---

### 2.2 - Tipos de Stored Procedures

**2.2.1 - Stored Procedures de Sistema**

São procedures internas do SQL Server usadas para executar **tarefas administrativas**  
Características:  
- Criadas automaticamente pelo SQL Server
- Possuem prefixo **`sp_`**

Exemplo:

```sql
EXEC sp_helpdb;
```

---

**2.2.2 - Stored Procedures Estendidas**

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

**2.2.3 - Stored Procedures Locais**

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

**2.2.4 - Stored Procedures com Parâmetros**

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

**2.2.5 - Stored Procedures Temporárias**

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

### 2.3 - Vantagens e Benefícios do Uso de Stored Procedures

Algumas **vantagens** de utilizar **Stored Procedures** no SQL Server incluem:

- Reutilização de código
- Melhor organização da lógica do banco de dados
- Maior controle de permissões
- Redução do tráfego entre aplicação e banco
- Execução diretamente no servidor

---

Além dessas vantagens citadas anteriormente, existem alguns **benefícios práticos** importantes no uso de Stored Procedures, sendo possível listar:

**2.3.1 - Redução no Tráfego de Rede entre a Aplicação e o SQL Server**  

Um dos principais benefícios das Stored Procedures é a **redução da quantidade de comunicação entre a aplicação e o banco de dados**  
Exemplo:  

**2.3.1.1 - Cenário sem o uso de Stored Procedure**  

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

**2.3.1.2 - Cenário com o uso de Stored Procedure**

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

**2.3.2 - Compartilhamento de Código Facilita a Manutenção**  

→ Stored Procedures permitem **centralizar regras de negócio no banco de dados**  
→ Isso facilita a manutenção porque:  
- Várias aplicações podem utilizar a mesma procedure
- Alterações na lógica precisam ser feitas apenas em um lugar
- Evita duplicação de código em diferentes aplicações

---

**2.3.3 - Redução da Complexidade no Acesso ao Banco de Dados**

→ Sem Stored Procedures, a aplicação precisaria executar diversas consultas e manipular os resultados  
→ Aplicações podem executar operações complexas com **apenas uma chamada**  

Exemplo:
```sql
EXEC dbo.usp_ProcessCustomerOrder;
```

---

**2.3.4 - Aumento da Segurança** 

→ Stored Procedures permitem controlar melhor o acesso aos dados  
→ Em vez de conceder permissões diretamente nas tabelas, é possível conceder permissão apenas na procedure:

Exemplo:
```sql
GRANT EXECUTE ON dbo.usp_GetCustomerData TO AppUser;
```

→ Dessa forma, o usuário pode executar a procedure sem ter acesso direto às tabelas

---

**2.3.5 - Redução do Risco de SQL Injection**

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

**2.3.6 -Possível Melhoria de Desempenho**

→ Stored Procedures podem melhorar o desempenho porque:  
- São **pré-compiladas e armazenadas no servidor**  
- Utilizam **planos de execução reutilizáveis**  
- Reduzem o tráfego de rede entre aplicação e banco

→ Isso pode resultar em execuções mais eficientes em cenários com alto volume de operações  

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

## FUNCTIONS 
 

---

### FUNÇÕES ESCALARES 
 
---

### FUNÇÕES QUE RETORNAM TABELAS
 
---

## TRIGGERS
 

