# Shared Governance Tool

This repository now carries the reusable bootstrap engine as the Python package `governance_bootstrap`.

## What Is Generic
- GitHub label sync from `config/project/labels.json`.
- GitHub milestone sync from `config/project/milestones.json`.
- GitHub Project v2 creation and issue sync from `config/project/project-definition.json`.
- Issue/task generation from `config/stories/backlog-manifest.json`.
- Branch-driven PR autofill for story-linked metadata and related task context.
- Auto-label and issue milestone helpers.

## What Stays Project-Specific
- Label names and colors.
- Milestone names and dates.
- Project board name, fields, options, views and `phaseMilestoneMap`.
- Backlog phases, user stories, tasks and default labels.
- The target repository passed with `--repo owner/repo`.

## Consumer Setup
1. Copy `governance.bootstrap.json`, `config/project`, `config/stories` and the workflow into the consumer repo.
2. Use the built-in Actions token for PR workflows that only need repo-scoped issue and pull request writes.
3. Add a repository secret named `GOVERNANCE_PAT` only when the consumer also wants Project v2 sync from PR hygiene or the manual bootstrap flow.
4. Give `GOVERNANCE_PAT` access to repo issues and Project v2 operations.
5. Run the manual workflow with `dry_run=true`.
6. Run again with `dry_run=false` when the dry-run output is correct.

Use `docs/repo/governance-bootstrap.workflow-template.yml` as the consumer workflow template after publishing this package in its own repository. Replace `OWNER/github-governance-bootstrap` with the final shared-tool repository.

Local dry-run:

```bash
export GH_TOKEN=...
python -m governance_bootstrap bootstrap --repo owner/repo --dry-run
```

Real bootstrap:

```bash
export GH_TOKEN=...
python -m governance_bootstrap bootstrap --repo owner/repo --no-dry-run --link-subissues
```
