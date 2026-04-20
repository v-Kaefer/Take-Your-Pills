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
USAGE
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

child_url="$(./scripts/github/create-issue.sh "${CREATE_ARGS[@]}")"

child_number="${child_url##*/}"

echo "Sub-issue criada: $child_url"

repo_node_id="$(gh api "repos/$REPO" --jq '.node_id')"
graphql_query="mutation(\$repo:ID!, \$parent:Int!, \$child:Int!) { addSubIssue(input: {repositoryId: \$repo, parentIssueNumber: \$parent, subIssueNumber: \$child}) { clientMutationId } }"
set +e
mutation_response="$(gh api graphql -f query="$graphql_query" -f repo="$repo_node_id" -F parent="$PARENT" -F child="$child_number" 2>/dev/null)"
mutation_exit=$?
set -e

if [[ $mutation_exit -eq 0 ]]; then
  echo "Vínculo de sub-issue criado via GraphQL."
  echo "$mutation_response" >/dev/null
else
  gh issue comment "$PARENT" --repo "$REPO" --body "Linked child issue: #$child_number"
  echo "Fallback aplicado: comentário na issue pai com link da filha."
fi
