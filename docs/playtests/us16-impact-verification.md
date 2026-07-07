# US-16 Impact Verification

- Generated: 2026-07-06 23:54 UTC
- Engine: `4.7.stable.arch_linux.5b4e0cb0f`
- Compared refs:
  - `baseline_pre_us16` -> `cc38aca` (`cc38aca`)
  - `initial_us16_retune` -> `fa5493c` (`fa5493c`)
  - `current_us16` -> `HEAD` (`9a1d96f`)
- Method: headless Godot probe run against each ref through `scripts/validation/us16_impact_compare.py`.

## Mechanics and pacing

| Metric | Baseline | Initial retune | Current | Current vs baseline | Current vs retune | Reading |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Opening scroll speed | 240 | 240 | 220 | -8.3% | -8.3% | Lower is calmer in the opening seconds. |
| Time to mid band | 33.333 | 33.333 | 36.367 | +9.1% | +9.1% | Higher means the first readable phase lasts longer. |
| Time to transition score | 83.333 | 83.333 | 87.433 | +4.9% | +4.9% | Higher delays the scenario swap and keeps the opening calmer. |
| Tier-1 speed-up effective speed | 360 | 336 | 297 | -17.5% | -11.6% | Lower reduces the first post-pickup spike. |
| Tier-2 speed-up effective speed | 480 | 432 | 352 | -26.7% | -18.5% | Lower reduces the harshest boost spike. |
| Tier-1 slowdown effective speed | 180 | 192 | 187 | +3.9% | -2.6% | Higher is less punitive after one slowdown stack. |
| Tier-2 slowdown effective speed | 120 | 144 | 154 | +28.3% | +6.9% | Higher is less punitive after two slowdown stacks. |
| Single pill score delta | 100 | 120 | 100 | 0.0% | -16.7% | Lower reduces score inflation from common pickups. |

## Key observations

- The current branch materially calms the opening by dropping the base scroll speed and by delaying the score-band ramp compared with both earlier states.
- The final speed-up spikes are the softest of the three revisions, which directly improves readability after stacking the red-orange collectables.
- The slowdown path stays failure-compatible but is less punishing than the baseline at the second stack, so recovery remains possible for longer.
- Pill scoring is back to `100`, undoing the inflated `120` value from the first retune and reducing score inflation on common pickups.
- The added pacing logic is measurable in isolated synthetic benchmarks, but its absolute controller-path cost still stays in the single-digit microsecond range on this machine.

## Performance

| Benchmark | Baseline | Initial retune | Current | Current vs baseline | Current vs retune |
| --- | ---: | ---: | ---: | ---: | ---: |
| Score signal burst median (`us/emit`) | 3.487 | 3.394 | 4.866 | +39.5% | +43.4% |
| Score tick loop median (`us/frame`) | 4.437 | 4.36 | 5.85 | +31.8% | +34.2% |

These benchmark numbers were confirmed manually in isolated warmed worktrees for `cc38aca`, `fa5493c`, and `9a1d96f`, all with a dedicated `HOME`/`user://` directory per ref. They show a real controller-path regression in the current branch, but the absolute cost still remains in the single-digit microsecond range and is unlikely to be user-visible on its own.

## Raw samples

- `score_signal_burst` current samples: `[4.866, 4.909, 4.866, 4.865, 4.874, 4.88, 4.865]`
- `score_tick_loop` current samples: `[5.951, 5.84, 5.85, 6.009, 5.888, 5.831, 5.828]`
