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
ASSIGNEES=()
APPLY=false
DRY_RUN=true

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
  --assignee login (pode repetir)
  --apply      Executa criação/atualização no GitHub
  --dry-run    Apenas simula (padrão)
USAGE
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

map_type_label() {
  case "$1" in
    epic|feature) echo "user-story" ;;
    task) echo "task" ;;
    bug) echo "bug" ;;
    chore) echo "repo" ;;
    *) echo "$1" ;;
  esac
}

map_priority_label() {
  case "$1" in
    p0) echo "critical" ;;
    p1) echo "high" ;;
    p2) echo "medium" ;;
    p3) echo "low" ;;
    *) echo "$1" ;;
  esac
}

emit_result() {
  local action="$1"
  local number="$2"
  local url="$3"
  local created="$4"
  local updated="$5"
  local message="$6"

  {
    printf '{'
    printf '"repo":%s,' "$(printf '%s' "$REPO" | json_escape)"
    printf '"title":%s,' "$(printf '%s' "$TITLE" | json_escape)"
    printf '"action":%s,' "$(printf '%s' "$action" | json_escape)"
    printf '"number":%s,' "$(printf '%s' "$number" | json_escape)"
    printf '"url":%s,' "$(printf '%s' "$url" | json_escape)"
    printf '"created":%s,' "$created"
    printf '"updated":%s,' "$updated"
    printf '"dryRun":%s,' "$DRY_RUN"
    printf '"message":%s' "$(printf '%s' "$message" | json_escape)"
    printf '}\n'
  }
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
      ASSIGNEES+=("$2")
      shift 2
      ;;
    --apply)
      APPLY=true
      DRY_RUN=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      APPLY=false
      shift
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

if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado."
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 não encontrado."
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

deduped_assignees=()
declare -A ASSIGNEE_SEEN=()
for assignee in "${ASSIGNEES[@]}"; do
  IFS=',' read -r -a assignees_parts <<< "$assignee"
  for assignee_part in "${assignees_parts[@]}"; do
    trimmed_assignee="$(echo "$assignee_part" | xargs)"
    if [[ -n "$trimmed_assignee" && -z "${ASSIGNEE_SEEN[$trimmed_assignee]+x}" ]]; then
      ASSIGNEE_SEEN["$trimmed_assignee"]=1
      deduped_assignees+=("$trimmed_assignee")
    fi
  done
done

if [[ "$APPLY" == true ]]; then
  gh auth status >/dev/null
  gh api user >/dev/null
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
  BODY=$'Summary / Resumo\n\n- preencher\n'
fi

mapped_type="$(map_type_label "$TYPE")"
mapped_priority="$(map_priority_label "$PRIORITY")"
desired_labels=("type:$mapped_type" "priority:$mapped_priority")
if [[ -n "$EXTRA_LABELS" ]]; then
  IFS=',' read -r -a LABELS <<< "$EXTRA_LABELS"
  for label in "${LABELS[@]}"; do
    trimmed="$(echo "$label" | xargs)"
    if [[ -n "$trimmed" ]]; then
      desired_labels+=("$trimmed")
    fi
  done
fi

issues_payload="$(gh api --paginate "repos/$REPO/issues?state=all&per_page=100" | jq -s 'add')"
existing_issue_json="$(jq -c --arg title "$TITLE" '.[] | select(.pull_request|not) | select(.title == $title)' <<<"$issues_payload" | head -n 1 || true)"

if [[ -n "$existing_issue_json" ]]; then
  existing_number="$(jq -r '.number' <<<"$existing_issue_json")"
  existing_url="$(jq -r '.html_url' <<<"$existing_issue_json")"
  if [[ "$APPLY" == true ]]; then
    declare -a EDIT_ARGS
    EDIT_ARGS=(issue edit "$existing_number" --repo "$REPO")
    for label in "${desired_labels[@]}"; do
      EDIT_ARGS+=(--add-label "$label")
    done
    if [[ -n "$MILESTONE" ]]; then
      EDIT_ARGS+=(--milestone "$MILESTONE")
    fi
    for assignee in "${deduped_assignees[@]}"; do
      EDIT_ARGS+=(--add-assignee "$assignee")
    done
    gh "${EDIT_ARGS[@]}" >/dev/null
    emit_result "updated_existing" "$existing_number" "$existing_url" false true "Issue existente encontrada e alinhada."
  else
    emit_result "would_update_existing" "$existing_number" "$existing_url" false true "Issue existente encontrada (dry-run)."
  fi
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  emit_result "would_create" "" "" false false "Nenhuma issue existente encontrada; criação simulada."
  exit 0
fi

declare -a CMD
CMD=(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY")
for label in "${desired_labels[@]}"; do
  CMD+=(--label "$label")
done

if [[ -n "$MILESTONE" ]]; then
  CMD+=(--milestone "$MILESTONE")
fi

for assignee in "${deduped_assignees[@]}"; do
  CMD+=(--assignee "$assignee")
done

created_url="$("${CMD[@]}")"
created_number="${created_url##*/}"
emit_result "created" "$created_number" "$created_url" true false "Issue criada com sucesso."
