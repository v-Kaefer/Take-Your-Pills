# Contributing

## 1) Branch naming
Use branches with the approved prefix pattern:

- `feat/...`
- `fix/...`
- `chore/...`
- `docs/...`
- `refactor/...`
- `test/...`
- `hotfix/...`
- `phase/...`
- `task/...`

Example: `feat/repo-governance-bootstrap`

## 2) Pull request body (required sections)
Follow `/.github/pull_request_template.md` and keep these sections filled:

- `## Linked Issue` with `Closes/Fixes/Resolves #123`
- `## How to test`
- `## Evidence`
- `## DoD checklist`

## 3) Local validation before PR updates
From repository root:

```bash
./scripts/validation/repo_quality.sh
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --dry-run --skip-labels
```

For full governance bootstrap execution (real write operations), use:

```bash
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --no-dry-run --link-subissues
```

## 4) Governance bootstrap references
- Main runbook: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- Local orchestrator: `/scripts/github/bootstrap_local.sh`
- Underlying scripts (kept separated):
  - `/scripts/github/sync_labels.py`
  - `/scripts/github/create_project_v2.py`
  - `/scripts/github/generate_issues.py`
