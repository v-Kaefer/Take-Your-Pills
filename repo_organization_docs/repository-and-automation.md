# Take Your Pills — Repository Structure & Automation

> Consolidated reference from initial repository planning documents.
> The live implementation is in `.github/`, `scripts/`, `governance_bootstrap/`, and `config/`.
> This document captures the design rationale and originally-planned architecture.

---

## Repository Model

### Branch hierarchy
```
main          ← stable, releasable; receives from develop (releases) and hotfix/... (emergency patches)
develop       ← continuous integration
phase/<name>  ← per-phase work branch (optional; feature branches may come directly from develop)
feat/<scope>  ← feature work
fix/<scope>   ← bug fixes
docs/<scope>  ← documentation only
refactor/<scope>
test/<scope>
hotfix/<scope>
task/<scope>
```

Rules:
- No direct commits to `main`
- `main` receives stable merges via PR from `develop` (releases) or `hotfix/...` (emergency patches)
- Features enter `develop` first
- PRs must be single-topic; long branches must be split or integrated early
- Every open branch must declare: what works · what is missing · known issues · next step expected

### Backlog hierarchy
```
Phase → User Story → Task/Sub-issue → PR
```
No "epic" as a primary operational unit.

---

## Label System

### Status
`status:backlog` · `status:in-progress` · `status:blocked` · `status:needs-review` · `status:ready-for-qa` · `status:done`

### Type
`type:user-story` · `type:task` · `type:bug` · `type:repo`

### Priority
`priority:low` · `priority:medium` · `priority:high` · `priority:critical`

### Test
`test:automated` · `test:smoke` · `test:manual`

### Phase
`phase:0` through `phase:5`

Live label definitions: `config/project/labels.json`  
Sync command: `make labels_sync`

---

## Milestones

| Milestone | Scope |
|---|---|
| MS0 | Repository foundation and governance bootstrap |
| MS1 | Phase 1 — Technical base and first playable loop |
| MS2 | Phase 2 — Full MVP (collectibles, velocity, scenarios) |
| MS3 | Phase 3 — Polish, playtesting and Part 3 delivery |

Live milestone definitions: `config/project/milestones.json`  
Sync command: `make milestones_sync`

---

## Testing Policy

Three-tier approach (full policy: `docs/repo/testing-policy.md`):

| Tier | Tool | When |
|---|---|---|
| Automated | GdUnit4 via `game-tests.yml` | On every PR touching game paths |
| Smoke | Godot headless `--quit` via `godot-smoke.yml` | On every PR |
| Manual | Checklist in PR body `## How to test` | All PRs |

Test files: `tests/godot/`  
Test suite: `game-tests.yml` (GdUnit4 v6.1.3, Godot 4.6.2)  
Smoke check: `godot-smoke.yml` (firebelley/setup-godot, Godot 4.2.2)

---

## Definition of Done — Multiple Layers

### Task / PR level
- [ ] Code implemented as specified
- [ ] Automated or smoke test added / verified
- [ ] Evidence attached (screenshot, log, or manual checklist)
- [ ] No known critical regression introduced
- [ ] PR reviewed and approved

### Phase level
- All User Stories of the phase closed
- Full manual test checklist executed
- Phase branch merged to `develop`
- No open P0/P1 bugs against phase scope

### Project level
- `develop` merged to `main` via release PR, or a `hotfix/...` branch for emergency patches
- Version tagged (`alpha-x.y.z`, `beta-x.y.z`, or `final-x.y.z`)
- GitHub Release created with exported builds

---

## Automation Pipeline (implemented)

### Active GitHub Actions workflows

| Workflow | Trigger | Purpose |
|---|---|---|
| `pr-metadata.yml` | PR opened/updated | Validates branch naming + PR body contract |
| `main-source-branch.yml` | PR to `main` | Enforces source must be `develop` or `hotfix/...` |
| `godot-smoke.yml` | PR opened/updated | Lightweight Godot headless check |
| `game-tests.yml` | PR touching game paths | Full GdUnit4 test suite |
| `release-version.yml` | PR to `main` (opened/merged) | Release planning and publish; hotfix merges auto-bump the patch version |
| `governance-bootstrap.yml` | Manual dispatch | Label/milestone/issue sync |

Full map: `docs/workflow-map.md`

### Local hooks and validation

| Tool | Path | Purpose |
|---|---|---|
| Pre-push hook | `.githooks/pre-push` | Change summary, YAML/Python/JSON lint; requires Bash 4.3+ |
| Repo quality check | `scripts/validation/repo_quality.sh` | Asserts required files exist |
| PR body validator | `scripts/validation/validate_pr_body.py` | Local PR validation before push |

Enable hook: `git config core.hooksPath .githooks`

macOS ships `/bin/bash` 3.2 by default. Install and use Bash 4.3+ before enabling the local pre-push hook on macOS.

### Governance CLI

All governance operations run through `python -m governance_bootstrap`:

```
labels sync        — sync labels from config/project/labels.json
milestones sync    — sync milestones
issues generate    — generate stories/tasks from backlog manifest
project create     — create GitHub Project v2
project sync       — add issues to project with field mappings
issue-milestones sync — assign milestones from issue body metadata
release prepare-main  — validate and plan a release
release publish       — tag, create GitHub Release, upload assets
```

Shortcut: `make <target>` — see `make help` for all targets.

---

## Originally Planned Automation (not yet implemented)

These items were planned in initial documents but not yet built:

### CODEOWNERS-based technical review routing
- `.github/CODEOWNERS` mapping file paths to reviewer usernames
- Automatic reviewer assignment when PR touches specific game areas

### Functional review routing by issue/sub-issue
- Workflow reading issue metadata to assign functional reviewers
- Fallback: sub-issue inherits parent issue's lead reviewer

### Phase-aware reviewer workflow
- `.github/review-routing.yml` defining per-phase reviewer preferences
- Workflow adapting reviewer list as project phase changes

These would require the repository to move to an organisation for team-based reviewer groups.

---

## Language Convention

Technical artefacts (labels, branches, workflows, scripts): **English**  
Templates, instruction text, job names: Portuguese allowed

---

## Key Config File Locations

| What | Path |
|---|---|
| Labels manifest | `config/project/labels.json` |
| Milestones manifest | `config/project/milestones.json` |
| Project definition | `config/project/project-definition.json` |
| Backlog manifest | `config/stories/backlog-manifest.json` |
| Phase manifests | `config/stories/phases/phase-*.json` |
| Bootstrap config | `governance.bootstrap.json` |
