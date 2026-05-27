#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
TITLE="${TITLE:-}"
BODY="${BODY:-}"
BODY_FILE="${BODY_FILE:-}"
LABELS="${LABELS:-}"

if [[ -z "${REPO}" ]]; then
  echo "Missing repository. Set REPO or GITHUB_REPOSITORY."
  exit 1
fi

if [[ -z "${TITLE}" ]]; then
  echo "Missing TITLE."
  exit 1
fi

cmd=(gh issue create --repo "${REPO}" --title "${TITLE}")
if [[ -n "${BODY_FILE}" ]]; then
  cmd+=(--body-file "${BODY_FILE}")
else
  cmd+=(--body "${BODY}")
fi

labels="${LABELS//,/ }"
for label in ${labels}; do
  [[ -n "${label}" ]] && cmd+=(--label "${label}")
done

"${cmd[@]}"
