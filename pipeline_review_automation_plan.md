# Planejamento — Pipeline de Review Automático por CODEOWNERS + Issue/Sub-Issue + Labels

> Escopo deste documento: **apenas planejamento e configuração do repositório**.
> Não inclui implementação de features do jogo.

## 1. Objetivo

Este documento descreve o planejamento da pipeline de automação de review para o repositório `v-Kaefer/Take-Your-Pills`, combinando:

- review técnico por caminho de arquivo com `CODEOWNERS`
- review funcional por issue/sub-issue vinculada à PR
- padronização de labels em arquivo versionado
- validação de vínculo PR ↔ issue
- roteamento automático de reviewers
- regras e pontos de atenção de segurança

Este documento **não implementa** nada. Ele serve como plano técnico e como referência para os próximos passos.

---

## 2) Premissas e Escopo consolidado de preparação do repositório

### Situação atual considerada
- o repositório ainda está em fase inicial
- a automação será planejada do zero
- o repositório está sob um usuário (`v-Kaefer`) e não sob uma organização

### Consequência prática
Enquanto o repositório estiver sob usuário pessoal, a pipeline deve ser planejada principalmente para:
- **reviewers individuais**
- `CODEOWNERS` por usuário
- roteamento por usernames

### 2.1 Governança e convenções
- Definir padrão de branches (`main`, `dev`, branches de trabalho derivadas de `dev`).
- Definir padrão de commits e PRs.
- Definir regra de handoff entre responsáveis.

### 2.2 Taxonomia administrativa
- Padronizar labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- Criar milestones Fase A–G.

Referência das fases (escopo macro):
- Fase A: fundação técnica
- Fase B: MVP jogável (Entrega 2)
- Fase C: playtesting e revisão estrutural
- Fase D: estilização e design
- Fase E: MVP completo
- Fase F: refinamento
- Fase G: entrega final

### 2.3 Fluxo de trabalho do time
- Garantir branch `dev` como branch de integração.
- Definir/confirmar board com colunas: Backlog, Ready, In Progress, Review, QA, Done.
- Definir regras mínimas de transição no board (PR vinculada para Review, aceite completo para Done).

### 2.4 Proteção de branches
- `main`: sem push direto, merge por PR, mínimo 1 review, checks obrigatórios.
- `dev`: integração por PR, evitar merge sem revisão, checks básicos quando existirem.

### 2.5 Qualidade operacional de repositório (planejamento)
- Planejar fluxo de `pre-push` com:
  - detecção de conflitos de merge
  - bloqueio de arquivos indevidos
  - smoke test do Godot (verificação rápida de integridade/importação)
  - execução de testes (quando existirem)
- Definição documental de critérios mínimos de validação.

### 2.6 Integração da pipeline de review (Fase A)
- Planejar automação com `CODEOWNERS` + vínculo PR↔issue + roteamento automático de reviewers.
- Planejar arquivos de metadados em `.github/` (templates, routing, labels versionadas).
- Planejar workflows de validação de vínculo e solicitação automática de review.


O repositório não será migrado para uma organização no futuro, ele serve para formular, desenvolver e apresentar um trabalho para a faculdade.

---

## 3. Objetivo da pipeline

A pipeline deve cobrir estes cenários:

- se a PR tocar determinada área do código, pedir review aos owners técnicos daquela área
- se a PR estiver vinculada à issue/sub-issue X, pedir review ao líder funcional daquela task
- se a PR tocar UI e também fechar uma sub-issue de gameplay, pedir review técnico de UI **e** review funcional de gameplay
- se uma sub-issue não tiver líder próprio, herdar o líder da issue pai, de acordo com seu contexto
- se a issue estiver em determinado status de projeto, permitir ajustes futuros no reviewer preferencial

A regra principal será:

> `CODEOWNERS` garante review técnico por área de código.  
> Workflow garante review funcional por issue/sub-issue.

---

## 4. Arquitetura planejada

## Camada 1 — Padrão de metadados
Arquivos planejados:
- `.github/ISSUE_TEMPLATE/feature.yml`
- `.github/ISSUE_TEMPLATE/sub-issue.yml`
- `.github/pull_request_template.md`
- `.github/review-routing.yml`
- `.github/labels.yml`

Função:
- garantir que issues e PRs tenham metadados parseáveis
- reduzir texto livre e ambiguidade
- centralizar regras de roteamento e labels

## Camada 2 — Review técnico nativo
Arquivo planejado:
- `.github/CODEOWNERS`

Função:
- solicitar review automaticamente quando a PR mexer em caminhos específicos
- servir como base técnica mínima, independente do contexto da issue

