# A0020 – Transparent Data Encryption (TDE)  
Author: Rafael Binda  
Created: 2026-04-04  
Version: 1.0  

---

## Descrição  

Este material aborda o recurso Transparent Data Encryption (TDE) no SQL Server, incluindo conceitos, funcionamento, arquitetura de criptografia, configuração prática e boas práticas de administração  

O entendimento do TDE é essencial para garantir proteção de dados em repouso, mitigar riscos de exposição de dados sensíveis e atender requisitos de segurança em ambientes corporativos  

Além disso, o uso de criptografia como o TDE contribui para a conformidade com a LGPD (Lei Geral de Proteção de Dados – Lei nº 13.709/2018), especialmente no que diz respeito à proteção de dados pessoais contra acesso não autorizado, perda ou vazamento de informações  

Embora o TDE não substitua controles de acesso, auditoria ou criptografia em trânsito, ele é um componente fundamental dentro de uma estratégia de segurança da informação alinhada às boas práticas e às exigências legais  

---

## 1 – O que é TDE  

O Transparent Data Encryption (TDE) é um recurso utilizado para criptografar os dados armazenados em disco no SQL Server  
A criptografia ocorre de forma transparente para aplicações e usuários, sem necessidade de alterações no código  

### Objetivo  

- Proteger dados em repouso  
- Evitar acesso indevido a arquivos físicos  
- Atender requisitos de segurança e compliance  

---

## 2 – Funcionamento  

O TDE realiza a criptografia no nível de página antes da gravação em disco e descriptografa durante a leitura  

### Características  

- Criptografia aplicada em arquivos de dados (MDF / NDF)  
- Criptografia aplicada no arquivo de log (LDF)  
- Criptografia aplicada em backups  
- Transparente para aplicações  
- Não criptografa dados em trânsito  

### Disponibilidade  

- SQL Server 2008+  
- Enterprise (inicialmente)  
- Standard a partir de 2016  

### Impacto  

- Pequeno overhead de CPU  
- Baixo impacto em I/O  
- Sem impacto na aplicação  

---

## 3 – Arquitetura Interna – Encryption Hierarchy  

### Cadeia de criptografia  

1. DPAPI (Windows)  
2. Service Master Key (SMK)  
3. Database Master Key (DMK)  
4. Certificado  
5. Database Encryption Key (DEK)  

---

### Fluxo de criptografia (visão hierárquica)

1. DPAPI (Windows)  
   ↓  
2. Service Master Key (SMK)  
   ↓  
3. Database Master Key (DMK)  
   ↓  
4. Certificado  
   ↓  
5. Database Encryption Key (DEK)  
   ↓  
6. Dados (MDF / NDF / LDF / Backups)  

---

### Explicação do fluxo  

- DPAPI (Windows)  
  - Protege a Service Master Key  
  - Vinculada ao sistema operacional  

- Service Master Key (SMK)  
  - Criada automaticamente  
  - Protegida pelo DPAPI  

- Database Master Key (DMK)  
  - Protege certificados e chaves  

- Certificado  
  - Protege a DEK  
  - SQL Server atua como CA (Certificate Authority)  

- Database Encryption Key (DEK)  
  - Chave simétrica que criptografa os dados  
  - Utiliza AES  

- Dados  
  - MDF, NDF, LDF e backups  

---

### Observações  

- O SQL Server atua como CA (Certificate Authority)  
  - CA é responsável por emitir e gerenciar certificados  
  - Pode ser interna (SQL Server) ou externa  
- Hierarquia protege contra exposição direta  
- Múltiplas camadas aumentam segurança  
- Certificados são protegidos pela DMK  
- **Perda do certificado = perda do banco** 

---

## 4 – Tipos de chave envolvidos  

