#!/usr/bin/env bash
set -euo pipefail

OWNER=""
PROJECT_NUMBER=""
OUTPUT_FILE=".github/project/fields.json"

usage() {
  cat <<'USAGE'
Uso:
  ./scripts/github/seed-project.sh --owner v-Kaefer --project-number 1 [--output .github/project/fields.json]
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner)
      OWNER="$2"
      shift 2
      ;;
    --project-number)
      PROJECT_NUMBER="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
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

if [[ -z "$OWNER" || -z "$PROJECT_NUMBER" ]]; then
  echo "Parâmetros obrigatórios ausentes: --owner --project-number"
  usage
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"

project_json="$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json)"
fields_json="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 200 --format json)"

PROJECT_JSON="$project_json" FIELDS_JSON="$fields_json" python3 - "$OWNER" "$PROJECT_NUMBER" "$OUTPUT_FILE" <<'PY'
import json
import os
import sys

owner = sys.argv[1]
project_number = int(sys.argv[2])
output_file = sys.argv[3]
project = json.loads(os.environ["PROJECT_JSON"])
fields = json.loads(os.environ["FIELDS_JSON"])

field_map = {}
for field in fields.get("fields", fields if isinstance(fields, list) else []):
    name = field.get("name")
    if not name:
        continue
    entry = {
        "id": field.get("id"),
        "data_type": field.get("dataType"),
    }
    options = {}
    for option in field.get("options", []):
        option_name = option.get("name")
        option_id = option.get("id")
        if option_name and option_id:
            options[option_name] = option_id
    if options:
        entry["options"] = options
    field_map[name] = entry

payload = {
    "owner": owner,
    "project_number": project_number,
    "project_id": project.get("id"),
    "project_url": project.get("url"),
    "fields": field_map,
}

with open(output_file, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

echo "Arquivo gerado: $OUTPUT_FILE"
