#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
CONFIG_FILE=""
SCHEMA_FILE="config/issues/schema.json"
DRY_RUN=true
VALIDATE_ONLY=false

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/create-issue-tree.sh --file config/issues/roadmap.json [--repo owner/name] [--schema config/issues/schema.json] [--dry-run|--apply] [--validate-only]
USAGE
}

log() {
  printf '[create-issue-tree] %s\n' "$1" >&2
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd não encontrado."
    exit 1
  fi
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
      DRY_RUN=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
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

require_cmd python3
require_cmd jq

validate_and_normalize() {
  python3 - "$CONFIG_FILE" "$SCHEMA_FILE" <<'PY'
import json
import sys
from collections import OrderedDict

config_path = sys.argv[1]
schema_path = sys.argv[2]

with open(config_path, "r", encoding="utf-8") as f:
    data = json.load(f)
with open(schema_path, "r", encoding="utf-8") as f:
    schema = json.load(f)

required_top = schema.get("required", [])
props_top = schema.get("properties", {})
allowed_top = set(required_top) | set(props_top.keys())

missing = [k for k in required_top if k not in data]
if missing:
    raise SystemExit(f"Config inválido: campos obrigatórios ausentes: {', '.join(missing)}")

extra_top = [k for k in data.keys() if k not in allowed_top]
if extra_top:
    raise SystemExit(f"Config inválido: campos não suportados no topo: {', '.join(extra_top)}")

if str(data.get("schemaVersion", "")) != "1.0":
    raise SystemExit("Config inválido: schemaVersion deve ser '1.0'")

allowed_types = {"epic", "feature", "task", "bug", "chore"}
allowed_priorities = {"p0", "p1", "p2", "p3"}
allowed_areas = {"gameplay", "ui", "art", "audio", "infra", "docs", "automation"}


def to_list(value):
    if value is None:
        return []
    if isinstance(value, list):
        return value
    raise SystemExit("Config inválido: valor deveria ser lista")


def dedupe_str_list(values):
    out = []
    seen = set()
    for raw in values:
        val = str(raw).strip()
        if not val or val in seen:
            continue
        seen.add(val)
        out.append(val)
    return out


def validate_issue(item, ctx):
    if not isinstance(item, dict):
        raise SystemExit(f"Config inválido em {ctx}: item deve ser objeto")
    for field in ("title", "type", "area", "priority"):
        if not str(item.get(field, "")).strip():
            raise SystemExit(f"Config inválido em {ctx}: campo obrigatório '{field}' ausente")

    issue_type = str(item["type"]).strip()
    priority = str(item["priority"]).strip()
    area = str(item["area"]).strip()

    if issue_type not in allowed_types:
        raise SystemExit(f"Config inválido em {ctx}: type inválido '{issue_type}'")
    if priority not in allowed_priorities:
        raise SystemExit(f"Config inválido em {ctx}: priority inválida '{priority}'")
    if area not in allowed_areas:
        raise SystemExit(f"Config inválido em {ctx}: area inválida '{area}'")

    labels = to_list(item.get("labels", []))
    assignees = to_list(item.get("assignees", []))
    children = to_list(item.get("children", []))

    if not all(str(x).strip() for x in labels):
        raise SystemExit(f"Config inválido em {ctx}: labels contém valor vazio")
    if not all(str(x).strip() for x in assignees):
        raise SystemExit(f"Config inválido em {ctx}: assignees contém valor vazio")

    for idx, child in enumerate(children):
        validate_issue(child, f"{ctx}.children[{idx}]")


def get_defaults():
    defaults = data.get("defaults", {})
    if defaults is None:
        defaults = {}
    if not isinstance(defaults, dict):
        raise SystemExit("Config inválido: defaults deve ser objeto")

    labels = dedupe_str_list(to_list(defaults.get("labels", [])))
    assignees = dedupe_str_list(to_list(defaults.get("assignees", [])))
    milestone = str(defaults.get("milestone", "")).strip()
    body = str(defaults.get("body", ""))

    return {
        "labels": labels,
        "assignees": assignees,
        "milestone": milestone,
        "body": body,
    }


def get_project():
    project = data.get("project", None)
    if project is None:
        return {}
    if not isinstance(project, dict):
        raise SystemExit("Config inválido: project deve ser objeto")

    owner = str(project.get("owner", "")).strip()
    number = project.get("number", "")
    if owner and (not isinstance(number, int) or number < 1):
        raise SystemExit("Config inválido: project.number deve ser inteiro >= 1 quando project.owner for informado")

    fields_file = str(project.get("fieldsFile", ".github/project/fields.json")).strip() or ".github/project/fields.json"
    status_on_create = str(project.get("statusOnCreate", "Backlog")).strip() or "Backlog"

    extra_field_values = project.get("extraFieldValues", {})
    if extra_field_values is None:
        extra_field_values = {}
    if not isinstance(extra_field_values, dict):
        raise SystemExit("Config inválido: project.extraFieldValues deve ser objeto")

    normalized_extra = {}
    for key, value in extra_field_values.items():
        k = str(key).strip()
        v = str(value).strip()
        if not k or not v:
            raise SystemExit("Config inválido: project.extraFieldValues não aceita chave/valor vazio")
        normalized_extra[k] = v

    return {
        "owner": owner,
        "number": number if isinstance(number, int) else None,
        "fieldsFile": fields_file,
        "statusOnCreate": status_on_create,
        "extraFieldValues": normalized_extra,
    }


def get_linking():
    linking = data.get("linking", {})
    if linking is None:
        linking = {}
    if not isinstance(linking, dict):
        raise SystemExit("Config inválido: linking deve ser objeto")

    strategy = str(linking.get("subIssueStrategy", "graphql_or_comment")).strip() or "graphql_or_comment"
    if strategy not in {"graphql_or_comment"}:
        raise SystemExit("Config inválido: linking.subIssueStrategy inválido")

    return {"subIssueStrategy": strategy}


def merge_defaults(defaults, item):
    item_labels = dedupe_str_list(to_list(item.get("labels", [])))
    item_assignees = dedupe_str_list(to_list(item.get("assignees", [])))
    labels = dedupe_str_list(defaults["labels"] + item_labels)
    assignees = dedupe_str_list(defaults["assignees"] + item_assignees)
    milestone = str(item.get("milestone", defaults["milestone"]))
    milestone = milestone.strip()
    body = str(item.get("body", defaults["body"]))

    return labels, assignees, milestone, body


def normalize_item(item, key, parent_key, kind, defaults):
    labels, assignees, milestone, body = merge_defaults(defaults, item)
    issue_type = str(item["type"]).strip()
    area = str(item["area"]).strip()
    priority = str(item["priority"]).strip()

    required_labels = [
        f"type:{issue_type}",
        f"area:{area}",
        f"priority:{priority}",
    ] + labels

    return {
        "key": key,
        "parentKey": parent_key,
        "kind": kind,
        "title": str(item["title"]).strip(),
        "type": issue_type,
        "area": area,
        "priority": priority,
        "body": body,
        "labels": labels,
        "assignees": assignees,
        "milestone": milestone,
        "requiredLabels": dedupe_str_list(required_labels),
    }


def collect_items(epics, defaults):
    normalized = []
    for epic_idx, epic in enumerate(epics):
        if epic.get("type") != "epic":
            raise SystemExit(f"Config inválido em epics[{epic_idx}]: type deve ser 'epic'")
        epic_key = f"epic-{epic_idx}"
        normalized.append(normalize_item(epic, epic_key, "", "EPIC", defaults))

        children = epic.get("children", []) or []
        for child_idx, child in enumerate(children):
            child_key = f"{epic_key}-child-{child_idx}"
            normalized.append(normalize_item(child, child_key, epic_key, "CHILD", defaults))
    return normalized


def ensure_titles_unique(items):
    seen = {}
    duplicates = []
    for item in items:
        title = item["title"]
        if title in seen:
            duplicates.append(title)
        else:
            seen[title] = 1
    if duplicates:
        unique = sorted(set(duplicates))
        raise SystemExit("Config inválido: títulos duplicados no manifesto: " + ", ".join(unique))


def ensure_parent_child(items):
    keys = {item["key"] for item in items}
    for item in items:
        if item["kind"] == "CHILD" and item["parentKey"] not in keys:
            raise SystemExit(f"Config inválido: parentKey inexistente para {item['key']}")


def collect_required_labels(items):
    out = OrderedDict()
    for item in items:
        for label in item["requiredLabels"]:
            out[label] = True
    return list(out.keys())


def main():
    epics = data.get("epics", [])
    if not isinstance(epics, list) or not epics:
        raise SystemExit("Config inválido: 'epics' deve ser uma lista não vazia")

    for idx, epic in enumerate(epics):
        validate_issue(epic, f"epics[{idx}]")

    defaults = get_defaults()
    project = get_project()
    linking = get_linking()
    items = collect_items(epics, defaults)

    if not items:
        raise SystemExit("Config inválido: nenhum item encontrado")

    ensure_titles_unique(items)
    ensure_parent_child(items)

    payload = {
        "schemaVersion": "1.0",
        "defaults": defaults,
        "project": project,
        "linking": linking,
        "requiredLabels": collect_required_labels(items),
        "items": items,
    }

    print(json.dumps(payload, ensure_ascii=False))


if __name__ == "__main__":
    main()
PY
}

log "Etapa: validar"
NORMALIZED_JSON="$(validate_and_normalize)"

if [[ "$VALIDATE_ONLY" == true ]]; then
  jq -n \
    --arg repo "$REPO" \
    --arg configFile "$CONFIG_FILE" \
    --arg schemaFile "$SCHEMA_FILE" \
    --argjson normalized "$NORMALIZED_JSON" \
    '{
      repo: $repo,
      configFile: $configFile,
      schemaFile: $schemaFile,
      validateOnly: true,
      dryRun: true,
      stage: "validate",
      summary: {
        totalItems: ($normalized.items | length),
        epics: ($normalized.items | map(select(.kind == "EPIC")) | length),
        children: ($normalized.items | map(select(.kind == "CHILD")) | length)
      },
      message: "Config válido."
    }'
  exit 0
