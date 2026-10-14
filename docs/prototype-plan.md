# Smallest playable RTS prototype

## Purpose and boundary

Prove one original-content interaction loop: an isometric map, one selectable worker, right-click movement, one resource type, gathering, and construction of one building. Use neutral placeholder art with original ownership. A 20×20 map, one resource node, one worker and one building footprint are sufficient. No enemy, combat, civilization bonuses, technology, multiplayer, match outcome or telemetry cohort is in this spike. This prototype checks **engine feasibility**, not the broader value proposition test in [risk validation](../Roadmap/00-strategy/risk-validation.md), which will later need a district objective and two distinct factions.

### Observable acceptance

1. Start from a fresh checkout with no Age of Empires installation or assets; see a legible isometric map, worker and resource node.
2. Left-click the worker and see selection feedback; right-click a reachable tile and see movement to it. An unreachable tile produces clear feedback without moving through blocked terrain.
3. Right-click the resource node; the worker approaches, gathers a fixed amount over time, and the displayed stockpile rises without exceeding node capacity.
4. Choose one building, see a placement preview and valid/invalid footprint feedback, place it on a valid tile, spend a fixed amount of the gathered resource once, and watch the worker complete construction. The footprint blocks subsequent paths.
5. Reset and replay a scripted command sequence; resource totals, positions and building state match the expected final state. Rendered mouse interaction is checked in a real client build.

These checks are intentionally narrow. Do not call completion of this prototype a match completion under the agreed [North Star](../Roadmap/00-strategy/north-star.md).

## Candidate implementation: Godot

Use a pinned stable Godot 4 release and a text-based project. `World.tscn` contains isometric `TileMapLayer`, `Camera2D`, one resource scene and a HUD. `Worker.tscn` and `Building.tscn` render sprites, but hold only view/input glue. `Simulation` owns integer grid coordinates, entity IDs, resource counts, construction progress and a fixed tick. `CommandBus` accepts `Select` only in the client layer and sends `Move`, `Gather`, and `Build` intents to the simulation. The simulation validates ownership, reachability, costs and occupancy, then emits state changes. Use `AStarGrid2D` for this one-worker slice and convert grid positions to isometric screen positions through the tilemap. Mark the building footprint solid when placement succeeds and replan movement. Godot's [isometric tile support](https://docs.godotengine.org/en/stable/tutorials/2d/using_tilesets.html) and [grid pathfinding](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_2d.html) are documented; this particular integration remains to be built.

Suggested slices, each independently reviewable:

1. **Map and movement:** original tiles, worker, selection and right-click pathing; headless path fixtures plus client smoke.
2. **Gathering:** one `ResourceDefinition`, node capacity, worker gather timer, stockpile UI; pure rules test for depletion and command interruption.
3. **Construction:** one `BuildingDefinition`, placement validation, cost transaction, progress and obstruction; pure rules test for insufficient stockpile, invalid placement and double spend; client smoke of the whole loop.

Store definitions as checked-in text resources or validated JSON with stable IDs. Choose one canonical format before content expansion. Keep renderer coordinates and frame delta out of rules. CI should invoke a pinned Godot binary in `--headless` mode to run scripted state tests and import/parse checks, then use a graphical smoke on a test machine. Exact commands belong in `Roadmap/WAYS-OF-WORKING.md` once a game project exists.

## Candidate implementation: openage

First build openage with its [macOS prerequisites](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/doc/build_instructions/macos.md), run upstream tests, and prove a clean original-content boot. Export the engine nyan API, create a `battle_for_la_roma` modpack with original `.nyan`, `.sprite`, `.texture` and `.terrain` assets, and replace the hardcoded test entity and terrain selection in [`spawn_entity.cpp`](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/libopenage/gamestate/event/spawn_entity.cpp) and [`terrain_factory.cpp`](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/libopenage/gamestate/terrain_factory.cpp) with pack-driven data. The current [game setup](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/libopenage/gamestate/game.cpp) also needs a map loader or a temporary original fixed map.

The existing drag-select/right-click Move path can be adapted for the worker. Then add C++ components and commands for resource node, gather, stockpile, build placement/cost/progress, plus activity/system handlers, UI wiring and tests. Update nyan ability-to-component/system mappings, since the current [map](https://github.com/SFTtech/openage/blob/3da21ab486154432a459db1a10534cc0e344db95/libopenage/gamestate/api/definitions.h) covers Idle and Move only. A modpack alone cannot supply these missing rules. Validate gameplay with new C++ tests and a rendered demo, and confirm launch with no proprietary game installation.

This route has substantial engine work before the first economic interaction. Keep it as a research fallback, rather than the primary prototype plan.

## Exit evidence

For either route, archive the source revision and build command, a short client capture, automated rule-test results, and a fresh-asset boot result. Record measured frame time and path latency at one worker and at a later representative unit count. If the prototype works, return to the roadmap's normal refine → approve → build cadence for a full player-facing slice. Do not infer that a document merge is a deployed build.
