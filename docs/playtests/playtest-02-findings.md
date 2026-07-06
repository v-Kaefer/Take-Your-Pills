# Playtest 02 Findings

## Session summary
- Source: `Relatorio Playtest 2.pdf`
- Session context: second playtest executed jointly with the professor.
- High-level conclusion: the core mechanic loop is consistent, but readability drops when speed increases and visual feedback does not explain risk, reward, and state clearly enough.

## Consolidated findings
| ID | Type | Severity | Area | Finding | Action |
| --- | --- | --- | --- | --- | --- |
| PT2-01 | balance / UX | high | pacing, spawn, platforms | Platform and spawn organization becomes harder to parse as speed increases, so the player loses orientation during the run. | Fix now |
| PT2-02 | visual | high | color transitions, HUD, effects | Ghosting and long color transitions create visual fatigue during repeated play. | Fix now |
| PT2-03 | UX | high | score, boosts, state feedback | Score accumulation and boost state are not visible enough during active play. | Fix now |

## Delivery handoff
- `US-15` / `#78`: prioritize clearer pickup feedback, clearer adverse-state feedback, and stronger score or boost readability during motion.
- `US-16` / `#83`: prioritize a calmer opening run, more readable spawn lanes, and a fairer speed curve before and after the scenario transition.
- `US-17` / `#88`: use the regression checklist and release-readiness gates here as the final acceptance path for the delivery build.

## Deferred items
- No extra scope is opened from this report.
- Stretch work remains outside the final delivery unless it is required to fix one of the three findings above.
