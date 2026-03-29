# A0009 – Sql Data Querying 

> **Author:** Rafael Binda  
> **Created:** 2026-02-27  
> **Version:** 1.0 

---

## Descrição
Este documento apresenta os fundamentos de consulta de dados utilizando SELECT, filtros, agrupamentos e junções no SQL Server

---

## Hands-on
[Q0004 - SQL Server Data Querying](../scripts/Q0004-sql-data-querying.sql) 

---

## 1 - Consultando Dados — Introdução ao SELECT

→ A instrução **SELECT** é a base da consulta de dados no SQL Server  
→ Ela é utilizada para recuperar informações armazenadas em uma ou mais tabelas, retornando um conjunto de resultados (result set) em formato tabular  
→ Compreender corretamente o funcionamento do **SELECT** é essencial antes de avançar para junções, agregações e otimizações  

### Conceitos Fundamentais
→ O **SELECT** permite extrair dados de:  

- Uma única tabela
- Múltiplas tabelas (utilizando JOIN)
- Visões (views)
- Subconsultas
   

### SELECT List (Filtro Vertical)
→ Define quais colunas aparecerão no resultado  
→ É chamado de filtro vertical, pois controla as colunas retornadas  
→ Se nenhuma coluna específica for definida, pode-se usar **`*`**, que retorna todas as colunas da tabela  
→ Apesar de válido, o uso de **`SELECT *`** não é recomendado, pois:  
- Aumenta I/O desnecessariamente  
- Pode impactar performance  
- Pode quebrar aplicações caso a estrutura da tabela mude


### WHERE (Filtro Horizontal)
→ A cláusula **WHERE** define quais linhas serão retornadas  
→ É chamada de filtro horizontal, pois restringe registros (linhas) com base em uma condição lógica  
→ Sem a cláusula **WHERE**, todas as linhas da tabela serão retornadas


### FROM
→ A cláusula **FROM** define a origem dos dados  
→ Ela pode conter:
- Uma tabela
- Múltiplas tabelas
- Junções (JOIN)
- Subconsultas
 
### Menor Comando SELECT Possível 
→ Mesmo sendo sintaticamente correto, recomenda-se sempre especificar explicitamente as colunas desejadas  
Exemplo:
``` sql
SELECT * FROM tabela;
``` 
 
### Sintaxe Geral com as Principais Cláusulas

``` sql
SELECT [ALL | DISTINCT] <lista_de_colunas>      -- Filtro vertical
FROM <tabela_ou_origem>
JOIN <tabela> ON <condicao_join>
WHERE <condicao_de_pesquisa>                    -- Filtro horizontal
GROUP BY <lista_de_colunas>
HAVING <condicao_de_grupo>
ORDER BY <lista_de_colunas>; 
``` 

### Ordem Lógica de Processamento

→ Embora a instrução comece com **SELECT**, o SQL Server processa logicamente a consulta na seguinte ordem:
- 1º FROM 
- 2º JOIN 
- 3º WHERE 
- 4º GROUP BY 
- 5º HAVING 
- 6º SELECT
- 7º ORDER BY

→ Entender essa ordem ajuda a compreender:
- Por que aliases não funcionam no **WHERE**
- Por que agregações não podem ser usadas diretamente no **WHERE**
- Por que o **HAVING** filtra grupos e não linhas individuais
 
---

## 2 — GROUP BY

→ Permite fazer agrupamento de linhas  
→ A cláusula **GROUP BY** é utilizada para agrupar linhas que possuem valores iguais em determinadas colunas, permitindo a aplicação de funções de agregação sobre esses grupos  
→ Ela é fundamental quando precisamos transformar dados detalhados em dados consolidados  
→ O **GROUP BY** agrupa registros com base em uma ou mais colunas  
→ A cláusula **WHERE** é executada antes do **GROUP BY**, ou seja, O **WHERE** é aplicado antes do agrupamento, isso significa que:
- Apenas os registros que satisfazem a condição do **WHERE** serão considerados
- O agrupamento ocorre somente sobre o conjunto já filtrado
  