## Camada 3 — Validação de vínculo
Workflow planejado:
- `.github/workflows/pr-validate-link.yml`

Função:
- garantir que a PR esteja vinculada a uma issue/sub-issue
- falhar se não houver vínculo válido

## Camada 4 — Roteamento automático de reviewers
Workflows / scripts planejados:
- `.github/workflows/pr-request-reviewers.yml`
- `.github/scripts/extract-linked-issue.js`
- `.github/scripts/parse-issue-metadata.js`
- `.github/scripts/resolve-reviewers.js`
- `.github/scripts/request-reviewers.js`

Função:
- ler issue vinculada
- extrair líder funcional
- combinar com review técnico
- pedir review automaticamente

## Camada 5 — Status de projeto / refinamentos avançados
Workflow opcional planejado:
- `.github/workflows/project-status-routing.yml`

Função:
- reagir a status do Project
- ajustar reviewer preferencial em cenários futuros

Observação:
Esta camada deve entrar **por último**, depois que a base estiver estável.

---

## 5. Estrutura de arquivos planejada

```text
.github/
  CODEOWNERS
  pull_request_template.md
  review-routing.yml
  labels.yml
  ISSUE_TEMPLATE/
    feature.yml
    sub-issue.yml
  workflows/
    issue-metadata-check.yml
    pr-validate-link.yml
    pr-request-reviewers.yml
    labels-sync.yml
    project-status-routing.yml   # opcional
  scripts/
    extract-linked-issue.js
    parse-issue-metadata.js
    resolve-reviewers.js
    request-reviewers.js
```

---

## 6. Planejamento dos arquivos de metadados

## 6.1 `CODEOWNERS`
Função:
- mapear caminhos do repositório para owners técnicos

Exemplo conceitual:
- `scenes/player/` → owner técnico de player
- `scenes/ui/` → owner técnico de UI
- `scripts/systems/` → owner técnico de systems
- `audio/` → owner técnico de áudio

Critério de uso:
- obrigatório para review técnico por área
- não substitui review funcional por issue

## 6.2 `feature.yml` e `sub-issue.yml`
Função:
- obrigar issues e sub-issues a seguirem estrutura padronizada

Campos planejados:
- tipo da task
- área
- prioridade
- parent issue
- líder funcional
- reviewers adicionais
- dependências

Regra:
- evitar texto livre como única fonte de metadados

## 6.3 `pull_request_template.md`
Função:
- padronizar a PR para que o workflow encontre a issue vinculada sem heurística frágil

Campos planejados:
- issue vinculada
- tipo de mudança
- áreas tocadas
- notas de teste
- observações de risco

## 6.4 `review-routing.yml`
Função:
- centralizar a lógica de roteamento por área e fallback

Conteúdo planejado:
- área → reviewers padrão
- fallback reviewer
- regras de herança de parent issue
- regras para múltiplas áreas

## 6.5 `labels.yml`
Função:
- padronizar labels em arquivo versionado
- permitir sincronização/recriação consistente das labels

Observação:
- GitHub não consome esse arquivo nativamente
- ele deve ser usado em conjunto com um workflow de sincronização de labels

---

## 7. Planejamento dos workflows

## 7.1 `issue-metadata-check.yml`
### Objetivo
Validar, no momento da abertura ou edição da issue, se os campos obrigatórios foram preenchidos.

### Evento planejado
- `issues` em `opened` e `edited`

### Validações planejadas
- área obrigatória
- prioridade obrigatória
- líder funcional obrigatório
- parent issue obrigatório quando a task for sub-issue

### Resultado esperado
- issues incompletas não seguem adiante sem correção

---

## 7.2 `pr-validate-link.yml`
### Objetivo
Garantir que toda PR relevante esteja ligada a uma issue/sub-issue válida.

### Evento planejado
- `pull_request` em `opened`, `edited`, `reopened`, `synchronize`

### Validações planejadas
- existe issue vinculada na PR
- a issue existe
- a issue contém metadados suficientes
- a PR não depende de interpretação ambígua do texto

### Resultado esperado
- PR sem issue vinculada falha na validação

---

## 7.3 `pr-request-reviewers.yml`
### Objetivo
Pedir reviewers automaticamente com base em:
- `CODEOWNERS`
- issue vinculada
- regra de herança da issue pai
- fallback por área

### Evento planejado
- depois da validação da PR
- ou em `pull_request` com gates de segurança explícitos

### Ações planejadas
- extrair issue vinculada
- ler metadados da issue
- resolver reviewers funcionais
- combinar com reviewers técnicos
- remover duplicatas
- remover o autor da PR
- solicitar review automaticamente

