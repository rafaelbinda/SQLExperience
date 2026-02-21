# A0001 – Study Environment Setup
>
> **Author:** Rafael Binda  
> **Created:** 2026-02-09  
> **Version:** 4.0

## Descrição:

Provisionamento de ambiente de laboratório para Microsoft SQL Server utilizando Hyper-V no Windows Home.


## Ambiente Utilizado

- Windows Home
- Hyper-V
- Windows Server 2025 Evaluation
- Microsoft SQL Server (uso em laboratório)

## Observação

Este ambiente é destinado exclusivamente para estudo e não deve ser utilizado em produção.

---
# Procedimento Completo
---

## 1. Habilitar Hyper-V no Windows Home  

→ Executar a instalação do arquivo: `01-sql-introduction\tools\A0001_X_EnableHyperV_Windows_Home.bat` e em seguida reiniciar o computador 

---

## 2. Verificar se o Hyper-V foi habilitado  

→ Comando digitado utilizando CMD:  
```cmd
systeminfo
``` 

### Resultado esperado: 
```cmd
Requisitos do Hyper-V: Hipervisor detectado. Recursos necessários para o Hyper-V não serão exibidos.
``` 

---

## 3. Confirmar Recursos do Hyper-V   

→ No CMD, execute: `optionalfeatures`

→ Marcar todos os itens: 
- [X] Hyper-V
  - [X] Hyper-V Management Tools
  - [X] Hyper-V PowerShell Module
- [X] Hyper-V Platform
  - [X] Hypervisor
  - [X] Hyper-V Services

---

## 4. Criar Comutador Virtual Externo  

→ Lado esquerdo -> Gerenciador do Hyper-V -> Clicar sobre o nome da máquina corrente DESKTOP-F86B6PH  
→ Lado direito  -> Gerenciador de Comutador Virtual -> Cria um NOVO EXTERNO para que as máquina enxerguem fora do host  
→ Informar um Nome: REDEEXTERNA  
→ Selecionar Realtek (não usar wireless)  
→ Salvar, nesse momento Vai desligar a rede e religar

---

## 5. Criar Nova Máquina Virtual
	
→ De um nome: SRVSQLSERVER  
→ Identificar o diretório que vai ficar salva a VM  
→ Selecionar Geração 2  
→ Informar quantidade de memória (desmarcar dinâmica)  
→ Conexão: Escolher a REDEEXTERNA que foi criada anteriormente  
→ Anexar um disco rígido mais tarde  
→ Concluir

---

## 6. Configurar Hardware da VM  

→ Sobre a VM SRVSQLSERVER -> Acessar Configurações e:  
→ Alterar o número de processadores (escolhi 4)  
→ Criar o disco rígido "virtual" em Controlador SCSI  
→ Clicar em Adicionar → Novo → Expansão dinâmica  
→ Definir um nome: SRVSQLSERVER_disk0.vhdx  
→ Definir um local: E:\SQLEXPERIENCE\MAQUINAVIRTUAL\SRVSQLSERVER\Virtual Machines\HD\  
→ Definir um tamanho: 127 GB  

---

## 7. Adicionar a ISO 

→ Acessar Controlador SCSI → Selecionar Unidade de DVD → Adicionar → Arquivo de imagem  
→ Procurar: E:\SQLEXPERIENCE\M02A01 - Windows Server 2025.iso  
→ Aplicar  

---

## 8. Ajustar Firmware

→ Mover a Unidade de DVD como primeiro item da lista (para que de o boot pela ISO)  
→ Mover o Disco Rígido como 2º item da lista  
→ Aplicar

---

## 9. Iniciar VM

→ É necessário clicar dentro da VM para iniciar pelo DVD

---

## 10. Instalar o Windows

→ Selecionar Required Only  
→ Try Windows Admin Center ... (Marcar Don't show this message again)

---

## 11. Configuração Inicial Local Server

→ Ajustar Time Zone  
→ Ajustar idioma para Português   	
→ Habilitar Remote Desktop  
→ Renomear a máquina para SRVSQLSERVER

---

## 12. Licenciamento Windows 2025 Evaluation

→ O Limite de uso/tempo máximo do dessa versão do Windows é 180 dias  
→ Para Verificar prazo de validade utilizando o CMD utilizar o comando: `slmgr.vbs /dlv`  
→ É possível renovar até 6x usando o comando: `slmgr.vbs /rearm`

---


