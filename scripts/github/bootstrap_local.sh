#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

RUN_LABELS=true
RUN_MILESTONES=true
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
  --run-milestones          Run milestones sync (default)
  --skip-milestones         Skip milestones sync
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

requires_authentication() {
  if [[ "${DRY_RUN}" == "false" && ( "${RUN_LABELS}" == "true" || "${RUN_MILESTONES}" == "true" ) ]]; then
    return 0
  fi

  if [[ "${DRY_RUN}" == "false" && ( "${RUN_PROJECT}" == "true" || "${RUN_ISSUES}" == "true" ) ]]; then
    return 0
  fi

  return 1
}

mirror_token_envs() {
  if [[ -z "${GITHUB_TOKEN:-}" && -n "${GH_TOKEN:-}" ]]; then
    export GITHUB_TOKEN="${GH_TOKEN}"
  fi
  if [[ -z "${GH_TOKEN:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    export GH_TOKEN="${GITHUB_TOKEN}"
  fi
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
    --run-milestones)
      RUN_MILESTONES=true
      shift
      ;;
    --skip-milestones)
      RUN_MILESTONES=false
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

mirror_token_envs

if requires_authentication; then
  if [[ -z "${GITHUB_TOKEN:-}" && -z "${GH_TOKEN:-}" ]]; then
    echo "Missing auth token. Set GITHUB_TOKEN or GH_TOKEN."
    exit 1
  fi
fi

export GITHUB_REPOSITORY="${REPO}"

cd "${ROOT_DIR}"

if [[ "${RUN_LABELS}" == "true" ]]; then
  echo "==> Sync labels"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 -m governance_bootstrap labels sync --repo "${REPO}" --file config/project/labels.json --dry-run
  else
    python3 -m governance_bootstrap labels sync --repo "${REPO}" --file config/project/labels.json
  fi
fi

if [[ "${RUN_MILESTONES}" == "true" ]]; then
  echo "==> Sync milestones"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 -m governance_bootstrap milestones sync --repo "${REPO}" --file config/project/milestones.json --dry-run
  else
    python3 -m governance_bootstrap milestones sync --repo "${REPO}" --file config/project/milestones.json
  fi
fi

if [[ "${RUN_PROJECT}" == "true" ]]; then
  echo "==> Create project v2"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 -m governance_bootstrap project create --repo "${REPO}" --file config/project/project-definition.json --dry-run
  else
    python3 -m governance_bootstrap project create --repo "${REPO}" --file config/project/project-definition.json
  fi
fi

if [[ "${RUN_ISSUES}" == "true" ]]; then
  echo "==> Generate issues/tasks"
  if [[ "${DRY_RUN}" == "true" ]]; then
    python3 -m governance_bootstrap issues generate --repo "${REPO}" --file config/stories/backlog-manifest.json --dry-run
  else
    if [[ "${LINK_SUBISSUES}" == "true" ]]; then
      python3 -m governance_bootstrap issues generate --repo "${REPO}" --file config/stories/backlog-manifest.json --link-subissues
    else
      python3 -m governance_bootstrap issues generate --repo "${REPO}" --file config/stories/backlog-manifest.json
    fi
  fi
fi

echo "Local bootstrap finished."
