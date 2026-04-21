# Runbook — Bootstrap de governança

## 1) Permissões necessárias
Para criar/editar Project, labels, issues e sub-issues automaticamente, use uma conta com:
- acesso **Admin** ao repositório
- permissão para **Projects** (Project v2)
- token com escopos: `repo`, `project` e `read:org` (se necessário)

## 2) Como conceder admin no GitHub
1. Repositório -> **Settings** -> **Collaborators and teams**.
2. Adicione o usuário/conta que executará as automações.
3. Defina role **Admin**.

## 3) Como executar agora
### Opção A — Workflow manual (recomendado)
1. Push desta branch.
2. GitHub -> **Actions** -> `Governance bootstrap (manual)` -> **Run workflow**.
3. Rodar `dry_run=true` primeiro.
4. Rodar `dry_run=false` para criar labels + issues/tasks/sub-issues.

### Opção B — Local com GitHub CLI
```bash
gh auth login
export GITHUB_REPOSITORY=v-Kaefer/Take-Your-Pills
python scripts/github/sync_labels.py config/project/labels.json
python scripts/github/generate_issues.py config/stories/backlog-manifest.json --link-subissues
python scripts/github/create_project_v2.py config/project/project-definition.json
```

## 4) Observações
- Responsáveis por fase estão `TBD` em `config/phases/phase-review-policy.json`.
- Loja e ranking online estão marcados como stretch no manifesto.
- Base de teste Godot definida como GDUnit4 em política de testes.
