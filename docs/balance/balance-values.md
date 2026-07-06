# Balance values (US-16 / #83)

All gameplay pacing/economy numbers used to live scattered across `const`/`@export`
fields in ~6 different scripts and `.tscn` scenes. They are now centralized in
`scripts/balance/balance_config.gd` (a typed `Resource`), instanced as
`scripts/balance/default_balance.tres`, and exposed at runtime through the
`Balance` autoload (`scripts/balance_manager.gd`) as `Balance.config.*`.

Editing gameplay balance no longer requires touching GDScript: open
`default_balance.tres` in the Godot Inspector and adjust the exported fields.

## Values (old → new)

| Parameter | Old | New | Read by |
|---|---|---|---|
| `default_scroll_speed` | 240.0 | 240.0 (unchanged) | `game.gd`, `run_session_controller.gd` |
| `speed_up_threshold` | 3 | 3 (unchanged) | `speed_up_boost_controller.gd` |
| `speed_up_boost_duration` | 8.0 | **6.0** | `speed_up_boost_controller.gd` |
| `speed_up_timer_multiplier` | 1.25 | 1.25 (unchanged) | `speed_up_boost_controller.gd` |
| `speed_up_multipliers` | `[1.0, 1.5, 2.0]` | **`[1.0, 1.4, 1.8]`** | `speed_up_boost_controller.gd` |
| `speed_down_threshold` | 3 | 3 (unchanged) | `speed_down_boost_controller.gd` |
| `speed_down_multipliers` | `[1.0, 0.75, 0.5]` | **`[1.0, 0.8, 0.6]`** | `speed_down_boost_controller.gd` |
| `base_score_per_meter` | 10.0 | 10.0 (unchanged) | `run_score_controller.gd` |
| `score_distance_divisor` | 10.0 | 10.0 (unchanged) | `run_score_controller.gd` |
| `score_box` | 250 | 250 (unchanged) | `box_collectable.tscn` (documented source of truth) |
| `score_pill` | 100 | **120** | `pill_collectable.tscn` (documented source of truth) |
| `score_speed_up` | 50 | 50 (unchanged) | `speed_up_collectable.tscn` (documented source of truth) |
| `score_speed_down` | 0 | 0 (unchanged) | `speed_down_collectable.tscn` (documented source of truth) |
| `transition_score` | 20000 | 20000 (unchanged, deliberate) | `scenario_transition_controller.gd` |
| `spawn_buffer_px` | 256.0 | **320.0** | `chunk_manager.gd` |
| `recycle_buffer_px` | 128.0 | 128.0 (unchanged) | `chunk_manager.gd` |
| `chunk_overlap_px` | 32.0 | 32.0 (unchanged) | `chunk_manager.gd` |

Collectable `score_value` fields remain per-instance overrides authored in each
`.tscn` (legitimate per-scene data). The matching `score_*` fields in
`BalanceConfig` are the documented source of truth for those numbers and must
be kept in sync by hand whenever a collectable's value is retuned.

## Rationale (mapped to backlog tasks T-16.1..T-16.4)

- **T-16.1 (obstacle spawn balance)**: raised `spawn_buffer_px` 256→320 to give
  the player more forward visibility/reaction time before an obstacle enters
  the screen, without touching hand-authored chunk content or the round-robin
  chunk selection (both out of scope for this pass).
- **T-16.2 (item spawn / economy balance)**: `score_pill` 100→120, a small bump
  to keep the base pickup relevant against the unchanged `transition_score`.
  `score_box`/`score_speed_up`/`score_speed_down` kept as-is.
- **T-16.3 (boost/slowdown cost/effect balance)**: Playtest 2 (PT2-01) reported
  that players lose orientation as speed increases — the 2.0x top speed-up
  tier was the likely culprit. Softened to `[1.0, 1.4, 1.8]` and shortened the
  base `BOOST_DURATION` (8.0→6.0s) so a single pickup burst is calmer by
  default, while stacking (`speed_up_timer_multiplier=1.25`) still rewards
  repeated collection. Slowdown's bottom tier (adjacent to the fail state) was
  softened `0.5→0.6` to make the "almost dead" speed less jarring.
- **T-16.4 (adverse-state frequency/impact)**: impact addressed by the 0.6
  slowdown floor above. Frequency is otherwise a function of speed-down pickup
  density in hand-authored chunks (out of scope) and `speed_down_threshold`
  (kept at 3). If manual playtesting shows the fail state still triggers too
  eagerly, raising `speed_down_threshold` to 4 is the next safe knob — left
  as a follow-up rather than applied speculatively.
- **`transition_score`**: kept at 20000 — no Playtest 2 finding points at
  transition timing itself as a problem, so it wasn't touched this pass.

These are starting points to validate against
`docs/playtests/playtest-02-regression-checklist.md` in a manual playtest
pass, not final numbers.

## Adding a new tunable

1. Add the `@export` field to `scripts/balance/balance_config.gd` (pick the
   right `@export_group`).
2. Set its value on `scripts/balance/default_balance.tres` (or via the Godot
   Inspector).
3. Read it from `Balance.config.<field>` at `_ready()` in the consuming
   script — cache it into a local var if it's read every frame/tick.
