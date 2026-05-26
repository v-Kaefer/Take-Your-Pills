#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/pr-hygiene.yml"
repo_quality="scripts/validation/repo_quality.sh"
workflow_map="docs/workflow-map.md"

for path in "$workflow" "$repo_quality" "$workflow_map" "governance_bootstrap/pr_hygiene.py"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "pull_request_target:" "$workflow"
grep -Fq "ready_for_review" "$workflow"
grep -Fq "converted_to_draft" "$workflow"
grep -Fq "closed" "$workflow"
grep -Fq 'if: github.event.pull_request.head.repo.full_name == github.repository' "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"
grep -Fq 'GOVERNANCE_PROJECT_NUMBER: ${{ vars.GOVERNANCE_PROJECT_NUMBER }}' "$workflow"
grep -Fq "python -m governance_bootstrap pr hygiene" "$workflow"
grep -Fq -- '--event-path "$GITHUB_EVENT_PATH"' "$workflow"

grep -Fq ".github/workflows/pr-hygiene.yml" "$repo_quality"
grep -Fq "tests/test_pr_hygiene.sh" "$repo_quality"
grep -Fq ".github/workflows/pr-hygiene.yml" "$workflow_map"

echo "PR hygiene workflow contract OK"