fi

require_cmd gh

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

project_owner="$(jq -r '.project.owner // ""' <<<"$NORMALIZED_JSON")"
project_number="$(jq -r '.project.number // empty' <<<"$NORMALIZED_JSON")"
project_fields_file="$(jq -r '.project.fieldsFile // ".github/project/fields.json"' <<<"$NORMALIZED_JSON")"
project_status_on_create="$(jq -r '.project.statusOnCreate // "Backlog"' <<<"$NORMALIZED_JSON")"

have_project=false
if [[ -n "$project_owner" && -n "$project_number" ]]; then
  have_project=true
fi

log "Etapa: planejar"

auth_ok=true
perm_ok=true
labels_ok=true
project_ok=true
missing_labels_json='[]'
project_message=""

if ! gh auth status >/dev/null 2>&1; then
  auth_ok=false
fi

set +e
repo_permissions_json="$(gh api "repos/$REPO" --jq '{issues:(.permissions.push // false),pull:(.permissions.pull // true)}' 2>/dev/null)"
perm_exit=$?
set -e
if [[ $perm_exit -ne 0 ]]; then
  perm_ok=false
else
  issues_perm="$(jq -r '.issues // false' <<<"$repo_permissions_json")"
  if [[ "$issues_perm" != "true" ]]; then
    perm_ok=false
  fi
