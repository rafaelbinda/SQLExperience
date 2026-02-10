
/*
===============================================================================
@author        Rafael Binda
@date          2026-02-08
@version       1.0
@task          M01A01
@object        Annotation
@environment   -
@database      -
@server        SRVSQLSERVER
===============================================================================

Histórico / History:
1.0 - Criacao do script / Script creation

Descrição / Description:

1 - Via CMD saber o ip do google /  
	Find Google’s IP address using the Windows Command Prompt.

2 - Saber/Descobrir o nome de uma máquina na rede /  
	To know/discover the name of a machine on the network

3 - Saber a porta está ativa /
	Knowing the door is active

4 - Lista completa de conexões abertas, tanto ativas quanto aguardando conexões /
	Complete list of open connections, both active and waiting for connections

*/

/*
1 - Via CMD saber o ip do google /  
	Find Google's IP address via CMD.

	Opção 1 / Option 1 
	--->>> ping google.com.br

	Opção 2 / Option 2
	--->>> nslookup google.com

2 - Saber/Descobrir o nome de uma máquina na rede /  
	To know/discover the name of a machine on the network

	--->>> ping -a 192.168.1.103
	
3 - Saber a porta está ativa /
	Knowing the door is active

	--->>> telnet 192.168.1.103 1433
	
4 - Lista completa de conexões abertas, tanto ativas quanto aguardando conexões /
	Complete list of open connections, both active and waiting for connections

	--->>> netstat -ano | findstr LISTENING

	-a → Mostra todas as conexões e portas em escuta (listening)
	     Shows all listening connections and ports

	-n → Exibe os endereços e portas em formato numérico (sem tentar resolver nomes de host ou serviços)
		 Displays addresses and ports in numeric format (without attempting to resolve hostnames or services)

	-o → inclui o PID (Process ID), ou seja, o identificador do processo que está usando aquela conexão/porta
		 This includes the PID (Process ID), which is the identifier of the process using that connection/port.
	
	Com esse PID você pode descobrir qual programa está usando a porta:
	With this PID you can find out which program is using the port:

	--->>> tasklist /FI "PID eq 2144"
*/
	
