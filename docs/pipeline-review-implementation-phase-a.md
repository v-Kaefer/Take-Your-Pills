# Planejamento de implementação — integração da pipeline de review (Fase A)

Base técnica: `pipeline_review_automation_plan.md`.

## Objetivo desta frente na Fase A
Implementar a base operacional da automação de review (técnico + funcional) já na Fase A, em paralelo à fundação do projeto.

## Escopo de implementação na Fase A
- Estruturar os metadados versionados de issue/PR/review-routing.
- Definir e versionar `CODEOWNERS` inicial por áreas.
- Implementar validação de vínculo PR ↔ issue.
- Implementar roteamento automático inicial de reviewers.
- Deixar camada de status de projeto avançado para fase posterior.

## Divisão de trabalho para 4 integrantes (nomes a definir)

### Integrante 1 — Metadados e padronização
**Responsável por:**
- `.github/ISSUE_TEMPLATE/feature.yml`
- `.github/ISSUE_TEMPLATE/sub-issue.yml`
- `.github/pull_request_template.md`
- `.github/labels.yml`
- `.github/review-routing.yml` (estrutura inicial)

**Entregáveis:**
- Templates validados para obrigar campos mínimos.
- PR template com vínculo explícito de issue.
- Labels versionadas com taxonomia acordada.

### Integrante 2 — Governança técnica por área
**Responsável por:**
- `.github/CODEOWNERS`
- Mapeamento de paths do repositório para owners técnicos.
- Ajustes de branch protection para exigir review.

**Entregáveis:**
- `CODEOWNERS` funcional cobrindo áreas principais.
- Regra de review técnico automática ativa por path.

### Integrante 3 — Validação de vínculo PR ↔ issue
**Responsável por:**
- `.github/workflows/pr-validate-link.yml`
- `.github/scripts/extract-linked-issue.js`
- Validação de formato de referência da issue no corpo da PR.

**Entregáveis:**
- Workflow bloqueando PR sem vínculo válido.
- Script reutilizável para extrair issue vinculada.

### Integrante 4 — Roteamento automático de reviewers
**Responsável por:**
- `.github/workflows/pr-request-reviewers.yml`
- `.github/scripts/parse-issue-metadata.js`
- `.github/scripts/resolve-reviewers.js`
- `.github/scripts/request-reviewers.js`

**Entregáveis:**
- Solicitação automática de reviewers técnicos e funcionais.
- Fallback para owner funcional da issue pai quando necessário.

## Ordem recomendada de execução (Fase A)
1. Integrante 1 estabelece metadados e formato obrigatório.
2. Integrante 2 ativa revisão técnica base via `CODEOWNERS`.
3. Integrante 3 ativa gate de vínculo PR ↔ issue.
4. Integrante 4 ativa roteamento automático de reviewers.
5. Rodada de integração conjunta e ajustes finos.

## Dependências internas
- Integrante 3 depende do template de PR pronto (Integrante 1).
- Integrante 4 depende de:
  - metadados de issue/PR (Integrante 1),
  - extração de issue vinculada (Integrante 3),
  - owners técnicos mapeados (Integrante 2).

## Critérios de pronto da integração na Fase A
- PR sem issue vinculada falha em validação.
- PR com paths mapeados dispara review técnico por `CODEOWNERS`.
- PR vinculada à issue/sub-issue solicita review funcional automaticamente.
- Fluxo funciona para ao menos 2 áreas técnicas diferentes.
