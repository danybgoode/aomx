# Simulation foundation QA and benchmark — 2026-10-16

**Device/build:** Apple M2 Max, macOS, Godot 4.7.2 stable official, debug/headless for simulation timings. Each scenario issues move orders to both sides, then runs 300 ticks (30 logical seconds); the benchmark runs in `game/tests/skirmish_scale_benchmark.gd`. [Machine-readable results](fixtures/simulation-benchmark-macos-2026-10-16.json) retain the exact measured values, budgets and hashes. Route measurements include semantic order validation and path search. `units` includes the initial buildings/workers. The scenario extends map dimensions in a validated copy of the current content; it does not represent a finished large-map level. Budgets below were declared before the building-tile cache change.

| Case | Map / entities | Accepted orders | Route mean / p95 / budget | Tick mean / p95 / budget | Static memory |
| --- | --- | ---: | --- | --- | ---: |
| Baseline | 20×20 / 15 | 300/300 | 0.643 / 0.858 / 2 ms | 0.033 / 0.052 / 2 ms | 25,045,315 B |
| Crowded | 32×32 / 83 | 500/500 | 2.288 / 3.117 / 6 ms | 0.170 / 0.194 / 4 ms | 25,440,623 B |
| Large army | 48×48 / 163 | 800/800 | 5.388 / 7.446 / 12 ms | 0.337 / 0.376 / 8 ms | 25,978,071 B |

The first naive path-search run missed the declared route budgets (20×20 p95 4.251 ms; 32×32 p95 68.041 ms; the 48×48 run was stopped after over 90 seconds). Caching occupied building tiles, and rebuilding that cache after restore, brought the final full matrix within all budgets without changing canonical hashes. Route search is still per order and units may visually overlap; further crowd control needs its own production-sized scenario.

**Rendered desktop probes:** macOS Godot 4.7.2 Compatibility renderer, 1280×800. `foundation_render_probe.gd` captured the save/resume settings panel and an 82-entity crowd after 120 frames. Save/resume p95 frame interval 13.83 ms, reported process 20.52 ms, peak static memory 35.6 MiB. Crowd p95 interval 13.39 ms, process 24.44 ms, peak 35.8 MiB. These are local debug observations, not release FPS or minimum-device results. The crowd remains visible and the HUD usable, while fighter sprites overlap in dense ranks.

**Linux comparison:** GitHub Actions [run 39003896658](https://github.com/danybgoode/aomx/actions/runs/39003896658) used pinned Godot 4.7.2 on `ubuntu-latest`; [exact results](fixtures/simulation-benchmark-linux-2026-10-17.json) are archived. Route p95 values were 1.160, 4.363 and 10.355 ms; tick p95 values were 0.118, 0.299 and 0.544 ms. All three cases met the same declared budgets, and their canonical state hashes matched macOS. Runner hardware differs from the Mac, so these timings are evidence for CI capacity only, not a device comparison.

**Determinism:** `cross_platform_hash_test.gd` runs 700 ticks for each faction against pinned checkpoint/final hashes in `game/tests/fixtures/cross-platform-hashes.v1.json`. macOS and Linux results match both fixtures: Regios `2512f7f049d6786fa43bf157643055351d11ef57145d9ac148c1ed43ca5c6a51`; Poblanos `8889bbfe066bc29dcdf25c82a363a78a5b24665d6ebb0fd1356f6e30941c95b9`. The fixture records current rules only; it is not an AoE II: Definitive Edition parity claim.

**Regression:** all 12 Godot headless suites, the Godot-to-ingest contract and Node suite passed locally. One Node Postgres restart test is skipped by its existing local test configuration. The save client suite confirms one test-tagged match start/result and readable rejection of corrupt data. No server database migration or production cohort event is part of this epic.

**Reproduce:** set `GODOT_BIN` to Godot 4.7.2 and run `"$GODOT_BIN" --headless --path game --script res://tests/skirmish_scale_benchmark.gd`. For rendered probes, set `AOMX_FOUNDATION_MODE=save_resume` or `crowd` and `AOMX_FOUNDATION_CAPTURE=/absolute/path.png`, then run `"$GODOT_BIN" --path game --script res://tests/foundation_render_probe.gd`. The probe uses disposable `user://` files and deletes them afterward.
