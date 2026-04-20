#!/usr/bin/env bash
set -euo pipefail

OWNER=""
TITLE=""
REPO=""

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-project.sh --owner v-Kaefer --title "Take Your Pills" [--repo owner/name]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --repo)
      REPO="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento inválido: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) não encontrado."
  exit 1
fi

if [[ -z "$OWNER" || -z "$TITLE" ]]; then
  echo "Parâmetros obrigatórios ausentes: --owner --title"
  usage
  exit 1
fi

project_json="$(gh project create --owner "$OWNER" --title "$TITLE" --format json)"
project_number="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("number",""))' <<< "$project_json")"

echo "$project_json"

if [[ -n "$REPO" && -n "$project_number" ]]; then
  repo_name="$REPO"
  if [[ "$repo_name" == */* ]]; then
    repo_name="${repo_name#*/}"
  fi
  gh project link "$project_number" --owner "$OWNER" --repo "$repo_name"
fi
