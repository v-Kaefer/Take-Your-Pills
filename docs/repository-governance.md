# Governança do repositório

Este documento define as regras-base de colaboração e automação do repositório.

## Convenções de idioma

- Convenções técnicas (labels, branches, workflows, scripts): **inglês**.
- Texto explicativo e orientativo: **português**.
- Quando aplicável, campos curtos em formato bilingue (ex.: `Summary / Resumo`).

## Convenções de branch

Formato:

`<type>/<slug>`

Tipos aceitos:

- `feat`
- `fix`
- `chore`
- `docs`
- `refactor`
- `test`
- `hotfix`

Exemplo:

`feat/add-initial-governance-workflows`

## Regras de pull request

- Toda PR deve usar o template padrão.
- Toda PR deve referenciar issue (ex.: `Closes #123`).
- Toda PR deve manter checklist de validação mínima preenchida.

## Estrutura de backlog recomendada

- Epic (escopo macro)
  - Feature (funcionalidade)
    - Task/Sub-issue (execução granular)

## Labels

Fonte única da verdade:

- `.github/labels.yml`

Sincronização:

- `scripts/github/bootstrap-labels.sh`
