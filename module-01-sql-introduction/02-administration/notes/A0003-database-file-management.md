# A0003 – Mantendo banco de dados

Author: Rafael Binda  
Created: 2026-03-29  
Version: 1.0

---

## Descrição

Este material aborda a manutenção e o gerenciamento de arquivos de banco de dados no SQL Server, incluindo redução de tamanho (shrink), crescimento de arquivos e movimentação de arquivos de dados e log

O foco é compreender como essas operações funcionam internamente, seus impactos no desempenho e em quais cenários devem ou não ser utilizadas em ambientes produtivos

---

## Hands-on  

—  

---

## 1.0 - Reduzindo o tamanho dos arquivos de dados

### 1.1 - DBCC SHRINKDATABASE

- Reduz todos os arquivos do banco, tanto de dados quanto de log
- O segundo parâmetro define o percentual de espaço livre que deve ser mantido

Exemplo:

```sql
DBCC SHRINKDATABASE (<databasename>, 10)
```

#### Significado do nome

- **DB** = Database
- **CC** = Consistency Check

#### O SHRINK apaga os dados?
→ Resposta: Não  
→ O SQL Server realiza uma operação de condensação dos dados no início do arquivo, liberando espaço no final para permitir a redução física

#### Boa prática

O SHRINK deve ser uma operação **pontual**, executada apenas quando realmente necessário

#### Como funciona internamente

- Um arquivo de dados é organizado em páginas de **8 KB**
- Um conjunto de 8 páginas forma uma **extent** de **64 KB**
- Se existirem páginas vazias no início ou no meio do arquivo, e páginas utilizadas mais ao final, o SQL Server pode mover essas páginas ocupadas para regiões mais ao início
- Com isso, o espaço livre fica concentrado no final do arquivo, tornando possível reduzir seu tamanho físico

#### Observação

Embora o comando não apague dados, ele pode causar fragmentação e gerar impacto de desempenho, principalmente em arquivos de dados

---

### 1.2 - AUTO_SHRINK

- A propriedade `AUTO_SHRINK` executa uma lógica semelhante ao `DBCC SHRINKDATABASE`
- A Propriedade `AUTO_SHRINK` executa `DBCC SHRINKDATABASE` com 10%, ou seja, o SQL Server tenta manter aproximadamente **10% de espaço livre**
- É executado a cada 30 minutos

#### Problemas do AUTO_SHRINK

- Gera maior overhead
- Pode causar fragmentação
- Degrada o desempenho
- Pode gerar o chamado **efeito sanfona**

##### Efeito sanfona

- O banco reduz o arquivo, mas depois precisa crescer novamente
- Esse ciclo de shrink e crescimento contínuo pode levar a alocações em áreas diferentes do disco, piorando a performance e a fragmentação

#### Exemplo de cenário

- Um banco utilizado há muitos anos
- Ocorreu uma grande exclusão de dados
- Após essa exclusão, ficou muito espaço livre que não será reutilizado em curto prazo

#### Observação prática

- Para **arquivo de dados**, é mais raro haver necessidade
- Para **arquivo de log**, a necessidade é mais comum

---

### 1.3 - DBCC SHRINKFILE

- Permite reduzir um arquivo específico
- Pode ser usado tanto para arquivos de dados quanto de log
- O segundo parâmetro define o tamanho final desejado em **MB**
- O SQL Server tentará chegar nesse tamanho, se possível

Exemplo:

```sql
DBCC SHRINKFILE (N'Database_data', 1000)
```

> O ideal é utilizar o **nome lógico do arquivo**, e não o caminho físico

#### Opções importantes

##### TRUNCATEONLY

- Apenas reduz o espaço livre no final do arquivo
- Não movimenta páginas internas
- Disponível para cenários específicos, principalmente em arquivos de dados com espaço livre ao final

Exemplo:

```sql
DBCC SHRINKFILE (N'Database_data', TRUNCATEONLY)
```

##### EMPTYFILE

- Esvazia um arquivo de dados
- Move as páginas para outros arquivos dentro do mesmo **FILEGROUP**
- Permite posteriormente remover o arquivo do banco

Exemplo:

```sql
DBCC SHRINKFILE (N'ExamplesDBFG_Data2', EMPTYFILE)
```

#### Cenário de uso do EMPTYFILE

Suponha um banco com múltiplos arquivos de dados no mesmo FILEGROUP e a necessidade de remover um deles

Passos conceituais:

1. Esvaziar o arquivo com `EMPTYFILE`
2. Garantir que os dados sejam movidos para os demais arquivos do mesmo FILEGROUP
3. Remover o arquivo com `ALTER DATABASE ... REMOVE FILE`

#### Observação

O `EMPTYFILE` não se aplica a arquivo de log

---

## 2.0 - Reduzindo o tamanho dos arquivos de log

### 2.1 - DBCC SHRINKFILE para arquivos de log

No arquivo de log, o comportamento é diferente do arquivo de dados

- Não ocorre movimentação de dados como em data files
- A redução depende da posição da porção ativa do log
- Pode acontecer de reduzir pouco ou até não reduzir nada

Exemplo:

