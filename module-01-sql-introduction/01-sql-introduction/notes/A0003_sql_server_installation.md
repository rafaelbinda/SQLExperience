===============================================================================
@author        Rafael Binda
@date          2026-02-10
@version       2.0
@task          A0003_sqlserver_installation
@object        Annotation
@environment   -
@database      -
@server        -
===============================================================================

Histórico:
1.0 - Criação das anotações

Descrição:
Documento com informações para instalação do SQL Server seguindo boas práticas

Observações:
Deverá fazer o download do SQL Server no site da Microsoft 
Para informações a respeito de collation verificar o arquivo annotations\A0002_collation.txt

Conteúdo adicional:
https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022?view=sql-server-ver16&preserve-view=true
https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option?view=sql-server-ver17


Meu cenário:
-> Versão: SQL Server 2022
-> Atualização: Cumulative Update 23 (CU23)
-> Data de liberação: Janeiro 22, 2026
-> Edição: Entreprise Developer
-> Sistema Operacional: Windows Server 2025 Evaluation
-> Ambiente Virtualizado com Hyper-V

==============================================================================================================================================================

1 - Servidor Windows Server 2025 Evaluation

    -> Servidor deve estar ingressado em Dominio (AD)
    -> Evitar ambiente WORKGROUP em produção
    -> Criar conta dedicada no AD para o servico SQL
    -> Conta nao deve ser Administrator
	
	Durante a Instalação: O usuário que está instalando o SQL Server precisa de privilégios de administrador. 
	
	IMPORTANTE:
	Durante a configuração dos serviços, deve especificar uma conta de usuário (de preferência de domínio) que não seja administradora.
	
	Por que não usar Administrador?
	Risco de Segurança: 
	Se o serviço do SQL Server for comprometido (por exemplo, via injeção de SQL), o atacante terá controle total da máquina ou do domínio.
	Melhores Práticas: A recomendação é usar uma conta de usuário de domínio comum ou, preferencialmente, Managed Service Accounts (MSAs) ou Virtual Accounts. 
		
    -> Configurar senha para NUNCA EXPIRAR
    -> Remover privilegios desnecessarios
    -> Servidor preferencialmente dedicado ao SQL Server

==============================================================================================================================================================

2 - Ao executar o instalador do SQL Server - Tipo de Instância

    -> Definir se será utilizada Instância Padrão ou Nomeada
    -> Instância Padrão utiliza porta 1433
    -> Instância Nomeada deve obrigatoriamente utilizar porta fixa
    -> Nao utilizar portas dinâmicas em ambiente de produção
    -> Configurar porta fixa no SQL Server Configuration Manager
    -> Validar liberação da porta no Firewall do Windows
    -> Validar liberação da porta no Firewall de rede (se existir)

==============================================================================================================================================================

3 - Ao executar o instalador do SQL Server - (Feature Selection)

Instance Features 
	[x] Dababase Engine Service								-> Servidor de banco de dados relacional		
	                                                           Serviço principal do SQL Server
		[x] SQL Server Replication							-> Replicação para banco de dados distribuído	
		                                                       Permite copiar e sincronizar dados entre servidores
		[x] AI Services and Language Extensions				-> Disponível só no SQL 2025 
		                                                       Permite rodar scripts externos dentro do SQL Server (Python, R, Java)
		[x] Full-Text and Semantic Extractions for Search	-> Permite buscas avançadas em texto.			
		                                                       Sem isso, o LIKE '%texto%' fica limitado e lento
		[x] PolyBase Query Service for External Data		-> Permite consultar dados externos como se fossem tabelas 
		                                                       Arquivos CSV, Hadoop, Azure Blob, muito usado para integração e Data Lake
	[ ] Analysis Services									-> Usado para BI avançado (Power BI, relatórios analíticos) - Se não usar não instalar

Shared Features
	[x] Integration Services								-> Ferramenta de ETL - Eu uso o Pentaho mas instalar para possível estudo no futuro
		[ ] Scale Out Master								-> Controlador central do SSIS Scale Out - A princípio não instalar
															   Só precisa se for montar ambiente distribuído de ETL pesado
		[ ] Scale Out Worker								-> Máquina que executa pacotes SSIS distribuídos
															   Só faz sentido em arquitetura grande com processamento distribuído

