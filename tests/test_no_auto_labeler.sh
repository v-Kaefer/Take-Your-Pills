#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required for this test." >&2
  exit 1
fi

if rg -n \
  --glob '.github/workflows/**' \
  --glob 'scripts/github/**/*.py' \
  --glob 'scripts/github/**/*.sh' \
  --glob 'Makefile' \
  --glob '!docs/**' \
  'auto[-_ ]label|labeler' .; then
  echo "Auto-labeler references found in active workflows or scripts." >&2
  exit 1
fi
