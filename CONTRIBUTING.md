# Contributing

Guia oficial para automação de backlog no GitHub com execução única (bulk-first) via manifesto JSON.

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

For PRs targeting `main`, also fill:

- `## Release version`
- `## Related develop PRs`

The PR metadata workflow rejects empty sections, placeholder text, issue links outside `## Linked Issue`, and missing test type. To validate a PR body locally:

```bash
PR_BODY="$(cat path/to/pr-body.md)" scripts/validation/validate_pr_body.py
```

When a PR fails branch naming or metadata checks in GitHub Actions, the workflow leaves a sticky PR comment with the exact fix to apply.

PRs targeting `develop` also get an automated change-summary comment with grouped diff analysis.

## 3) Create PR with template
When the PR is opened via CLI, prefer the wrapper versioned in the repo so the same template used by the GitHub UI is applied automatically:

```bash
./scripts/github/create-pr.sh --base develop --head feat/minha-branch --title "Minha PR"
```

The wrapper applies `.github/pull_request_template.md` by default and rejects `--fill`, because that mode ignores the template contract.

## 4) Local validation before PR updates
From repository root:

```bash
./scripts/validation/repo_quality.sh
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --dry-run --skip-labels
git config core.hooksPath .githooks
```

With the tracked `pre-push` hook enabled, pushes will print a sector-based change summary and run targeted syntax checks on changed Python, shell, YAML, JSON, and TOML files before the push is accepted.

When changing the backlog manifest, also validate the issue tree schema and structure:

```bash
./scripts/github/create-issue-tree.sh \
  --file config/issues/roadmap.json \
  --schema config/issues/schema.json \
  --validate-only
```

For full governance bootstrap execution (real write operations), use:

```bash
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --no-dry-run --link-subissues
```

The release workflow validates the release version on PRs to `main` before merge, then creates a tag and GitHub Release when the PR is merged. It normalizes versions such as `alpha-0.0.1`, `beta-0.1.0`, and `final-1.0.0`, and it comments on the linked `develop` PRs.

## 5) Governance bootstrap references
- Main runbook: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- Local orchestrator: `/scripts/github/bootstrap_local.sh`
- Underlying scripts (kept separated):
  - `/scripts/github/sync_labels.py`
  - `/scripts/github/create_project_v2.py`
  - `/scripts/github/create_milestones.py`
  - `/scripts/github/generate_issues.py`
  - `/scripts/github/sync_project_v2.py`
  - `/scripts/github/sync_issue_milestones.py`

## 6) GitHub issue and Project maintenance scripts
All scripts that write to GitHub expect `GITHUB_TOKEN` or `GH_TOKEN` in the environment. Use a token with repository issue permissions; Project v2 operations also require `project` scope.

Create missing repository milestones from the manifest:

```bash
python3 scripts/github/create_milestones.py \
  config/project/milestones.json \
  --repo v-Kaefer/Take-Your-Pills
```

Add repository issues to Project v2, sync custom fields, keep issue order from oldest to newest, and repair sub-issue links:

```bash
python3 scripts/github/sync_project_v2.py \
  config/project/project-definition.json \
  --repo v-Kaefer/Take-Your-Pills \
  --project-number 4 \
  --link-subissues
```

Only repair native sub-issue links without reprocessing Project items:

```bash
python3 scripts/github/sync_project_v2.py \
  config/project/project-definition.json \
  --repo v-Kaefer/Take-Your-Pills \
  --project-number 4 \
  --only-link-subissues
```

Sync issue milestones from generated issue metadata. User stories read `- Milestone: MSx` from their body; tasks inherit the parent story milestone from `Parent story: ... (#N)`. Closed `not_planned` issues are duplicates or discarded planning entries and must not count toward milestones, so clear them during normal maintenance:

```bash
python3 scripts/github/sync_issue_milestones.py \
  --repo v-Kaefer/Take-Your-Pills \
  --clear-not-planned
```

Preview milestone changes without writing to GitHub:

```bash
python3 scripts/github/sync_issue_milestones.py \
  --repo v-Kaefer/Take-Your-Pills \
  --clear-not-planned \
  --dry-run
```
