#!/usr/bin/env bash
set -euo pipefail

if rg -n --glob '.github/workflows/**' --glob 'scripts/github/**' --glob 'CONTRIBUTING.md' --glob 'docs/**' 'auto[-_ ]label|labeler' .; then
  echo "Auto-labeler references found in active workflows or scripts." >&2
  exit 1
fi
