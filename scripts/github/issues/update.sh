#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-${GITHUB_REPOSITORY:-}}"
ISSUE_NUMBER="${ISSUE_NUMBER:-}"
TITLE="${TITLE:-}"
BODY="${BODY:-}"
BODY_FILE="${BODY_FILE:-}"
ADD_LABELS="${ADD_LABELS:-}"
REMOVE_LABELS="${REMOVE_LABELS:-}"

if [[ -z "${REPO}" ]]; then
  echo "Missing repository. Set REPO or GITHUB_REPOSITORY."
  exit 1
fi

if [[ -z "${ISSUE_NUMBER}" ]]; then
  echo "Missing ISSUE_NUMBER."
  exit 1
fi

cmd=(gh issue edit "${ISSUE_NUMBER}" --repo "${REPO}")
if [[ -n "${TITLE}" ]]; then
  cmd+=(--title "${TITLE}")
fi
if [[ -n "${BODY_FILE}" ]]; then
  cmd+=(--body-file "${BODY_FILE}")
elif [[ -n "${BODY}" ]]; then
  cmd+=(--body "${BODY}")
fi

add_flags() {
  local flag="$1"
  local raw="${2:-}"
  raw="${raw//,/ }"
  for item in ${raw}; do
    [[ -n "${item}" ]] && cmd+=("${flag}" "${item}")
  done
}

add_flags --add-label "${ADD_LABELS}"
add_flags --remove-label "${REMOVE_LABELS}"

"${cmd[@]}"
