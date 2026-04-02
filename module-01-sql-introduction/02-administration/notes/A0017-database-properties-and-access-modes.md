# A0017 – SQL Server Database Properties and Access Modes

Author: Rafael Binda  
Created: 2026-03-24  
Version: 1.0  

---

## Descrição

Este material aborda propriedades de bancos de dados no SQL Server relacionadas a nível de compatibilidade, modos de acesso, comportamento do banco e impactos operacionais e de desempenho 

- O SQL Server possui diversas outras propriedades de banco de dados  
- Este material aborda apenas algumas dessas propriedades  
- Novas propriedades serão adicionadas conforme evolução dos estudos  

---

## Hands-on  

[INST-Q0003 - SQL Version and Compatibility](../../../dba-scripts/SQL-instance-information/INST-Q0003-version-and-compatibility.sql)  
[INST-Q0006 - SQL Database Properties and Access Modes](../../../dba-scripts/SQL-instance-information/INST-Q0006-database-properties-and-access-modes.sql)

---


## 1. Propriedade COMPATIBILITY_LEVEL

Define como o banco de dados se comporta em relação às versões do SQL Server

### Características

- Controla funcionalidades disponíveis no banco  
- Afeta o comportamento do Query Optimizer  
- Não altera a versão do SQL Server (engine)

Exemplo definir compatibilidade com SQL Server 2019:  
```sql
    ALTER DATABASE AdventureWorks SET COMPATIBILITY_LEVEL = 150;
```

---

### Tabela de Compatibility Level

| Código | Versão SQL Server |
|--------|------------------|
| 160    | SQL Server 2022  |
| 150    | SQL Server 2019  |
| 140    | SQL Server 2017  |
| 130    | SQL Server 2016  |
| 120    | SQL Server 2014  |
| 110    | SQL Server 2012  |
| 100    | SQL Server 2008  |
| 90     | SQL Server 2005  |
| 80     | SQL Server 2000  |
| 70     | SQL Server 7.0   |

#### Significado do Código

- O valor do compatibility_level representa a versão do SQL Server cujo comportamento o banco irá seguir  

- Exemplo  
  - 150 → comportamento do SQL Server 2019  
  - 160 → comportamento do SQL Server 2022  

- Esse código não representa a versão (build) instalada do SQL Server  
- A versão real do servidor pode ser diferente e mais recente  

---

#### Diferença entre Compatibility Level e Versão do SQL Server

- Versão do SQL Server (engine)  
  Define os recursos instalados no servidor  

- Compatibility Level  
  Define como o banco se comporta  
  Afeta Query Optimizer, planos de execução e regras de linguagem  

---

#### Impacto no Desempenho

- Alterações podem gerar mudanças nos planos de execução  
- Pode haver melhoria ou pequena degradação de desempenho  
- Sempre testar antes de alterar em produção  

---

Exemplo prático:  
Um banco pode estar rodando em SQL Server 2022 com compatibility level 150  
O servidor é 2022, mas o comportamento do banco é equivalente ao SQL Server 2019  

---

## 2. Propriedade AUTO_CLOSE

A propriedade AUTO_CLOSE controla o fechamento automático do banco de dados quando não há conexões ativas

- No SQL Server Express o AUTO_CLOSE geralmente vem habilitado por padrão  
- Utilizado para economia de recursos em ambientes leves  

### Comportamento

- O banco é fechado quando a última conexão é encerrada  
- Recursos de memória são liberados  
- Ao receber nova conexão  
  - O banco precisa ser reaberto  
  - Estruturas internas são carregadas novamente  

---

### Impacto no Desempenho

- Pode causar degradação de performance
- Reabertura frequente do banco
- Recarregamento de dados em memória
- Maior tempo de resposta nas primeiras consultas
- Se o tempo de abertura for elevado e o timeout da aplicação for baixo o usuário pode receber erro de timeout  

---

### Migração entre Edições

- A configuração é mantida em backup e restore  

Exemplo:    
  - Banco criado no Express com AUTO_CLOSE ON  
  - Restaurado em Standard ou Enterprise o banco continuará com AUTO_CLOSE habilitado  

---

### Recomendações

- Não recomendado para ambientes de produção  
- Não recomendado para sistemas com acesso frequente  
- Pode ser utilizado em desenvolvimento ou cenários leves  

---

### Alteração da Propriedade

- Habilitar:

```sql
    ALTER DATABASE AdventureWorks SET AUTO_CLOSE ON;
```

- Desabilitar:
```sql
    ALTER DATABASE AdventureWorks SET AUTO_CLOSE OFF;
```

---

## 3. Propriedade READ_ONLY

Define o banco como somente leitura

### Comportamento

