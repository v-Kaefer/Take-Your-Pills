#!/usr/bin/env bash
set -euo pipefail

required=(
  ".github/pull_request_template.md"
  ".github/workflows/pr-metadata.yml"
  ".github/workflows/develop-change-summary.yml"
  ".github/workflows/release-version.yml"
  ".github/ISSUE_TEMPLATE/user-story.yml"
  ".github/ISSUE_TEMPLATE/task-sub-issue.yml"
  ".github/ISSUE_TEMPLATE/bug-report.yml"
  "config/project/labels.json"
  "config/stories/backlog-manifest.json"
  "pyproject.toml"
  "tests/test_governance_bootstrap.py"
  "tests/test_pr_template.sh"
  "tests/test_pre_push_hook.sh"
  "scripts/validation/pre_push.py"
  "scripts/validation/validate_pr_body.py"
  ".githooks/pre-push"
  "governance_bootstrap/comments.py"
  "governance_bootstrap/release.py"
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path"; exit 1; }
done

echo "Repo quality baseline OK"
