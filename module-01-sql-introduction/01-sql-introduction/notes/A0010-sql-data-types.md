# A0010 – Sql Data Types 

> **Author:** Rafael Binda  
> **Created:** 2026-02-28  
> **Version:** 1.0 

---

## Descrição
Este documento apresenta os tipos de Dados no SQL Server

---

## Observações
`scripts\Q0005-sql-data-types.sql`  

---

## 1 - Tipos de dados STRING

No SQL Server, os tipos de dados para texto (caracteres) são divididos em dois grandes grupos:

- **Não-Unicode (baseados em Code Page)**
- **Unicode (UTF-16)**

### 1.1 - Tipos Não-Unicode (Code Page)
→ Armazenam caracteres utilizando **1 byte por caractere** (dependendo da collation)   
→ Indicado quando você tem certeza de que não precisará armazenar múltiplos idiomas  

--- 

**CHAR(n)**
- **Tamanho fixo**
- Sempre reserva exatamente `n` bytes
- Recomendado utilizar `VARCHAR` ao invés de `CHAR` quando o tamanho não for fixo
  
Exemplo:
```sql
CHAR(10)
```
→ Sempre ocupará **10 bytes**, mesmo que seja armazenado 'ABC'  
→ Tamanho máximo: **8.000 bytes**  

**Quando usar?**
→ Quando o tamanho da informação é previsível  
Exemplo: códigos fixos, siglas, UF, etc

---

**VARCHAR(n)**
- **Tamanho variável**
- Armazena apenas o necessário + 2 bytes de controle
- Pode consumir um pouco mais além dos 2 bytes de controle por causa da arquitetura da página

Exemplo:
```sql
VARCHAR(10)
```
- 'ABC' → 3 bytes
- 'ABCDEFGHIJ' → 10 bytes 

### Limites:
- `VARCHAR(n)` → até **8.000 bytes**
- `VARCHAR(MAX)` → até **2 GB**

---

**TEXT** **(Obsoleto)**
- **Tamanho variável**
- Pode armazenar até **2 GB**
- Armazenamento fora da estrutura principal da linha
- Deprecated (não utilizar em novos projetos)
- Recomendado utilizar `VARCHAR` ao invés de `TEXT`  
  
---

### 1.2 - Tipos Unicode (UTF-16)  

→ Armazenam caracteres usando **2 bytes por caractere**   
→ Necessário quando o sistema precisa suportar múltiplos idiomas, acentos especiais, caracteres asiáticos  
→ Tamanho máximo: **4.000 caracteres** (8.000 bytes)

---

**NCHAR(n)**
- **Tamanho fixo**
- Sempre ocupa `n × 2 bytes`

Exemplo:
```sql
NCHAR(10)
```
→ Sempre ocupará **20 bytes**

---
**NVARCHAR(n)**
- **Tamanho variável**
- Armazena:
  - (Quantidade de caracteres × 2 bytes)
  - + 2 bytes de controle

### Limites:
- `NVARCHAR(n)` → até **4.000 caracteres**
- `NVARCHAR(MAX)` → até **2 GB** mas só pode receber até 1GB de dados pois o espaço de armazenamento é de 2 bytes por caracter

Exemplo:

```sql
NVARCHAR(10)
```
- 'ABC' → 6 bytes
- 'ABCDEFGHIJ' → 20 bytes

---

**NTEXT** **(Obsoleto)**
- Tamanho variável
- Até **2 GB**
- Tipo descontinuado
- Não utilizar em novos desenvolvimentos
- Recomendado utilizar `NVARCHAR(MAX)` ao invés de `NTEXT`

---

**Boas Práticas**

- Utilizar `VARCHAR` ao invés de `CHAR` quando possível  
- Utilizar `NVARCHAR` apenas quando houver necessidade real de suporte a múltiplos idiomas  
- Evitar `TEXT` e `NTEXT` (tipos obsoletos)  
- Utilizar `VARCHAR(MAX)` ou `NVARCHAR(MAX)` para grandes volumes de texto
- Considerar o impacto de armazenamento ao utilizar Unicode pois consome o dobro de espaço

---

