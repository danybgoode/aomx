# ADR 001: Select Godot for the first playable game slice

- **Status:** Proposed recommendation; revisit after measured prototype evidence
- **Date:** 2026-10-13
- **Decision owner:** Battle for La Roma project
- **Related:** [technical feasibility](../technical-feasibility.md), [engine comparison](../engine-comparison.md), [prototype plan](../prototype-plan.md)

## Context

Battle for La Roma is a new RTS with original Mexican-themed content, a need for small AI-agent-friendly changes, and no game implementation yet. The next engineering need is a playable economy/placement loop that can be verified without proprietary Age of Empires assets. The product strategy prioritizes rules that players can understand without knowing cultural references. The agreed North Star requires trustworthy completed-match events once real matches exist; its 15% later-day target has no baseline.

openage has specialized rendering, pathfinding, event scheduling, nyan data and modpacks. At inspected commit [`3da21ab`](https://github.com/SFTtech/openage/tree/3da21ab486154432a459db1a10534cc0e344db95), its [README](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/README.md) reports gameplay as basically non-functional. Source inspection found selection/movement paths but no live gathering, construction, combat or AI loop. The local build did not configure past missing `toml11`; runtime capability was not verified.

Godot has documented [isometric 2D tiles](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html), [grid navigation](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html), [headless execution](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html) and [multiplayer APIs](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html). These are engine capabilities, not an implemented RTS.

## Decision

Use **Godot 4.x stable**, pinned to an exact version when the project is created, for rendering, UI, input and tooling. Build a separate fixed-tick, data-driven RTS simulation behind a command/state boundary. Begin with the one-worker, one-resource, one-building prototype in the [plan](../prototype-plan.md). Keep game outcomes, resource balances and construction in simulation code; use graphics/physics for presentation only. Defer multiplayer architecture selection beyond the server-authority boundary until scale and repeatability tests exist.

Do not fork openage or use proprietary AoE assets for this prototype. openage remains a reference for pathfinding, event scheduling and content modeling, and can be reconsidered if its own runtime and standalone original-content workflow are demonstrated.

## Rationale and consequences

Godot offers a shorter credible path to an original-content playable test with fewer toolchain layers. The team must implement RTS rules, crowd handling, content validation and eventually multiplayer itself. Godot physics cannot guarantee determinism, so a deterministic simulation is an explicit design and test goal, not an assumed engine feature. A server-authoritative approach can protect future match results and the North Star event boundary, but it has not been implemented.

Godot is [MIT licensed](https://godotengine.org/license/); openage is [GPLv3 or later](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/copying.md). Project and asset licenses still need an owner decision before distribution. No deployment or playable build exists from this decision.

## Revisit triggers

Reassess if the Godot prototype misses the acceptance checks, representative unit-count pathfinding or frame-time targets, or if original-content openage demonstrates a substantially simpler complete loop. Record benchmark devices, unit counts and map sizes before changing the engine decision. A later multiplayer choice must be tested with repeatable state hashes and a real server/client session.

## Prototype review · 2026-10-14

Godot 4.7.2 (`ed1daf0bf`) ran the original 20×20 isometric worker/resource/structure prototype on Apple M2 Max. Headless rules passed move rejection, resource conservation, interrupted gathering, one-time construction cost, footprint pathing and replay equality. In the rendered client, selection, movement, unreachable feedback, gathering/delivery and construction were visible. A 1,000-order route benchmark averaged 1.497 ms per order; 10,000 fixed ticks averaged 0.00110 ms per tick. The debug process-frame monitor ranged roughly 18–35 ms during automated capture, so this is not evidence about representative unit-count frame time.

**Builder recommendation:** Continue with Godot for the next bounded slice. Keep this recommendation provisional until the owner reviews it and a multi-unit solo skirmish supplies representative pathing and frame evidence. This prototype does not produce a terminal match or launch cohort.

## Solo-skirmish review · 2026-10-14

The owner approved Godot 4.7.2 for the small solo-skirmish plan. A local 20×20 match now has worker economy, a production building, melee/ranged combat, an authored opponent, command-post win/loss, 15-minute draw and restart. Headless state replay and rendered debug outcome checks passed. On Apple M2 Max at 12 units, 5,000 path orders averaged 0.5440 ms and 1,000 fixed ticks averaged 0.0491 ms. During rendered debug capture the process-frame monitor showed roughly 14–28 ms; this is not a release-build frame budget. Units may overlap during movement, and crowd routing and larger maps have not been measured.

**Decision:** Continue with pinned Godot 4.7.2 for the next bounded gameplay slice. Revisit if crowd behavior, larger representative unit counts, export or frame measurements miss their acceptance checks. The local match is test traffic, with no public release or launch cohort.
