#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/pr-hygiene.yml"
repo_quality="scripts/validation/repo_quality.sh"
workflow_map="docs/workflow-map.md"

for path in "$workflow" "$repo_quality" "$workflow_map" "governance_bootstrap/pr_hygiene.py"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "pull_request_target:" "$workflow"
grep -Fq "workflow_run:" "$workflow"
grep -Fq 'workflows: ["PR guardrails"]' "$workflow"
grep -Fq "types: [completed]" "$workflow"
grep -Fq "ready_for_review" "$workflow"
grep -Fq "converted_to_draft" "$workflow"
grep -Fq "closed" "$workflow"
grep -Fq "github.event.workflow_run.conclusion == 'success'" "$workflow"
grep -Fq "github.event.workflow_run.event == 'pull_request_target'" "$workflow"
grep -Fq "concurrency:" "$workflow"
grep -Fq "cancel-in-progress: true" "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ github.token }}' "$workflow"
grep -Fq 'GH_TOKEN: ${{ github.token }}' "$workflow"
grep -Fq 'GOVERNANCE_PAT: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"
grep -Fq 'GOVERNANCE_PROJECT_NUMBER: ${{ vars.GOVERNANCE_PROJECT_NUMBER }}' "$workflow"
grep -Fq "python -m governance_bootstrap pr hygiene" "$workflow"
grep -Fq -- '--event-path "$GITHUB_EVENT_PATH"' "$workflow"
grep -Fq "Checkout base branch after PR guardrails" "$workflow"

grep -Fq ".github/workflows/pr-hygiene.yml" "$repo_quality"
grep -Fq "tests/test_pr_hygiene.sh" "$repo_quality"
grep -Fq ".github/workflows/pr-hygiene.yml" "$workflow_map"
grep -Fq "PR guardrails -> PR hygiene" "$workflow_map"

echo "PR hygiene workflow contract OK"
