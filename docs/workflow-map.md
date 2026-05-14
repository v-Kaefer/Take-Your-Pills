# Mapa de workflows

## Objetivo

Descrever como os workflows de qualidade, governança e smoke test se conectam.

## Fluxo principal

Os workflows atuais se dividem em quatro grupos:

1. `repo-quality.yml`
2. `pr-metadata.yml`
3. `main-source-branch.yml`
4. `godot-smoke.yml`

O `governance-bootstrap.yml` fica como execução manual para sincronização e geração de backlog.

## `repo-quality.yml`

- Papel: validar qualidade dos arquivos do repositório.
- Ferramentas: `actionlint`, `yamllint`, `markdownlint`, `shellcheck`.
- Validações adicionais: suíte Python de governança e consistência de manifestos JSON de backlog.
- Resultado: evita regressões em automações, scripts e documentação.

## `pr-metadata.yml`

- Papel: validar nome de branch e corpo da PR.
- Validações:
  - padrão de branch aprovado;
  - presença das seções obrigatórias do template;
  - referência de issue dentro de `## Linked Issue`;
  - checklist e campo de teste preenchidos.

## `main-source-branch.yml`

- Papel: garantir a política de branch principal.
- Validação:
  - PR direcionada para `main` precisa vir de `develop` no mesmo repositório.

## `godot-smoke.yml`

- Papel: smoke test da engine quando houver projeto Godot.
- Validação:
  - confirma a existência de `project.godot`;
  - executa `godot --headless --quit` quando o projeto existe;
  - registra skip explícito quando ainda não houver projeto Godot.

## `governance-bootstrap.yml`

- Papel: execução manual da sincronização de governança.
- Responsabilidades:
  - sincronizar labels;
  - sincronizar milestones;
  - validar a base do repositório;
  - criar Project v2;
  - gerar issues e sub-issues a partir de manifesto.