→ Ordem lógica relevante:
- 1º FROM
- 2º WHERE
- 3º GROUP BY

→ É usado por exemplo para:
- Agrupar vendas por cliente
- Agrupar pedidos por data
- Agrupar produtos por categoria
- Cada combinação única das colunas especificadas gera um grupo

### Usado para realizar cálculos (Agregações)
→ O **GROUP BY** normalmente é utilizado em conjunto com funções de agregação, como:
- COUNT() → Contagem de registros
- SUM() → Soma
- AVG() → Média
- MIN() → Menor valor
- MAX() → Maior valor

→ Sem o **GROUP BY**, essas funções retornam um único resultado global  
→ Com o **GROUP BY**, elas retornam um resultado para cada grupo  

### Regra Importante
→ Ao utilizar **GROUP BY** toda coluna presente no SELECT deve:
- Estar dentro de uma função de agregação ou
- Estar declarada na cláusula **GROUP BY**
→ Caso contrário, o SQL Server retornará erro  
→ Essa regra existe porque, ao agrupar, o banco precisa saber como consolidar cada coluna  

### Diferença entre WHERE e HAVING
→ Embora ambos filtrem dados, eles atuam em momentos diferentes:
- WHERE → Filtra linhas antes do agrupamento
- HAVING → Filtra grupos após o agrupamento

Resumo lógico:
``` sql
WHERE → filtra linhas
GROUP BY → cria grupos
HAVING → filtra grupos
```

---

## 3 - JOIN

→ A cláusula **JOIN** é utilizada para combinar dados de duas ou mais tabelas com base em uma relação entre colunas  
→ Ela permite consultar dados relacionados que estão distribuídos em tabelas diferentes  

### Sintaxes de JOIN
Existem duas formas de escrever junções no SQL Server:

**Sintaxe Antiga (Não Recomendada)**
- Também conhecida como sintaxe implícita
- Utiliza vírgula , para separar tabelas
- A condição de junção fica dentro do **WHERE**
- Mistura filtro com relacionamento
- Menor legibilidade e maior risco de erro

Exemplo:
``` sql
SELECT P.FirstName AS PRIMEIRO_NOME, SOH.CustomerID, SOD.OrderQty
FROM Person.Person P, Sales.SalesOrderHeader SOH, Sales.SalesOrderDetail SOD
WHERE SOH.SalesOrderID = SOD.SalesOrderID
AND SOH.CustomerID IS NOT NULL
AND SOD.OrderQty > 2;
``` 

**Sintaxe Padrão ANSI (Recomendada)**
- Utiliza a palavra-chave **JOIN**
- A condição de relacionamento fica no **ON**
- O **WHERE** é usado apenas para filtro
- Melhor organização e legibilidade

Exemplo:
``` sql
SELECT P.FirstName, SOH.CustomerID, SOD.OrderQty
FROM Sales.SalesOrderHeader SOH
INNER JOIN Sales.SalesOrderDetail SOD 
    ON SOH.SalesOrderID = SOD.SalesOrderID
INNER JOIN Sales.Customer C
    ON SOH.CustomerID = C.CustomerID
INNER JOIN Person.Person P
    ON C.PersonID = P.BusinessEntityID
WHERE SOD.OrderQty > 2;
```

### Tipos de JOIN

- **INNER JOIN** → Retorna apenas registros que possuem correspondência em ambas as tabelas.

- **LEFT JOIN** → Retorna todos os registros da tabela da esquerda, mesmo sem correspondência na direita

- **RIGHT JOIN** → Retorna todos os registros da tabela da direita, mesmo sem correspondência na esquerda

- **FULL JOIN** → Retorna todos os registros de ambas as tabelas, combinando quando houver correspondência

- **CROSS JOIN** → Retorna o produto cartesiano entre as tabelas (todas as combinações possíveis)


### Processamento dos JOIN (Ordem Lógica)
Dentro do fluxo geral da query, os JOINs são processados após o **FROM** e antes do **WHERE**





