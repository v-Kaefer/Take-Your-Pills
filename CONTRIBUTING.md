# Contributing

Guia oficial para automação de backlog no GitHub com execução única (bulk-first) via manifesto JSON.

## Objetivo principal

Use o fluxo abaixo quando quiser criar/atualizar labels, issues, sub-issues e integração com Project em uma única rodada, sem operação manual por item.

## Pré-requisitos

- `gh` autenticado (`gh auth login`)
- `python3`
- `jq`
- permissões no repositório alvo (leitura e escrita em issues)
- permissões no Project (quando `project.owner`/`project.number` estiverem no manifesto)
- labels esperadas já existentes no repositório (ou sincronizadas antes)

## Configuração recomendada

Defina repositório padrão para evitar repetir `--repo`:

```bash
export GH_REPO="owner/name"
```

## Fluxo oficial (bulk-first)

### Passo 1) Sincronizar labels

Sempre execute primeiro para garantir as labels exigidas pelo manifesto.

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

Critério de sucesso: saída JSON com `created`/`updated`/`unchanged` e `dryRun` coerente.

### Passo 2) Validar manifesto sem acessar GitHub

```bash
./scripts/github/create-issue-tree.sh \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --validate-only
```

Quando usar `--validate-only`:

- validar estrutura JSON/schema e consistência interna
- validar tipos, prioridades, áreas, obrigatórios e relações pai-filho
- sem leitura/escrita no repositório

Critério de sucesso: JSON com `stage: "validate"` e `message: "Config válido."`.

### Passo 3) Planejar execução completa (dry-run)

```bash
./scripts/github/create-issue-tree.sh \
  --repo owner/name \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --dry-run
```

Quando usar `--dry-run`:

- sempre como etapa obrigatória recomendada antes de `--apply`
- executa pré-checagens externas (`gh auth`, permissões, labels esperadas, acesso ao project)
- calcula plano (`plannedCreate`/`plannedUpdate`) sem escrever nada

Critério de sucesso: JSON com `stage: "plan"`, `failed: 0` e preconditions válidas.

### Passo 4) Aplicar execução única

```bash
./scripts/github/create-issue-tree.sh \
  --repo owner/name \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --apply
```

Quando usar `--apply`:

- após validação e dry-run aprovados
- cria/atualiza issues de forma idempotente por título
- cria e vincula sub-issues ao pai
- adiciona itens ao Project e tenta preencher campos mapeados

Critério de sucesso: JSON com `stage: "apply"` e resumo final com contagens.

## Interpretação do resumo final

Campos de auditoria no JSON de saída:

- `plannedCreate` / `plannedUpdate`: plano calculado no início
- `created` / `updated`: ações efetivas em issues
- `linked`: sub-issues vinculadas ao pai
- `projectItemsAdded`: itens adicionados ao Project
- `projectFieldsUpdated`: atualizações de campos do Project
- `failed`: falhas parciais

Política de falha parcial:

- o fluxo continua para os demais itens
- cada item retorna status e mensagem
- não há abort silencioso

## Reexecução segura (idempotência)

- reexecutar o mesmo manifesto não deve duplicar issue com mesmo título
- itens existentes são atualizados (labels/milestone/assignees)
- vínculo de sub-issue usa estratégia `graphql_or_comment` com fallback
- no Project, inclusão repetida tenta evitar duplicação e reporta status por item

## Manifesto (execução única)

Arquivo de exemplo: `config/issues/roadmap.json`.

Seções principais:

- `defaults`: labels/assignees/milestone/body padrão para todos os itens
- `project`: owner/number, arquivo de mapeamento de campos e valores extras
- `linking`: estratégia de vínculo pai-filho
- `epics`: árvore de backlog (epic + children)

Schema oficial: `config/issues/schema.json`.

## Troubleshooting

### `gh auth` inválido ou expirado

- rode `gh auth status`
- reautentique com `gh auth login`

### Sem permissão de escrita em issues/project

- confirme acesso ao repo e project
- revise escopos do token do `gh`

### `missingLabels` no dry-run

- sincronize labels com `bootstrap-labels.sh`
- rode dry-run novamente

### Erro de schema/manifesto

- rode `--validate-only`
- ajuste campos obrigatórios, enums (`type`, `area`, `priority`) e estrutura `children`

### Campos do Project não atualizam

- confira `project.fieldsFile` e IDs/opções em `.github/project/fields.json`
- regenere o mapeamento quando necessário:

```bash
./scripts/github/seed-project.sh \
  --owner owner \
  --project-number 1 \
  --output .github/project/fields.json
```

## Scripts avançados (uso pontual)

Os comandos abaixo existem para casos específicos, mas não são o fluxo principal bulk-first:

- `create-issue.sh`: criação/atualização unitária
- `create-subissue.sh`: criação de item filho e vínculo ao pai
- `create-project.sh`: criação de Project
- `seed-project.sh`: geração de mapeamento de campos do Project
