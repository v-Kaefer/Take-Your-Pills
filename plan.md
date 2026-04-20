# Plano de automação e preparação do repositório (pré-implementação)

Este documento consolida as definições, sugestões e propostas para implementar **workflows, actions, scripts, issues e sub-issues** no repositório `v-Kaefer/Take-Your-Pills`, mantendo convenções técnicas em inglês e textos explicativos em português.

## 1) Princípios de implementação

- **Convenções técnicas em inglês**: nomes de workflows, jobs, scripts, labels, branches e campos técnicos.
- **Texto explicativo em português**: descrições de templates, documentação e instruções de uso.
- **Bilingue no GitHub quando possível**: título/label técnica em inglês + descrição complementar em português.
- **Execução por fases**: primeiro governança e qualidade do repositório; depois automações de backlog; por fim integração avançada com Projects e CI de engine.

## 2) Escopo do que será implementado

### 2.1 Workflows (`.github/workflows`)

1. `ci.yml` (orquestrador)
2. `repo-quality.yml` (qualidade de arquivos do repositório)
3. `governance-checks.yml` (regras de governança)
4. `issue-automation.yml` (eventos de issues/PRs)
5. `project-sync.yml` (sincronização com GitHub Projects, fase posterior)
6. `verify-ai-contributions.yml` (opcional)

### 2.2 Arquivos de governança (`.github`)

- `CODEOWNERS`
- `pull_request_template.md`
- `labels.yml`
- `ISSUE_TEMPLATE/` com:
  - `epic.yml`
  - `feature_request.yml`
  - `task.yml`
  - `bug_report.yml`

### 2.3 Scripts (`scripts/github`)

- `bootstrap-labels.sh`
- `create-issue.sh`
- `create-subissue.sh`
- `create-issue-tree.sh`
- `create-project.sh` (fase posterior)
- `seed-project.sh` (fase posterior)

### 2.4 Configuração de backlog/projetos

- `config/issues/*.yml` para árvores de épico/feature/task
- `.github/project/fields.json` para mapear IDs de campos (quando Projects for ativado)

## 3) Convenção bilingue (PT-BR + EN) no GitHub

## 3.1 Labels

- Nome técnico (EN), ex.: `type:feature`, `priority:p1`, `area:ui`
- Descrição (PT-BR), ex.: “Trabalho de funcionalidade nova”, “Prioridade alta”, “Interface do jogo”

## 3.2 Templates de issue e PR

- Estrutura técnica em inglês (campos/chaves).
- Texto orientativo de preenchimento em português.
- Quando útil, duplicar prompts curtos em ambos os idiomas:
  - `Summary / Resumo`
  - `Acceptance Criteria / Critérios de aceitação`

## 3.3 Títulos e convenções

- Branches/PRs em inglês técnico: `feat/...`, `fix/...`, `chore/...`
- Corpo descritivo (contexto e justificativa) em português.

## 4) Proposta de fases (ordem recomendada)

## Fase 1 — Fundação de governança e qualidade

Entregas:
- `CODEOWNERS`, templates de issue/PR, `labels.yml`
- `ci.yml`, `repo-quality.yml`, `governance-checks.yml`
- `bootstrap-labels.sh`
- documentação inicial em `docs/` (governança e mapa de workflows)

Resultado:
- Repositório padronizado, com validação automática e base para colaboração.

## Fase 2 — Automação de issues e sub-issues

Entregas:
- `create-issue.sh`, `create-subissue.sh`, `create-issue-tree.sh`
- `config/issues/roadmap.yml` e arquivos de sprint/épicos

Resultado:
- Backlog reproduzível e criação estruturada de hierarquia épico → feature → task.

## Fase 3 — Integração com GitHub Projects

Entregas:
- `create-project.sh`, `seed-project.sh`
- `project-sync.yml`
- `.github/project/fields.json`

Resultado:
- Sincronização automática de status entre issues/PRs e quadro do Project.

## Fase 4 — CI específico do projeto (engine)

Entregas:
- workflows de validação/build/export do jogo (quando stack estiver consolidada)