fi

existing_issues_json='[]'
set +e
existing_issues_json="$(gh api "repos/$REPO/issues?state=all&per_page=100" 2>/dev/null)"
issues_exit=$?
set -e
if [[ $issues_exit -ne 0 ]]; then
  auth_ok=false
fi

repo_labels_json='[]'
set +e
repo_labels_json="$(gh label list --repo "$REPO" --limit 500 --json name 2>/dev/null)"
labels_exit=$?
set -e
if [[ $labels_exit -ne 0 ]]; then
  auth_ok=false
fi

required_labels_json="$(jq -c '.requiredLabels // []' <<<"$NORMALIZED_JSON")"
missing_labels_json="$(jq -cn --argjson required "$required_labels_json" --argjson current "$repo_labels_json" '
  ([$current[]?.name] | map(select(length > 0))) as $names |
  [$required[] | select((. as $x | $names | index($x)) == null)]
')"
if [[ "$(jq 'length' <<<"$missing_labels_json")" -gt 0 ]]; then
  labels_ok=false
fi

project_fields_json='{}'
if [[ "$have_project" == true ]]; then
  set +e
  gh project view "$project_number" --owner "$project_owner" --format json >/dev/null 2>&1
  project_view_exit=$?
  set -e
  if [[ $project_view_exit -ne 0 ]]; then
    project_ok=false
    project_message="Project não acessível para owner/number informados."
  elif [[ ! -f "$project_fields_file" ]]; then
    project_ok=false
    project_message="Arquivo de mapeamento de campos não encontrado: $project_fields_file"
  else
    set +e
    project_fields_json="$(cat "$project_fields_file")"
    fields_parse_exit=$?
    set -e
    if [[ $fields_parse_exit -ne 0 ]]; then
      project_ok=false
      project_message="Falha ao ler arquivo de campos do project."
    fi
  fi
