# Mapa de workflows

## Objetivo

Descrever como os workflows de qualidade, governança e smoke test se conectam.

## Fluxo principal

Os workflows atuais se dividem em seis grupos:

1. `repo-quality.yml`
2. `pr-metadata.yml`
3. `main-source-branch.yml`
4. `develop-change-summary.yml`
5. `release-version.yml`
6. `godot-smoke.yml`

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

## `develop-change-summary.yml`

- Papel: resumir mudanças de PRs abertos contra `develop`.
- Validações:
  - lê os arquivos alterados via GitHub API;
  - agrupa por setor do jogo e por área de suporte;
  - publica comentário fixo com contexto de impacto, setores afetados e exemplos representativos, sem repetir a lista bruta de arquivos.

## `release-version.yml`

- Papel: registrar e publicar a versão de release para PRs abertos contra `main`.
- Validações:
  - lê versão `alpha`, `beta` ou `final` do template da PR;
  - exige lista explícita de PRs de `develop` vinculados;
  - comenta nos PRs de `develop` com a versão planejada e, no merge, com a release criada;
  - cria tag e GitHub Release no merge para `main`.

## `godot-smoke.yml`

- Papel: smoke test da engine quando houver projeto Godot.
- Validação:
  - confirma a existência de `project.godot`;
  - executa `godot --headless --quit` quando o projeto existe;
  - registra skip explícito quando ainda não houver projeto Godot.

## Hook local `pre-push`

- Papel: impedir pushes com lint quebrado antes que saiam da máquina.
- Validações:
  - resume os arquivos e pastas afetados pelo push;
  - roda checagens sintáticas direcionadas para arquivos Python, shell, YAML, JSON e TOML alterados;
  - bloqueia o push se qualquer checagem falhar.

## `governance-bootstrap.yml`

- Papel: execução manual da sincronização de governança.
- Responsabilidades:
  - sincronizar labels;
  - sincronizar milestones;
  - validar a base do repositório;
  - criar Project v2;
  - gerar issues e sub-issues a partir de manifesto.
