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

## 1 - Views no SQL Server

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

## FUNCTIONS 
 

---

### FUNÇÕES ESCALARES 
 
---

### FUNÇÕES QUE RETORNAM TABELAS
 
---

## TRIGGERS
 

