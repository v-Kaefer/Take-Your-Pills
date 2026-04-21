#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_LABELS=true
RUN_PROJECT=true
RUN_ISSUES=true
DRY_RUN=true
LINK_SUBISSUES=false
REPO="${GITHUB_REPOSITORY:-}"

usage() {
  cat <<'EOF'
Usage: scripts/github/bootstrap_local.sh [options]

Options:
  --repo <owner/repo>       Repository (fallback: GITHUB_REPOSITORY)
  --dry-run                 Enable dry-run for project/issues (default)
  --no-dry-run              Disable dry-run for project/issues
  --run-labels              Run labels sync (default)
  --skip-labels             Skip labels sync
  --run-project             Run project creation (default)
  --skip-project            Skip project creation
  --run-issues              Run issues/tasks generation (default)
  --skip-issues             Skip issues/tasks generation
  --link-subissues          Link tasks as real GitHub sub-issues (non-dry-run)
  --help                    Show this help

Auth:
  - Expects GITHUB_TOKEN or GH_TOKEN in environment.
  - If only one exists, this script mirrors it to the other.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --no-dry-run)
      DRY_RUN=false
      shift
      ;;
    --run-labels)
      RUN_LABELS=true
      shift
      ;;
    --skip-labels)
      RUN_LABELS=false
      shift
      ;;
    --run-project)
      RUN_PROJECT=true
      shift
      ;;
    --skip-project)
      RUN_PROJECT=false
      shift
      ;;
    --run-issues)
      RUN_ISSUES=true
      shift
      ;;
    --skip-issues)
      RUN_ISSUES=false
      shift
      ;;
    --link-subissues)
      LINK_SUBISSUES=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 2
      ;;
  esac
done

if [[ -z "${REPO}" ]]; then
  echo "Missing repository. Use --repo <owner/repo> or set GITHUB_REPOSITORY."
  exit 1
fi

if [[ -z "${GITHUB_TOKEN:-}" && -n "${GH_TOKEN:-}" ]]; then
  export GITHUB_TOKEN="${GH_TOKEN}"
fi
if [[ -z "${GH_TOKEN:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
  export GH_TOKEN="${GITHUB_TOKEN}"
fi

if [[ "${RUN_LABELS}" == "true" || ( "${DRY_RUN}" == "false" && ( "${RUN_PROJECT}" == "true" || "${RUN_ISSUES}" == "true" ) ) ]]; then
  if [[ -z "${GITHUB_TOKEN:-}" && -z "${GH_TOKEN:-}" ]]; then
    echo "Missing auth token. Set GITHUB_TOKEN or GH_TOKEN."
    exit 1
  fi
fi

export GITHUB_REPOSITORY="${REPO}"

cd "${ROOT_DIR}"

if [[ "${RUN_LABELS}" == "true" ]]; then
  echo "==> Sync labels"
  python3 scripts/github/sync_labels.py config/project/labels.json
fi

if [[ "${RUN_PROJECT}" == "true" ]]; then
  echo "==> Create project v2"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 scripts/github/create_project_v2.py config/project/project-definition.json --repo "${REPO}" --dry-run
  else
    python3 scripts/github/create_project_v2.py config/project/project-definition.json --repo "${REPO}"
  fi
fi

if [[ "${RUN_ISSUES}" == "true" ]]; then
  echo "==> Generate issues/tasks"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 scripts/github/generate_issues.py config/stories/backlog-manifest.json --repo "${REPO}" --dry-run
  else
    if [[ "${LINK_SUBISSUES}" == "true" ]]; then
      python3 scripts/github/generate_issues.py config/stories/backlog-manifest.json --repo "${REPO}" --link-subissues
    else
      python3 scripts/github/generate_issues.py config/stories/backlog-manifest.json --repo "${REPO}"
    fi
  fi
fi

echo "Bootstrap local finalizado."
