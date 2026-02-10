
/*
===============================================================================
@author        Rafael Binda
@date          2026-02-09
@version       1.0
@task          M02A01
@object        Annotation
@environment   -
@database      -
@server        SRVSQLSERVER
===============================================================================

Histórico / History:
1.0 - Criacao do script / Script creation

Descrição / Description:

Habilitar o uso do Hyper-V no Windows Home /
Enable the use of Hyper-V on Windows Home

Criação de uma Maquina Virtual usando Hyper-V + Windows Server 2025 /
Creation of a Virtual Machine using Hyper-V + Windows Server 2025

Observações / Notes:
Criação do ambiente de desenvolvimento usando Hyper-V com Windows Server 2025
Este será o servidor de banco de dados

Preparing the development environment using Hyper-V with Windows Server 2025
This will be the database server


===============================================================================
*/
      
/*

==============================================================================================================================================================
1º - Habilitar o uso do Hyper-V no Windows Home /
	Enable the use of Hyper-V on Windows Home

	--->>> Instalar o pack M02E01_EnableHyperV_Windows_Home.bat
	--->>> Install the package M02E01_EnableHyperV_Windows_Home.bat
==============================================================================================================================================================

2º - Pós instalação /
	After-installation

	--->>> Reinicia o computador
	--->>> Restart the computer

==============================================================================================================================================================

3º - Pós reinicialização verificar se o Hyper-V foi habilitado /
	After restarting, check if Hyper-V has been enabled

	Execute no CMD / Run it in the Command Prompt (CMD)
	--->>> systeminfo

	Vai ter que listar:
	Requisitos do Hyper-V: Hipervisor detectado. Recursos necessários para o Hyper-V não serão exibidos.

	It will need to display:
	Hyper-V Requirements: A hypervisor has been detected. Features required for Hyper-V will not be displayed.

==============================================================================================================================================================

4º - Habilitar o uso do Hyper-V / Enable the use of Hyper-V

	Execute no CMD / Run it in the Command Prompt (CMD)
	--->>> optionalfeatures

	Em Hyper-V vai ter que estar tudo selecionado
	Hyper-V
	-> Ferramentas de Gerenciamento do Hyper-V
	-> Módulo do Hyper-V para Windows Power Shell
	Plataforma Hyper V
	-> Hipervisor do Hyper-V
	-> Serviços do Hyper-V
	
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	In Hyper-V, everything must be selected:
	Hyper-V
	-> Hyper-V Management Tools
	-> Hyper-V Module for Windows PowerShell
	Hyper-V Platform
	-> Hyper-V Hypervisor
	-> Hyper-V Services

==============================================================================================================================================================

5º - Menu iniciar do Windows -> Gerenciador do Hyper-V

	Lado esquerdo -> Gerenciador do Hyper-V -> Clica sobre o nome da máquina corrente DESKTOP-F86B6PH
    Lado direito  -> Gerenciador de Comutador Virtual -> Cria um NOVO EXTERNO para que as máquina enxerguem fora do host
	Nome: REDEEXTERNA
	Observação: Possibilita comunicação de dentro da vm com o mundo externo 
	Rede externa: Selecionada Realtek (NÃO USAR WIRELESS)
	Salvar: Vai desligar a rede e religar

	----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Left side → Hyper-V Manager → Click on the name of the current machine DESKTOP-F86B6PH
	Right side → Virtual Switch Manager → Create a NEW EXTERNAL switch so that virtual machines can access networks outside the host
	Name: REDEEXTERNA
	Note: Enables communication from inside the VM to the external network
	External network: Select Realtek (DO NOT use wireless)
	Save: The network connection will be temporarily disconnected and then reconnected

==============================================================================================================================================================

6º - Adicionar nova máquina virtual
	Dá um nome: SRVSQLSERVER
	Identifica o diretório que vai ficar salva a VM
	Selecionar Geração 2
	Informar quantidade de memória (desmarcar dinâmica)
	Conexao: Escolhe a REDEEXTERNA
	Anexar um disco rígido mais tarde
	Concluir

	----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	Add a new virtual machine
	Name: SRVSQLSERVER
	Specify the directory where the VM will be stored
	Select Generation 2
	Set the memory amount (disable Dynamic Memory)
	Network connection: Select REDEEXTERNA
	Attach a virtual hard disk later
	Finish

==============================================================================================================================================================

7º - Sobre a VM SRVSQLSERVER -> Acessar Configurações
	Alterar o número de processadores (escolhi 4)
	Criar o disco rígido "virtual" em Controlador SCSI 
	-> Adicionar 
	→ Novo 
	→ Expansão dinâmica
	→ Dá um nome: SRVSQLSERVER_disk0.vhdx
	→ Local: E:\SQLEXPERIENCE\MAQUINAVIRTUAL\SRVSQLSERVER\Virtual Machines\HD\
	→ Tamanho: 127 GB
	
	----------------------------------------------------------------------------------------------------------------------------------------------------------
	
	For the VM SRVSQLSERVER → Access Settings
	Change the number of processors (I chose 4)
	Create the virtual hard disk on SCSI Controller:
	Add → New
	Choose Dynamically Expanding
	Name: SRVSQLSERVER_disk0.vhdx
	Location: E:\SQLEXPERIENCE\MAQUINAVIRTUAL\SRVSQLSERVER\Virtual Machines\HD\
	Size: 127 GB

==============================================================================================================================================================

8º  -> Adicionar a ISO -> Acessar Controlador SCSI
	→ Selecionar Unidade de DVD
	→ Adicionar
	→ Arquivo de imagem
	→ Procurar: E:\SQLEXPERIENCE\M02A01 - Windows Server 2025.iso
	→ Aplicar

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-> Add the ISO → Access the SCSI Controller
	→ Select DVD Drive
	→ Add
	→ Image File
	→ Browse: E:\SQLEXPERIENCE\M02A01 - Windows Server 2025.iso
	→ Apply

==============================================================================================================================================================

9º  -> Vai em Firmware
	→ Mover a Unidade de DVD como primeiro item da lista (para que de o boot pela ISO)
	→ Mover o Disco Rígido como 2º item da lista
	→ Aplicar

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-> Go to Firmware
	→ Move the DVD Drive to the first item in the list (so the VM boots from the ISO)
	→ Move the Hard Disk to the second item in the list
	→ Apply

==============================================================================================================================================================

10º -> Iniciar	-> Tem que clicar no ESPAÇO dentro da VM para que ela inicie pelo CD / DVD
	-> Start	-> You need to click inside the VM window to make it boot from the CD/DVD.

==============================================================================================================================================================

11º -> Instalar o Windows
	→ Selecionar Required Only 
	→ Try Windows Admin Center ... (Marcar Don't show this message again)

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	→ Install Windows
	→ Select Required Only
	→ Select Try Windows Admin Center... (check Don't show this message again)

==============================================================================================================================================================

12º -> Local Server
	→ Ajustar Time Zone 
	→ Ajustar Data Portuguese 	
	→ Remote Desktop -> Habilitar para usar o RDP
	→ Renomear a máquina para SRVSQLSERVER

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-> Local Server
	→ Adjust Time Zone
	→ Adjust Date to Portuguese
	→ Remote Desktop → Enable to use RDP
	→ Rename the machine to SRVSQLSERVER

==============================================================================================================================================================

13º -> Limite de uso/tempo máximo do dessa versão do Windows é 180 dias
	
	-> Verificar prazo de validade: 
	comando: slmgr.vbs /dlv

	-> É possível renovar até 6x usando o comando abaixo
	comando: slmgr.vbs /rearm

	----------------------------------------------------------------------------------------------------------------------------------------------------------

	-> This Windows version has a usage/activation limit of 180 days.

	-> Check expiration date:
	Command: slmgr.vbs /dlv

	→ It is possible to renew up to 6 times using the command below:
	Command: slmgr.vbs /rearm

	
*/
