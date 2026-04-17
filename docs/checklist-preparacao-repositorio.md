# Checklist consolidada — preparação do repositório (implementada)

Base de alinhamento:
- `análise_geral_preparacao_repositorio.md`
- `plano_implementacao_preparacao_repositorio.md`

Escopo desta checklist:
- somente padrões, regras, issues e configuração do repositório
- nenhum item de feature de jogo

---

## Onda 0 — Normalização documental (pré-requisito)
- [x] **O0.1** Confirmar identificador canônico `01.05` em: `análise_geral_preparacao_repositorio.md`, `plano_implementacao_preparacao_repositorio.md`, `docs/pipeline-review-implementation-phase-a.md`, `docs/issues-creation-matrix.md` e `docs/issues-rollout-plan.md`.
- [x] **O0.2** Atualizar referências antigas (`02.03`) para `01.05` quando representarem a mesma frente de CODEOWNERS/pipeline.
- [x] **O0.3** Validar links cruzados entre os documentos de planejamento e checklist.
- [x] **O0.4** Confirmar ausência de itens de gameplay nesta checklist.

## Onda 1 — Governança e convenções (issues 01.04 e 01.05)
- [x] **O1.1** Fechar política de branches (`main` estável, `dev` integração, branches de trabalho).
- [x] **O1.2** Fechar padrão de nome de branch para tarefas administrativas do repositório.
- [x] **O1.3** Fechar padrão de commit (mensagens claras e rastreáveis à issue).
- [x] **O1.4** Fechar padrão de PR (vínculo obrigatório com issue, escopo e critérios de aceite).
- [x] **O1.5** Definir política de handoff entre responsáveis.
- [x] **O1.6** Planejar `CODEOWNERS` inicial por áreas de responsabilidade.

## Onda 2 — Organização administrativa do repositório
- [x] **O2.1** Consolidar taxonomia de labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- [x] **O2.2** Definir milestones por fase de preparação do repositório.
- [x] **O2.3** Consolidar estrutura de board (Backlog → Ready → In Progress → Review → QA → Done).
- [x] **O2.4** Definir regras de entrada/saída por coluna do board.
- [x] **O2.5** Definir padrão para abertura e rastreio de issues administrativas/sub-issues.

## Onda 3 — Qualidade operacional (pre-push e checks)
- [x] **O3.1** Formalizar plano de validações de `pre-push` (conflitos, arquivos proibidos, smoke tests básicos, testes quando houver).
- [x] **O3.2** Definir critérios objetivos de falha/sucesso por verificação.
- [x] **O3.3** Definir política de ativação gradual dos checks obrigatórios.
- [x] **O3.4** Definir estratégia de exceção temporária (quando um check ainda não puder ser obrigatório).

## Onda 4 — Pipeline de review (Fase A)
- [x] **O4.1** Planejar padrão de metadados obrigatórios em issue templates e PR template.
- [x] **O4.2** Planejar estrutura de roteamento de revisão por área.
- [x] **O4.3** Planejar validação obrigatória de vínculo PR-to-issue.
- [x] **O4.4** Planejar roteamento automático de reviewers técnicos.
- [x] **O4.5** Planejar roteamento automático de reviewers funcionais.
- [x] **O4.6** Planejar fallback para owner funcional da issue pai quando faltarem dados.
- [x] **O4.7** Confirmar princípios de segurança da automação (menor privilégio, separação validação/escrita, idempotência).

---

## Divisão por responsáveis administrativos (4 integrantes)

### Integrante 1 — Governança e metadados
- [x] Concluir itens **O1.1, O1.2, O1.3, O1.4, O1.5** (governança e convenções).
- [x] Concluir itens **O4.1 e O4.2** (padronização de metadados e roteamento-base).
- [x] Concluir itens **O0.1, O0.2 e O0.3** (normalização documental do `01.05`).

### Integrante 2 — Taxonomia e fluxo administrativo
- [x] Concluir itens **O2.1, O2.2 e O2.3** (labels, milestones e board).
- [x] Concluir itens **O2.4 e O2.5** (fluxo de status e padrão de issues).

### Integrante 3 — Qualidade operacional
- [x] Concluir itens **O3.1 e O3.2** (planejamento de `pre-push` e critérios de validação).
- [x] Concluir itens **O3.3 e O3.4** (ativação gradual e política de exceção).

### Integrante 4 — Pipeline de review
- [x] Concluir item **O1.6** (`CODEOWNERS` por área).
- [x] Concluir item **O4.3** (validação PR-to-issue).
- [x] Concluir itens **O4.4, O4.5, O4.6 e O4.7** (roteamento e segurança da automação).

---

## Dependências críticas de execução
- [x] Integrante 4 depende dos metadados definidos pelo Integrante 1.
- [x] Roteamento da pipeline depende da taxonomia definida pelo Integrante 2.
- [x] Gates da pipeline devem respeitar os critérios definidos pelo Integrante 3.

---

## Critérios de pronto desta checklist (implementação concluída)
- [x] Todos os itens foram executados com artefatos versionados de preparação do repositório.
- [x] Escopo está restrito a preparação do repositório.
- [x] Ordem por ondas e dependências está coerente com o plano.
- [x] Responsabilidades dos 4 integrantes estão claras e não sobrepostas.