- Chave simétrica (DEK – Database Encryption Key)  

  - Utilizada para criptografar os dados do banco  
  - Alta performance para operações de leitura e escrita  
  - Utiliza algoritmos eficientes como AES  

  Observação:  

  - Utiliza a mesma chave para criptografar e descriptografar  
  - É ideal para grandes volumes de dados devido ao baixo custo computacional  



### Sobre criptografia simétrica  

- A alta performance da DEK ocorre porque utiliza algoritmos como AES (Advanced Encryption Standard)  

- O AES é um algoritmo de criptografia simétrica amplamente utilizado no mercado  

  - Trabalha com blocos de dados (block cipher)  
  - Suporta tamanhos de chave: 128, 192 e 256 bits  
  - É considerado seguro, eficiente e padrão de mercado  

- No SQL Server, os algoritmos disponíveis incluem:  

  - AES_128  
  - AES_192  
  - AES_256 (mais recomendado)  
  - TRIPLE_DES (menos recomendado – legado)  

- A criptografia simétrica é mais rápida porque:  

  - Utiliza uma única chave  
  - Possui menor overhead computacional  
  - É otimizada para operações contínuas de I/O  

---

- Certificado (criptografia assimétrica)  

  - Utilizado para proteger (criptografar) a DEK  
  - Baseado em criptografia assimétrica (par de chaves)  

  - Estrutura:  

    - Chave pública → utilizada para criptografar  
    - Chave privada → utilizada para descriptografar  

  - A chave privada é o elemento crítico para acesso aos dados  
  - Sem ela, não é possível recuperar a DEK e, consequentemente, os dados  

  Observação:  

  - Criptografia assimétrica possui maior custo computacional  
  - Por isso, não é utilizada diretamente nos dados  
  - É usada apenas para proteger chaves menores (como a DEK)  

---

### Sobre criptografia assimétrica  

- Baseada em dois elementos matematicamente relacionados (chave pública e privada)  

- Vantagens:  
  - Maior segurança no armazenamento e distribuição de chaves  
  - Permite separar quem criptografa de quem descriptografa  

- Desvantagens:  
  - Mais lenta que criptografia simétrica  
  - Não escalável para grandes volumes de dados  

---

### Relação entre as chaves (visão arquitetural)  

O TDE combina os dois modelos para equilibrar performance e segurança  

- A DEK (simétrica):  
  - Responsável por criptografar os dados  
  - Otimizada para performance  

- O certificado (assimétrico):  
  - Responsável por proteger a DEK  
  - Focado em segurança  

---

### Conclusão  

- Criptografia simétrica → usada onde há volume e performance  
- Criptografia assimétrica → usada onde há necessidade de proteção da chave  

Essa combinação permite que o TDE seja:

- Seguro  
- Performático  
- Escalável   

---

## 5 – Habilitando TDE  

### Sequência  

1. Criar DMK  
2. Criar certificado  
3. Criar DEK  
4. Ativar criptografia  

---

### 5.1 – Criar Database Master Key  

```sql
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'Password';
```

---

### 5.2 – Criar certificado  

```sql
CREATE CERTIFICATE DBCriptCert
WITH SUBJECT = 'certificado para DBScript';
```

---

### 5.3 – Criar Database Encryption Key  

```sql
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_128
ENCRYPTION BY SERVER CERTIFICATE DBCriptCert;
```

---

### 5.4 – Habilitar criptografia  

```sql
ALTER DATABASE DBScript
SET ENCRYPTION ON;
```

---

## 6 – Backup do Certificado (CRÍTICO)  

### Exportar  

```sql
BACKUP CERTIFICATE DBCriptCert
TO FILE = 'C:\certificados\DBCriptCert.cer'
WITH PRIVATE KEY (
    FILE = 'C:\certificados\DBCriptCert.key',
    ENCRYPTION BY PASSWORD = 'password'
);
```

---

### Importar  

