# Playtest 02 Runbook

## Objective
Run Playtest 02 only after the MS3/MS4 gameplay fixes are available in the build under test.

## Entry criteria
- The build includes the intended MS3/MS4 fixes for screen usage, boosts, scenario flow, spawn, platforms, and highscore.
- The core smoke checklist passes:
  - game boots to main menu
  - space starts the run
  - space jumps during the run
  - space restarts from game over
  - boost and slowdown bars react to collectables
  - obstacle collision ends the run
  - score and distance update during the run
  - pause and resume work
- The build identifier, branch, commit, and test date are recorded.
- One facilitator and one note-taker are assigned.

## Build identification
Fill this before the session starts.

| Field | Value |
| --- | --- |
| Build date |  |
| Branch |  |
| Commit |  |
| Export target |  |
| Facilitator |  |
| Note-taker |  |

## Session flow
1. Prepare the test machine, controls, and capture method.
2. Ask the player to complete a blind first run.
3. Ask for two more runs after the first impression notes are captured.
4. Record visible friction during menu, early run, scenario transition, boost use, and game over.
5. Close with the question set below and save the evidence links.

## Live checklist
Mark each item during the session.

| Area | Check |
| --- | --- |
| Visual | The game uses the full visible area without a black band. |
| Visual | Laboratory and later-run scenario are clearly distinguishable. |
| Visual | Obstacles, pills, boosts, score items, and platforms remain readable at speed. |
| Controls | The player understands start, jump, pause, and restart without explanation. |
| Boosts | Speed-up and slow-down feedback is understandable during play. |
| Difficulty | The opening run feels fair and readable. |
| Difficulty | Mid-run pacing remains understandable after the first minute. |
| Progression | Scenario transition, if reached, does not look like a reset or bug. |
| Highscore | The player notices the record flow and can enter a name if a record is set. |
| Stability | No soft lock, invisible collision, or obvious reset bug happens. |

## Moderator questions
Use these after the runs.

1. What was the first thing that felt confusing?
2. Was the opening speed fair?
3. Could you tell the difference between score item, boost, and hazard?
4. Did the boost or slowdown state feel readable?
5. Did the environment change feel clear and meaningful?
6. Did the game-over and highscore flow make sense?
7. What would you change first before the final delivery?

## Evidence log
Record links or paths for the session evidence.

| Evidence | Link or path | Notes |
| --- | --- | --- |
| Build file |  |  |
| Screenshot set |  |  |
| Video capture |  |  |
| Raw notes |  |  |
| Filled feedback sheets |  |  |

## Exit criteria
- The checklist is filled.
- The moderator questions are answered for each participant.
- Evidence links are saved.
- Follow-up bugs or adjustments are created before closing the story.

## Recorded session handoff
- The Playtest 02 session was executed jointly with the professor and its outcome feeds the final MS4 fix pass.
- Keep this runbook as the canonical checklist if the session needs to be replayed or extended before release.
