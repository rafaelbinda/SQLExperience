=====================================================================================================================================================
@author        Rafael Binda
@date          2026-02-15
@version       3.0
@task          A0006_sql_server_version
@object        Annotation
@environment   -
@database      -
@server        -
=====================================================================================================================================================

Histórico:
1.0 - Criacao das anotações

Descrição:
Informações a respeito da versão do SQL SERVER

Observações:
Utiliza o executável que está disponível em annotations\files\A0003_X_PortQry.zip
Script disponível em dba_scripts\SQL_instance_information\Q0003_sql_version.sql

=====================================================================================================================================================

1 - 	Versão do SQL Server

	------------------------------------------------------------------------------------------------------------------
	Cenário de risco (Informação incluída na data de 15/02/2026):
	------------------------------------------------------------------------------------------------------------------
	1 - Ao executar o PortQry a versão exibida é a 16.0.1000.6
	2 - Ao identificar que está na versão 16.0.1000.6 é possível verificar no site da Microsoft qual é a versão que 
	    está instalada atualmente através do endereço abaixo:
		https://learn.microsoft.com/pt-br/troubleshoot/sql/releases/download-and-install-latest-updates#sql-server-2022
	3 - Olhando a história de atualizações de segurança do Microsoft SQL Server 2022, há vulnerabilidades de segurança
		listadas nas notas de atualização que podem ser exploradas por invasores se a instância estiver desatualizada 
		(como no caso da versão 16.0.1000.6 que foi lançada em novembro de 2022.
	4 - Se for contar a quantidade de CU disponíveis hoje existem 48 atualizações após a versão 16.0.1000.6
	
	------------------------------------------------------------------------------------------------------------------
	PROBLEMA:
	------------------------------------------------------------------------------------------------------------------
	Se um invasor souber que um servidor roda SQL Server 2022 versão 16.0.1000.6 (RTM / sem atualizações), ele pode 
	pesquisar no site de atualizações da Microsoft e identificar CVEs como CVE-2024-49021 e CVE-2024-49043, que permitem 
	execução remota de código. (CVE = Common Vulnerabilities and Exposures/Vulnerabilidades e Exposições Comuns)
	Com isso, teoricamente, um atacante sem autorização poderia explorar a falha e infiltrar-se no servidor.
	
	• CVE-2024-49021 – Vulnerabilidade de execução remota de código do Microsoft SQL Server
	• CVE-2024-49043 – Vulnerabilidade de execução remota de código em Microsoft.SqlServer.XEvent.Configuration.dll
	
	Essas CVEs permitem que um invasor remoto execute código arbitrário sem necessidade de credenciais elevadas, 
	potencialmente assumindo o controle do servidor SQL se o sistema estiver nessa versão vulnerável (anterior às correções).
		
=====================================================================================================================================================

2 - 	Diferença entre Linha Cumulative Update (CU) X Linha GDR (General Distribution Release)
	
	------------------------------------------------------------------------------------------------------------------
	- CU (Cumulative Update) inclui:
	------------------------------------------------------------------------------------------------------------------
	→ Todas as correções de segurança
	→ Correções de bugs
	→ Correções de estabilidade
	→ Correções de performance
	→ Correções de features

	E é cumulativa de verdade:
	Instala a última CU → recebe tudo desde o RTM.

	Vantagem:
	→ Ambiente mais saudável
	→ Menos incidentes
	→ Menos chamados misteriosos
	→ Melhor performance
	
	Desvantagem:
	→ Pode alterar comportamento interno
	→ Pode expor bugs novos (raro, mas possível)
	→ Exige ambiente de homologação
	
	------------------------------------------------------------------------------------------------------------------
	- GDR (General Distribution Release) inclui:
	------------------------------------------------------------------------------------------------------------------
	→ Apenas correções de segurança críticas
	→ Nada de correção de bug funcional
	→ Nada de melhoria de performance

	Vantagem:
	→ Menor risco de alteração no comportamento do engine

	Desvantagem:
	→ Bugs conhecidos continuam existindo
	→ Problemas de performance não são corrigidos
	→ Você pode ficar "preso" em limitações já resolvidas na linha CU

	------------------------------------------------------------------------------------------------------------------
	- Níveis de versão
	------------------------------------------------------------------------------------------------------------------
	→ RTM	Versão inicial
	→ SP	Grande pacote acumulativo (modelo antigo)
	→ CU	Atualização cumulativa mensal
	→ GDR	Apenas correção de segurança

=====================================================================================================================================================