# Take Your Pills — Project Definitions

> Consolidated reference from initial planning documents.
> Superseded by the live backlog manifest (`config/stories/backlog-manifest.json`) for issue generation,
> and by milestones in `config/project/milestones.json`. This document serves as design rationale.

---

## Academic Timeline

| Milestone | Date |
|---|---|
| Part 1 — Pitch / GDD | 06/04/2026 |
| Part 2 — Checkpoint 1 | 13/05/2026 |
| Part 2 — Checkpoint 2 | 20/05/2026 |
| Part 2 — Delivery | 01–03/06/2026 |
| Part 3 — Checkpoint | 22/06/2026 |
| Part 3 — Final delivery | 06–08/07/2026 |

Development window: **08/04/2026 → 08/07/2026**

---

## MVP Scope

### Included
- Infinite runner loop
- Local ranking
- 4 collectibles (points, special, accelerate, decelerate)
- Velocity state machine (slow / normal / fast)
- 3 scenario contexts: laboratory → streets → house → streets
- 2D stylised visuals
- Playable and presentable build

### Excluded from this phase
- Online ranking
- Shop / upgrades
- Expanded narrative
- Persistent progress beyond local ranking
- Bosses, combat, inventory, or complex sub-modes

---

## Game Loop

### Macro
1. Player starts in **laboratory** (0.5× multiplier, predictable obstacles, onboarding)
2. Transition to **streets** (1.0×, main loop, highest time spent)
3. Temporary **house** event (2.0×, time-limited, high risk / high reward)
4. Return to **streets** → repeat until death

### Micro
run → dodge → collect → change velocity state → survive extreme speed → accumulate score → die → record score → fast restart

---

## Scoring System

```
Final score = Base collectible value × Scenario multiplier × Velocity multiplier
```

| Scenario | Multiplier |
|---|---|
| Laboratory | 0.5× |
| Streets | 1.0× |
| House | 2.0× |

| Velocity state | Multiplier |
|---|---|
| Super Slow | 0.5× |
| Slow | 0.75× |
| Normal | 1.0× |
| Fast | 1.5× |
| Super Fast | 2.0× |

---

## Velocity State Machine

- Every 3 accelerating collectibles → advance 1 state
- Every 3 decelerating collectibles → drop 1 state
- Exceeding upper limit → death (fall / injury)
- Exceeding lower limit → death (drowsiness / falling asleep)
- Must be implemented as a **state machine**, not a raw speed value

Required feedback: HUD state indicator, short sound on state change, subtle visual transition, clear warning at extreme state.

---

## Collectibles

| ID | Type |
|---|---|
| A | Common score |
| B | Special / rare score |
| C | Acceleration |
| D | Deceleration |

Collectibles must be data-driven: identifier, base value, type, sprite, applied effect, spawn weight.

---

## Godot Technical Structure

### Recommended scenes
`Main`, `Game`, `Player`, `HUD`, `MainMenu`, `GameOverMenu`, `LocalRankingMenu`,
`ObstacleBase`, `CollectableBase`, `Spawner`, `ScenarioController`, `ScenarioTransitionTrigger`, `HouseSessionController`

### Autoloads
`GameSession`, `SaveManager`, `AudioManager`

### Data resources
`CollectableData`, `ScenarioData`, `SpeedStateConfig`, `SpawnTable`

---

## Team Model

- 4 members participate in all phases
- Every issue: 1 primary owner + 1 shadow owner
- Shadow takes over if primary stalls for more than 2 working days
- All in-progress branches must be pushed remotely
- Every stalled task requires a written handoff

### Responsibility areas (primary focus, not rigid ownership)
| Person | Area |
|---|---|
| A — Core | Player, jump, collision, death, game feel |
| B — Systems | Score, velocity, counters, scenario rules, spawn tables |
| C — UI / flow | HUD, menus, local ranking, pause, restart |
| D — Integration | Audio, effects, scene integration, build, manual QA |

---

## Internal Development Schedule

| Phase | Dates | Goal |
|---|---|---|
| A — Technical foundation | 16/04–29/04 | First playable loop: run, jump, collision, death, restart, HUD, score |
| B — MVP for Part 2 checkpoint | 30/04–13/05 | 4 collectibles, velocity system, laboratory + streets functional |
| C — Complete MVP for Part 2 | 14/05–03/06 | House, local ranking, menus, full game flow, stable build |
| D — Playtesting & structural review | 08/06–17/06 | Manual test checklist, bug prioritisation, rhythm/UX adjustments |
| E — Refinement for Part 3 | 18/06–22/06 | Critical bug fixes, UX improvement, scoring clarity |
| F — Final delivery | 23/06–08/07 | Final polish, audio-visual review, final build, presentation material |

---

## Testing Strategy

### Automated (GdUnit4)
- Velocity state transitions
- Collectible counting
- Score calculation and multiplier rules
- Local ranking sort and persistence
- House entry / exit and duration timer

### Mandatory manual checklist (per build)
- Running is smooth
- Jump responds correctly
- Collision feels fair
- Player understands why they died
- HUD communicates velocity state clearly
- Score changes correctly per scenario and velocity
- Laboratory → streets transition works
- House enters and exits correctly
- Local ranking saves and loads
- Restart always works

---

## Definition of Done

An issue can only be closed when:
- Feature works in-game
- Merged into `develop`
- Manually tested
- Does not break the main flow
- Reviewed by at least one other person

---

## Main Risks

| Risk | Mitigation |
|---|---|
| Scope creep | Keep focus on defined MVP; no online, shop, or expanded narrative |
| Long branches / merge conflicts | Short branches, frequent pushes, early integration into `develop` |
| Velocity system confusion | Clear HUD, audio-visual feedback, specific score/state tests |
| House becoming a complex sub-game | Treat as a timed event; reuse main loop mechanics |
| Dependency on one person | Shadow owner, mandatory handoff, always-published branch |

---

## Priority Directive

> When in doubt between adding a new feature or improving the clarity of the main loop,
> default to: **prioritise control, readability, stability, and a complete MVP flow.**

Project is successful if it delivers: playable game without critical crashes · understandable velocity system · coherent score · full lab → streets → house → streets flow · functional local ranking · sufficient polish for the final Part 3 presentation.
