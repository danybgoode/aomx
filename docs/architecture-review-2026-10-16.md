# GDD and architecture alignment review — 2026-10-16

**Scope.** This review compares the [v0.3 GDD](design/GDD.md), the local ignored `references/roadmap-alignment.md` brief, current Godot source, tests, and existing roadmap. “Verified” below means directly visible in source or an existing test; it does not mean this review completed a fresh owner playthrough, device benchmark, or public release. The [full-game build path](../Roadmap/full-game-build-path.md) is the delivery map. The agreed [North Star](../Roadmap/00-strategy/north-star.md) remains unchanged, including the provisional 15% target and unknown baseline.

**After this baseline review:** The [simulation foundation epic](../Roadmap/01-core-play/harden-rts-simulation/README.md) merged in [PR #39](https://github.com/danybgoode/aomx/pull/39) and shipped to a Restricted owner preview. The owner reported browser download, save/resume and both victory routes passed. [ADR 003](architecture-decisions/003-simulation-contract.md) and the [benchmark report](simulation-benchmark-2026-10-16.md) hold the new save/replay, Linux hash and crowd evidence. The gap matrix below deliberately describes the pre-epic source snapshot.

## Assessment

Godot 4.7.2 remains a viable engine for the next major work. The existing 20×20 solo match is a useful vertical prototype: `game/skirmish.gd` is a scene-independent `RefCounted` rules object with a fixed 0.1-second logical tick, integer tile positions, command validation/logging, stable IDs, sorted entity updates, snapshots and a state hash. `game/skirmish_main.gd` schedules ticks from frame delta and handles rendering/input, while headless tests cover representative prototype rules. These choices support extraction of a larger simulation contract. They do **not** establish cross-device determinism, scalable pathing, a versioned save/replay format, or multiplayer suitability. [ADR 001](architecture-decisions/001-engine-selection.md) correctly keeps the engine choice conditional on evidence.

The greatest mismatch is between a compact hardcoded skirmish and the GDD's complete four-age, four-resource, content-heavy RTS. `game/skirmish.gd` owns fixed map geometry, one resource, costs, faction modifiers, AI, commands and victory rules in one file. `snapshot()` supports hashing but there is no demonstrated load path or version migration. `game/tests/skirmish_benchmark.gd` measures a 12-unit, 20×20 case, far short of representative large-army or mobile/web budgets. `game/project.godot` enables touch mouse emulation; this is not a touch command design. [The existing art manifest](../game/assets/manifest.v0.1.json) separates render assets from rules, but is scoped to the prototype.

## Capability gap matrix

“Partial” means a working prototype subset, not full GDD fidelity. “Planned” means covered by a current seed, epic or the new build path; “missing” means no verified implementation. The owner chose Age of Empires II: Definitive Edition ([ADR 002](architecture-decisions/002-aoe2-definitive-edition-reference.md)); the exact build/patch and scenario baselines remain open, so parity is not scored.

| Capability | Current evidence | Status and next dependency |
| --- | --- | --- |
| Commands, fixed tick, terminal solo match | `game/skirmish.gd`, `game/tests/skirmish_test.gd`, `game/tests/district_test.gd` | **Partial.** Extract a versioned command/state seam and reproducible replay before multiplying rules. |
| Economy and construction | One gold source/stockpile, carry/drop-off, one recruitment post, queues in `skirmish.gd` | **Partial.** Four resources, farms/renewables, repair, multi-builders, population, trade and general prerequisites are unimplemented. |
| Combat and units | Worker, melee, ranged, fixed damage/range/cooldown, command-post destruction | **Partial.** Armor classes, projectiles, siege, stances, formations, elevation, garrison, healing/conversion and broader counters remain. |
| Ages and technologies | No age/tech state in `snapshot()`; values are constants in `skirmish.gd` | **Missing.** Needs validated content schema and an explicit prerequisite/effect engine. |
| Map, vision and pathing | Fixed 20×20 map, hardcoded obstacles, breadth-first route search | **Partial.** Random maps, fog/LOS, elevation, larger maps and crowd routing need representative tests. |
| Opponent AI | Scripted periodic gather/build/train/attack and district contest | **Partial.** Scouting, economic planning, difficulty, composition and team decisions remain. |
| Factions and world | Regios/Poblanos prototype modifiers; La Roma objective; current art manifest | **Partial.** Final roster, faction tech trees, content balance, authored maps and cultural review remain decisions/work. |
| UI, controls and onboarding | Desktop HUD, minimap, selection, zoom and contextual orders in `skirmish_main.gd` and `game/ui/` | **Partial.** Control groups, queues/tech UI, tutorial, accessibility and true touch controls remain. |
| Save/replay/network | Snapshot/hash and local telemetry outbox; no game-state reload or multiplayer protocol | **Missing.** Versioned save/load and replay first; choose and prove synchronization model before multiplayer work. |
| Delivery and measurement | Restricted macOS owner preview; staged ingest; test-tagged events and local reports | **Partial.** Existing alpha QA/invitation gates remain open; no eligible cohort or observed retention baseline. Desktop web/mobile release claims need device evidence. |
| Campaigns, scenarios and editor | GDD concept only | **Planned long term.** Requires stable content/map/objective schema and save/version rules. |

## Five highest-priority architectural risks

1. **Prototype model growth:** Rules, constants, AI and fixed map assumptions are coupled in `skirmish.gd`. Adding the full tech tree in place would make save compatibility and independent testing harder. Establish a command/state/content boundary while preserving the playable match.
2. **Crowd routing and performance:** The current route search and 12-unit benchmark do not demonstrate hundreds of moving entities, congested construction, larger maps or low-end device performance. Profile defined scenarios before choosing a new routing strategy.
3. **Determinism and network model:** Fixed ticks and same-machine hashes are useful but insufficient across OS, CPU, Godot build and serialization versions. Compare long headless runs on target platforms, then decide lockstep versus an authoritative alternative.
4. **Content and persistence drift:** Hardcoded costs and roles lack stable IDs, schema validation, versioning and save migration. Define content and simulation versions separately before expanding ages, factions or mods.
5. **Platform and asset claims:** Current touch mouse emulation, Web compatibility checks and local art sources do not prove mobile usability, sustained browser performance, or a releasable asset pipeline. Set device scenarios and export/rights records early.

## Five largest roadmap gaps closed by the new build path

1. A foundation epic for command/state separation, versioned saves/replays, content schema and benchmark harness.
2. A complete economy and progression sequence covering four resources, population, construction, research and four ages.
3. A warfare/world sequence covering combat depth, fog, scalable pathing, generated maps and AI.
4. An early multiplayer feasibility decision plus a later synchronization/reconnection milestone; a platform feasibility rail for Web and touch before final release work.
5. A dedicated owned-art pipeline plus explicit campaign/scenario/editor, accessibility, audio, licensing and final distribution work, instead of leaving these inside generic world and release-candidate seeds.

## External RTS references

These are research inputs only; no code, data or assets have been adopted. A future spike should pin commits and inspect specific modules/tests before deriving algorithms or any reuse proposal.

| Project | Evidence and transfer value | Limit |
| --- | --- | --- |
| [openage](https://github.com/SFTtech/openage) | Its [pathfinding field specification](https://github.com/SFTtech/openage/blob/master/doc/code/pathfinding/field_types.md) details cost, integration and flow fields; this is a candidate approach to compare against our per-order breadth-first search under crowd load. Its README says current gameplay is basically nonfunctional and requires original AoE assets; it is GPLv3 or later. | Study and benchmark the idea in our geometry before any implementation; no drop-in Godot system or standalone original-content path is proven. |
| [freeaoe](https://github.com/sandsmark/freeaoe) | Its [README implementation inventory](https://github.com/sandsmark/freeaoe/blob/master/README.md) reports carrying/drop-off, garrison, ages, research and scenario triggers, useful as a behavioral test checklist. The same README lists formations, patrol and pathfinding performance as TODO/known gaps. | These are author reports, not independently run scenarios here. It needs original game data and is GPL-3.0; inspect actual modules/commits before algorithm decisions. |
| [OpenRA](https://github.com/OpenRA/OpenRA) | [OrderManager.cs](https://github.com/OpenRA/OpenRA/blob/bleed/OpenRA.Game/Network/OrderManager.cs) shows per-frame order queues, sync hashes, desync reporting and replay-aware pacing; [Map.cs](https://github.com/OpenRA/OpenRA/blob/bleed/OpenRA.Game/Map/Map.cs) shows a versioned map data boundary. These are concrete comparison points for our replay/network and map schema design. | It targets Westwood games rather than AoE2, and its GPLv3-or-later code cannot be presumed reusable in this undecided-license project. Godot integration and mechanic equivalence cannot be inferred. |

Any code reuse needs a separate license and integration decision. The project's own license remains undecided.
This is a first source/document survey on the linked branches, not a commit-pinned implementation audit. The simulation-foundation spike must pin versions and review specific tests before selecting algorithms or adapting any code.

## Decisions and confidence

**Owner decisions still open:** exact Definitive Edition build/patch and allowed fidelity deviations; final conquest and La Roma victory rules; Terrenos fiction; faction roster/naming; multiplayer model; minimum device and battle-size budgets; commercial release and localization policy. The owner confirmed rights for all three local art sets on 2026-10-16, but per-asset origin/license records and exports still need to be preserved. Do not silently turn concept-board labels, fictional bonuses or map modes into approved rules.

**Confidence:** high in the source-level gap and near-term Godot recommendation; medium in the proposed dependency order; low in performance, cross-platform fidelity, online model and player demand until representative builds and playtests exist. No tests were run as part of this document review; existing test and benchmark claims are cited as prior project evidence.
