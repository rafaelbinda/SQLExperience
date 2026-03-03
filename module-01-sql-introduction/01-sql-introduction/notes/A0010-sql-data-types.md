# A0010 – Sql Data Types 

> **Author:** Rafael Binda  
> **Created:** 2026-02-28  
> **Version:** 2.0 

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

## 2 - Tipos de dados Numéricos

Os tipos de dados numéricos no SQL Server são divididos em quatro categorias principais:

- Inteiros
- Decimais (Precisos)
- Aproximados (Ponto Flutuante)
- Monetários e Lógicos

---

### 2.1 - Tipos Inteiros
- **INT** é o tipo inteiro mais utilizado
- **BIGINT** deve ser usado apenas quando houver necessidade real de grande volume
- Escolher o tipo correto ajuda a economizar espaço e melhorar performance

Armazenam apenas números inteiros (sem casas decimais)

| Tipo      | Tamanho  | Intervalo                                              |
|-----------|----------|--------------------------------------------------------|
| TINYINT   | 1 byte   | 0 a 255 (não aceita negativos)                         |
| SMALLINT  | 2 bytes  | -32.768 a 32.767                                       |
| INT       | 4 bytes  | -2.147.483.648 a 2.147.483.647                         |
| BIGINT    | 8 bytes  | -9.223.372.036.854.775.808 a 9.223.372.036.854.775.807 |

---

### 2.2 - Tipos Decimais (Precisos)

Usados quando é necessário controle exato sobre casas decimais

- **DECIMAL(p, s)**  
- **NUMERIC(p, s)**

- **NUMERIC** é sinônimo de **DECIMAL**
- Exigem definição de:  
→ **Precisão (p)** → Total de dígitos  
→ **Escala (s)** → Quantidade de dígitos após a vírgula  

Exemplo:
```sql
DECIMAL(16,6)
```
Significa:  
→ Total de 16 dígitos  
→ 6 dígitos reservados para a parte decimal  

Exemplo de valor máximo:
```
9999999999.999999
```
### Armazenamento
→ O tamanho em bytes varia conforme a precisão:
| Precisão | Bytes |
|----------|-------|
| 1–9      | 5 bytes |
| 10–19    | 9 bytes |
| 20–28    | 13 bytes |
| 29–38    | 17 bytes |

---

### 2.3 - Tipos Aproximados (Ponto Flutuante)

→ Utilizados para cálculos científicos ou estatísticos onde pequenas imprecisões são aceitáveis  
→ Nunca utilizar **FLOAT** ou **REAL** para:  
- Valores financeiros
- Controle contábil
- Cálculo tributário
- Comparações exatas

---

**FLOAT**
- Armazena valores aproximados
- Pode ter precisão de até 53 bits
- Ocupa 4 bytes (FLOAT(24)) ou 8 bytes (FLOAT(53))

Exemplo:
```sql
FLOAT(53)
```
---

**REAL**
- Equivalente a FLOAT(24)
- Ocupa 4 bytes (32 bits)

--- 
**Por que (24) e (53)?**  
Porque no SQL Server, os tipos **REAL** e **FLOAT** são baseados no padrão `IEEE 754 – Floating Point Arithmetic`  
- 24 bits = precisão de single precision (32 bits)  
- 53 bits = precisão de double precision (64 bits)  
→ REAL = ~7 dígitos decimais de precisão  
→ FLOAT(53) = ~15 a 16 dígitos decimais de precisão  

→ A sintaxe é:
```sql
FLOAT(n)
REAL(n)
```
Onde:  
→ n = número de bits de precisão mantissa  
→ Pode variar de 1 até 53  

**Regra do SQL Server**  
→ O SQL Server simplifica assim:  
|Valor de n |	Armazenamento |	Equivalente |
|-----------|---------------|-------------|
| 1 a 24    | 4 bytes       |    REAL     |
| 25 a 53   | 8 bytes       |  FLOAT(53)  |
 
→ Ou seja:
- FLOAT(24) → ocupa 4 bytes
- FLOAT(53) → ocupa 8 bytes

**E se não declarar nada?**    
- **REAL** (sem parâmetro) = FLOAT(24)  
→ 4 bytes  
→ Máxima precisão possível  
→ Single precision  

- **FLOAT** (sem parâmetro) = FLOAT(53)  
→ O SQL Server assume automaticamente **FLOAT(53)**  
→ 8 bytes  
→ Máxima precisão possível  
→ Double precision  

**Resumo prático**
|Declaração	|       Armazena	  |Bytes        |
|-----------|-------------------|-------------|
|REAL	      | FLOAT(24)	        |4 bytes      |
|FLOAT(24)  |	Single precision	|4 bytes      |
|FLOAT(53)  | Double precision	|8 bytes      |
|FLOAT	    | Assume 53	        |8 bytes      |   

--- 

**Exemplo de Imprecisão com FLOAT e REAL**  
Tipos aproximados como FLOAT e REAL utilizam representação binária (IEEE 754), o que pode gerar pequenas imprecisões em operações matemáticas  

Exemplo:
```sql
DECLARE @a FLOAT = 0.1
DECLARE @b FLOAT = 0.2

IF (@a + @b = 0.3)
    SELECT 'Verdadeiro'
ELSE
    SELECT 'FALSO'

--ou

DECLARE @a REAL = 0.1
DECLARE @b REAL = 0.2

IF (@a + @b = 0.3)
    SELECT 'Verdadeiro'
ELSE
    SELECT 'FALSO'

```  

**Resultado: FALSO**

Por que isso acontece?  

**REAL = FLOAT(24)**    
→ Usa apenas 24 bits de mantissa    
→ Tem cerca de 7 dígitos de precisão  

