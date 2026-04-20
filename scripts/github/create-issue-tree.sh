#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
CONFIG_FILE=""

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-issue-tree.sh --file config/issues/roadmap.yml [--repo owner/name]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"
      shift 2
      ;;
    --file)
      CONFIG_FILE="$2"
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

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Parâmetro obrigatório ausente: --file"
  usage
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Arquivo de configuração não encontrado: $CONFIG_FILE"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

mapfile -t ITEMS < <(python3 - "$CONFIG_FILE" <<'PY'
import base64
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

epic = data.get("epic", {})
if not epic:
    raise SystemExit("Config inválido: campo 'epic' ausente")

def emit(kind, item):
    title = str(item.get("title", "")).strip()
    issue_type = str(item.get("type", "")).strip() or ("epic" if kind == "EPIC" else "task")
    area = str(item.get("area", "")).strip()
    priority = str(item.get("priority", "")).strip()
    body = str(item.get("body", "")).encode("utf-8")
    labels = item.get("labels", [])
    labels_csv = ",".join(str(x).strip() for x in labels if str(x).strip())
    print("\t".join([
        kind,
        title,
        issue_type,
        area,
        priority,
        base64.b64encode(body).decode("ascii"),
        labels_csv,
    ]))

emit("EPIC", epic)
for child in epic.get("children", []):
    emit("CHILD", child)
PY
)

if [[ "${#ITEMS[@]}" -eq 0 ]]; then
  echo "Nenhum item encontrado no arquivo: $CONFIG_FILE"
  exit 1
fi

IFS=$'\t' read -r kind epic_title epic_type epic_area epic_priority epic_body_b64 epic_labels <<< "${ITEMS[0]}"
if [[ "$kind" != "EPIC" ]]; then
  echo "Config inválido: primeira entrada deve ser EPIC"
  exit 1
fi

epic_body="$(printf '%s' "$epic_body_b64" | base64 -d)"
declare -a EPIC_ARGS
EPIC_ARGS=(
  --repo "$REPO"
  --title "$epic_title"
  --type "$epic_type"
  --area "$epic_area"
  --priority "$epic_priority"
  --body "$epic_body"
)
if [[ -n "$epic_labels" ]]; then
  EPIC_ARGS+=(--labels "$epic_labels")
fi

epic_url="$(./scripts/github/create-issue.sh "${EPIC_ARGS[@]}")"

epic_number="${epic_url##*/}"

echo "Epic criada: $epic_url"

for ((i = 1; i < ${#ITEMS[@]}; i++)); do
  IFS=$'\t' read -r child_kind child_title child_type child_area child_priority child_body_b64 child_labels <<< "${ITEMS[$i]}"
  if [[ "$child_kind" != "CHILD" ]]; then
    continue
  fi

  child_body="$(printf '%s' "$child_body_b64" | base64 -d)"

  declare -a CHILD_ARGS
  CHILD_ARGS=(
    --repo "$REPO"
    --parent "$epic_number"
    --title "$child_title"
    --type "$child_type"
    --area "$child_area"
    --priority "$child_priority"
    --body "$child_body"
  )
  if [[ -n "$child_labels" ]]; then
    CHILD_ARGS+=(--labels "$child_labels")
  fi

  ./scripts/github/create-subissue.sh "${CHILD_ARGS[@]}"
done
