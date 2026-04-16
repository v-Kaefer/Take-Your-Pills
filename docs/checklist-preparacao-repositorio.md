# Checklist consolidada — preparação do repositório (sem implementação)

Base de alinhamento:
- `análise_geral_preparacao_repositorio.md`
- `plano_implementacao_preparacao_repositorio.md`

Escopo desta checklist:
- somente padrões, regras, issues e configuração do repositório
- nenhum item de feature de jogo

---

## Onda 0 — Normalização documental (pré-requisito)
- [ ] **O0.1** Confirmar identificador canônico `01.05` em: `análise_geral_preparacao_repositorio.md`, `plano_implementacao_preparacao_repositorio.md`, `docs/pipeline-review-implementation-phase-a.md`, `docs/issues-creation-matrix.md` e `docs/issues-rollout-plan.md`.
- [ ] **O0.2** Atualizar referências antigas (`02.03`) para `01.05` quando representarem a mesma frente de CODEOWNERS/pipeline.
- [ ] **O0.3** Validar links cruzados entre os documentos de planejamento e checklist.
- [ ] **O0.4** Confirmar ausência de itens de gameplay nesta checklist.

## Onda 1 — Governança e convenções (issues 01.04 e 01.05)
- [ ] **O1.1** Fechar política de branches (`main` estável, `dev` integração, branches de trabalho).
- [ ] **O1.2** Fechar padrão de nome de branch para tarefas administrativas do repositório.
- [ ] **O1.3** Fechar padrão de commit (mensagens claras e rastreáveis à issue).
- [ ] **O1.4** Fechar padrão de PR (vínculo obrigatório com issue, escopo e critérios de aceite).
- [ ] **O1.5** Definir política de handoff entre responsáveis.
- [ ] **O1.6** Planejar `CODEOWNERS` inicial por áreas de responsabilidade.

## Onda 2 — Organização administrativa do repositório
- [ ] **O2.1** Consolidar taxonomia de labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- [ ] **O2.2** Definir milestones por fase de preparação do repositório.
- [ ] **O2.3** Consolidar estrutura de board (Backlog → Ready → In Progress → Review → QA → Done).
- [ ] **O2.4** Definir regras de entrada/saída por coluna do board.
- [ ] **O2.5** Definir padrão para abertura e rastreio de issues administrativas/sub-issues.

## Onda 3 — Qualidade operacional (pre-push e checks)
- [ ] **O3.1** Formalizar plano de validações de `pre-push` (conflitos, arquivos proibidos, smoke tests básicos, testes quando houver).
- [ ] **O3.2** Definir critérios objetivos de falha/sucesso por verificação.
- [ ] **O3.3** Definir política de ativação gradual dos checks obrigatórios.
- [ ] **O3.4** Definir estratégia de exceção temporária (quando um check ainda não puder ser obrigatório).

## Onda 4 — Pipeline de review (Fase A)
- [ ] **O4.1** Planejar padrão de metadados obrigatórios em issue templates e PR template.
- [ ] **O4.2** Planejar estrutura de roteamento de revisão por área.
- [ ] **O4.3** Planejar validação obrigatória de vínculo PR-to-issue.
- [ ] **O4.4** Planejar roteamento automático de reviewers técnicos.
- [ ] **O4.5** Planejar roteamento automático de reviewers funcionais.
- [ ] **O4.6** Planejar fallback para owner funcional da issue pai quando faltarem dados.
- [ ] **O4.7** Confirmar princípios de segurança da automação (menor privilégio, separação validação/escrita, idempotência).

---

## Divisão por responsáveis administrativos (4 integrantes)

### Integrante 1 — Governança e metadados
- [ ] Concluir itens **O1.1, O1.2, O1.3, O1.4, O1.5** (governança e convenções).
- [ ] Concluir itens **O4.1 e O4.2** (padronização de metadados e roteamento-base).
- [ ] Concluir itens **O0.1, O0.2 e O0.3** (normalização documental do `01.05`).

### Integrante 2 — Taxonomia e fluxo administrativo
- [ ] Concluir itens **O2.1, O2.2 e O2.3** (labels, milestones e board).
- [ ] Concluir itens **O2.4 e O2.5** (fluxo de status e padrão de issues).

### Integrante 3 — Qualidade operacional
- [ ] Concluir itens **O3.1 e O3.2** (planejamento de `pre-push` e critérios de validação).
- [ ] Concluir itens **O3.3 e O3.4** (ativação gradual e política de exceção).

### Integrante 4 — Pipeline de review
- [ ] Concluir item **O1.6** (`CODEOWNERS` por área).
- [ ] Concluir item **O4.3** (validação PR-to-issue).
- [ ] Concluir itens **O4.4, O4.5, O4.6 e O4.7** (roteamento e segurança da automação).

---

## Dependências críticas de execução
- [ ] Integrante 4 depende dos metadados definidos pelo Integrante 1.
- [ ] Roteamento da pipeline depende da taxonomia definida pelo Integrante 2.
- [ ] Gates da pipeline devem respeitar os critérios definidos pelo Integrante 3.

---

## Critérios de pronto desta checklist (sem implementar)
- [ ] Todos os itens permanecem como planejamento (sem execução técnica).
- [ ] Escopo está restrito a preparação do repositório.
- [ ] Ordem por ondas e dependências está coerente com o plano.
- [ ] Responsabilidades dos 4 integrantes estão claras e não sobrepostas.
