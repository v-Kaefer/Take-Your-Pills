# Contributing — Repository Administration Scope

This document defines how contributors/admins should work on **repository preparation tasks only** (standards, rules, issues, governance, and planning), without implementing game features.

## 1) Repository organization

Main planning references:
- `análise_geral_preparacao_repositorio.md`
- `plano_implementacao_preparacao_repositorio.md`
- `docs/checklist-preparacao-repositorio.md` (repository-preparation checklist)

Operational support docs:
- `docs/repo-admin-checklist.md`
- `docs/issues-creation-matrix.md`
- `docs/issues-rollout-plan.md`
- `docs/pipeline-review-implementation-phase-a.md`

Canonical rule:
- Use `01.05` as the canonical identifier for the CODEOWNERS/pipeline preparation front.

## 2) Branch and PR flow

- `main`: stable branch
- `dev`: integration branch for ongoing preparation work
- Work branches: one focused scope per task/issue

PR requirements for admin tasks:
- reference the related issue
- describe repository-only scope
- include checklist updates when applicable
- do not mix gameplay feature changes with repository admin changes

## 3) How each admin should execute tasks

### Admin 1 — Governance and metadata
Owns:
- branch/commit/PR conventions
- issue/PR templates and required metadata
- canonical normalization (`01.05`)

Execution guidance:
1. Confirm conventions in planning docs.
2. Update templates/metadata plans first.
3. Ensure downstream tasks have stable required fields.

### Admin 2 — Taxonomy and project management flow
Owns:
- labels, milestones, board structure, status transitions

Execution guidance:
1. Define taxonomy before automation routing.
2. Keep issue categories consistent with area/type/priority/status.
3. Ensure board transitions are explicit and auditable.

### Admin 3 — Operational quality gates
Owns:
- pre-push planning and validation criteria
- activation policy for checks

Execution guidance:
1. Define checks and pass/fail criteria clearly.
2. Separate mandatory checks from future checks.
3. Document temporary exceptions with reason and deadline.

### Admin 4 — Review automation pipeline
Owns:
- CODEOWNERS planning
- PR↔issue validation planning
- reviewer auto-routing planning

Execution guidance:
1. Depend on Admin 1 metadata definitions.
2. Depend on Admin 2 taxonomy for routing logic.
3. Depend on Admin 3 gate policy for required checks.
4. Keep automation aligned with least-privilege and idempotency.

## 4) Recommended execution order

Wave model (mapped to the planning checklist sections):
1. Wave 0 (Onda 0) — document normalization
2. Wave 1 (Onda 1) — governance and conventions
3. Wave 2 (Onda 2) — taxonomy, milestones, board
4. Wave 3 (Onda 3) — pre-push and check policy
5. Wave 4 (Onda 4) — review pipeline planning

## 5) Contribution rules for this phase

- Keep changes minimal and scoped to repository preparation.
- Prefer small PRs with one administrative objective each.
- Update planning/checklist documents together when scope changes.
- Preserve traceability between plan, checklist, and issues.
- Do not implement gameplay features in repository-preparation PRs.
