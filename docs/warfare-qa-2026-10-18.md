# Expanded warfare and world — QA record

**Device:** owner Apple M2 Max Mac, macOS, Godot 4.7.2 stable official. The architecture budget was declared in the [epic](../Roadmap/01-core-play/expand-warfare-and-world/README.md) before tuning. The first five rows use the local debug editor/runtime; the next rows use a temporary release-template QA export from merged commit `c5e7053`, with the same simulation and render probe code and a probe scene in place of the game menu. That QA export is distinct from the signed Restricted app.

| Scenario | Map / units / load | Route p95 (≤ 6 ms) | Tick p95 (≤ 4 ms) | Frame p95 (≤ 33.3 ms) | Static memory (≤ 512 MiB) |
| --- | --- | ---: | ---: | ---: | ---: |
| Sustained routing and combat, debug/headless | 28×28 / 80 active / 4,200 accepted orders, 324 duel casualties replenished, 3,250 projectile frames, 6,000 ticks (10 logical minutes) | 1.211 ms | 1.487 ms | — | 30.28 MiB |
| Rendered combat, 1280×800 normal | 28×28 / 80 / 600 frames, 100 combat ticks, 408 projectile frames, 110% fit | — | — | 22.689 ms | 37.87 MiB |
| Rendered combat, 1280×800 enlarged | 28×28 / 80 / 600 frames, 100 combat ticks, 120% | — | — | 22.883 ms | 37.87 MiB |
| Rendered combat, 1024×700 normal | 28×28 / 80 / 600 frames, 100 combat ticks, 88% fit | — | — | 22.604 ms | 37.87 MiB |
| Rendered combat, 1024×700 enlarged | 28×28 / 80 / 600 frames, 100 combat ticks, 120% | — | — | 22.775 ms | 37.87 MiB |
| Release-template sustained routing and combat, headless | 28×28 / 80 active / 4,200 accepted orders, 324 replenished casualties, 3,250 projectile frames, 6,000 ticks | 0.869 ms | 1.360 ms | — | 104.70 MiB peak process RSS |
| Release-template rendered combat, 1280×800 normal | 28×28 / 80 / 600 frames, 100 combat ticks, 110% fit | — | — | 21.996 ms | 232.97 MiB peak process RSS |
| Release-template rendered combat, 1280×800 enlarged | 28×28 / 80 / 600 frames, 100 combat ticks, 120% | — | — | 22.872 ms | 232.55 MiB peak process RSS |
| Release-template rendered combat, 1024×700 normal | 28×28 / 80 / 600 frames, 100 combat ticks, 88% fit | — | — | 22.828 ms | 232.94 MiB peak process RSS |
| Release-template rendered combat, 1024×700 enlarged | 28×28 / 80 / 600 frames, 100 combat ticks, 120% | — | — | 22.709 ms | 233.69 MiB peak process RSS |

The sustained probe keeps AI off to make routing load repeatable. Four fighters conduct a live ranged/armored/siege duel while the remaining roster receives route orders; casualties are replenished so combat persists. The rendered probe advances that duel at the game's actual 10 Hz logical cadence under an 80-unit render load, with 3 replenished casualties. A preliminary probe that forced a tick on every rendered frame measured 37.887 ms p95; that was a six-times-faster simulation workload, so it was replaced by the actual cadence before recording frame evidence. These are diagnostic workloads, not the required downloaded-build representative match. In a release export Godot's `Performance.MEMORY_STATIC` monitor returned zero, so the release memory values are `/usr/bin/time -l` maximum resident set size, converted to MiB; they are not directly comparable to the debug static-memory values. The release harnesses exited with Godot resource-leak warnings from the temporary probe wrapper; the signed game app was not changed. The 48×48 comparison ran 162 entities and 800 orders for 300 ticks: route p95 6.369 ms against its earlier 12 ms budget, tick p95 7.599 ms against 8 ms, static memory 27.28 MB. These are a regression comparison, not release device evidence. Fog line-of-sight footprints are cached by tile; crowd waits make one bounded reroute decision, report blockage, and fail explicitly at 90 blocked ticks. A same-side swap lets two workers pass without overlapping. The earlier repeated path search exceeded the baseline and crowded tick budgets, so it was removed before these results.

## Rendered evidence

- [1280×800 normal](screenshots/warfare/desktop-1280x800.png) and [120%](screenshots/warfare/desktop-1280x800-120.png)
- [1024×700 normal](screenshots/warfare/desktop-1024x700.png) and [120%](screenshots/warfare/desktop-1024x700-120.png)

The stress probe intentionally packs both armies near the starting view. At 120% the board extends beyond the viewport; the minimap pans to hidden routes and the objective remains visible. Armored and siege roles have A/S badges over their reused silhouettes. Fog hides unrevealed enemy actors, resource markers and post HP.

## Deterministic and data checks

`warfare_test.gd` covers hidden targeting, explored memory, same-side crowd movement without enemy phasing, full building-footprint sight, immediate dead-target cancellation, a controlled unsupported-melee loss to armor followed by a two-ranged counter win, normal recruitment, attack-move/hold/stop, moving-target projectile miss after shooter death, restored projectile impact, replay and Conquest with surviving enemy units. `skirmish_client_test.gd` additionally covers unbound minimap rendering/input, armored/siege drag selection, fogged source hit testing, and a projectile becoming visible only after entering sight. `district_test.gd` covers contest/empty resets, both factions, 750-tick hold and command-post precedence. The pinned 700-tick macOS hashes are in `cross-platform-hashes.v3.json`. The Godot-to-ingest contract accepts one test-tagged completion and excludes it from public cohorts. The Node suite and affected Godot suites pass locally.

## Restricted release evidence

PR [#48](https://github.com/danybgoode/aomx/pull/48) passed Project checks and CodeQL, received independent high-risk review, and merged as `c5e705309257`. The signed macOS source archive is `preview-c5e705309257`, SHA-256 `a68d0b732fe94ffdadd9c817921d5aeebfb4da395af743fd31bd485aab91b4ce`, with `godot-4.7.2-skirmish-3` / `la-roma-warfare-3`. Strict code-signature verification passed at export. The Restricted ingest VM is healthy on `aomx-ingest:c5e7053`; the owner-Mac live smoke accepted this game/content pair, returned stable retry receipts, excluded test and forged non-test preview events, and rejected an unsupported version. Its temporary event-write invite was revoked, confirmed HTTP 401, and both plaintext files removed. No public cohort event was accepted. Restricted itch upload #2157380 is processing at this record's time. Authenticated channel download verification, four faction×victory walkthroughs, downloaded-app save/resume and in-app test sync remain open. Keep the epic in progress until these results are recorded.
