# Contributing

## 1) Branch naming

Use branches with the approved prefix pattern:

- `feat/...`
- `fix/...`
- `docs/...`
- `refactor/...`
- `test/...`
- `hotfix/...`
- `phase/...`
- `task/...`

Example: `feat/repo-governance-bootstrap`

## 2) Pull request body

Follow `/.github/pull_request_template.md` and keep these sections filled:

- `## Linked Issue` with `Closes`, `Fixes`, or `Resolves #123`
- `## Milestone` with a value such as `MS0`
- `## Summary`
- `## How to test`
- `## Evidence`
- `## DoD checklist`

The PR metadata workflow rejects empty sections, template placeholders, issue links outside `## Linked Issue`, and missing test type. Validate a PR body locally with:

```bash
PR_BODY="$(cat path/to/pr-body.md)" scripts/validation/validate_pr_body.py
```

## 3) Workflow and helper map

Use [docs/workflow-map.md](docs/workflow-map.md) as the canonical reference for:

- active GitHub workflows;
- local hooks and validation scripts;
- GitHub helper wrappers;
- legacy or retired automation that should not be treated as current policy.

## 4) Local validation

From the repository root:

```bash
./scripts/validation/repo_quality.sh
git config core.hooksPath .githooks
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --dry-run --skip-labels
```

The pre-push hook requires Bash 4+. The default macOS `/bin/bash` is 3.2, so macOS contributors should install a newer Bash, for example with Homebrew, before enabling the hook.

For full governance bootstrap execution with real writes, use:

```bash
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --no-dry-run --link-subissues
```

## 5) Governance bootstrap references

- Main runbook: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- Local orchestrator: `/scripts/github/bootstrap_local.sh`
- Shared CLI: `python -m governance_bootstrap`

The helper inventory and workflow status live in [docs/workflow-map.md](docs/workflow-map.md), so this file stays focused on contribution guidance instead of duplicating the automation matrix.
