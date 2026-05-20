#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_TEMPLATE_FILE="$SCRIPT_DIR/../../.github/pull_request_template.md"
TEMPLATE_FILE="${PR_TEMPLATE_FILE:-$DEFAULT_TEMPLATE_FILE}"

usage() {
  cat <<'EOF'
Uso:
  ./scripts/github/create-pr.sh [gh pr create flags]

Descrição:
  Cria uma pull request aplicando o template versionado por padrão.
  Evita o uso de --fill, porque esse modo ignora o contrato do template.
EOF
}

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) não encontrado." >&2
  exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  echo "Template de PR não encontrado: $TEMPLATE_FILE" >&2
  exit 1
fi

for arg in "$@"; do
  case "$arg" in
    --fill|--fill-first|--fill-verbose)
      echo "Use --title/--body ou o editor do gh; este wrapper aplica o template versionado e não suporta --fill." >&2
      exit 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
  esac
done

exec gh pr create --template "$TEMPLATE_FILE" "$@"
