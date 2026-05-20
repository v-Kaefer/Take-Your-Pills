#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

remote_repo="$tmpdir/remote.git"
work_repo="$tmpdir/work"

git init -q --bare "$remote_repo"
git init -q "$work_repo"

cd "$work_repo"
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false
git config push.gpgSign false
git remote add origin "$remote_repo"

mkdir -p scenes/player docs
printf '%s\n' 'extends Node' > scenes/player/player.gd
git add scenes/player/player.gd
git commit -q -m "initial"
git branch -M main
git push -q origin main

git config core.hooksPath "$repo_root/.githooks"

printf '%s\n' 'print("player updated")' >> scenes/player/player.gd
printf '%s\n' '# summary' > docs/summary.md
git add scenes/player/player.gd docs/summary.md
git commit -q -m "update systems"

output="$(git push origin HEAD:main 2>&1)"

grep -Fq "pre-push audit" <<<"$output"
grep -Fq "Gameplay impact" <<<"$output"
grep -Fq "Player systems" <<<"$output"
grep -Fq "Support changes" <<<"$output"
grep -Fq "Documentation" <<<"$output"
grep -Fq "Lint checks passed" <<<"$output"

mkdir -p scripts
cat > scripts/broken.py <<'EOF'
def broken(
    return 1
EOF

git add scripts/broken.py
git commit -q -m "introduce broken python"

if output="$(git push origin HEAD:main 2>&1)"; then
  echo "Expected pre-push hook to block the invalid Python file" >&2
  exit 1
fi

grep -Fq "Lint checks failed" <<<"$output"
grep -Fq "broken.py" <<<"$output"
grep -Fq "SyntaxError" <<<"$output"
