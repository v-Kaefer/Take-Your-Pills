# Contributing

Guia simples e direto para rodar os scripts de automação do repositório.

## Pré-requisitos

- `gh` autenticado (`gh auth login`)
- `python3`
- `jq`
- permissões no repositório alvo

## Regra geral dos scripts

- `script` = automação CLI orientada por JSON
- destino via `GH_REPO` ou `--repo owner/name`
- quando disponível:
  - `--dry-run` = simulação (padrão)
  - `--apply` = execução real

## Scripts de backlog e issues

### 1) Sincronizar labels

```bash
./scripts/github/bootstrap-labels.sh --repo owner/name --dry-run
./scripts/github/bootstrap-labels.sh --repo owner/name --apply
```

Com arquivo customizado:

```bash
./scripts/github/bootstrap-labels.sh \
  --repo owner/name \
  --labels-file .github/labels.yml \
  --apply
```

### 2) Criar ou atualizar issue unitária

```bash
./scripts/github/create-issue.sh \
  --repo owner/name \
  --title "[Feature] Exemplo" \
  --type feature \
  --area automation \
  --priority p1 \
  --labels "ready" \
  --dry-run
```

Execução real:

```bash
./scripts/github/create-issue.sh \
  --repo owner/name \
  --title "[Feature] Exemplo" \
  --type feature \
  --area automation \
  --priority p1 \
  --labels "ready" \
  --apply
```

### 3) Criar sub-issue e vincular ao pai

```bash
./scripts/github/create-subissue.sh \
  --repo owner/name \
  --parent 123 \
  --title "[Task] Exemplo" \
  --type task \
  --area docs \
  --priority p2 \
  --dry-run
```

Execução real:

```bash
./scripts/github/create-subissue.sh \
  --repo owner/name \
  --parent 123 \
  --title "[Task] Exemplo" \
  --type task \
  --area docs \
  --priority p2 \
  --apply
```

### 4) Criar árvore completa de issues por JSON

Validar manifesto:

```bash
./scripts/github/create-issue-tree.sh \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --validate-only
```

Simular criação:

```bash
./scripts/github/create-issue-tree.sh \
  --repo owner/name \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --dry-run
```

Criar de fato:

```bash
./scripts/github/create-issue-tree.sh \
  --repo owner/name \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --apply
```

## Scripts de project

### 5) Criar project (GitHub Projects)

```bash
./scripts/github/create-project.sh \
  --owner owner \
  --title "Take Your Pills"
```

Criando e vinculando ao repositório:

```bash
./scripts/github/create-project.sh \
  --owner owner \
  --title "Take Your Pills" \
  --repo owner/name
```

### 6) Gerar mapeamento de campos do project

```bash
./scripts/github/seed-project.sh \
  --owner owner \
  --project-number 1 \
  --output .github/project/fields.json
```

## Dica rápida de destino padrão

Defina um repositório padrão para evitar repetir `--repo`:

```bash
export GH_REPO="owner/name"
```
