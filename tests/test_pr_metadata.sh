#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/pr-metadata.yml"
workflow_map="docs/workflow-map.md"
guide="docs/repo/governance-shared-tool.md"

for path in "$workflow" "$workflow_map" "$guide" "governance_bootstrap/pr_autofill.py" "scripts/validation/validate_pr_body.py"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "pull_request_target:" "$workflow"
grep -Fq "pull-requests: write" "$workflow"
grep -Fq "Autofill PR metadata from branch" "$workflow"
grep -Fq "python -m governance_bootstrap pr autofill" "$workflow"
grep -Fq -- '--backlog-file config/stories/backlog-manifest.json' "$workflow"
grep -Fq "Validate branch naming and PR metadata" "$workflow"
grep -Fq "python3 scripts/validation/validate_pr_body.py" "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ github.token }}' "$workflow"
grep -Fq 'GH_TOKEN: ${{ github.token }}' "$workflow"
grep -Fq 'REPO_NAME: ${{ github.repository }}' "$workflow"
grep -Fq 'PR_NUMBER: ${{ github.event.pull_request.number }}' "$workflow"

autofill_line=$(grep -n "Autofill PR metadata from branch" "$workflow" | head -n1 | cut -d: -f1)
validation_line=$(grep -n "Validate branch naming and PR metadata" "$workflow" | head -n1 | cut -d: -f1)
if [[ "$autofill_line" -ge "$validation_line" ]]; then
  echo "Autofill step must run before PR validation." >&2
  exit 1
fi

grep -Fq '.github/workflows/pr-metadata.yml' "$workflow_map"
grep -Fq 'governance_bootstrap/pr_autofill.py' "$workflow_map"
grep -Fq 'autofill before validation' "$workflow_map"
grep -Fq 'Branch-driven PR autofill for story-linked metadata and related task context.' "$guide"

echo "PR metadata workflow contract OK"
