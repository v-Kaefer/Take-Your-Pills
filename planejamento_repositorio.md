# Planejamento de preparação do repositório (somente requisitos de setup)

> Escopo deste documento: **apenas planejamento e configuração do repositório**.  
> Não inclui implementação de features do jogo.

## 1) Fontes revisadas para consolidar requisitos
- `copilot_repo_admin_request.md`
- `docs/repo-admin-checklist.md`
- `docs/issues-rollout-plan.md` (Lote 0 e item 02.03 em Fase A)
- `docs/issues-creation-matrix.md` (itens de área `repo/build/qa/test`)
- `pipeline_review_automation_plan.md`
- `docs/pipeline-review-implementation-phase-a.md`
- `take_your_pills_project_definitions_update.md` (política de branches, labels e validações de push)
- `take_your_pills_issues_detalhados.md` (01.04, 02.01, 02.02)

## 2) Escopo consolidado de preparação do repositório

### 2.1 Governança e convenções
- Definir padrão de branches (`main`, `dev`, branches de trabalho derivadas de `dev`).
- Definir padrão de commits e PRs.
- Definir regra de handoff entre responsáveis.

### 2.2 Taxonomia administrativa
- Padronizar labels (`priority:*`, `type:*`, `area:*`, `status:*`).
- Criar milestones Fase A–F.

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
  - smoke check Godot
  - execução de testes (quando existirem)

### 2.6 Integração da pipeline de review (Fase A)
- Planejar automação com `CODEOWNERS` + vínculo PR↔issue + roteamento de reviewers.
- Planejar arquivos de metadados em `.github/` (templates, routing, labels versionadas).
- Planejar workflows de validação de vínculo e solicitação automática de review.

## 3) Divisão planejada para 4 integrantes (papéis e responsáveis a definir)

### Papel 1 — Líder de Convenções e Metadados (Assignee TBD)
- Convenções de branch/commit/PR.
- Templates de issue/PR e estrutura de metadados.
- Versionamento de labels/review routing.

### Papel 2 — Líder de Administração do Repositório (Assignee TBD)
- Labels e milestones.
- Branch `dev`, proteção de `main`/`dev`.
- Estrutura e regras do board.

### Papel 3 — Líder de Quality Gates e Validações de Push (Assignee TBD)
- Plano de `pre-push` e checks básicos.
- Definição documental de critérios mínimos de validação.

### Papel 4 — Líder da Pipeline de Review Automático (Fase A) (Assignee TBD)
- Planejamento de `CODEOWNERS`.
- Planejamento de validação PR↔issue.
- Planejamento de roteamento automático de reviewers.

## 4) Checklist consolidada (somente preparação do repositório)
- [ ] Definir convenções de repositório (branch/commit/PR/handoff).
- [ ] Consolidar taxonomia oficial de labels.
- [ ] Criar milestones Fase A–F.
- [ ] Garantir branch `dev` e política de integração.
- [ ] Configurar proteção de branch para `main`.
- [ ] Configurar proteção de branch para `dev`.
- [ ] Definir checks de proteção recomendados.
- [ ] Estruturar board com colunas padrão.
- [ ] Definir regras operacionais do board.
- [ ] Planejar fluxo de validação `pre-push` (conflitos/arquivos proibidos/smoke/testes).
- [ ] Planejar integração de pipeline de review na Fase A (`CODEOWNERS` + PR↔issue + reviewers).
- [ ] Consolidar dependências e ordem de execução entre as 4 frentes.

## 5) Ordem recomendada de execução (planejamento)
1. Convenções e metadados base.
2. Labels, milestones, board e políticas de branch.
3. Planejamento de qualidade de push.
4. Planejamento da pipeline de review da Fase A.
5. Revisão final de consistência (sem implementação nesta etapa).

### Dependências entre etapas
- Etapa 2 depende da Etapa 1 (convenções definem padrão de labels/PR/branch para configuração administrativa).
- Etapa 3 depende da Etapa 1 e da Etapa 2 (gates de push devem refletir convenções e políticas de branch).
- Etapa 4 depende da Etapa 1 e da Etapa 2 (metadados, labels e governança base precisam estar definidos).
- Etapa 5 depende da conclusão das Etapas 1–4.
