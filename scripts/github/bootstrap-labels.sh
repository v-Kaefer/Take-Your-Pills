#!/usr/bin/env bash
set -euo pipefail

REPO="${GH_REPO:-}"
LABELS_FILE=".github/labels.yml"
APPLY=false
DRY_RUN=true

usage() {
  cat <<'EOF'
Uso:
  ./scripts/github/bootstrap-labels.sh [--repo owner/name] [--labels-file path] [--dry-run|--apply]

Descrição:
  Sincroniza labels no GitHub com base em um arquivo versionado.
  O arquivo .github/labels.yml, apesar da extensão .yml, usa formato JSON
  (válido em YAML 1.2) no padrão:
  { "labels": [ { "name": "...", "color": "...", "description": "..." } ] }
EOF
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
    --labels-file)
      LABELS_FILE="$2"
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

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 não encontrado."
  exit 1
fi

if [[ ! -f "$LABELS_FILE" ]]; then
  echo "Arquivo de labels não encontrado: $LABELS_FILE"
  exit 1
fi

if [[ -z "$REPO" ]]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi

if [[ "$APPLY" == true ]]; then
  gh auth status >/dev/null
  gh api user >/dev/null
fi

mapfile -t LABEL_ROWS < <(python3 - "$LABELS_FILE" <<'PY'
import json
import sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
except Exception as exc:
    print(f"Failed to parse labels file: {path} ({exc})", file=sys.stderr)
    sys.exit(1)

labels = data.get("labels", [])
for item in labels:
    name = str(item.get("name", "")).strip()
    color = str(item.get("color", "")).strip().lstrip("#")
    description = str(item.get("description", "")).strip()
    if not name or not color:
        continue
    print(f"{name}\t{color}\t{description}")
PY
)

created_count=0
updated_count=0
unchanged_count=0

for row in "${LABEL_ROWS[@]}"; do
  IFS=$'\t' read -r name color description <<< "$row"
  if [[ -z "${name:-}" || -z "${color:-}" ]]; then
    continue
  fi
  existing="$(gh label list --repo "$REPO" --search "$name" --json name,color,description | jq -c --arg name "$name" '.[] | select(.name == $name)' | head -n 1 || true)"
  if [[ -n "$existing" ]]; then
    existing_color="$(jq -r '.color // ""' <<<"$existing")"
    existing_description="$(jq -r '.description // ""' <<<"$existing")"
    if [[ "${existing_color^^}" == "${color^^}" && "$existing_description" == "$description" ]]; then
      unchanged_count=$((unchanged_count + 1))
      continue
    fi
    if [[ "$APPLY" == true ]]; then
      gh label create "$name" \
        --repo "$REPO" \
        --color "$color" \
        --description "$description" \
        --force >/dev/null
    fi
    updated_count=$((updated_count + 1))
    continue
  fi

  if [[ "$APPLY" == true ]]; then
    gh label create "$name" \
      --repo "$REPO" \
      --color "$color" \
      --description "$description" \
      --force >/dev/null
  fi
  created_count=$((created_count + 1))
done

printf '{'
printf '"repo":%s,' "$(printf '%s' "$REPO" | json_escape)"
printf '"labelsFile":%s,' "$(printf '%s' "$LABELS_FILE" | json_escape)"
printf '"dryRun":%s,' "$DRY_RUN"
printf '"created":%s,' "$created_count"
printf '"updated":%s,' "$updated_count"
printf '"unchanged":%s' "$unchanged_count"
printf '}\n'
