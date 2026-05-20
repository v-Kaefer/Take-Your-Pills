#!/usr/bin/env bash
set -euo pipefail

workflow=".github/workflows/release-version.yml"
preset="export_presets.cfg"

for path in "$workflow" "$preset"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "chickensoft-games/setup-godot@v2" "$workflow"
grep -Fq "include-templates: true" "$workflow"
grep -Fq 'godot --headless --path . --export-release "Windows Desktop" build/release/take-your-pills-windows.exe' "$workflow"
grep -Fq 'godot --headless --path . --export-release "Linux/X11" build/release/take-your-pills-linux.x86_64' "$workflow"
grep -Fq 'godot --headless --path . --export-pack "Linux/X11" build/release/take-your-pills-godot.zip' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-windows.exe' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-linux.x86_64' "$workflow"
grep -Fq -- '--asset build/release/take-your-pills-godot.zip' "$workflow"

grep -Fq 'name="Windows Desktop"' "$preset"
grep -Fq 'name="Linux/X11"' "$preset"
grep -Fq 'export_path="build/release/take-your-pills-windows.exe"' "$preset"
grep -Fq 'export_path="build/release/take-your-pills-linux.x86_64"' "$preset"

echo "Release version workflow contract OK"