fi

items_planned_json="$(jq -cn --argjson items "$(jq -c '.items' <<<"$NORMALIZED_JSON")" --argjson existing "$existing_issues_json" '
  [$items[] | (.title) as $itemTitle | . + {
    planAction: (
      if ([ $existing[] | select((.pull_request|not) and .title == $itemTitle)] | length) > 0 then "update" else "create" end
    )
  }]
')"

if [[ "$auth_ok" != "true" || "$perm_ok" != "true" || "$labels_ok" != "true" || "$project_ok" != "true" ]]; then
  jq -n \
    --arg repo "$REPO" \
    --arg configFile "$CONFIG_FILE" \
    --arg schemaFile "$SCHEMA_FILE" \
    --argjson missingLabels "$missing_labels_json" \
    --arg projectMessage "$project_message" \
    --argjson items "$items_planned_json" \
    --argjson authOk "$auth_ok" \
    --argjson permOk "$perm_ok" \
    --argjson labelsOk "$labels_ok" \
    --argjson projectOk "$project_ok" \
    '{
      repo: $repo,
      configFile: $configFile,
      schemaFile: $schemaFile,
      validateOnly: false,
      dryRun: true,
      stage: "plan",
      preconditions: {
        authOk: $authOk,
        permissionsOk: $permOk,
        labelsOk: $labelsOk,
        projectOk: $projectOk,
        missingLabels: $missingLabels,
        projectMessage: $projectMessage
      },
      summary: {
        totalItems: ($items | length),
        plannedCreate: ($items | map(select(.planAction == "create")) | length),
        plannedUpdate: ($items | map(select(.planAction == "update")) | length),
        failed: 1
      },
      items: $items,
      message: "Pré-condições inválidas. Corrija antes de aplicar."
    }'
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  jq -n \
    --arg repo "$REPO" \
    --arg configFile "$CONFIG_FILE" \
    --arg schemaFile "$SCHEMA_FILE" \
    --argjson missingLabels "$missing_labels_json" \
    --argjson items "$items_planned_json" \
    '{
      repo: $repo,
      configFile: $configFile,
      schemaFile: $schemaFile,
      validateOnly: false,
      dryRun: true,
      stage: "plan",
      preconditions: {
        authOk: true,
        permissionsOk: true,
        labelsOk: true,
        projectOk: true,
        missingLabels: $missingLabels
      },
      summary: {
        totalItems: ($items | length),
        plannedCreate: ($items | map(select(.planAction == "create")) | length),
        plannedUpdate: ($items | map(select(.planAction == "update")) | length),
        failed: 0
      },
      items: $items,
      message: "Planejamento concluído (dry-run)."
    }'
  exit 0
fi

log "Etapa: aplicar"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
results_file="$tmp_dir/results.ndjson"

created_count=0
updated_count=0
linked_count=0
project_items_added_count=0
project_fields_updated_count=0
failed_count=0

