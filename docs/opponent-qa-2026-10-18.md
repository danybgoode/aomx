# Strategic opponent local QA — 2026-10-18

Build under test: Godot 4.7.2 on the owner Apple M2 Max, game `godot-4.7.2-skirmish-4`, content `la-roma-opponent-4`, save/replay schema 4. The committed [raw scenario report](opponent-scenario-report-2026-10-18.json) covers both player factions, all three opponent levels and seeds 1 and 2. Each case runs up to 4,200 fixed 0.1-second ticks against an idle player; it is a deterministic regression, not evidence of balance against people.

| Opponent | Terminal tick range | Result | Maximum case tick p95 | AI commands across four cases | Rejected AI orders |
| --- | ---: | --- | ---: | ---: | ---: |
| Learner | 2,192 | 4 district wins | 0.545 ms | 364 | 0 |
| Standard | 1,673–1,814 | 4 district wins | 0.657 ms | 421 | 0 |
| Challenger | 1,613–1,652 | 4 district wins | 0.995 ms | 597 | 0 |

All 12 full-match replays verified their final state and command log. The report includes each opening, result reason, age, plan/stall counts, resource and army trajectory, state hash and tick measurements. Two opening orders are seed-selected. A separate controlled Conquest test makes a visible enemy post attackable and confirms a legal AI attack order and terminal command-post result. Focused tests also cover hidden-unit invariance, visible armor response, timed sight memory, depleted source rerouting, permanent needed-resource exhaustion classification, three-level save/resume and replay, and unknown-level rejection. The existing district tests cover contest reset and command-post precedence. A delayed-scout strategic test reached fourth age and completed its research for both factions. These controlled checks do not prove that a normal uncoached player will experience both win routes.

The headless 80-unit warfare probe recorded route p95 1.264 ms (6 ms budget), tick p95 1.613 ms (4 ms budget), and peak static memory 30.55 MiB (512 MiB budget) over 6,000 ticks. A rendered 1280×800 debug probe recorded frame p95 27.292 ms (33.3 ms budget) and 38.23 MiB static memory over 600 frames. Opponent-matrix tick p95 stayed under 1 ms in each case. These are owner-Mac debug observations; a ten-minute release export on a minimum device remains unmeasured.

Local setup screenshots at 1280×800, 430×800 and 844×390 were inspected; selector, description and faction choices were visible. The Node suite passed 15 checks with one environment-dependent Postgres test skipped, and the Godot-to-ingest contract passed with only excluded test events. The Godot regression suite and cross-platform hash fixture passed locally on macOS. PR #50's Linux Project checks also passed the version-4 pinned hash fixture on both factions.

## Release and player-read work still owed

The integration PR, required independent high-risk review, merge and a signed Restricted download must be recorded separately. On that exact downloaded build, complete the numbered owner steps in all three [epic sprints](../Roadmap/01-core-play/build-strategic-opponent/README.md): test level choice and resume, both factions and victory routes, and one excluded in-app sync receipt after compatible ingest is deployed. The four-player uncoached clarity read needs approved notice/invitations; no participant or later-day retention observation exists yet. Keep the epic in progress until these results are recorded. The current 15% later-day completion goal remains provisional with no observed baseline.
