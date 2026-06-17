# Take Your Pills — AI Coding Guide

This file is read by OpenAI Codex, GitHub Copilot coding agent, and any AI tool the
team points at for context. Read it **before** making any change to the game code.

---

## Architecture overview

The game uses a **signal bus** (`scripts/run_signals.gd`) as the only communication
channel between systems. Nodes emit signals; other nodes subscribe.
**Direct node references across systems are forbidden** outside the composition root
(`scenes/game/game.gd`) — use signals instead.

```
RunSignals (autoload singleton)
    ├── collectable_collected(collectable, body, score_value)  ← CollectableBase
    ├── run_booted                                              ← RunSessionController
    ├── run_running                                             ← RunSessionController
    ├── run_paused                                              ← RunSessionController
    ├── run_game_over                                           ← RunSessionController
    ├── score_changed(score)                                    ← RunScoreController
    ├── distance_changed(distance)                              ← RunScoreController
    ├── speed_up_collected()                                   ← SpeedUpCollectable
    ├── speed_down_collected()                                 ← SpeedDownCollectable
    ├── speed_state_changed(level, threshold, boost_active)    ← AdverseStateController
    ├── speed_too_slow()                                       ← AdverseStateController
    ├── player_hit_obstacle(obstacle, body)                    ← obstacle scene
    ├── request_next_chunk(chunk)                              ← chunk logic
    └── chunk_exited_screen(chunk)                             ← chunk logic
```

---

## Node responsibilities (Single Responsibility Principle)

| Script | Owns | Must NOT touch |
|---|---|---|
| `scenes/game/game.gd` | Composition root: wires controllers, routes input, restarts the scene | Score math, HUD text/layout, collectable side effects, speed logic |
| `scenes/game/controllers/run_session_controller.gd` | Run state machine (MENU / RUNNING / PAUSED / GAME_OVER), player/chunk run transitions | Score math, HUD layout, collectable logic |
| `scenes/game/controllers/run_score_controller.gd` | Score and distance accumulation, collectable reward handling | Run state, HUD layout, speed logic |
| `scenes/game/controllers/adverse_state_controller.gd` | Speed-up / speed-down counter, threshold trigger, boost timer, slow-to-zero failure, scroll speed changes | Score, HUD, player physics |
| `scenes/game/controllers/collectable_audio_controller.gd` | Collectable sound effect playback | Score, HUD, speed logic |
| `scenes/game/hud.gd` | Display only — subscribes to RunSignals, updates labels and icons | Game state, physics, collectable logic |
| `scenes/game/collectables/collectable_base.gd` | Area2D collision → emit `collectable_collected` | Game state, HUD, speed |
| `scenes/game/chunk_manager.gd` | Chunk spawning and infinite scrolling | Game state, score, HUD |
| `scenes/player/player.gd` | Player physics, jump, run states | Score, HUD, collectables |

---

## How to add a new collectable type

1. Create `scenes/game/collectables/<name>_collectable.gd` extending `CollectableBase`.
2. If the collectable has a side effect (speed change, power-up, etc.), add a new signal
   to `scripts/run_signals.gd` and emit it **before** calling `super._on_body_entered(body)`.
3. Create `<name>_collectable.tscn`:
   - Script: the new `.gd` file (not `collectable_base.gd`)
   - Visual: a `Polygon2D` square with a **distinct color** — do **not** replace the
     colored-square with a sprite/PNG icon. Icons belong in the HUD only.
4. Create a dedicated controller (extending `Node`) that subscribes to the new signal
   and handles the side effect. **Never handle collectable types inside `game.gd`.**
5. Add instances to chunk scenes (`chunk_a/b/c.tscn`). When editing a `.tscn`:
   - Update `load_steps` = `[ext_resource]` count + `[sub_resource]` count + 1
   - Declare parent nodes before their children

### How to add a new gameplay controller

1. Create `scenes/game/controllers/<name>_controller.gd` extending `Node`.
2. Make it listen to `RunSignals` and keep its own state; do not let `game.gd`
   own that feature's variables.
3. Add the controller node under `Controllers` in `scenes/game/game.tscn`.
4. Wire its exported/runtime references once from `game.gd._ready()`.
5. Add or extend tests that exercise the controller through the scene.

---

## How to add new HUD elements

1. Add nodes to `scenes/game/hud.tscn` (parent before children, no `uid=` lines).
2. Add `@onready` vars in `hud.gd` pointing to the new nodes by their scene path.
3. Subscribe to a `RunSignals` signal in `hud.gd._ready()` to update the element.
4. **Do not call new HUD update methods from `game.gd`.** The HUD drives itself from signals.

---

## Critical rules — never violate

### Textures and assets

```gdscript
# WRONG — preload() runs at parse time; if the asset lacks a .ctex import entry
# the entire script fails to compile, making the game unbootable.
const ICON := preload("res://assets/icon/some_icon.png")

# CORRECT — load() runs at runtime; script compiles even without import metadata.
var _icon: Texture2D = null
func _ready() -> void:
    _icon = load("res://assets/icon/some_icon.png") as Texture2D
```

Always null-check before using a loaded texture: `if _icon != null: node.texture = _icon`.

### Scene files (.tscn)

- `load_steps` must be accurate: `[ext_resource]` count + `[sub_resource]` count + 1.
- Declare every parent node before its children.
- Do not manually write `uid=` values — let the Godot editor manage UIDs.

### game.gd

- Do **not** add new instance variables for game mechanics here.
- Do **not** read `collectable.collectable_type` inside `game.gd`.
- Do **not** mutate HUD state, player run state, chunk speed, or score directly here.
- Create a dedicated `*_controller.gd` node instead and inject it in `_ready()`.
- After **any** change to `game.gd`, run the smoke-test checklist below.

### Signals

- All cross-system signals live in `scripts/run_signals.gd`.
- Emit data in signals (`count`, `active`), not node references where possible.

---

## Smoke-test checklist

Run this after every change to any game scene or script:

- [ ] Game boots to main menu (no black screen, no errors in console)
- [ ] **Spacebar starts the run** from the main menu
- [ ] **Spacebar jumps** while running
- [ ] **Spacebar restarts** from the game-over screen
- [ ] Collecting 3 red-orange squares: HUD stripes turn blue one-by-one, then all red + speed increases
- [ ] After 8 seconds: speed returns to normal, stripes reset to grey
- [ ] Hitting an obstacle ends the run and shows the game-over screen
- [ ] Score and distance increment during the run
- [ ] Pause (Esc) and resume work correctly

If any item fails, **do not open a PR**. Fix the regression first.
