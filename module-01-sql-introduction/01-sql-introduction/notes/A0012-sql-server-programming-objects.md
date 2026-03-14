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

Algumas vantagens de usar stored procedure são:  
- Reutilização de código
- Melhor organização da lógica do banco
- Maior controle de permissões
- Redução do tráfego entre aplicação e banco
- Execução diretamente no servidor

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

### Resumo

| Tipo | Prefixo | Uso |
|---|---|---|
| Sistema | `sp_` | tarefas administrativas internas |
| Estendida | `xp_` | integração externa (não recomendado) |
| Local | definido pelo usuário | lógica de negócio e automação |

---

# Observação

Boas práticas recomendam:

- utilizar prefixos próprios como **`usp_`** (user stored procedure)
- evitar utilizar **`sp_`** em procedures criadas pelo usuário

Exemplo recomendado:

```sql
CREATE PROCEDURE dbo.usp_UpdateCustomerStatus
AS
BEGIN
    -- lógica da procedure
END;
```


## FUNCTIONS 
 

---

### FUNÇÕES ESCALARES 
 
---

### FUNÇÕES QUE RETORNAM TABELAS
 
---

## TRIGGERS
 

