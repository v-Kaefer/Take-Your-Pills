# Mapa de workflows

## Objetivo

Descrever como os workflows da Fase 1 se conectam e quais responsabilidades cobrem.

## Fluxo principal

`ci.yml` é o workflow orquestrador e chama:

1. `repo-quality.yml`
2. `governance-checks.yml`

## Workflows da Fase 1

## `ci.yml`

- Papel: orquestração da pipeline de repositório.
- Trigger: `push`, `pull_request`, `workflow_dispatch`.
- Resultado: consolida checagens de qualidade e governança.

## `repo-quality.yml`

- Papel: validar qualidade dos arquivos do repositório.
- Ferramentas: `actionlint`, `yamllint`, `markdownlint`, `shellcheck`.
- Validação adicional: consistência de manifestos JSON de backlog via `create-issue-tree.sh --validate-only`.
- Resultado: evita regressões em arquivos de automação e documentação.

## `governance-checks.yml`

- Papel: validar regras mínimas de governança.
- Validações:
  - presença de arquivos obrigatórios;
  - padrão de nome de branch;
  - referência de issue na PR.

## Evolução prevista

Fases futuras devem adicionar:

- automação de issues/sub-issues;
- sincronização com GitHub Projects;
- CI específico da engine do jogo.
