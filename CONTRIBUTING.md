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

## 2) Pull request body (required sections)
Follow `/.github/pull_request_template.md` and keep these sections filled:

- `## Linked Issue` with `Closes/Fixes/Resolves #123`
- `## Milestone` with a value such as `MS0`
- `## How to test`
- `## Evidence`
- `## DoD checklist`

The PR metadata workflow rejects empty sections, template placeholders, issue links outside `## Linked Issue`, and missing test type. To validate a PR body locally:

```bash
PR_BODY="$(cat path/to/pr-body.md)" scripts/validation/validate_pr_body.py
```

When a PR fails branch naming or metadata checks in GitHub Actions, the workflow leaves a sticky PR comment with the exact fix to apply.

The repository does not use `phase:*` labels. Use milestones for delivery grouping and Project fields for operational phase tracking.

## 3) Automatic labels
The auto-label workflow adds labels to issues and PRs from structured metadata. It only adds missing labels; it never removes or replaces existing labels.

- Issues can receive `type:*`, `priority:*`, `test:*`, and `status:backlog`.
- PRs can inherit `type:*`, `priority:*`, and `test:*` from the linked issue in `## Linked Issue`.
- PRs can also receive `test:*` from `## How to test`.
- `phase:*` labels are not used; milestone and Project fields carry delivery phase information.

## 4) Local validation before PR updates
From repository root:

```bash
./scripts/validation/repo_quality.sh
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --dry-run --skip-labels
```

For full governance bootstrap execution (real write operations), use:

```bash
./scripts/github/bootstrap_local.sh --repo v-Kaefer/Take-Your-Pills --no-dry-run --link-subissues
```

## 5) Governance bootstrap references
- Main runbook: `/docs/repo/governance-bootstrap-runbook.pt-BR.md`
- Local orchestrator: `/scripts/github/bootstrap_local.sh`
- Underlying scripts (kept separated):
  - `/scripts/github/sync_labels.py`
  - `/scripts/github/auto_label.py`
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
