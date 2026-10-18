# Expanded warfare and world — QA record

**Device:** owner Apple M2 Max Mac, macOS, Godot 4.7.2 stable official. The architecture budget was declared in the [epic](../Roadmap/01-core-play/expand-warfare-and-world/README.md) before tuning. These initial measurements use the local debug editor/runtime. Add signed downloaded release results below before closing the epic.

| Scenario | Map / units / load | Route p95 (≤ 6 ms) | Tick p95 (≤ 4 ms) | Frame p95 (≤ 33.3 ms) | Static memory (≤ 512 MiB) |
| --- | --- | ---: | ---: | ---: | ---: |
| Sustained routing and combat, debug/headless | 28×28 / 80 active / 4,200 accepted orders, 324 duel casualties replenished, 3,250 projectile frames, 6,000 ticks (10 logical minutes) | 1.235 ms | 1.448 ms | — | 30.28 MiB |
| Render, 1280×800 normal | 28×28 / 80 / 180 frames, 110% fit | — | — | 24.949 ms | 37.80 MiB |
| Render, 1280×800 enlarged | 28×28 / 80 / 180 frames, 120% | — | — | 24.720 ms | 37.81 MiB |
| Render, 1024×700 normal | 28×28 / 80 / 180 frames, 88% fit | — | — | 25.385 ms | 37.81 MiB |
| Render, 1024×700 enlarged | 28×28 / 80 / 180 frames, 120% | — | — | 24.745 ms | 37.81 MiB |

The sustained probe keeps AI off to make routing load repeatable. Four fighters conduct a live ranged/armored/siege duel while the remaining roster receives route orders; casualties are replenished so combat persists. This is a diagnostic workload, not the required downloaded-build representative match. The 48×48 comparison ran 162 entities and 800 orders for 300 ticks: route p95 6.369 ms against its earlier 12 ms budget, tick p95 7.599 ms against 8 ms, static memory 27.28 MB. These are a regression comparison, not release device evidence. Fog line-of-sight footprints are cached by tile; crowd waits make one bounded reroute decision, report blockage, and fail explicitly at 90 blocked ticks. A swap lets two workers pass without overlapping. The earlier repeated path search exceeded the baseline and crowded tick budgets, so it was removed before these results.

## Rendered evidence

- [1280×800 normal](screenshots/warfare/desktop-1280x800.png) and [120%](screenshots/warfare/desktop-1280x800-120.png)
- [1024×700 normal](screenshots/warfare/desktop-1024x700.png) and [120%](screenshots/warfare/desktop-1024x700-120.png)

The stress probe intentionally packs both armies near the starting view. At 120% the board extends beyond the viewport; the minimap pans to hidden routes and the objective remains visible. Armored and siege roles have A/S badges over their reused silhouettes. Fog hides unrevealed enemy actors, resource markers and post HP.

## Deterministic and data checks

`warfare_test.gd` covers hidden targeting, explored memory, congestion, a controlled unsupported-melee loss to armor followed by a two-ranged counter win, normal recruitment, attack-move/hold/stop, moving-target projectile miss after shooter death, projectile save, replay and Conquest with surviving enemy units. `skirmish_client_test.gd` additionally covers armored/siege drag selection, fogged source hit testing, and a projectile becoming visible only after entering sight. `district_test.gd` covers contest/empty resets, both factions, 750-tick hold and command-post precedence. The pinned 700-tick macOS hashes are in `cross-platform-hashes.v3.json`. The Godot-to-ingest contract accepts one test-tagged completion and excludes it from public cohorts. The Node suite and affected Godot suites pass locally.

## Restricted release evidence

Pending reviewed PR, signed export, Restricted upload, downloaded-build verification, four faction×victory walkthroughs and test-tagged sync receipt. Keep the epic in progress until those results are recorded.