**FLOAT = FLOAT(53)**  
→ Tem cerca de 15–16 dígitos de precisão  

→ 0.1 e 0.2 não possuem representação binária exata  
→ Eles são armazenados como valores aproximados  
→ A soma resulta em algo próximo de 0.3, mas não exatamente 0.3  
→ Como a comparação exige igualdade exata, **o IF retorna FALSO**  

**O que acontece internamente?**  

**REAL**
→ O valor armazenado para 0.1 vai ser `0.10000000149011612`  
→ O valor armazenado para 0.2 vai ser `0.20000000298023224`  
→ Somando: `0.30000000447034836`  
**Então: 0.30000000447034836 ≠ 0.3**  

**FLOAT**
→ O valor armazenado para 0.1 vai ser `0.1000000000000000055511151231257827021181583404541015625`   
→ O valor armazenado para 0.2 vai ser `0.200000000000000011102230246251565404236316680908203125`    
→ Somando: `0.3000000000000000444089209850062616169452667236328125`    
**Então: 0.3000000000000000444089209850062616169452667236328125 ≠ 0.3**  

**REAL** gera erro maior porque:  
→ Tem menos bits  
→ Arredonda mais cedo  

**FLOAT(53):**  
→ Tem mais bits  
→ Aproxima melhor  
→ Mas ainda não é exato  

**Conclusão técnica**  
→ REAL ≠ FLOAT(53)  
→ Ambos seguem IEEE 754  
→ Ambos são aproximados  
→ FLOAT(53) é mais preciso  
→ Nenhum representa 0.1 exatamente  

---

### 2.4 - Tipos Monetários

**MONEY**
- Tamanho de armazenamento 8 bytes
- 4 casas decimais fixas
- Intervalo de `-922.337.203.685.477,5808` até `922.337.203.685.477,5807`

---

**SMALLMONEY**
- Tamanho de armazenamento 4 bytes  
- 4 casas decimais fixas  
- Intervalo de `-214.748,3648` até `214.748,3647`
- 
---

### Atenção
- **MONEY** e **SMALLMONEY** são limitados a 4 casas decimais
- Podem causar arredondamentos indesejados
- **Recomendação:** Preferir `DECIMAL` para valores financeiros

---

### 3 - Tipo Lógico

**BIT**
- Aceita apenas `0`, `1` ou `NULL`
- Utilizado para representar verdadeiro/falso
- O SQL Server otimiza armazenamento de múltiplas colunas BIT internamente
- Ele não ocupa 1 byte por coluna necessariamente pois o SQL Server faz uma otimização interna chamada **Bit Packing**

### O que é Bit Packing?

Em vez de armazenar cada coluna BIT ocupando 1 byte inteiro, o SQL Server:  
→ Agrupa várias colunas BIT  
→ Compacta elas dentro de um único byte  

**Regra de armazenamento**
→ A cada 8 colunas BIT consomem apenas 1 byte  

|Quantidade de colunas BIT|Espaço usado  |
|-------------------------|--------------|
|1 a 8 colunas BIT	      |1 byte        |
|9 a 16 colunas BIT	      |2 bytes       |
|17 a 24 colunas BIT	    |3 bytes       |
|        ...	            |   ...        |


**Exemplo 1**  
```sql
CREATE TABLE Exemplo2 (
    Flag1 BIT,
    Flag2 BIT,
    Flag3 BIT,
    Flag4 BIT,
    Flag5 BIT,
    Flag6 BIT,
    Flag7 BIT,
    Flag8 BIT
)
```
→ Resultado: **Espaço usado 1 Byte**  

**Exemplo 2**  
```sql
CREATE TABLE Exemplo2 (
    Flag1 BIT,
    Flag2 BIT,
    Flag3 BIT,
    Flag4 BIT,
    Flag5 BIT,
    Flag6 BIT,
    Flag7 BIT,
    Flag9 BIT
)
```
→ Resultado: **Espaço usado 2 Bytes**  

**Por que isso acontece?**  
Porque:  
→ Um byte tem 8 bits  
→ Cada coluna BIT usa apenas 1 bit  
→ Então o SQL Server armazena até 8 colunas dentro do mesmo byte  

**Importante**  
Isso só funciona porque:  
→ BIT precisa apenas de 1 ou 0  
→ O engine gerencia isso internamente  
→ Não é visível para o usuário  

---

**E o NULL?**  
Se a coluna permitir NULL:  
→ O controle de NULL é feito na null bitmap da linha  
→ Isso é separado do armazenamento do valor  

**O que é a Null Bitmap?**  
→ Ela existe sempre que a tabela tem pelo menos uma coluna que permite NULL  
→ Toda linha no SQL Server possui uma estrutura interna parecida com isso:  

**| Row Header | Fixed-Length Data | Null Bitmap | Variable-Length Data | Variable Column Offset Array |**  

→ A Null Bitmap é uma área da linha que:   
- Indica quais colunas permitem NULL  
- Indica quais colunas estão NULL naquela linha  

**Se uma coluna BIT permite NULL:**  
Ela tem duas estruturas:  
- O valor 0 ou 1 → armazenado no grupo compactado de bits  
- O estado NULL → armazenado na null bitmap  
Ou seja:  
→ O NULL não ocupa espaço dentro do byte compactado dos BIT  
→ Ele é controlado separadamente  

**Conclusão**  
Quando dizemos `O controle de NULL é feito na null bitmap`, significa que:  
→ O SQL Server não armazena NULL como valor físico  
→ Ele usa um bit indicando ausência de valor  
→ Esse bit fica numa área específica da linha  


---









