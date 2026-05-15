#!/usr/bin/env bash
set -euo pipefail

template=".github/pull_request_template.md"

if [[ ! -f "$template" ]]; then
  echo "Missing PR template: $template" >&2
  exit 1
fi

for pattern in \
  '## Linked Issue' \
  '## Milestone' \
  '## Summary' \
  '## Release version' \
  '## Related develop PRs' \
  '## How to test' \
  '## Evidence' \
  '## Known risks' \
  '## DoD checklist' \
  'Closes #'
do
  if ! grep -Fq "$pattern" "$template"; then
    echo "Missing expected template content: $pattern" >&2
    exit 1
  fi
done