```sql
DBCC SHRINKFILE (N'ExamplesDBFG_Log', 1000)
```

---

### 2.2 - Entendendo a limitação do shrink no log

O transaction log é organizado internamente em **VLFs** (Virtual Log Files)

Exemplo conceitual:

- VLOG1 = vazio
- VLOG2 = vazio
- VLOG3 = início da parte lógica ativa do log
- VLOG4 = final da parte lógica ativa do log
- VLOG5 = vazio
- VLOG6 = vazio

#### Importante

A porção ativa do log **não pode ser truncada**

Por isso:

- Se a parte ativa estiver próxima do final do arquivo, o shrink pode não reduzir quase nada
- Se a parte ativa estiver mais no início, pode haver mais espaço disponível para redução

Ou seja, o shrink do log depende diretamente da posição do **MINLSN** e da parte ativa do log

---

### 2.3 - Fluxo conceitual do shrink em log

Em um cenário simplificado:

1. Executa-se o `DBCC SHRINKFILE` no log
2. O SQL Server tenta remover VLFs inativos do final do arquivo
3. Partes finais inativas podem ser descartadas
4. Registros internos podem ser gravados para reorganizar a parte lógica
5. A porção ativa continua preservada
6. Após truncamento do log, pode surgir mais espaço elegível para shrink
7. Pode ser necessário executar o shrink novamente

---

### 2.4 - O que pode impedir a redução do log

Mesmo após executar shrink, o log pode continuar grande por vários motivos:

- Transação em aberto
- Backup de log não realizado, quando o banco está em `FULL` ou `BULK_LOGGED`
- Replicação
- Always On Availability Groups
- Outros recursos que dependem da retenção do log

---

### 2.5 - Importante sobre Recovery Model

- **Nunca** altere o banco de `FULL` para `SIMPLE` apenas para tentar reduzir o log, e depois volte para `FULL` como se nada tivesse acontecido
- Isso quebra a cadeia de backups de log

#### Consequência

Após essa alteração, os backups de log anteriores deixam de compor uma sequência contínua para recuperação point-in-time, até que um novo backup full seja realizado

---

## 3.0 - Aumentando o tamanho de arquivos

### 3.1 - Aumentar manualmente o tamanho de um arquivo

É possível aumentar manualmente o tamanho de um arquivo existente

Exemplo:

```sql
ALTER DATABASE <databasename>
MODIFY FILE
(
    NAME = N'Database_data',
    SIZE = 100MB
);
```

#### Observação

Essa operação é usada quando se deseja crescimento controlado, evitando múltiplos autogrowths pequenos

---

### 3.2 - Criando um novo arquivo

Também é possível adicionar um novo arquivo ao banco

Exemplo:

```sql
ALTER DATABASE <databasename>
ADD FILE
(
    NAME = N'ExamplesDBFG_Data3',
    FILENAME = N'C:\MSSQLSERVER\FG_DATA\ExamplesDBFG_Data3.ndf',
    SIZE = 100MB,
    MAXSIZE = 1GB,
    FILEGROWTH = 10MB
);
```

#### Observações

- O arquivo pode ser criado em outro volume
- Isso pode ajudar em organização e estratégia de I/O
- Em ambientes bem planejados, pode fazer parte da distribuição de arquivos entre filegroups

---

## 4.0 - Alterando a localização de arquivos

### 4.1 - Alterando a localização de arquivo de dados ou log

A alteração da localização física de arquivos gera indisponibilidade e exige planejamento

#### Motivações comuns

- Falta de espaço em disco em determinado volume
- Reorganização do storage
- Posicionamento em volumes diferentes para melhorar I/O

---

### 4.2 - Passo a passo conceitual para mover um arquivo

#### 1º - Obter nome lógico e nome físico do arquivo

```sql
SELECT
    name,
    physical_name
FROM sys.master_files
WHERE database_id = DB_ID('<databasename>');
```

#### 2º - Colocar o banco offline

```sql
ALTER DATABASE <databasename>
SET OFFLINE
WITH ROLLBACK IMMEDIATE;
```

#### 3º - Informar ao SQL Server a nova localização

Exemplo para um arquivo de log:

```sql
ALTER DATABASE <databasename>
MODIFY FILE
(
    NAME = N'ExamplesDBFG_Log2',
    FILENAME = N'C:\MSSQLSERVER\LOGNEWDISC\ExamplesDBFG_Log2.ldf'
);
```

#### 4º - Mover fisicamente o arquivo no sistema operacional

Essa etapa é feita fora do SQL Server, por exemplo, via Windows Explorer ou outro método administrativo.

#### 5º - Colocar o banco online novamente

```sql
ALTER DATABASE <databasename>
SET ONLINE;
```

---

## 5.0 - Observações finais

- Operações de SHRINK devem ser exceção, não rotina
- `AUTO_SHRINK` normalmente deve permanecer desabilitado
- Em arquivos de dados, shrink pode aumentar fragmentação
- Em arquivos de log, o shrink depende da posição da porção ativa
- Antes de reduzir log, é fundamental entender o motivo do crescimento
- Antes de mover arquivos, é importante validar dependências, janela de manutenção e estratégia de rollback
