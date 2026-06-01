#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/quality-assurance.yml"
metadata=".github/workflows/pr-metadata.yml"
workflow_map="docs/workflow-map.md"
repo_quality="scripts/validation/repo_quality.sh"

for path in "$workflow" "$metadata" "$workflow_map" "$repo_quality"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq 'if: github.event.pull_request.head.repo.full_name == github.repository' "$workflow"
grep -Fq 'COVERAGE_COMMENT_FILE: ${{ runner.temp }}/coverage-comment.md' "$workflow"
grep -Fq 'cat "$comment_file" >> "$GITHUB_STEP_SUMMARY"' "$workflow"
grep -Fq "fs.readFileSync(process.env.COVERAGE_COMMENT_FILE, 'utf8')" "$workflow"
grep -Fq 'if [[ "$status" != "D" ]]; then' "$workflow"
grep -Fq 'done < <(git diff --name-status "$base" "$head")' "$workflow"

if grep -Fq '${{ steps.comment.outputs.body }}' "$workflow"; then
  echo "Workflow should not inject the generated comment body into github-script source." >&2
  exit 1
fi

grep -Fq 'HEAD_REF: ${{ github.event.pull_request.head.ref }}' "$metadata"
grep -Fq 'REPO_NAME: ${{ github.repository }}' "$metadata"
grep -Fq 'PR_NUMBER: ${{ github.event.pull_request.number }}' "$metadata"
grep -Fq -- '--branch "$HEAD_REF" \' "$metadata"
grep -Fq -- '--repo "$REPO_NAME" \' "$metadata"
grep -Fq -- '--pr-number "$PR_NUMBER" \' "$metadata"

if grep -Fq -- '--branch "${{ github.event.pull_request.head.ref }}"' "$metadata"; then
  echo "PR metadata workflow should pass the head ref through an environment variable." >&2
  exit 1
fi

grep -Fq '.github/workflows/quality-assurance.yml' "$workflow_map"
grep -Fq 'infra,.github/workflows/quality-assurance.yml,1' "$workflow_map"
grep -Fq '".github/workflows/quality-assurance.yml"' "$repo_quality"

echo "Quality assurance workflow contract OK"
