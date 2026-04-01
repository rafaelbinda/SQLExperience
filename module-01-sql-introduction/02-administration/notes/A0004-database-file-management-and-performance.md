# A0004 – Database File Management and Performance  
Author: Rafael Binda  
Created: 2026-03-31  
Version: 1.0  

---

## Descrição  

Este material aborda conceitos avançados de gerenciamento de arquivos no SQL Server com foco em desempenho, organização física, TempDB, Instant File Initialization (IFI) e criptografia com Transparent Data Encryption (TDE)

O entendimento desses tópicos é essencial para administração eficiente, otimização de I/O e resolução de problemas em ambientes de produção

---

Hands-on  


---

## 1 – Posicionamento dos Arquivos  

A organização física dos arquivos influencia diretamente o desempenho do SQL Server

### Boas práticas:

- Manter o arquivo de paginação do Windows em disco separado  
- Separar arquivos de dados e log  
- Separar o TempDB dos bancos de usuários  
- Distribuir arquivos em múltiplos discos para melhor throughput  

### Explicação técnica:

- Arquivos de log (LDF) utilizam escrita sequencial (sequential write)  
- Arquivos de dados (MDF/NDF) utilizam leitura e escrita aleatória (random I/O)  
- Misturar ambos no mesmo disco gera contenção de I/O  

### Estrutura recomendada:

1. Windows + Page File  
2. Arquivos de dados (MDF / NDF)  
3. Arquivos de log (LDF)  
4. TempDB  
5. Área de manutenção (backups, importações, ...)  

---

## 2 – Instant File Initialization (IFI)  

Por padrão, ao criar ou expandir arquivos, o SQL Server preenche o espaço com zeros (zeroing), o que pode impactar diretamente o tempo de criação e crescimento dos arquivos

O Instant File Initialization (IFI) permite que arquivos de dados sejam criados e expandidos sem esse preenchimento, reduzindo significativamente o tempo dessas operações

### Funcionamento

- Aplicável apenas a arquivos de dados (MDF / NDF)  
- Arquivos de log (LDF) continuam exigindo zeroing  
- SQL Server 2022 trouxe melhorias no crescimento do log, porém não equivale ao IFI completo  

### Configuração

- Pode ser habilitado durante a instalação  
- Após instalação: via **Local Security Policy (Windows)**  
  - Permissão: *Perform volume maintenance tasks*  

### Abordagem prática para dimensionamento de arquivos

Para evitar crescimento frequente e garantir melhor desempenho, recomenda-se definir o tamanho inicial dos arquivos com base no comportamento real do ambiente

#### Passo a passo:

1. Iniciar o SQL Server e monitorar o comportamento do banco  
   - Observar o crescimento dos arquivos durante a operação normal  
   - Identificar até que ponto os arquivos crescem e se estabilizam  

2. Analisar o crescimento observado  
   - Exemplo:
     - Arquivo de dados estabiliza em ~500 MB  
     - Arquivo de log estabiliza em ~100 MB  

3. Ajustar o tamanho inicial (SIZE)  
   - Configurar valores ligeiramente acima do uso observado  
   - Aplicar tanto para arquivos de dados quanto para log  

### Benefícios dessa abordagem

- Evita crescimento sequencial logo após o startup  
- Reduz fragmentação no disco  
- Melhora o desempenho inicial do servidor  
- Diminui overhead causado por autogrowth  

### Boas práticas

- Definir tamanho inicial adequado para arquivos  
- Evitar crescimento por porcentagem  
- Preferir crescimento fixo em MB  
- Planejar crescimento ao invés de depender de autogrowth  

---

## 3 – TempDB  

O TempDB é um banco de sistema crítico utilizado como área temporária

### Características:

- Recriado a cada inicialização  
- Utilizado para:
  - Controle de concorrência  
  - Execução de consultas  
  - Triggers  
  - Tabelas temporárias  

### PAGELATCH (explicação)

PAGELATCH é um tipo de espera (wait) relacionado à contenção em memória, não em disco  
Ocorre quando múltiplas sessões tentam acessar estruturas internas do SQL Server ao mesmo tempo

#### Estruturas internas:

- PFS (Page Free Space): controla espaço livre nas páginas  
- GAM (Global Allocation Map): indica quais extents estão livres  
- SGAM (Shared Global Allocation Map): controla extents compartilhados  

Essas estruturas podem gerar contenção em ambientes com alta concorrência

### Boas práticas:

- Separar o TempDB em disco dedicado  
- Criar múltiplos arquivos de dados  
- Manter arquivos com mesmo tamanho e crescimento  

| CPU | Arquivos recomendados |
|-----|----------------------|
| Até 8 | 1 por CPU |
| Acima de 8 | 1 a cada 4 CPUs |

### Dimensionamento do TempDB

1. Monitorar o comportamento após inicialização  
2. Identificar crescimento estabilizado  
3. Ajustar SIZE com base no uso real  

Exemplo:

- Dados: 500 MB  
- Log: 100 MB  

Configurar valores ligeiramente acima  

### Benefícios:

- Evita crescimento sequencial após startup  
- Reduz fragmentação  
- Melhora desempenho inicial  

---

## 4 – Autogrowth e Capacity Planning  

O crescimento automático deve ser tratado como exceção, não regra

### Boas práticas:

- Evitar crescimento por porcentagem  
- Preferir crescimento fixo em MB  
- Definir tamanho inicial adequado  

### Problemas comuns:

- Crescimento frequente → impacto de performance  
- Fragmentação de arquivos  
- No log: aumento excessivo de VLFs  

---

## 5 – Transparent Data Encryption (TDE)  

TDE permite criptografar dados em repouso no banco de dados

### Características:

- Transparente para aplicações  
- Não criptografa dados em trânsito  
- Impacto em CPU  

### Hierarquia de criptografia:

```code
Windows DPAPI  
↓  
Service Master Key  
↓  
Database Master Key  
↓  
Database Encryption Key  
```

### Configuração:

#### 1 – Criar master key

```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'StrongPassword';
```

#### 2 – Criar certificado

```sql
CREATE CERTIFICATE DBCriptCert 
WITH SUBJECT = 'Certificado para criptografia';
```

#### 3 – Criar encryption key

```sql
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE DBCriptCert;
```

#### 4 – Habilitar TDE

```sql
ALTER DATABASE SeuBanco SET ENCRYPTION ON;
```

---

## 6 – Backup e Restore com TDE  

### Exportar certificado

```sql
BACKUP CERTIFICATE DBCriptCert 
TO FILE = 'D:\certificados\DBScriptCert.cer'
WITH PRIVATE KEY 
(
    FILE = 'D:\certificados\DBScriptCert.key',
    ENCRYPTION BY PASSWORD = 'Password'
);
```

### Importar certificado

```sql
CREATE CERTIFICATE DBCriptCert 
FROM FILE = 'D:\certificados\DBScriptCert.cer'
WITH PRIVATE KEY 
(
    FILE = 'D:\certificados\DBScriptCert.key',
    ENCRYPTION BY PASSWORD = 'Password'
);
```

### Erro comum:

Msg 33111  
Cannot find server certificate  

---

## 7 – Considerações Importantes  

- Planejar crescimento dos arquivos  
- TempDB mal configurado gera contenção  
- Log mal dimensionado impacta recovery  
- Sem certificado TDE → banco não pode ser restaurado  

---