Instance root directory										-> Pasta base onde os arquivos da instância serão instalados.
															   Isso não é onde ficam os bancos (.mdf/.ldf) por padrão.	
Shared feature directory									-> Pasta onde ficam componentes compartilhados entre instâncias.
															   SSMS components
															   Client tools
															   DLLs compartilhadas
															   Integration Services
Shared feature directory (x86)								-> Versão 32 bits dos componentes compartilhados
															   Quase ninguém usa x86
															   Pode deixar padrão
															   Só é usado para compatibilidade antiga	

==============================================================================================================================================================

4 - Server Configuration - Serviços

	-> SQL Server Agent										-> Usar a conta que eu criei no Windows (.\USRSQLSERVER)
	-> SQL Server Database Engine							-> Usar a conta que eu criei no Windows (.\USRSQLSERVER)
	-> As demais pode deixar como está sem entrada de um usuário específico
    -> Startup Type como Automatic para:
        -> SQL Server Database Engine
        -> SQL Server Agent

    [X] Grant Perform Volumen Maintanance Tasks privilege to SQL Server Database Engine Service
    -> Concede ao serviço do SQL Server a permissão para usar Instant File Initialization (IFI).
	-> Melhora performance em:
	   Crescimento automático (autogrowth)
	   Restore
	   Criação de banco grande

==============================================================================================================================================================

5 - Collation

    -> Definir Collation antes da instalação
    -> Padrão recomendado moderno:
        Latin1_General_100_CI_AI_SC_UTF8
    -> Nao alterar Collation apos ambiente estar em produção
    -> Validar compatibilidade com aplicações antes da definição
	Para informações a respeito de collation verificar o arquivo annotations\A0002_collation.txt


==============================================================================================================================================================

6 - Database Engine Configuration - Server Configuration

	-> Escolher Mixed Model (SQL Server and Windows authentication)
	-> Nesse momento é definida a senha padrão do usuário "sa"
       Dica: Colocar a mesma senha da conta do serviço (.\USRSQLSERVER)
	-> Adicionar o usuário corrente
	-> Adicionar o usuário da conta do serviço (.\USRSQLSERVER)
	   Todos que forem adicionados aqui terão permissão de sysadmin
	-> Ambiente de produção tem que ter alguns cuidados a mais mas é assunto para outro momento

==============================================================================================================================================================

7 - Database Engine Configuration - Data Directories

	-> O Data root não alterar
	-> O System database não alterar
	-> Os demais definir um diretório que fique fácil para uso no dia a dia 
	-> Se possível:
	   Dados em um disco exclusivo
	   Log em um disco exclusivo
	   Backup em um disco exclusivo

==============================================================================================================================================================

8 - Database Engine Configuration - TempDB

	-> Para estudo nesse momento não alterar nada
    -> Número de arquivos = número de cores lógicas (até 8 inicialmente)
    -> Mesmo tamanho para todos os arquivos
    -> Tamanho inicial mínimo recomendado: 512MB ou 1GB por arquivo
    -> Autogrowth fixo (ex: 256MB ou 512MB)
    -> Nao usar crescimento percentual
     
==============================================================================================================================================================

9 - Database Engine Configuration - MaxDOP
    
	-> Seguir recomendacao Microsoft:
    -> Até 8 cores: MaxDOP = numero de cores
    -> Acima de 8 cores: MaxDOP = 8
    -> Sempre validar se ha multiplos NUMA nodes
		
	Cuidado com o MaxDOP 
	Hoje em nosso ambiente de produção estava configurado com 8 cores e o BI executou um processo
	que fez uso de todos os cores ao limite elevando o consumo de CPU do servidor de banco de dados a 90%  
	travando o ambiente completamente

==============================================================================================================================================================

