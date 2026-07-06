# Playtest 02 Regression Checklist

Run this after applying the critical fixes raised by Playtest 02.

## Core loop
- [ ] Game boots to the main menu without visual corruption.
- [ ] Space starts the run from the menu.
- [ ] Space jumps while running.
- [ ] Esc pauses and resumes correctly.
- [ ] Space restarts from game over.

## Gameplay systems
- [ ] Score increments during the run.
- [ ] Distance increments during the run.
- [ ] Speed-up collectables fill the correct HUD bar.
- [ ] Speed-down collectables fill the correct HUD bar.
- [ ] Boost activation resets the speed-up bar and shows the timer.
- [ ] Slowdown state remains readable and does not desync the HUD.
- [ ] Obstacle collision ends the run exactly once.

## Level flow
- [ ] Opening run pacing is readable and not immediately punishing.
- [ ] Spawn distribution still creates usable risk/reward choices.
- [ ] Scenario progression, if present in the build, preserves run state.
- [ ] Platforms or floor changes do not create invisible collisions.

## Presentation
- [ ] Visible game area uses the full intended screen space.
- [ ] Main gameplay elements remain readable at speed.
- [ ] Score, boost, and slowdown information remain readable while speed changes.
- [ ] Color transitions do not cause distracting ghosting or visual fatigue over repeated runs.
- [ ] Highscore flow, if present in the build, still works after playtest fixes.

## Evidence
- [ ] Final regression result recorded.
- [ ] Remaining known issues documented with owner or follow-up issue.
