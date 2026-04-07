# A0021 – Resource Governor (RG)
Author      : Rafael Binda  
Created     : 2026-04-06  
Version     : 2.0

---

## Descrição  

O **Resource Governor (RG)** é um recurso do SQL Server que permite **controlar e limitar o consumo de recursos** (CPU e memória) por sessões ou cargas de trabalho  

Seu principal objetivo é garantir que uma carga de trabalho não degrade a performance das demais, promovendo isolamento e previsibilidade no uso dos recursos da instância  

Esse recurso é amplamente utilizado em ambientes com múltiplas aplicações, relatórios ou usuários concorrentes  

---

## Hands-on  

[Q0018 - Resource Governor Configuration](../scripts/Q0018-resource-governor-configuration.sql)  
[INST-Q0011 - Resource Governor Overview](../../../dba-scripts/SQL-instance-information/INST-Q0011-resource-governor-overview.sql)

---

## Disponibilidade  

- Introduzido no **SQL Server 2008**  
- Inicialmente disponível apenas na edição **Enterprise**  
- A partir do **SQL Server 2025**, disponível também na edição **Standard**  

---

## Objetivo do Resource Governor  

- Controlar consumo de CPU por sessões  
- Controlar consumo de memória  
- Isolar cargas de trabalho  
- Evitar contenção de recursos  
- Garantir estabilidade e previsibilidade  

---

## Cenários comuns de uso  

- Execução de consultas pesadas sem filtros (ex: SELECT sem WHERE)  
- Relatórios com grande volume de dados (ex: período de 10 anos)  
- Aplicações concorrentes compartilhando a mesma instância  
- Ambientes com múltiplos tipos de workload (OLTP + Reporting)  

---

## Quando usar o Resource Governor

- Ambientes com múltiplos workloads concorrentes  
- Necessidade de proteger workloads críticos (ex: OLTP)  
- Controle de queries ad-hoc ou mal otimizadas  
- Ambientes multi-tenant  
- Processos de ETL competindo com cargas transacionais  

---

## Quando NÃO usar o Resource Governor 

- Para corrigir problemas de performance causados por queries mal otimizadas  
- Ambientes com baixa concorrência  
- Ausência de contenção de recursos  
- Como substituto de tuning (indexação, modelagem, etc.)  

---

## Arquitetura do Resource Governor  

O Resource Governor funciona como uma **camada de controle dentro do SQL Server**, interceptando as sessões no momento da conexão e definindo como os recursos serão distribuídos durante sua execução  

Ele é composto por três elementos principais:  

### 1 – Resource Pools  

- Representam o **limite físico de recursos**  
- Definem quanto de CPU e memória pode ser utilizado  
- Funcionam como `containers` de recursos  

---

### 2 – Workload Groups  

- Representam **grupos de sessões ou workloads**  
- Cada grupo está associado a um Resource Pool  
- Permitem organizar diferentes tipos de carga de trabalho  

---

### 3 – Classifier Function  

- Função definida pelo usuário  
- Executada no momento da conexão  
- Responsável por **classificar a sessão** em um Workload Group  
- Pode utilizar propriedades da conexão (login, aplicação, host, etc.)  

---

## Fluxo de funcionamento  

1. Uma nova conexão é estabelecida  
2. A **Classifier Function** é executada  
3. A sessão é direcionada para um **Workload Group**  
4. O grupo está vinculado a um **Resource Pool**  
5. Os limites de CPU e memória são aplicados durante a execução  

Observação:  
A classificação ocorre apenas no momento da conexão. Sessões já existentes não são reclassificadas automaticamente  

---

## Estrutura lógica  

```text
Internal Request (DAC)     |                      | Internal Group   | Internal Pool  
SQL Agent Request          |                      | Default Group    | Default Pool  
Request from website       | -> Classifier        | Report App Group | PoolB  
Report Server Request      |                      | Report App Group | PoolB  
Request from SSMS          |                      | UserA Group      | PoolA  
```

---

## Comportamento padrão  

- **Internal Group** e **Default Group** já existem, portanto, não é necessário criá-los  
- Conexões não classificadas são direcionadas para o **Default Group**  
- Cada Workload Group deve estar associado a um Resource Pool  
- Os limites de recursos são definidos no nível do Resource Pool  

---

## Configuração e acesso  

O Resource Governor pode ser acessado via SSMS:  

Servidor → Management → Resource Governor  

---

## Estado padrão  

- O Resource Governor vem **desabilitado por padrão**  
- É necessário habilitá-lo manualmente para uso  

---

## Monitoramento  

As seguintes DMVs são utilizadas para análise do Resource Governor:  

- sys.dm_resource_governor_resource_pools  
- sys.dm_resource_governor_workload_groups  
- sys.dm_exec_sessions  
- sys.dm_exec_requests  

---

## Limitações  

- A classificação ocorre apenas na conexão (não por query)  
- Não controla diretamente I/O de disco  
- Não garante percentual exato de CPU em tempo real  
- Não cancela queries nem derruba conexões  
- Atua principalmente em cenários de contenção de recursos  

---

## Observações  

- O uso inadequado pode causar restrições excessivas de recursos  
- Deve ser utilizado com planejamento e testes  
- Ideal para ambientes críticos com múltiplas cargas concorrentes  
- Não substitui boas práticas de tuning e modelagem de queries  

---
