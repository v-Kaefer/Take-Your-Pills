#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
ISSUE_NUMBER="${ISSUE_NUMBER:-}"

if [[ -z "${REPO}" ]]; then
  echo "Missing repository. Set REPO or GITHUB_REPOSITORY."
  exit 1
fi

if [[ -z "${ISSUE_NUMBER}" ]]; then
  echo "Missing ISSUE_NUMBER."
  exit 1
fi

gh issue delete "${ISSUE_NUMBER}" --repo "${REPO}" --yes
