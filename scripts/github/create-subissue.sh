#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
PARENT=""
TITLE=""
TYPE=""
AREA=""
PRIORITY=""
BODY=""
BODY_FILE=""
EXTRA_LABELS=""
ASSIGNEE=""
MILESTONE=""
APPLY=false
DRY_RUN=true

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-subissue.sh --parent 12 --title "..." --type task --area ui --priority p2 [opções]

Opções:
  --repo owner/name
  --parent issue_number
  --title text
  --type epic|feature|task|bug|chore
  --area text
  --priority p0|p1|p2|p3
  --body text
  --body-file path
  --labels "label-a,label-b"
  --milestone text|number
  --assignee login
  --apply
  --dry-run
USAGE
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

emit_result() {
  local action="$1"
  local child_number="$2"
  local child_url="$3"
  local link_method="$4"
  local message="$5"
  {
    printf '{'
    printf '"repo":%s,' "$(printf '%s' "$REPO" | json_escape)"
    printf '"parent":%s,' "$(printf '%s' "$PARENT" | json_escape)"
    printf '"title":%s,' "$(printf '%s' "$TITLE" | json_escape)"
    printf '"action":%s,' "$(printf '%s' "$action" | json_escape)"
    printf '"childNumber":%s,' "$(printf '%s' "$child_number" | json_escape)"
    printf '"childUrl":%s,' "$(printf '%s' "$child_url" | json_escape)"
    printf '"linkMethod":%s,' "$(printf '%s' "$link_method" | json_escape)"
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
    --parent)
      PARENT="$2"
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
    --assignee)
      ASSIGNEE="$2"
      shift 2
      ;;
    --milestone)
      MILESTONE="$2"
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

if [[ -z "$PARENT" || -z "$TITLE" || -z "$TYPE" || -z "$AREA" || -z "$PRIORITY" ]]; then
  echo "Parâmetros obrigatórios ausentes: --parent --title --type --area --priority"
  usage
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado."
  exit 1
fi

if [[ -n "$BODY_FILE" ]]; then
  if [[ ! -f "$BODY_FILE" ]]; then
    echo "Arquivo de body não encontrado: $BODY_FILE"
    exit 1
  fi
  BODY="$(cat "$BODY_FILE")"
fi

if [[ -z "$BODY" ]]; then
  BODY="Parent Issue / Issue pai: #$PARENT"
else
  BODY="$BODY\n\nParent Issue / Issue pai: #$PARENT"
fi

declare -a CREATE_ARGS
CREATE_ARGS=(
  --repo "$REPO"
  --title "$TITLE"
  --type "$TYPE"
  --area "$AREA"
  --priority "$PRIORITY"
  --body "$BODY"
)

if [[ -n "$EXTRA_LABELS" ]]; then
  CREATE_ARGS+=(--labels "$EXTRA_LABELS")
fi

if [[ -n "$MILESTONE" ]]; then
  CREATE_ARGS+=(--milestone "$MILESTONE")
fi

if [[ -n "$ASSIGNEE" ]]; then
  CREATE_ARGS+=(--assignee "$ASSIGNEE")
fi

if [[ "$APPLY" == true ]]; then
  CREATE_ARGS+=(--apply)
else
  CREATE_ARGS+=(--dry-run)
fi

child_issue_result="$(./scripts/github/create-issue.sh "${CREATE_ARGS[@]}")"
child_number="$(jq -r '.number // empty' <<<"$child_issue_result")"
child_url="$(jq -r '.url // empty' <<<"$child_issue_result")"

if [[ -z "$child_number" ]]; then
  emit_result "issue_stage_only" "" "" "none" "Dry-run sem número de issue filha."
  exit 0
fi

if [[ "$DRY_RUN" == true ]]; then
  emit_result "would_link_subissue" "$child_number" "$child_url" "none" "Issue filha existente/criada em simulação; vínculo não aplicado."
  exit 0
fi

repo_node_id="$(gh api "repos/$REPO" --jq '.node_id')"
graphql_query="mutation(\$repo:ID!, \$parent:Int!, \$child:Int!) { addSubIssue(input: {repositoryId: \$repo, parentIssueNumber: \$parent, subIssueNumber: \$child}) { clientMutationId } }"
set +e
mutation_response="$(gh api graphql -f query="$graphql_query" -f repo="$repo_node_id" -F parent="$PARENT" -F child="$child_number" 2>/dev/null)"
mutation_exit=$?
set -e

if [[ $mutation_exit -eq 0 ]]; then
  echo "$mutation_response" >/dev/null
  emit_result "linked" "$child_number" "$child_url" "graphql:addSubIssue" "Vínculo de sub-issue criado via GraphQL."
  exit 0
fi

comments_payload="$(gh issue view "$PARENT" --repo "$REPO" --comments --json comments)"
already_linked_comment="$(jq -r --arg child "#$child_number" '.comments[]?.body | select(contains($child))' <<<"$comments_payload" | head -n 1 || true)"
if [[ -z "$already_linked_comment" ]]; then
  gh issue comment "$PARENT" --repo "$REPO" --body "Linked child issue: #$child_number" >/dev/null
  emit_result "linked_with_fallback" "$child_number" "$child_url" "issue_comment" "Fallback aplicado com comentário na issue pai."
else
  emit_result "already_linked_with_fallback" "$child_number" "$child_url" "issue_comment" "Comentário de fallback já existente; sem duplicação."
fi
