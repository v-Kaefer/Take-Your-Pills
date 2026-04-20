#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
CONFIG_FILE=""
SCHEMA_FILE="config/issues/schema.json"
APPLY=false
DRY_RUN=true
VALIDATE_ONLY=false

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-issue-tree.sh --file config/issues/roadmap.json [--repo owner/name] [--schema config/issues/schema.json] [--dry-run|--apply] [--validate-only]
USAGE
}

json_escape() {
  python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
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
    --schema)
      SCHEMA_FILE="$2"
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
    --validate-only)
      VALIDATE_ONLY=true
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

if [[ -z "$CONFIG_FILE" ]]; then
  echo "Parâmetro obrigatório ausente: --file"
  usage
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Arquivo de configuração não encontrado: $CONFIG_FILE"
  exit 1
fi

if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Schema não encontrado: $SCHEMA_FILE"
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 não encontrado."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq não encontrado."
  exit 1
fi

validate_config() {
  python3 - "$CONFIG_FILE" "$SCHEMA_FILE" <<'PY'
import json
import sys

config_path = sys.argv[1]
schema_path = sys.argv[2]

with open(config_path, "r", encoding="utf-8") as f:
    data = json.load(f)
with open(schema_path, "r", encoding="utf-8") as f:
    schema = json.load(f)

required = schema.get("required", [])
props = schema.get("properties", {})
allowed_top = set(required) | set(props.keys())

missing = [k for k in required if k not in data]
if missing:
    raise SystemExit(f"Config inválido: campos obrigatórios ausentes: {', '.join(missing)}")

extra = [k for k in data.keys() if k not in allowed_top]
if extra:
    raise SystemExit(f"Config inválido: campos não suportados no topo: {', '.join(extra)}")

if str(data.get("schemaVersion", "")) != "1.0":
    raise SystemExit("Config inválido: schemaVersion deve ser '1.0'")

epics = data.get("epics", [])
if not isinstance(epics, list) or not epics:
    raise SystemExit("Config inválido: 'epics' deve ser uma lista não vazia")

def validate_issue(item, ctx):
    if not isinstance(item, dict):
        raise SystemExit(f"Config inválido em {ctx}: item deve ser objeto")
    for field in ("title", "type", "area", "priority"):
        if not str(item.get(field, "")).strip():
            raise SystemExit(f"Config inválido em {ctx}: campo obrigatório '{field}' ausente")
    if item["type"] not in {"epic", "feature", "task", "bug", "chore"}:
        raise SystemExit(f"Config inválido em {ctx}: type inválido '{item['type']}'")
    if item["priority"] not in {"p0", "p1", "p2", "p3"}:
        raise SystemExit(f"Config inválido em {ctx}: priority inválida '{item['priority']}'")
    labels = item.get("labels", [])
    if labels is not None and not isinstance(labels, list):
        raise SystemExit(f"Config inválido em {ctx}: labels deve ser lista")
    assignees = item.get("assignees", [])
    if assignees is not None and not isinstance(assignees, list):
        raise SystemExit(f"Config inválido em {ctx}: assignees deve ser lista")
    children = item.get("children", [])
    if children is not None and not isinstance(children, list):
        raise SystemExit(f"Config inválido em {ctx}: children deve ser lista")
    for idx, child in enumerate(children or []):
        validate_issue(child, f"{ctx}.children[{idx}]")

for idx, epic in enumerate(epics):
    if epic.get("type") != "epic":
        raise SystemExit(f"Config inválido em epics[{idx}]: type deve ser 'epic'")
    validate_issue(epic, f"epics[{idx}]")

print("Config válido.")
PY
}

validate_config

if [[ "$VALIDATE_ONLY" == true ]]; then
  exit 0
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ "$APPLY" == true ]]; then
  gh auth status >/dev/null
  gh api user >/dev/null
fi

mapfile -t ITEMS < <(python3 - "$CONFIG_FILE" <<'PY'
import base64
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

def emit(kind, parent_key, key, item):
    title = str(item.get("title", "")).strip()
    issue_type = str(item.get("type", "")).strip()
    area = str(item.get("area", "")).strip()
    priority = str(item.get("priority", "")).strip()
    body = str(item.get("body", "")).encode("utf-8")
    labels = item.get("labels", [])
    labels_csv = ",".join(str(x).strip() for x in labels if str(x).strip())
    assignees = item.get("assignees", [])
    assignees_csv = ",".join(str(x).strip() for x in assignees if str(x).strip())
    milestone = str(item.get("milestone", "")).strip()
    print("\t".join([
        kind,
        parent_key,
        key,
        title,
        issue_type,
        area,
        priority,
        base64.b64encode(body).decode("ascii"),
        labels_csv,
        assignees_csv,
        milestone,
    ]))

for epic_idx, epic in enumerate(data.get("epics", [])):
    epic_key = f"epic-{epic_idx}"
    emit("EPIC", "", epic_key, epic)
    for child_idx, child in enumerate(epic.get("children", [])):
        child_key = f"{epic_key}-child-{child_idx}"
        emit("CHILD", epic_key, child_key, child)
PY
)

