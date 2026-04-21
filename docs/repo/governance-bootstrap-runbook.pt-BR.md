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
4. Em **Settings -> Actions -> General**, permita:
   - `Read and write permissions` para o `GITHUB_TOKEN`;
   - criação e aprovação de PRs por GitHub Actions (se desejado).
5. Para criar **Project v2**, autentique o `gh` com PAT contendo escopo `project` (além de `repo`).

## 3) Como executar agora
### Opção A — Workflow manual (recomendado)
1. Push desta branch.
2. GitHub -> **Actions** -> `Governance bootstrap (manual)` -> **Run workflow**.
3. Rodar `dry_run=true` primeiro.
4. Rodar `dry_run=false` para criar labels + issues/tasks/sub-issues.

### Opção B — Local com script único
> Segurança: evite colocar PAT diretamente no histórico do shell. Prefira carregar via gerenciador de segredos, arquivo de ambiente local não versionado, ou prompt interativo.

```bash
gh auth login
export GITHUB_REPOSITORY=v-Kaefer/Take-Your-Pills
export GH_TOKEN=SEU_PAT_COM_PERMISSAO_PROJECT
chmod +x scripts/github/bootstrap_local.sh

# Primeiro teste
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --dry-run

# Execução real
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --no-dry-run --link-subissues
```

Os scripts continuam separados (`sync_labels.py`, `create_project_v2.py`, `generate_issues.py`), mas o `bootstrap_local.sh` orquestra tudo em um único comando.

## 4) Observações
- Responsáveis por fase estão `TBD` em `config/phases/phase-review-policy.json`.
- Loja e ranking online estão marcados como stretch no manifesto.
- Base de teste Godot definida como GDUnit4 em política de testes.
