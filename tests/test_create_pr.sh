#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin"

cat > "$tmpdir/bin/gh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$@" > "${GH_CALL_LOG:?}"
EOF
chmod +x "$tmpdir/bin/gh"

export PATH="$tmpdir/bin:$PATH"
export GH_CALL_LOG="$tmpdir/gh-call.log"

bash scripts/github/create-pr.sh --base develop --head feat/test --title "Title" --body "Body"

grep -Fxq 'pr' "$GH_CALL_LOG"
grep -Fxq 'create' "$GH_CALL_LOG"
grep -Fxq -- '--template' "$GH_CALL_LOG"
grep -Fq 'pull_request_template.md' "$GH_CALL_LOG"
grep -Fxq -- '--base' "$GH_CALL_LOG"
grep -Fxq 'develop' "$GH_CALL_LOG"
grep -Fxq -- '--head' "$GH_CALL_LOG"
grep -Fxq 'feat/test' "$GH_CALL_LOG"
grep -Fxq -- '--title' "$GH_CALL_LOG"
grep -Fxq 'Title' "$GH_CALL_LOG"
grep -Fxq -- '--body' "$GH_CALL_LOG"
grep -Fxq 'Body' "$GH_CALL_LOG"

if bash scripts/github/create-pr.sh --fill 2>"$tmpdir/fill.err"; then
  echo "Wrapper accepted --fill, but it should reject it." >&2
  exit 1
fi

grep -qi 'não suporta --fill' "$tmpdir/fill.err"
