#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
TITLE=""
TYPE=""
AREA=""
PRIORITY=""
BODY=""
BODY_FILE=""
EXTRA_LABELS=""
MILESTONE=""
ASSIGNEE=""

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-issue.sh --title "..." --type feature --area ui --priority p1 [opções]

Opções:
  --repo owner/name
  --title text
  --type epic|feature|task|bug|chore
  --area text
  --priority p0|p1|p2|p3
  --body text
  --body-file path
  --labels "label-a,label-b"
  --milestone text|number
  --assignee login
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --title)
      TITLE="$2"
      shift 2
      ;;
    --type)
      TYPE="$2"
      shift 2
      ;;
    --area)
      AREA="$2"
      shift 2
      ;;
    --priority)
      PRIORITY="$2"
      shift 2
      ;;
    --body)
      BODY="$2"
      shift 2
      ;;
    --body-file)
      BODY_FILE="$2"
      shift 2
      ;;
    --labels)
      EXTRA_LABELS="$2"
      shift 2
      ;;
    --milestone)
      MILESTONE="$2"
      shift 2
      ;;
    --assignee)
      ASSIGNEE="$2"
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

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ -n "$BODY_FILE" ]]; then
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "Arquivo de body não encontrado: $BODY_FILE"
    exit 1
  fi
  BODY="$(cat "$BODY_FILE")"
fi

if [[ -z "$TITLE" || -z "$TYPE" || -z "$AREA" || -z "$PRIORITY" ]]; then
  echo "Parâmetros obrigatórios ausentes: --title --type --area --priority"
  usage
  exit 1
fi

case "$TYPE" in
  epic|feature|task|bug|chore) ;;
  *)
    echo "Tipo inválido: $TYPE"
    exit 1
    ;;
esac

case "$PRIORITY" in
  p0|p1|p2|p3) ;;
  *)
    echo "Prioridade inválida: $PRIORITY"
    exit 1
    ;;
esac

if [[ -z "$BODY" ]]; then
  BODY="Summary / Resumo\n\n- preencher\n"
fi

declare -a CMD
CMD=(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY")
CMD+=(--label "type:$TYPE" --label "area:$AREA" --label "priority:$PRIORITY")

if [[ -n "$EXTRA_LABELS" ]]; then
  IFS=',' read -r -a LABELS <<< "$EXTRA_LABELS"
  for label in "${LABELS[@]}"; do
    trimmed="$(echo "$label" | xargs)"
    if [[ -n "$trimmed" ]]; then
      CMD+=(--label "$trimmed")
    fi
  done
fi

if [[ -n "$MILESTONE" ]]; then
  CMD+=(--milestone "$MILESTONE")
fi

if [[ -n "$ASSIGNEE" ]]; then
  CMD+=(--assignee "$ASSIGNEE")
fi

"${CMD[@]}"
