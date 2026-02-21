=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-18
@version       2.0
@task          A0007_architecture
@object        Annotation
@environment   -
@database      -
@server        -
=====================================================================================================================================================

Histórico:
1.0 - Criacao das anotações

Descrição:
Informações a respeito arquitetura do SQL SERVER

Observações:
Script disponível em dba_scripts\SQL_examples\CREATE_DATABASE.sql

Conteúdo adicional:
https://docs.microsoft.com/en-us/sql/relational

=====================================================================================================================================================

1 - 	Arquitetura do SQL Server

	→ Recomendado pela Microsoft manter essas extensões
	→ .mdf = Arquivo de dados
	→ .ldf = Arquivo de logs

	------------------------------------------------------------------------------------------------------------------
	.mdf
	------------------------------------------------------------------------------------------------------------------
	→ .mdf é sempre o arquivo primário
	→ Só existe 1
	
	------------------------------------------------------------------------------------------------------------------
	.ndf
	------------------------------------------------------------------------------------------------------------------
	→ São arquivos secundários 
	→ Pode ter "n" secundários

	Porque criar mais de um arquivo de dados?
	
	1º motivo - Aumentar a capacidade de armazenamento
	Exemplo: 
	Meu espaço de armazenamento do arquivo primário está se esgotando, posso criar um arquivo secundário em outro diretório

	2º motivo - Desempenho / Paralelismo de I/O
	Exemplo:
	2.1 - Tenho dois arquivos de dados cada um em um volume diferente lá no storage
	2.2 - Eu crio uma tabela em arquivo de dados em um volume XYZ do storage
	2.3 - Eu crio uma tabela em outro arquivo de dados em um volume YYY do storage
	2.4 - Quando eu fizer uma operação de JOIN entre essas tabelas o SQL consegue ler em paralelo essas tabelas
	Porque? 
	Ele cria uma thread por arquivo de dados
	Estando esses arquivos de dados em discos diferentes ele tem como operar em paralelo ganhando desempenho

	------------------------------------------------------------------------------------------------------------------
	.ldf
	------------------------------------------------------------------------------------------------------------------
	→ É um registro sequencial das operações de atualização que ocorrem no banco de dados
	→ Obrigatório pelo menos 1 arquivo de log
	→ É um arquivo de escrita sequencial (LSN - Log Sequence Number)

	Existe algum motivo de criar mais de um arquivo de log?
	→ Para desempenho não adianta nada devido a escrita sequencial
	→ Aumentar o armazenamento
	Exemplo:
	1 - O arquivo de log está em um disco que está sem espaço
	2 - É criado um segundo arquivo de log em outro disco/volume
	3 - Quando encerra a gravação completa do log no primeiro arquivo e não tem mais espaço físico ele começa a gravar no segundo arquivo de log.


=====================================================================================================================================================

2 - 	Arquitetura interna do arquivo de dados
	
	------------------------------------------------------------------------------------------------------------------
	- Extents
	------------------------------------------------------------------------------------------------------------------
	→ Os dados são gravados em páginas de tamanho fixo
	→ Uma extent possui 8 páginas de 8 KB totalizando 64 KB
	→ Essa é a unidade de crescimento ou redução do arquivo
	→ Sempre cresce multiplo de 64 KB


=====================================================================================================================================================

3 - 	Bancos de Dados de Sistema

	------------------------------------------------------------------------------------------------------------------
	MASTER
	------------------------------------------------------------------------------------------------------------------
	→ Mais importante de todos. 
	→ Catálogo da instância, com informações de Metadata dos objetos de instância
	→ Tem o nome dos bancos de dados que existem no banco
	→ É nele que está a localização dos arquivos de dados e logs de todos os bancos de dados existentes
	→ No processo de inicialização é o primeiro banco a ser inicializado
	→ Sem ele inicializado o SQL não abre

	------------------------------------------------------------------------------------------------------------------
	MSDB			
	------------------------------------------------------------------------------------------------------------------
	→ Armazena Metadata de diversas funcionalidades como SQL Agent, 
	→ Armazena Metadata de histórico Backup e Restore 
	
	------------------------------------------------------------------------------------------------------------------
	TEMPDB			
	------------------------------------------------------------------------------------------------------------------
	→ Rascunho do SQL Server
	→ Banco de dados de operações temporárias

	------------------------------------------------------------------------------------------------------------------
	MODEL	
	------------------------------------------------------------------------------------------------------------------
	→ Modelo de criação para novos bancos de dados
	→ É um template
	
	------------------------------------------------------------------------------------------------------------------
	DISTRIBUTION	
	------------------------------------------------------------------------------------------------------------------
	→ Metadata da Replicação 
	→ Nem sempre está presente no SQL Server
	→ Só vai aparecer se for configurado banco de dados distribuído
	→ Mantém 3 papéis:
		Publishier	- origem dos dados
		Distributor - quem gerencia
		Subscriber	- destino dos dados


=====================================================================================================================================================

4 - 	Checkpoint

	O que que acontece quando a gente atualiza um dado no SQL?
	→ Vamos imaginar que uma aplicação está conectada no SQL Server e envia uma atualização / UPDATE que vai alterar alguns dados em uma tabela
	1º - O SQL primeiramente executa o UPDATE em memória no Buffer Cache ou também chamada de Data Cache
		→ O SQL Server mantém em memória somente os dados mais acessados ele não carrega em cache todos os dados assim ele consegue ter desempenho
	2º - O SQL olha no cache para ver se os dados que sofrerão o UPDATE estão em memória e se encontrar realiza a atualização 
	3º - Se o SQL não encontrar na memória ele vai lá no disco captura as informações e traz para memória e realiza o UPDATE 
	4º - Se alguem chegar no servidor e "derrubar" ele já era e para não acontecer isso ele grava no arquivo de LOG .ldf as alterações realizadas
		→ Data Pages localizados ou são lidos para o buffer cache e modificados
		→ Vai no último LSN e realiza o registro nos próximos LSN
		→ Ele guarda os dados de antes da atualização e os dados "novos" de após a atualização e libera o usuário para prosseguir com o que ele desejar
	5º - Esse processo vai se repetindo por determinado tempo, alterando os dados em memória
		→ Altera em memória e registra no log
		→ Altera em memória e registra no log ...
	6º - De tempos em tempos ocorre um processo chamado de Checkpoint que escreve as transações finalizadas nos arquivos de dados 
		→ Dessa maneira ele ganha desempenho pois iria custar muito caro ficar indo localizar os dados e alterar em tempo real diretamente no disco
		→ Se ele fizesse isso iria ocorrer Page Split direto pois iria ultrapassar continuamente o tamanho das extents que é de 64 kb 

=====================================================================================================================================================