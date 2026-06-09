#!/usr/bin/env bash
set -euo pipefail

required=(
  ".github/workflows/godot-smoke.yml"
  ".github/workflows/game-tests.yml"
  "scripts/validation/game_core_contract.sh"
  "tests/godot/player_behavior_test.gd"
  "tests/godot/obstacle_behavior_test.gd"
  "tests/godot/chunk_manager_behavior_test.gd"
  "tests/godot/game_flow_test.gd"
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "chickensoft-games/setup-godot@v2" .github/workflows/godot-smoke.yml
grep -Eq "version:[[:space:]]*['\"]?4[.]6[.]2['\"]?$" .github/workflows/godot-smoke.yml
if grep -Fq "firebelley/setup-godot" .github/workflows/godot-smoke.yml; then
  echo "Godot smoke workflow must not use the unavailable firebelley setup action." >&2
  exit 1
fi
grep -Fq "./scripts/validation/game_core_contract.sh" .github/workflows/godot-smoke.yml
grep -Fq 'if [ -f project.godot ]; then' .github/workflows/godot-smoke.yml
grep -Fq 'godot --version || true' .github/workflows/godot-smoke.yml
grep -Fq 'godot --headless --quit' .github/workflows/godot-smoke.yml
grep -Fq 'Skipping smoke check: project.godot not found yet.' .github/workflows/godot-smoke.yml

grep -Fq "godot-gdunit-labs/gdUnit4-action@v1.3.1" .github/workflows/game-tests.yml
grep -Eq "godot-version:[[:space:]]*['\"]?4[.]6[.]2['\"]?$" .github/workflows/game-tests.yml
grep -Eq "version:[[:space:]]*['\"]?v6[.]1[.]3['\"]?$" .github/workflows/game-tests.yml
grep -Eq "paths:[[:space:]]*['\"]?res://tests/godot['\"]?$" .github/workflows/game-tests.yml
grep -Fq "warnings-as-errors: true" .github/workflows/game-tests.yml
grep -Fq "checks: write" .github/workflows/game-tests.yml

grep -Fq "extends GdUnitTestSuite" tests/godot/player_behavior_test.gd
grep -Fq "test_player_jump_requests_follow_state_transitions" tests/godot/player_behavior_test.gd
grep -Fq "test_obstacle_emits_player_hit_only_once_for_player_bodies" tests/godot/obstacle_behavior_test.gd
grep -Fq "test_chunk_manager_spawns_buffer_and_recycles_offscreen_chunks" tests/godot/chunk_manager_behavior_test.gd
grep -Fq "test_game_boots_in_main_menu_state" tests/godot/game_flow_test.gd
grep -Fq "test_start_transitions_to_running_state" tests/godot/game_flow_test.gd
grep -Fq "test_collectable_score_persists_after_next_frame" tests/godot/game_flow_test.gd

echo "Godot game CI contract OK"
