#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

labels_file="$tmpdir/labels.json"
cat > "$labels_file" <<'JSON'
{
  "labels": [
    { "name": "alpha", "color": "111111", "description": "A" },
    { "name": "beta", "color": "222222", "description": "B" },
    { "name": "gamma", "color": "333333", "description": "C" }
  ]
}
JSON

mkdir -p "$tmpdir/bin"

cat > "$tmpdir/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "$1 $2" in
  "auth status")
    exit 0
    ;;
  "api user")
    exit 0
    ;;
  "label list")
    search=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --search)
          search="$2"
          shift 2
          ;;
        --repo|--json|--limit)
          shift 2
          ;;
        *)
          shift
          ;;
      esac
    done

    case "$search" in
      alpha)
        printf '%s\n' '[{"name":"alpha","color":"111111","description":"A"}]'
        ;;
      beta)
        printf '%s\n' '[{"name":"beta","color":"AAAAAA","description":"old"}]'
        ;;
      gamma)
        printf '%s\n' '[]'
        ;;
      *)
        printf '%s\n' '[]'
        ;;
    esac
    ;;
  "label create")
    printf '%s\n' "$*" >> "${GH_CREATE_LOG:?}"
    ;;
  *)
    echo "Unexpected gh call: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$tmpdir/bin/gh"

export PATH="$tmpdir/bin:$PATH"
export GH_CREATE_LOG="$tmpdir/create.log"

dry_run_output="$tmpdir/dry-run.json"
bash scripts/github/bootstrap-labels.sh --repo owner/name --labels-file "$labels_file" > "$dry_run_output"

grep -Fq '"dryRun":true' "$dry_run_output"
grep -Fq '"created":1' "$dry_run_output"
grep -Fq '"updated":1' "$dry_run_output"
grep -Fq '"unchanged":1' "$dry_run_output"

: > "$GH_CREATE_LOG"
apply_output="$tmpdir/apply.json"
bash scripts/github/bootstrap-labels.sh --repo owner/name --labels-file "$labels_file" --apply > "$apply_output"

grep -Fq '"dryRun":false' "$apply_output"
grep -Fq 'beta' "$GH_CREATE_LOG"
grep -Fq 'gamma' "$GH_CREATE_LOG"