if [[ "${#ITEMS[@]}" -eq 0 ]]; then
  echo "Nenhum item encontrado no arquivo: $CONFIG_FILE"
  exit 1
fi

declare -A EPIC_NUMBERS
declare -a RESULTS
created_count=0
updated_count=0
failed_count=0

for row in "${ITEMS[@]}"; do
  IFS=$'\t' read -r kind _ key title issue_type area priority body_b64 labels assignees milestone <<< "$row"
  if [[ "$kind" != "EPIC" ]]; then
    continue
  fi
  body="$(printf '%s' "$body_b64" | base64 -d)"
  declare -a ARGS
  ARGS=(
    --repo "$REPO"
    --title "$title"
    --type "$issue_type"
    --area "$area"
    --priority "$priority"
    --body "$body"
  )
  if [[ -n "$labels" ]]; then
    ARGS+=(--labels "$labels")
  fi
  if [[ -n "$assignees" ]]; then
    IFS=',' read -r -a assignees_arr <<< "$assignees"
    for assignee in "${assignees_arr[@]}"; do
      ARGS+=(--assignee "$assignee")
    done
  fi
  if [[ -n "$milestone" ]]; then
    ARGS+=(--milestone "$milestone")
  fi
  if [[ "$APPLY" == true ]]; then
    ARGS+=(--apply)
  else
    ARGS+=(--dry-run)
  fi

  set +e
  result="$(./scripts/github/create-issue.sh "${ARGS[@]}")"
  cmd_exit=$?
  set -e
  if [[ $cmd_exit -ne 0 ]]; then
    failed_count=$((failed_count + 1))
    continue
  fi
  RESULTS+=("$result")
  action="$(jq -r '.action // ""' <<<"$result")"
  number="$(jq -r '.number // ""' <<<"$result")"
  if [[ -n "$number" ]]; then
    EPIC_NUMBERS["$key"]="$number"
  fi
  if [[ "$action" == "created" ]]; then
    created_count=$((created_count + 1))
  elif [[ "$action" == "updated_existing" ]]; then
    updated_count=$((updated_count + 1))
  fi
done

for row in "${ITEMS[@]}"; do
  IFS=$'\t' read -r kind parent_key _ title issue_type area priority body_b64 labels assignees milestone <<< "$row"
  if [[ "$kind" != "CHILD" ]]; then
    continue
  fi
  parent_number="${EPIC_NUMBERS[$parent_key]:-}"
  if [[ -z "$parent_number" ]]; then
    failed_count=$((failed_count + 1))
    continue
  fi
  body="$(printf '%s' "$body_b64" | base64 -d)"
  declare -a ARGS
  ARGS=(
    --repo "$REPO"
    --parent "$parent_number"
    --title "$title"
    --type "$issue_type"
    --area "$area"
    --priority "$priority"
    --body "$body"
  )
  if [[ -n "$labels" ]]; then
    ARGS+=(--labels "$labels")
  fi
  if [[ -n "$assignees" ]]; then
    IFS=',' read -r -a assignees_arr <<< "$assignees"
    for assignee in "${assignees_arr[@]}"; do
      ARGS+=(--assignee "$assignee")
    done
  fi
  if [[ -n "$milestone" ]]; then
    ARGS+=(--milestone "$milestone")
  fi
  if [[ "$APPLY" == true ]]; then
    ARGS+=(--apply)
  else
    ARGS+=(--dry-run)
  fi

  set +e
  result="$(./scripts/github/create-subissue.sh "${ARGS[@]}")"
  cmd_exit=$?
  set -e
  if [[ $cmd_exit -ne 0 ]]; then
    failed_count=$((failed_count + 1))
    continue
  fi
  RESULTS+=("$result")
done

printf '{'
printf '"repo":%s,' "$(printf '%s' "$REPO" | json_escape)"
printf '"configFile":%s,' "$(printf '%s' "$CONFIG_FILE" | json_escape)"
printf '"schemaFile":%s,' "$(printf '%s' "$SCHEMA_FILE" | json_escape)"
printf '"dryRun":%s,' "$DRY_RUN"
printf '"created":%s,' "$created_count"
printf '"updated":%s,' "$updated_count"
printf '"failed":%s,' "$failed_count"
printf '"results":['
if [[ "${#RESULTS[@]}" -gt 0 ]]; then
  for i in "${!RESULTS[@]}"; do
    if [[ "$i" -gt 0 ]]; then
      printf ','
    fi
    printf '%s' "${RESULTS[$i]}"
  done
fi
printf ']}\n'
