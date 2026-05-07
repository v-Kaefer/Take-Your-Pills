#!/usr/bin/env bash
set -euo pipefail

required=(
  ".github/pull_request_template.md"
  ".github/workflows/pr-metadata.yml"
  ".github/ISSUE_TEMPLATE/user-story.yml"
  ".github/ISSUE_TEMPLATE/task-sub-issue.yml"
  ".github/ISSUE_TEMPLATE/bug-report.yml"
  "config/project/labels.json"
  "config/stories/backlog-manifest.json"
  "pyproject.toml"
  "tests/test_governance_bootstrap.py"
  "scripts/validation/validate_pr_body.py"
  "scripts/github/auto_label.py"
  ".github/workflows/auto-label.yml"
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path"; exit 1; }
done

echo "Repo quality baseline OK"
