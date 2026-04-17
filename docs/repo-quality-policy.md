# Repository quality policy

## Pre-push checks

Local hook file: `.githooks/pre-push`

Checks:
1. block generated/dependency paths (`node_modules`, `dist`, `build`, `tmp`, `.DS_Store`)
2. block oversized files (> 1MB) unless explicitly approved
3. parse `.github/workflows/*.yml` to catch syntax errors early

## CI checks

Required in PR:
- `Branch Name Check`
- `Commit Message Check`
- `PR Validate Link`
- `Label Patterns Validation`
- `Repository Quality Checks`

## Activation policy

1. Start in warning mode for new checks if needed.
2. Promote to required checks in branch protection after one stable cycle.
3. Keep review-pipeline checks always required once stable.

## Temporary exception policy

Any temporary exception must include:
- explicit reason
- owner responsible for follow-up
- expiration date
- linked issue tracking the removal of the exception