```sql
CREATE CERTIFICATE DBCriptCert
FROM FILE = 'C:\certificados\DBCriptCert.cer'
WITH PRIVATE KEY (
    FILE = 'C:\certificados\DBCriptCert.key',
    DECRYPTION BY PASSWORD = 'password'
);
```

---

### Restore  

- Restaurar normalmente após importar certificado  

---

## 7 – Erro comum  

Ao tentar restaurar um banco de dados protegido com TDE em outro servidor, pode ocorrer o seguinte erro:

Msg 33111, Level 16, State 3, Line 66  
Cannot find server certificate with thumbprint...

---

### Causa  

Esse erro ocorre quando o SQL Server não encontra o certificado utilizado para proteger a Database Encryption Key (DEK)  
Como o TDE utiliza uma cadeia de criptografia, o banco de dados não pode ser acessado sem o certificado correspondente  

---

### Explicação técnica  

- A DEK está armazenada dentro do banco de dados  
- Porém, ela está criptografada pelo certificado  
- Durante o restore, o SQL Server tenta descriptografar a DEK  
- Se o certificado não existir no servidor destino, o processo falha  

---

### Cenário típico  

- Backup realizado em um servidor origem com TDE habilitado  
- Restore sendo executado em outro servidor  
- Certificado não foi exportado/importado  

---

### Como resolver  

1. Exportar o certificado no servidor de origem:

    BACKUP CERTIFICATE DBCriptCert  
    TO FILE = 'C:\certificados\DBCriptCert.cer'  
    WITH PRIVATE KEY (  
        FILE = 'C:\certificados\DBCriptCert.key',  
        ENCRYPTION BY PASSWORD = 'password'  
    );  

2. Importar o certificado no servidor destino:

    CREATE CERTIFICATE DBCriptCert  
    FROM FILE = 'C:\certificados\DBCriptCert.cer'  
    WITH PRIVATE KEY (  
        FILE = 'C:\certificados\DBCriptCert.key',  
        DECRYPTION BY PASSWORD = 'password'  
    );  

3. Realizar o restore normalmente após a importação  

---

### Boas práticas para evitar o erro  

- Sempre realizar backup do certificado imediatamente após sua criação  
- Armazenar os arquivos (.cer e .key) em local seguro  
- Documentar o processo de recuperação  
- Testar restore em ambiente de homologação  

---

### Observação crítica  

- Sem o certificado (e sua chave privada), o banco de dados é irrecuperável  
- Não existe workaround ou bypass para esse cenário  
- Esse é um dos principais riscos operacionais ao utilizar TDE  
```

---

## 8 – Monitoramento  

- sys.dm_database_encryption_keys  
- Status  
- Progresso  
- Algoritmo  

---

## 9 – Impactos e Considerações  

### Impactos  

- CPU adicional  
- Tempo inicial de criptografia  
- Impacto em backup  

### Considerações  

- Não protege memória  
- Não protege dados em trânsito  
- Não substitui criptografia de aplicação  

---

## 10 – Boas práticas  

- Backup imediato do certificado  
- Armazenar .cer e .key com segurança  
- Testar restore  
- Utilizar AES  
- Documentar processo  

---

## 11 – Dicas  

- Mesmo certificado entre servidores  
- Criar em homologação  
- Testar recuperação  

---

## 12 – Relação com LGPD  

O uso do TDE contribui diretamente para práticas de segurança exigidas pela LGPD  

### Princípios relacionados  

- Segurança  
  - Proteção contra acessos não autorizados  

- Prevenção  
  - Redução de risco de vazamento de dados  

- Responsabilização (accountability)  
  - Demonstração de medidas técnicas de proteção  

### Importante  

- TDE não é suficiente sozinho para LGPD  
- Deve ser combinado com:
  - Controle de acesso  
  - Auditoria  
  - Criptografia em trânsito  
  - Políticas de segurança  

---

## 13 – Observações finais  

- Pode ser habilitado online  
- Sem indisponibilidade  
- Protege apenas dados em repouso  