Resultado:
- CI/CD técnico do produto além da governança.

## 5) Estrutura de issues e sub-issues

Modelo recomendado:
- **Epic** (macro objetivo)
  - **Feature** (blocos funcionais)
    - **Task/Sub-issue** (execução granular)

Campos mínimos por issue:
- tipo (`type:*`)
- área (`area:*`)
- prioridade (`priority:*`)
- critério de aceitação
- dependências
- referência à issue pai (quando houver)

## 6) Regras de automação propostas

### 6.1 `issue-automation.yml`

- Auto-label por tipo/template
- Comentário inicial orientativo em épicos
- Verificação de vínculo PR ↔ issue
- Atualização de status por evento (opened, labeled, merged)

### 6.2 `governance-checks.yml`

- Branch naming policy
- Presença e integridade de arquivos obrigatórios
- PR com template preenchido
- (quando definido) referência de issue obrigatória

### 6.3 `repo-quality.yml`

- `actionlint`, `yamllint`, `markdownlint`, `shellcheck`
- validação estrutural de arquivos YAML/JSON usados pela automação

## 7) Definições de segurança e permissões

- Permissões mínimas por workflow (`contents: read` por padrão)
- Elevar para `issues: write` / `pull-requests: write` apenas quando necessário
- Para Projects, configurar token com escopo apropriado
- Evitar segredos em scripts versionados; usar `secrets`/`vars` do GitHub

## 8) Critérios de pronto para iniciar implementação

- Escopo e ordem das fases aprovados
- Convenção bilingue aprovada
- Taxonomia inicial de labels aprovada
- Modelo de issue hierarchy (Epic/Feature/Task) aprovado
- Decisão sobre ativar ou não `verify-ai-contributions.yml` nesta primeira entrega

## 9) Próximo passo após aprovação deste plano

Após validação deste `plan.md`, iniciar implementação pela **Fase 1** com commits incrementais, mantendo:
- nomes técnicos em inglês;
- textos de orientação em português;
- elementos bilingues quando suportado pelo GitHub.

## 10) Definição operacional memorizada de "script"

Para este repositório, "script" significa:

- automação executável (CLI);
- orientada por manifesto JSON versionado;
- que cria/atualiza entidades no repositório alvo (`GH_REPO` ou `--repo owner/name`);
- com execução reproduzível, previsível e rastreável.

## 11) Checklist detalhado de implementação (JSON-first)

- [x] Definir contrato JSON versionado (`schemaVersion`) para árvore de issues.
- [x] Versionar schema único em `config/issues/schema.json`.
- [x] Criar manifestos JSON em `config/issues/*.json` seguindo o schema.
- [x] Implementar validação de manifesto antes da execução.
- [x] Implementar modo `--validate-only` para validar sem criar itens.
- [x] Padronizar scripts principais em `scripts/github/`.
- [x] Adicionar `--dry-run` e `--apply` para diferenciar simulação de execução real.
- [x] Garantir resolução explícita do repositório alvo via `GH_REPO`/`--repo`.
- [x] Implementar idempotência em criação de issue (evitar duplicação por título).
- [x] Implementar atualização de issue existente quando já encontrada.
- [x] Implementar criação determinística de árvore (épico antes dos filhos).
- [x] Implementar fallback de vínculo de sub-issue quando mutation GraphQL falhar.
- [x] Evitar comentários duplicados no fallback de vínculo.
- [x] Implementar relatório estruturado em JSON ao final de cada execução.
- [x] Reportar contagem de criados, atualizados, inalterados/falhas.
- [x] Validar autenticação/token quando execução real (`--apply`) for solicitada.
- [x] Integrar validação dos manifestos JSON no workflow de qualidade do repositório.

### Pendências futuras (não bloqueantes para esta entrega)

- [ ] Evoluir idempotência para chave lógica composta (além de título) com reconciliação.
- [ ] Persistir mapa local de IDs criados para reconciliação entre execuções.
- [ ] Expandir sync automático de Project (seed + atualização de campos) por manifesto.
