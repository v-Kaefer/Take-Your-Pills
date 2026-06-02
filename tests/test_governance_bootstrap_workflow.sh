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

grep -A4 -F "Sync labels" "$workflow" | grep -Fq 'GITHUB_TOKEN: ${{ secrets.TAKE_YOUR_PILLS_PAT }}'
grep -A4 -F "Sync milestones" "$workflow" | grep -Fq 'GITHUB_TOKEN: ${{ secrets.TAKE_YOUR_PILLS_PAT }}'
grep -A4 -F "Create project v2" "$workflow" | grep -Fq 'GH_TOKEN: ${{ secrets.GOVERNANCE_PAT }}'
grep -A5 -F "Generate issues and tasks" "$workflow" | grep -Fq 'GITHUB_TOKEN: ${{ secrets.TAKE_YOUR_PILLS_PAT }}'
grep -A5 -F "Generate issues and tasks" "$workflow" | grep -Fq 'GH_TOKEN: ${{ secrets.TAKE_YOUR_PILLS_PAT }}'

echo "Governance bootstrap workflow contract OK"
