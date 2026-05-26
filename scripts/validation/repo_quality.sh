#!/usr/bin/env bash
set -euo pipefail

required=(
  ".github/pull_request_template.md"
  ".github/workflows/pr-metadata.yml"
  ".github/workflows/main-source-branch.yml"
  ".github/workflows/release-version.yml"
  ".github/workflows/quality-assurance.yml"
  ".github/workflows/godot-smoke.yml"
  ".github/workflows/game-tests.yml"
  ".github/workflows/governance-bootstrap.yml"
  ".github/ISSUE_TEMPLATE/user-story.yml"
  ".github/ISSUE_TEMPLATE/task-sub-issue.yml"
  ".github/ISSUE_TEMPLATE/bug-report.yml"
  "config/project/labels.json"
  "config/stories/backlog-manifest.json"
  "docs/workflow-map.md"
  "export_presets.cfg"
  "pyproject.toml"
  "governance_bootstrap/comments.py"
  "governance_bootstrap/release.py"
  "tests/test_governance_bootstrap.py"
  "tests/test_pre_push_hook.sh"
  "tests/test_quality_assurance.sh"
  "tests/test_release_version.sh"
  "tests/test_godot_ci.sh"
  "scripts/validation/validate_pr_body.py"
  ".githooks/pre-push"
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path"; exit 1; }
done

echo "Repo quality baseline OK"
