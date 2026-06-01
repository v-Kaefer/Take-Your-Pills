#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/release-version.yml"
preset="export_presets.cfg"
template=".github/pull_request_template.md"

for path in "$workflow" "$preset" "$template"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "plan-release:" "$workflow"
grep -Fq "publish-release:" "$workflow"
grep -Fq "contents: read" "$workflow"
grep -Fq "contents: write" "$workflow"
grep -Fq "issues: write" "$workflow"
grep -Fq 'GITHUB_TOKEN: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"
grep -Fq 'GH_TOKEN: ${{ secrets.GOVERNANCE_PAT }}' "$workflow"

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
grep -Fq "## Release version" "$template"
grep -Fq "## Related develop PRs" "$template"
grep -Fq "For \`develop -> main\` PRs" "$template"
grep -Fq "write \`N/A\`" "$template"

echo "Release version workflow contract OK"
