#!/usr/bin/env bash
set -euo pipefail

required=(
  ".github/workflows/godot-smoke.yml"
  ".github/workflows/game-tests.yml"
  "tests/godot/player_behavior_test.gd"
  "tests/godot/obstacle_behavior_test.gd"
  "tests/godot/chunk_manager_behavior_test.gd"
  "tests/godot/game_flow_test.gd"
)

for path in "${required[@]}"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq "version: 4.6.2" .github/workflows/godot-smoke.yml
grep -Fq -- '--quit --log-file /tmp/godot-smoke.log' .github/workflows/godot-smoke.yml

grep -Fq "godot-gdunit-labs/gdUnit4-action@v1.3.1" .github/workflows/game-tests.yml
grep -Fq "godot-version: '4.6.2'" .github/workflows/game-tests.yml
grep -Fq "version: 'v6.1.3'" .github/workflows/game-tests.yml
grep -Fq "paths: 'res://tests/godot'" .github/workflows/game-tests.yml
grep -Fq "warnings-as-errors: true" .github/workflows/game-tests.yml

grep -Fq "extends GdUnitTestSuite" tests/godot/player_behavior_test.gd
grep -Fq "test_player_jump_requests_follow_state_transitions" tests/godot/player_behavior_test.gd
grep -Fq "test_obstacle_emits_player_hit_only_once_for_player_bodies" tests/godot/obstacle_behavior_test.gd
grep -Fq "test_chunk_manager_spawns_buffer_and_recycles_offscreen_chunks" tests/godot/chunk_manager_behavior_test.gd
grep -Fq "test_game_boot_pause_game_over_and_restart_prompt" tests/godot/game_flow_test.gd

echo "Godot game CI contract OK"
