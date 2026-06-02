#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/governance-bootstrap.yml"

[[ -f "$workflow" ]] || { echo "Missing required file: $workflow" >&2; exit 1; }

grep -Fq "workflow_dispatch:" "$workflow"
grep -Fq "run_labels_sync:" "$workflow"
grep -Fq "run_milestones_sync:" "$workflow"
grep -Fq "run_issue_generation:" "$workflow"
grep -Fq "run_project_creation:" "$workflow"
grep -Fq "dry_run:" "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"
grep -Fq 'GH_TOKEN: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"

if grep -Fq "TAKE_YOUR_PILLS_PAT" "$workflow"; then
  echo "Governance bootstrap workflow must use GOVERNANCE_PAT." >&2
  exit 1
fi

echo "Governance bootstrap workflow contract OK"
