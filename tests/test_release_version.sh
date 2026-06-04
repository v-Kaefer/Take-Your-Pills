#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/release-version.yml"
preset="export_presets.cfg"

for path in "$workflow" "$preset"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "plan-release:" "$workflow"
grep -Fq "publish-release:" "$workflow"
grep -Fq "contents: read" "$workflow"
grep -Fq "contents: write" "$workflow"
grep -Fq "issues: write" "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ github.token }}' "$workflow"
grep -Fq 'GH_TOKEN: ${{ github.token }}' "$workflow"

if grep -Fq 'secrets.GOVERNANCE_PAT' "$workflow"; then
  echo "Release workflow must use the built-in Actions token, not GOVERNANCE_PAT." >&2
  exit 1
fi

if grep -Fq 'Validate release version before merge' "$workflow" && grep -A5 -F 'Validate release version before merge' "$workflow" | grep -Fq 'GITHUB_TOKEN:'; then
  echo "Release dry-run validation should not inject a token." >&2
  exit 1
fi

grep -Fq "chickensoft-games/setup-godot@v2" "$workflow"
grep -Fq "include-templates: true" "$workflow"
grep -Fq 'godot --headless --path . \' "$workflow"
grep -Fq -- '--export-release "Windows Desktop" \' "$workflow"
grep -Fq -- 'build/release/take-your-pills-windows.exe' "$workflow"
grep -Fq -- '--export-release "Linux/X11" \' "$workflow"
grep -Fq -- 'build/release/take-your-pills-linux.x86_64' "$workflow"
grep -Fq -- '--export-pack "Linux/X11" \' "$workflow"
grep -Fq -- 'build/release/take-your-pills-godot.zip' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-windows.exe' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-linux.x86_64' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-godot.zip' "$workflow"

grep -Fq 'name="Windows Desktop"' "$preset"
grep -Fq 'name="Linux/X11"' "$preset"
grep -Fq 'export_path="build/release/take-your-pills-windows.exe"' "$preset"
grep -Fq 'export_path="build/release/take-your-pills-linux.x86_64"' "$preset"

echo "Release version workflow contract OK"
