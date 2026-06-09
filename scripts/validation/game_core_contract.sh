#!/usr/bin/env bash
set -euo pipefail

game_script="scenes/game/game.gd"
game_scene="scenes/game/game.tscn"

for path in "$game_script" "$game_scene"; do
  [[ -f "$path" ]] || { echo "Missing required file: $path" >&2; exit 1; }
done

grep -Fq 'Controllers' "$game_scene"
grep -Fq '[node name="RunSessionController" type="Node" parent="Controllers"]' "$game_scene"
grep -Fq '[node name="RunScoreController" type="Node" parent="Controllers"]' "$game_scene"
grep -Fq '[node name="CollectableAudioController" type="Node" parent="Controllers"]' "$game_scene"

grep -Eq '^var current_state: .*:$' "$game_script"
grep -Eq '^var score: .*:$' "$game_script"
grep -Eq '^var distance: .*:$' "$game_script"

for banned in \
  'RunSignals.' \
  'collectable_type' \
  'collect_sfx_player.play' \
  'score_accumulator' \
  'bonus_score' \
  'current_scenario_multiplier' \
  'current_speed_multiplier' \
  'hud.update_state' \
  'hud.update_score' \
  'hud.update_distance' \
  'hud.show_main_menu' \
  'hud.show_pause_menu' \
  'hud.show_game_over' \
  'chunks.start_run' \
  'chunks.pause_run' \
  'chunks.end_run' \
  'chunks.set_scroll_speed' \
  'player.start_run' \
  'player.pause_run' \
  'player.end_run'
do
  if grep -Fq "$banned" "$game_script"; then
    echo "game.gd contract violation: found '$banned'" >&2
    exit 1
  fi
done

echo "Game core contract OK"
