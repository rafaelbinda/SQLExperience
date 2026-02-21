===============================================================================
@author        Rafael Binda
@date          2026-02-08
@version       1.0
@task          A0005_network_commands
@object        Annotation
@environment   -
@database      -
@server        -
===============================================================================

Histórico:
1.0 - Criacao das anotações

Descrição:

1 - Via CMD saber o ip do google
2 - Saber/Descobrir o nome de uma máquina na rede   
3 - Saber a porta está ativa 
4 - Lista completa de conexões abertas, tanto ativas quanto aguardando conexões 

Observações:
Este documento contém informações complementares ao documento A0004_sql_server_connectivity_troubleshooting


===============================================================================

1 - Via CMD saber o ip do google 

	Opção 1 
	--->>> ping google.com.br

	Opção 2
	--->>> nslookup google.com

==============================================================================================================================================================

2 - Saber/Descobrir o nome de uma máquina na rede 

	--->>> ping -a 192.168.1.103

==============================================================================================================================================================

3 - Saber a porta está ativa

	--->>> telnet 192.168.1.103 1433

==============================================================================================================================================================

	
4 - Lista completa de conexões abertas, tanto ativas quanto aguardando conexões 

	--->>> netstat -ano | findstr LISTENING

	-a → Mostra todas as conexões e portas em escuta (listening)
	-n → Exibe os endereços e portas em formato numérico (sem tentar resolver nomes de host ou serviços)
	-o → inclui o PID (Process ID), ou seja, o identificador do processo que está usando aquela conexão/porta
	
	Com esse PID você pode descobrir qual programa está usando a porta:
	
	--->>> tasklist /FI "PID eq 2144"

==============================================================================================================================================================	