### Resultado esperado
- PR já nasce ou evolui com reviewers corretos pedidos automaticamente

---

## 7.4 `labels-sync.yml`
### Objetivo
Sincronizar labels a partir de `.github/labels.yml`.

### Uso planejado
- execução manual (`workflow_dispatch`) inicialmente
- execução opcional em mudanças do arquivo de labels no futuro

### Resultado esperado
- labels do repositório permanecem padronizadas

---

## 7.5 `project-status-routing.yml` (opcional)
### Objetivo
Enriquecer a lógica de roteamento com status do Project.

### Observação
- esta automação é mais complexa
- deve entrar apenas depois que as camadas anteriores estiverem estáveis

### Uso planejado
- ler status da issue no Project
- registrar ou inferir reviewer preferencial futuro

---

## 8. Planejamento dos scripts auxiliares

## 8.1 `extract-linked-issue.js`
Função:
- encontrar o número da issue referenciada na PR

Entrada:
- corpo da PR

Saída:
- número da issue vinculada ou erro estruturado

## 8.2 `parse-issue-metadata.js`
Função:
- ler a issue vinculada
- extrair área, prioridade, líder funcional, parent issue e reviewers adicionais

Entrada:
- corpo da issue e/ou labels relevantes

Saída:
- objeto normalizado de metadados

## 8.3 `resolve-reviewers.js`
Função:
- combinar reviewers vindos de diferentes fontes

Fontes planejadas:
- issue atual
- issue pai
- config de roteamento
- paths / CODEOWNERS

Saída:
- lista final deduplicada de reviewers

## 8.4 `request-reviewers.js`
Função:
- chamar a API para solicitar reviewers

Entrada:
- lista final de reviewers
- número da PR

Saída:
- request review executado ou log de fallback

---

## 9. Regras de decisão planejadas

## Regra 1 — Review técnico por arquivo
Sempre usar `CODEOWNERS` para garantir review técnico por área tocada.

## Regra 2 — Review funcional por issue
Sempre usar issue/sub-issue vinculada para descobrir liderança funcional.

## Regra 3 — Combinação aditiva
Quando ambos existirem, a combinação deve ser **aditiva**, não excludente.

## Regra 4 — Herança da parent issue
Se a sub-issue não tiver líder funcional explícito, herdar da issue pai.

## Regra 5 — Fallback obrigatório
Se nenhum reviewer funcional puder ser resolvido, usar fallback definido em `review-routing.yml`.

## Regra 6 — Autor nunca aprova a si mesmo
O autor da PR não deve entrar na lista final de requested reviewers.

## Regra 7 — Duplicatas devem ser removidas
Se um reviewer aparecer por mais de uma fonte, ele deve entrar apenas uma vez.

---

## 10. Pontos de atenção de segurança

Esta é a parte mais importante da pipeline.

## 10.1 Princípio do menor privilégio
Cada workflow deve receber apenas as permissões mínimas necessárias.

Planejamento:
- validações simples com permissões de leitura
- request de reviewers somente no workflow que realmente precisa escrever na PR

## 10.2 Separar validação de escrita
Sempre que possível:
- um workflow apenas valida
- outro workflow, separado, executa ações com permissão de escrita

Isso reduz superfície de risco.

## 10.3 Não executar código da PR para descobrir metadados
A automação de review deve se basear apenas em:
- corpo da PR
- issue vinculada
- arquivos de configuração do repositório base
- metadados do GitHub

Ela **não deve depender de checkout e execução do código proposto pela PR** só para resolver reviewers.

## 10.4 Cuidado extra com eventos que escrevem na PR
Qualquer workflow que faça request de review, adicione labels ou altere estado da PR deve ser tratado como sensível.

Planejamento:
- evitar usar permissões de escrita em workflows genéricos sem necessidade
- revisar cuidadosamente gatilhos e escopo

## 10.5 Nunca confiar em texto livre sem normalização
Campos críticos devem ser parseáveis e previsíveis.

Risco:
- issue escrita em formato inconsistente quebrar a automação

Mitigação:
- issue forms
- PR template
- validadores de metadados

## 10.6 Tratar dados ausentes ou inválidos com fallback seguro
Se a issue estiver incompleta ou inconsistente:
- não quebrar silenciosamente
- falhar com mensagem clara
- ou usar fallback controlado quando apropriado

## 10.7 Evitar loops e reprocessamentos desnecessários
A automação deve ser idempotente.

Planejamento:
- não pedir reviewers repetidamente a cada evento se o conjunto já estiver correto
- registrar ou comparar estado antes de escrever novamente

## 10.8 Não expor segredos em logs
Logs dos workflows e scripts não devem imprimir:
- tokens
- cabeçalhos completos
- payloads sensíveis