declare -A ITEM_NUMBER_BY_KEY

total_items="$(jq 'length' <<<"$items_planned_json")"

for ((i=0; i<total_items; i++)); do
  item_json="$(jq -c ".[$i]" <<<"$items_planned_json")"
  kind="$(jq -r '.kind' <<<"$item_json")"
  if [[ "$kind" != "EPIC" ]]; then
    continue
  fi

  title="$(jq -r '.title' <<<"$item_json")"
  issue_type="$(jq -r '.type' <<<"$item_json")"
  area="$(jq -r '.area' <<<"$item_json")"
  priority="$(jq -r '.priority' <<<"$item_json")"
  body="$(jq -r '.body' <<<"$item_json")"
  labels_csv="$(jq -r '.labels | join(",")' <<<"$item_json")"
  milestone="$(jq -r '.milestone // ""' <<<"$item_json")"
  key="$(jq -r '.key' <<<"$item_json")"

  mapfile -t assignees < <(jq -r '.assignees[]?' <<<"$item_json")

  args=(
    --repo "$REPO"
    --title "$title"
    --type "$issue_type"
    --area "$area"
    --priority "$priority"
    --body "$body"
  )

  if [[ -n "$labels_csv" ]]; then
    args+=(--labels "$labels_csv")
  fi
  if [[ -n "$milestone" ]]; then
    args+=(--milestone "$milestone")
  fi
  for assignee in "${assignees[@]}"; do
    args+=(--assignee "$assignee")
  done
  args+=(--apply)

  set +e
  result_json="$(./scripts/github/create-issue.sh "${args[@]}")"
  cmd_exit=$?
  set -e

  if [[ $cmd_exit -ne 0 ]]; then
    failed_count=$((failed_count + 1))
    jq -cn --argjson item "$item_json" '{item:$item,status:"failed",message:"Falha ao criar/atualizar issue"}' >> "$results_file"
    continue
  fi

  action="$(jq -r '.action // ""' <<<"$result_json")"
  number="$(jq -r '.number // ""' <<<"$result_json")"
  url="$(jq -r '.url // ""' <<<"$result_json")"

  if [[ -n "$number" ]]; then
    ITEM_NUMBER_BY_KEY["$key"]="$number"
  fi

  if [[ "$action" == "created" ]]; then
    created_count=$((created_count + 1))
  elif [[ "$action" == "updated_existing" ]]; then
    updated_count=$((updated_count + 1))
  fi

  project_add_status="skipped"
  project_fields_status="skipped"
  project_message_local=""

  if [[ "$have_project" == true && -n "$url" ]]; then
    set +e
    add_output="$(gh project item-add "$project_number" --owner "$project_owner" --url "$url" 2>&1)"
    add_exit=$?
    set -e
    if [[ $add_exit -eq 0 ]]; then
      project_items_added_count=$((project_items_added_count + 1))
      project_add_status="added"
    elif grep -qi "already exists" <<<"$add_output"; then
      project_add_status="already_present"
    else
      project_add_status="failed"
      project_message_local="$add_output"
    fi

    if [[ "$project_add_status" == "added" || "$project_add_status" == "already_present" ]]; then
      set +e
      item_list_json="$(gh project item-list "$project_number" --owner "$project_owner" --format json --limit 200 2>/dev/null)"
      item_list_exit=$?
      set -e
      if [[ $item_list_exit -eq 0 ]]; then
        item_id="$(jq -r --arg num "$number" '.items[]? | select((.content.number|tostring)==$num) | .id' <<<"$item_list_json" | head -n 1)"
        project_id="$(jq -r '.project_id // ""' <<<"$project_fields_json")"
        if [[ -n "$item_id" && -n "$project_id" ]]; then
          status_field_id="$(jq -r '.fields.Status.id // ""' <<<"$project_fields_json")"
          status_option_id="$(jq -r --arg name "$project_status_on_create" '.fields.Status.options[$name] // ""' <<<"$project_fields_json")"
          if [[ -n "$status_field_id" && -n "$status_option_id" ]]; then
            set +e
            gh project item-edit --id "$item_id" --project-id "$project_id" --field-id "$status_field_id" --single-select-option-id "$status_option_id" >/dev/null 2>&1
            status_edit_exit=$?
            set -e
            if [[ $status_edit_exit -eq 0 ]]; then
              project_fields_updated_count=$((project_fields_updated_count + 1))
              project_fields_status="updated"
            fi
          fi

          type_field_id="$(jq -r '.fields.Type.id // ""' <<<"$project_fields_json")"
          type_option_name="$(echo "$issue_type" | tr '[:lower:]' '[:upper:]')"
          type_option_id="$(jq -r --arg name "$type_option_name" '.fields.Type.options[$name] // ""' <<<"$project_fields_json")"
          if [[ -n "$type_field_id" && -n "$type_option_id" ]]; then
            gh project item-edit --id "$item_id" --project-id "$project_id" --field-id "$type_field_id" --single-select-option-id "$type_option_id" >/dev/null 2>&1 || true
          fi

          priority_field_id="$(jq -r '.fields.Priority.id // ""' <<<"$project_fields_json")"
          priority_option_name="$(echo "$priority" | tr '[:lower:]' '[:upper:]')"
          priority_option_id="$(jq -r --arg name "$priority_option_name" '.fields.Priority.options[$name] // ""' <<<"$project_fields_json")"
          if [[ -n "$priority_field_id" && -n "$priority_option_id" ]]; then
            gh project item-edit --id "$item_id" --project-id "$project_id" --field-id "$priority_field_id" --single-select-option-id "$priority_option_id" >/dev/null 2>&1 || true
          fi

          area_field_id="$(jq -r '.fields.Area.id // ""' <<<"$project_fields_json")"
          area_option_name="$(echo "$area" | sed 's/.*/\L&/; s/^./\U&/')"
          area_option_id="$(jq -r --arg name "$area_option_name" '.fields.Area.options[$name] // ""' <<<"$project_fields_json")"
          if [[ -n "$area_field_id" && -n "$area_option_id" ]]; then
            gh project item-edit --id "$item_id" --project-id "$project_id" --field-id "$area_field_id" --single-select-option-id "$area_option_id" >/dev/null 2>&1 || true
          fi

          while IFS= read -r field_name; do
            field_id="$(jq -r --arg field "$field_name" '.fields[$field].id // ""' <<<"$project_fields_json")"
            field_value="$(jq -r --arg field "$field_name" '.project.extraFieldValues[$field] // ""' <<<"$NORMALIZED_JSON")"
            if [[ -n "$field_id" && -n "$field_value" ]]; then
              gh project item-edit --id "$item_id" --project-id "$project_id" --field-id "$field_id" --text "$field_value" >/dev/null 2>&1 || true
            fi
          done < <(jq -r '.project.extraFieldValues | keys[]?' <<<"$NORMALIZED_JSON")
        fi
      fi
    fi
  fi

  jq -cn \
    --argjson item "$item_json" \
    --argjson result "$result_json" \
    --arg projectAddStatus "$project_add_status" \
    --arg projectFieldsStatus "$project_fields_status" \
    --arg projectMessage "$project_message_local" \
    '{
      item: $item,
      status: "ok",
      applyAction: ($result.action // ""),
      number: ($result.number // ""),
      url: ($result.url // ""),
      message: ($result.message // ""),
      project: {
        itemAdd: $projectAddStatus,
        fields: $projectFieldsStatus,
        message: $projectMessage
      }
    }' >> "$results_file"
done

for ((i=0; i<total_items; i++)); do
  item_json="$(jq -c ".[$i]" <<<"$items_planned_json")"
  kind="$(jq -r '.kind' <<<"$item_json")"
  if [[ "$kind" != "CHILD" ]]; then
    continue
  fi

  parent_key="$(jq -r '.parentKey' <<<"$item_json")"
  parent_number="${ITEM_NUMBER_BY_KEY[$parent_key]:-}"
  if [[ -z "$parent_number" ]]; then
    failed_count=$((failed_count + 1))
    jq -cn --argjson item "$item_json" '{item:$item,status:"failed",message:"Issue pai não disponível para vínculo"}' >> "$results_file"
    continue
  fi

  title="$(jq -r '.title' <<<"$item_json")"
  issue_type="$(jq -r '.type' <<<"$item_json")"
  area="$(jq -r '.area' <<<"$item_json")"
  priority="$(jq -r '.priority' <<<"$item_json")"
  body="$(jq -r '.body' <<<"$item_json")"
  labels_csv="$(jq -r '.labels | join(",")' <<<"$item_json")"
  milestone="$(jq -r '.milestone // ""' <<<"$item_json")"

  mapfile -t assignees < <(jq -r '.assignees[]?' <<<"$item_json")

  args=(
    --repo "$REPO"
    --parent "$parent_number"
    --title "$title"
    --type "$issue_type"
    --area "$area"
    --priority "$priority"
    --body "$body"
  )

  if [[ -n "$labels_csv" ]]; then
    args+=(--labels "$labels_csv")
  fi
  if [[ -n "$milestone" ]]; then
    args+=(--milestone "$milestone")
  fi
  for assignee in "${assignees[@]}"; do
    args+=(--assignee "$assignee")
  done
  args+=(--apply)

  set +e
  result_json="$(./scripts/github/create-subissue.sh "${args[@]}")"
  cmd_exit=$?
  set -e

  if [[ $cmd_exit -ne 0 ]]; then
    failed_count=$((failed_count + 1))
    jq -cn --argjson item "$item_json" '{item:$item,status:"failed",message:"Falha ao criar/vincular sub-issue"}' >> "$results_file"
    continue
  fi

  action="$(jq -r '.action // ""' <<<"$result_json")"
  child_number="$(jq -r '.childNumber // ""' <<<"$result_json")"
  if [[ "$action" == "linked" || "$action" == "linked_with_fallback" || "$action" == "already_linked_with_fallback" ]]; then
    linked_count=$((linked_count + 1))
  fi

  if [[ "$action" == "issue_stage_only" ]]; then
    failed_count=$((failed_count + 1))
  fi

  if [[ -n "$child_number" ]]; then
    ITEM_NUMBER_BY_KEY["$(jq -r '.key' <<<"$item_json")"]="$child_number"
  fi

  jq -cn \
    --argjson item "$item_json" \
    --argjson result "$result_json" \
    '{
      item: $item,
      status: "ok",
      applyAction: ($result.action // ""),
      number: ($result.childNumber // ""),
      url: ($result.childUrl // ""),
      message: ($result.message // "")
    }' >> "$results_file"
done

results_json='[]'
if [[ -s "$results_file" ]]; then
  results_json="$(jq -s '.' "$results_file")"
fi

jq -n \
  --arg repo "$REPO" \
  --arg configFile "$CONFIG_FILE" \
  --arg schemaFile "$SCHEMA_FILE" \
  --argjson items "$items_planned_json" \
  --argjson results "$results_json" \
  --argjson missingLabels "$missing_labels_json" \
  --argjson created "$created_count" \
  --argjson updated "$updated_count" \
  --argjson linked "$linked_count" \
  --argjson projectItemsAdded "$project_items_added_count" \
  --argjson projectFieldsUpdated "$project_fields_updated_count" \
  --argjson failed "$failed_count" \
  '{
    repo: $repo,
    configFile: $configFile,
    schemaFile: $schemaFile,
    validateOnly: false,
    dryRun: false,
    stage: "apply",
    preconditions: {
      authOk: true,
      permissionsOk: true,
      labelsOk: true,
      projectOk: true,
      missingLabels: $missingLabels
    },
    summary: {
      totalItems: ($items | length),
      plannedCreate: ($items | map(select(.planAction == "create")) | length),
      plannedUpdate: ($items | map(select(.planAction == "update")) | length),
      created: $created,
      updated: $updated,
      linked: $linked,
      projectItemsAdded: $projectItemsAdded,
      projectFieldsUpdated: $projectFieldsUpdated,
      failed: $failed
    },
    items: $results
  }'
