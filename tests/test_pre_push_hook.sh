#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
grep -Fq "Bash 4.3+ is required" "$repo_root/.githooks/pre-push"

if ((BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 3))); then
  echo "Skipping pre-push execution tests because Bash 4.3+ is required."
  exit 0
fi

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
git push -q -u origin main

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
grep -Fq "Lint checks: no lintable files detected." <<<"$output"
if grep -Fq "Lint checks passed for" <<<"$output"; then
  echo "Expected non-lintable-only changes to avoid reporting linted file success" >&2
  exit 1
fi
grep -Fq "[pre-push] mode: git hook stdin; reading refs queued by git push." <<<"$output"
grep -Fq "segment coverage check" <<<"$output"
grep -Fq "WARNING: gameplay files changed but no test files were included." <<<"$output"
grep -Fq "scenes/player/player.gd" <<<"$output"

if command -v script >/dev/null; then
  manual_output="$(script -q -e -c "cd '$work_repo' && PRE_PUSH_VERBOSE=1 bash '$repo_root/.githooks/pre-push'" /dev/null 2>&1)"
  manual_output="${manual_output//$'\r'/}"
  grep -Fq "[pre-push] mode: interactive terminal; running local upstream comparison." <<<"$manual_output"
  grep -Fq "[pre-push] [verbose] manual refs:" <<<"$manual_output"
  grep -Fq "[pre-push] result: passed." <<<"$manual_output"

  no_upstream_repo="$tmpdir/no-upstream"
  git init -q "$no_upstream_repo"
  cd "$no_upstream_repo"
  git config user.email "test@example.com"
  git config user.name "Test User"
  git config commit.gpgsign false
  git config tag.gpgsign false
  git config push.gpgSign false
  mkdir -p docs
  printf '%s\n' '# note' > docs/readme.md
  git add docs/readme.md
  git commit -q -m "seed"

  if no_upstream_output="$(script -q -e -c "cd '$no_upstream_repo' && bash '$repo_root/.githooks/pre-push'" /dev/null 2>&1)"; then
    echo "Expected manual pre-push invocation without upstream to fail" >&2
    exit 1
  fi
  no_upstream_output="${no_upstream_output//$'\r'/}"
  grep -Fq "no upstream configured" <<<"$no_upstream_output"
  grep -Fq "git push -u origin" <<<"$no_upstream_output"

  cd "$work_repo"
fi

mkdir -p tests/godot
printf '%s\n' 'extends GdUnitTestSuite' > tests/godot/player_behavior_test.gd
printf '%s\n' 'print("player updated again")' >> scenes/player/player.gd
git add scenes/player/player.gd tests/godot/player_behavior_test.gd
git commit -q -m "add gameplay + test together"

output_with_tests="$(git push origin HEAD:main 2>&1)"
grep -Fq "Lint checks: no lintable files detected." <<<"$output_with_tests"
grep -Fq "segment coverage check" <<<"$output_with_tests"
grep -Fq "Gameplay changes detected with test files present." <<<"$output_with_tests"
if grep -Fq "WARNING: gameplay files changed but no test files were included." <<<"$output_with_tests"; then
  echo "Expected no coverage warning when test files are present" >&2
  exit 1
fi

rm tests/godot/player_behavior_test.gd
printf '%s\n' 'print("player updated after deleting test")' >> scenes/player/player.gd
git add scenes/player/player.gd tests/godot/player_behavior_test.gd
git commit -q -m "delete gameplay test while changing gameplay"

output_with_deleted_test="$(git push origin HEAD:main 2>&1)"
grep -Fq "segment coverage check" <<<"$output_with_deleted_test"
grep -Fq "WARNING: gameplay files changed but no test files were included." <<<"$output_with_deleted_test"

printf '%s\n' '{"ok": true}' > metadata.json
git add metadata.json
git commit -q -m "add lintable json"

output_with_lintable="$(git push origin HEAD:main 2>&1)"
grep -Fq "Lint checks passed for 1 lintable file(s)." <<<"$output_with_lintable"

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
grep -Eq "invalid syntax|never closed|expected" <<<"$output"