## 10.9 Validar issue vinculada antes de agir
Antes de pedir review automaticamente, o workflow deve confirmar:
- issue existe
- issue pertence ao contexto esperado
- metadados mínimos estão presentes

## 10.10 Project/status como camada tardia
Integração com status do Project deve entrar só depois da base estar estável.

Motivo:
- aumenta complexidade
- aumenta risco de rotas erradas
- cria mais pontos de falha e manutenção

---

## 11. Planejamento do arquivo de labels padronizadas

Arquivo planejado:
- `.github/labels.yml`

Objetivo:
- servir como fonte versionada das labels do projeto
- permitir sincronização por workflow ou ferramenta dedicada

## Conteúdo planejado para `.github/labels.yml`

```yaml
labels:
  - name: "priority:high"
    color: "B60205"
    description: "Alta prioridade"

  - name: "priority:medium"
    color: "FBCA04"
    description: "Prioridade média"

  - name: "priority:low"
    color: "0E8A16"
    description: "Baixa prioridade"

  - name: "type:feature"
    color: "1D76DB"
    description: "Nova funcionalidade"

  - name: "type:bug"
    color: "D73A4A"
    description: "Correção de defeito"

  - name: "type:chore"
    color: "C5DEF5"
    description: "Tarefa técnica ou operacional"

  - name: "type:docs"
    color: "5319E7"
    description: "Documentação"

  - name: "type:test"
    color: "0052CC"
    description: "Testes automatizados ou manuais"

  - name: "type:polish"
    color: "F9D0C4"
    description: "Polimento visual, UX ou refinamento"

  - name: "area:player"
    color: "C2E0C6"
    description: "Área do player"

  - name: "area:runner"
    color: "C2E0C6"
    description: "Área do loop runner"

  - name: "area:collectables"
    color: "C2E0C6"
    description: "Área dos coletáveis"

  - name: "area:speed-system"
    color: "C2E0C6"
    description: "Área do sistema de velocidade"

  - name: "area:scenario"
    color: "C2E0C6"
    description: "Área dos cenários e transições"

  - name: "area:ui"
    color: "C2E0C6"
    description: "Área da interface"

  - name: "area:audio"
    color: "C2E0C6"
    description: "Área de áudio"

  - name: "area:build"
    color: "C2E0C6"
    description: "Área de build e entrega"

  - name: "area:qa"
    color: "C2E0C6"
    description: "Área de testes e QA"

  - name: "area:repo"
    color: "C2E0C6"
    description: "Área de repositório, workflow e automação"

  - name: "status:blocked"
    color: "000000"
    description: "Task bloqueada"

  - name: "status:needs-review"
    color: "5319E7"
    description: "Pronta para revisão"

  - name: "status:ready-for-qa"
    color: "006B75"
    description: "Pronta para validação de QA"
```

## Regras para labels
- uma issue deve ter exatamente uma label de prioridade
- uma issue deve ter pelo menos uma label de área
- uma issue deve ter exatamente uma label de tipo
- labels de status mudam ao longo do fluxo

---

## 12. Ordem recomendada de implementação futura

### Etapa 1
Criar:
- `CODEOWNERS`
- `feature.yml`
- `sub-issue.yml`
- `pull_request_template.md`
- `review-routing.yml`
- `labels.yml`

### Etapa 2
Criar workflow:
- `issue-metadata-check.yml`

### Etapa 3
Criar workflow:
- `pr-validate-link.yml`

### Etapa 4
Criar scripts:
- `extract-linked-issue.js`
- `parse-issue-metadata.js`
- `resolve-reviewers.js`
- `request-reviewers.js`

### Etapa 5
Criar workflow:
- `pr-request-reviewers.yml`

### Etapa 6
Criar workflow:
- `labels-sync.yml`

### Etapa 7
Avaliar necessidade real de:
- `project-status-routing.yml`

---

## 13. Resultado esperado da pipeline

Ao final da implementação futura, a pipeline deve permitir:

- review técnico automático por área do código
- review funcional automático por issue/sub-issue
- padronização versionada de labels
- validação de PR sem issue vinculada
- herança de liderança via issue pai
- adição segura e previsível de reviewers
- base sólida para evolução futura com status de Project

---

## 14. Diretriz final

A pipeline deve priorizar, nesta ordem:

1. previsibilidade
2. segurança
3. legibilidade operacional
4. baixo acoplamento
5. extensibilidade

Se houver dúvida entre uma automação mais “inteligente” e uma automação mais previsível, a decisão padrão deve ser:

> preferir a automação mais simples, mais auditável e mais segura.
