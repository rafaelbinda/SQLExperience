# A0008 – Network Commands

> **Author:** Rafael Binda  
> **Created:** 2026-02-10  
> **Version:** 2.0  

---

## Descrição

- Descobrir o ip do google
- Descobrir o nome de uma máquina na rede   
- Habilitar Telnet pelo Prompt de Comando e descobrir se uma porta está ativa
- Lista completa de conexões abertas, tanto ativas quanto aguardando conexões

---

## Observações
Este documento contém informações complementares ao documento A0004-sql-server-connectivity-troubleshooting.  
Este documento apresenta apenas recomendações, não uma lista completa de procedimentos.

---

## 1. Descobrir o ip do google usando CMD

→ Opção 1 - Comando digitado utilizando CMD:  
```cmd
ping google.com.br
```
### Resultado esperado:
```cmd
Pinging google.com.br [172.217.172.163] with 32 bytes of data:
Reply from 172.217.172.163: bytes=32 time=15ms TTL=117
Reply from 172.217.172.163: bytes=32 time=16ms TTL=117
Reply from 172.217.172.163: bytes=32 time=15ms TTL=117
Reply from 172.217.172.163: bytes=32 time=16ms TTL=117
```

→ Opção 2 - Comando digitado utilizando CMD:   
```cmd
nslookup google.com
```
### Resultado esperado:
```cmd
Server:  mhnet-costumer-dns-a.mhnet.com.br
Address:  187.45.96.96

Non-authoritative answer:
Name:    google.com
Addresses:  2800:3f0:4001:801::200e
          142.250.78.142
```

## 2. Descobrir o nome de uma máquina na rede  

→ Comando digitado utilizando CMD:  
```cmd
ping -a 192.168.1.109
```
### Resultado esperado:
```cmd
Pinging SRVSQLSERVER [192.168.0.109] with 32 bytes of data:
Reply from 192.168.0.109: bytes=32 time<1ms TTL=128
Reply from 192.168.0.109: bytes=32 time<1ms TTL=128
Reply from 192.168.0.109: bytes=32 time<1ms TTL=128
Reply from 192.168.0.109: bytes=32 time<1ms TTL=128
```
---

## 3. Habilitar Telnet pelo Prompt de Comando 

→ Comando digitado utilizando CMD:  
```cmd
telnet 192.168.0.109 1433
```
### Resultado esperado (se o Telnet não estiver instalado):
`'telnet' não é reconhecido como um comando interno ou externo, um programa operável ou um arquivo em lotes.`

→ Abra o Prompt de Comando (CMD) como Administrado e execute o seguinte comando e aguarde a instalação.  
```cmd
dism /online /Enable-Feature /FeatureName:TelnetClient
```
### Resultado esperado:
```cmd
Deployment Image Servicing and Management tool
Version: 10.0.26100.5074

Image Version: 10.0.26100.32230

Enabling feature(s)
[==========================100.0%==========================]
The operation completed successfully.
```

### Saber se uma porta está ativa usando Telnet

→ Comando digitado utilizando CMD:  
```cmd
telnet 192.168.0.109 1433
```
### Resultado esperado:
→ Quando você usa telnet para se conectar a uma porta TCP de um serviço como o SQL Server:
- O telnet abre a conexão na porta 1433.
- O SQL Server não “fala” nada automaticamente, então a tela fica em branco/presa, esperando que você envie algum comando.
- Isso significa que a conexão TCP foi estabelecida com sucesso, ou seja, a porta está aberta e acessível.
- Se você vir mensagens de erro como Could not open connection, aí sim é que há algum bloqueio de firewall, rede ou configuração do SQL.

---

## 4. Lista completa de conexões abertas, tanto ativas quanto aguardando conexões

→ Comando digitado utilizando CMD:  
```cmd
netstat -ano | findstr LISTENING
```
- -a → Mostra todas as conexões e portas em escuta (listening)
- -n → Exibe os endereços e portas em formato numérico (sem tentar resolver nomes de host ou serviços)
- -o → inclui o PID (Process ID), ou seja, o identificador do processo que está usando aquela conexão/porta

### Resultado esperado:
```cmd
  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING       952
  TCP    0.0.0.0:445            0.0.0.0:0              LISTENING       4
  TCP    0.0.0.0:1433           0.0.0.0:0              LISTENING       7212
  TCP    0.0.0.0:3389           0.0.0.0:0              LISTENING       1196
```

→ Após saber o PID que foi listado no comando anterior você pode descobrir qual programa está usando a porta.  
→ Comando digitado utilizando CMD:  
```cmd
tasklist /FI "PID eq 7212"
```
### Resultado esperado:
```cmd
Image Name                     PID Session Name        Session#    Mem Usage
========================= ======== ================ =========== ============
sqlservr.exe                  7212 Services                   0    769.400 K
```

---