- Permite apenas SELECT  
- Bloqueia INSERT, UPDATE, DELETE e ALTER  
- Tentativas de escrita retornam erro  

---

### Impacto no Desempenho

- Pode melhorar desempenho em cenários de leitura  
- Reduz locks  
- Elimina overhead de escrita  
- Reduz I/O de modificações  

---

### Comportamento Interno

- Não há geração de novas entradas no transaction log  
- Reduz atividade de escrita em disco  
- Estruturas permanecem estáveis  

---

### Backup e Restore

- Backups funcionam normalmente  
- Restore mantém o banco como READ_ONLY  

---

### Filegroups

- Pode ser combinado com filegroups READ_ONLY  
- Cenário comum  
  - Dados históricos READ_ONLY  
  - Dados atuais READ_WRITE  

---

### Alteração da Propriedade

Habilitar o modo somente leitura:

```sql
ALTER DATABASE AdventureWorks SET READ_ONLY;
```

Habilitar o modo de escrita:
```sql
ALTER DATABASE AdventureWorks SET READ_WRITE;
```

#### Considerações Operacionais
- Pode exigir encerramento de conexões  
- Aplicações que escrevem irão falhar  
- Deve ser alinhado com o comportamento esperado da aplicação  

---

## 4. Propriedade RESTRICTED_USER

Restringe o acesso ao banco para usuários privilegiados

### Comportamento

- Permite acesso apenas para  
  - sysadmin  
  - db_owner  
  - dbcreator  

- Usuários comuns não conseguem se conectar  

---

### Diferença entre modos de acesso

- MULTI_USER   
→ Permite múltiplas conexões  

- SINGLE_USER  
→ Permite apenas uma conexão  

- RESTRICTED_USER  
→ Permite múltiplas conexões, mas apenas de usuários privilegiados  

---

### Cenários de Uso

- Manutenção controlada com múltiplos administradores  
→ Permite que mais de um DBA acesse o banco simultaneamente sem interferência de usuários comuns  

- Análise de problemas sem interferência de usuários finais  
→ Garante ambiente controlado evitando impacto de consultas da aplicação  

- Preparação para alterações estruturais  
→ Facilita mudanças com acesso restrito e maior controle do ambiente  

---

### Impacto Operacional

- Aplicações podem falhar ao tentar se conectar  
- Usuários sem permissão recebem erro  
- Pode exigir coordenação com times de aplicação  

---

### Alteração da Propriedade

Habilitar o modo de acesso restrito:

```sql
ALTER DATABASE AdventureWorks SET RESTRICTED_USER;
```

Habilitar o modo multiusuário:

```sql
ALTER DATABASE AdventureWorks SET MULTI_USER;
```
---

## 5. Consulta de Propriedades do Banco

Permite visualizar configurações e características do banco

### sys.databases  

- Pode ser utilizada para consultar propriedades gerais dos bancos de dados
- A coluna compatibility_level mostra o nível de compatibilidade configurado para cada banco
  
```sql
    SELECT 
    database_id,
    name,
    compatibility_level,
    state_desc,
    user_access_desc,
    is_read_only,
    is_auto_close_on
    FROM sys.databases;
```

---

### sys.master_files  

- Pode ser utilizada em conjunto com sys.databases para relacionar propriedades do banco com seus arquivos físicos

```sql
    SELECT 
    database_id,
    file_id,
    name,
    type_desc,
    physical_name,
    size
    FROM sys.master_files;
```

#### Informações importantes sobre sys.master_files

- type_desc  
→ ROWS representa arquivos de dados  
→ LOG representa arquivos de log  

- size  
→ Representa a quantidade de páginas alocadas para o arquivo  
→ Cada página possui 8 KB  

- Para obter o tamanho aproximado em MB, pode-se utilizar a fórmula  

```code
  size * 8 / 1024  
```

---

### Exemplo de consulta combinada
- Essa consulta permite visualizar, em conjunto, o banco de dados, seu nível de compatibilidade e os arquivos associados

```sql
    SELECT 
    d.name,
    d.compatibility_level,
    mf.name AS file_name,
    mf.type_desc,
    mf.physical_name,
    mf.size
    FROM sys.databases AS d
    INNER JOIN sys.master_files AS mf
    ON d.database_id = mf.database_id;
```

---

### DATABASEPROPERTYEX

Função utilizada para consultar propriedades específicas do banco  
Permite consultar propriedades individuais de forma direta 

Exemplo:
```sql
    SELECT DATABASEPROPERTYEX('AdventureWorks', 'Collation');
```

---

## Observações

- As propriedades são configuradas por banco de dados  
- Podem ser alteradas via SSMS ou T-SQL  
- São fundamentais para administração, troubleshooting e performance tuning  
