# Balance values (US-16 / #83)

`US-16` keeps one useful piece of the older balancing pass: runtime pacing and
boost knobs should live in one config resource instead of being duplicated
across controllers. Those values now live in
`scripts/balance/default_balance.tres` and are exposed through the `Balance`
autoload as `Balance.config.*`.

This centralization is intentionally limited to values that are actually read by
runtime controllers. It does not replace scene-authored collectable scores or
chunk spawn buffers, which stay owned by their existing gameplay/level data.

## Runtime values

| Parameter | Value | Read by |
|---|---|---|
| `default_scroll_speed` | `220.0` | `run_session_controller.gd`, `run_pacing_controller.gd` |
| `mid_scroll_speed` | `235.0` | `run_pacing_controller.gd` |
| `transition_scroll_speed` | `255.0` | `run_pacing_controller.gd` |
| `late_scroll_speed` | `270.0` | `run_pacing_controller.gd` |
| `mid_score_threshold` | `8000` | `run_pacing_controller.gd` |
| `transition_score` | `20000` | `run_pacing_controller.gd`, `scenario_transition_controller.gd` |
| `late_score_threshold` | `32000` | `run_pacing_controller.gd` |
| `speed_up_threshold` | `3` | `speed_up_boost_controller.gd` |
| `speed_up_boost_duration` | `8.0` | `speed_up_boost_controller.gd` |
| `speed_up_timer_multiplier` | `1.25` | `speed_up_boost_controller.gd` |
| `speed_up_multipliers` | `[1.0, 1.35, 1.6]` | `speed_up_boost_controller.gd`, `run_session_controller.gd` |
| `speed_down_threshold` | `3` | `speed_down_boost_controller.gd` |
| `speed_down_multipliers` | `[1.0, 0.85, 0.7]` | `speed_down_boost_controller.gd`, `run_session_controller.gd` |
| `base_score_per_meter` | `10.0` | `run_score_controller.gd` |
| `score_distance_divisor` | `10.0` | `run_score_controller.gd` |

## Explicit non-goals

- Collectable `score_value` remains authored in each collectable `.tscn`.
- Chunk spawn and recycle buffers remain in `chunk_manager.gd`.
- `US-16` does not redefine scenario patterns or chunk distribution.

That split is deliberate: it keeps this PR aligned with the later pacing and
scenario decisions instead of creating a second, conflicting source of truth.

## Rationale

- Opening speed starts at `220.0` to make the first seconds less abrupt.
- The base pace ramps at `8000`, `20000`, and `32000` score so the run gains
  pressure gradually instead of jumping straight to the old faster baseline.
- Speed-up tiers use `[1.0, 1.35, 1.6]` and keep the `8.0s` duration, matching
  the later approved pacing curve instead of the harsher intermediate retune.
- Speed-down tiers use `[1.0, 0.85, 0.7]`, softening the slowdown penalty
  without removing the failure state.
- `transition_score` stays at `20000` and doubles as the scenario swap trigger
  and the third pacing band threshold, keeping those systems aligned.

## Adding a new tunable

1. Add the `@export` field to `scripts/balance/balance_config.gd`.
2. Set the default in `scripts/balance/default_balance.tres`.
3. Read it from `Balance.config.<field>` in the controller that owns the
   behavior.
4. Do not add mirror values in unrelated scenes or controllers unless that data
   is intentionally scene-authored.