9 - Database Engine Configuration - Memory

    -> Marcar (*) Recommended
    -> Definir memória máxima manualmente
    -> Reservar entre 4GB e 8GB para o Sistema Operacional
    -> Exemplo: servidor 32GB RAM
    -> Max Server Memory: 24576 MB (24GB)


==============================================================================================================================================================

10 - Database Engine Configuration - FILESTREAM
	
	-> Permite armazenar arquivos grandes (BLOBs) no sistema de arquivos NTFS, mas controlados pelo SQL Server.
	-> Em vez de guardar tudo dentro da tabela como VARBINARY(MAX), o SQL salva o arquivo fisicamente no disco e mantém o controle transacional.
	-> Usado quando você precisa armazenar:
	   PDFs
	   Imagens
	   Vídeos
	   Documentos grandes

	[x] Enable FILESTREAM for Transact-SQL access
		Permite acessar via T-SQL.
	[x] Enable FILESTREAM for file I/O streaming access
		Permite acesso direto via Windows API.
	[ ] Allow remote clients
		Permite acesso remoto aos arquivos. 
		Gera problemas sérios de segurança

==============================================================================================================================================================

11 - Checar o ambiente
	
	1 - Inciar os serviços
	2 - Abrir o CMD e digitar 
		
	-----> sqlcmd -? 
	Resultado: Vai listar todas as opções

	-----> sqlcmd
	Resultado: Vai conectar no servidor

==============================================================================================================================================================

12 - Instalar o SSMS

==============================================================================================================================================================

13 - Instalação de uma segunda/terceira instância para testes com collation:

	- Crio um novo usuário SQLServiceCollation e defino que a senha vai expirar nunca (teste de Instância com Collation diferente)
	- Na instalação Instalation -> New Stand Alone
	- Instalation Type -> Perform a new instalation 
	- Edition -> Developer
	- Licence term -> accept
	- Azure Extension -> Marcação do Azure é só se for para que ocorra a cobrança lá na conta do Azure
	- Feature Selection -> Marca no mínimo Database Engine Services, Full-Text 
		-> Altera o Instance root: C:\Microsoft SQL Server Instance III
	- Instance and Configuration -> Nomeia a Instância (MSSQLSERVERIII) 3ª Instância
	(ver) - Server Configuration 	
	-> Altera o Account Name para usar o usuário SQLServiceCollation e informa o password XYZ, alterar Startup Type para Automatic
		-> SQL Server Agent 
		-> SQL Server Database Engine
		-> Marcar Grant Perform Volume Maintenance Tasks privilegie to SQL Server Database Engine Service 
		This privilegie enables instant file initialization by avoiding zeroing of data pages. This may lead to information 
		disclosure by allowing deleted contente to be accessed.
		-> Definir uma Collation -> Latin1_General_100_CI_AI_SC_UTF8

	- Database Engine Configuration 
		- Server Configuration
		-> Marco Mixed Mode + informo password
		-> Add Current User
		-> Add User SQLServiceCollation
		
		- Data Directories
		-> Root: Mantem em 				C:\Microsoft SQL Server Instance III
		-> User database directory 	C:\Microsoft SQL Server Instance III\MSSQL_Data
		-> User database log directory 	C:\Microsoft SQL Server Instance III\MSSQL_Log
		-> Backup directory 		C:\Microsoft SQL Server Instance III\MSSQL_Backup
				
	- Temp DB
		(ver) -> Number of files (vai pegar sempre o número de processadores
		-> Initial size 		(100 mb - descobrir)
		-> Autogrowth 			(100 mb - descobrir)
		-> Data directories 		C:\Microsoft SQL Server Instance III\MSSQL_Temp
		-> TempDB Log File Initial size (100 mb - descobrir)
		-> TempDB Autogrowth		(100 mb - descobrir)
		-> Log directory		C:\Microsoft SQL Server Instance III\MSSQL_Temp_Log
		-> Cuidado com o MaxDOP 
	
	- Memory
		-> Alterar para recommeded e marcar Click here to accept the recommended mwmory configurations for the SQL Server Database Engine
		(ver) - FILESTREAM 		-> habilita as duas primeiras opções

==============================================================================================================================================================