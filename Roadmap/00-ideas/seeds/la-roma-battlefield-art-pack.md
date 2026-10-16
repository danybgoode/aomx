---
title: "La Roma battlefield art pack v0.1"
slug: la-roma-battlefield-art-pack
status: scaffolded
area: "02"
type: feature
appetite: L
underwritten_by: wave-2026-10
risk: low
epic: "02-civilizations-and-world/la-roma-battlefield-art-pack"
build_order: 10
updated: 2026-10-16
intent_ask: verbatim
hypothesis: "We believe original, readable CDMX battlefield art will help classic RTS players understand and enjoy the current La Roma match because primitives hide its setting and state. We'll know from blind comprehension checks now and first-match completion after an observed cohort."
persona: "Classic RTS players trying the existing solo skirmish, including players unfamiliar with Mexican cultural references."
grounded: false
grounded_reason: "The agreed first-match completion input has no real cohort baseline, and no evidence yet isolates the effect of production art."
target_metric: first_match_completion
target_from: null
target_to: null
read_date: null
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
intent_match: null
---

# Pitch — La Roma battlefield art pack v0.1

Moves: first_match_completion · Tests: Value proposition. This is a qualitative visual-readability bet until invited play yields a baseline.

## The ask, as given

The owner's core request, quoted word for word from the 2026-10-16 ask:

> Hi codex help me refine the next ask: we’re ready to move from developer art to production art. That’s an important transition for Battle for La Roma.
>
> The desired foundational asset pack is from:
> https://scrabling.itch.io/pixel-isometric-tiles
>
> the downloaded assets can be found in references/critters and references/isometric tileset.
>
> Battle for La Roma — La Roma Battlefield Art Pack v0.1
>
> Replace the colored primitives in the current Godot alpha with a coherent collection of original isometric assets, preserving the existing gameplay and battlefield geometry.
>
> First, establish the technical art specification
>
> The current art work already establishes an isometric grid.
>
> But we need to know its exact geometry.
>
> This is a discovery and specification task.
> Do not replace the renderer or gameplay systems yet.
>
> Preserve existing gameplay.
> Preserve simulation coordinates.
> Preserve collision and selection behavior.
> Do not rewrite the simulation.
> Do not import placeholder assets.
> Do not implement the new art renderer yet.
> Do not modify existing gameplay balancing.
>
> Step 0, refine the whole thing as per methodology, not sure if as part of refinement you already inspect the repository. returning the actual geometry, rendering constraints, and recommended asset dimensions. so that the epic build already has it? up to you.
>
> Step 2 — finalize the art manifest. turn the specification into a production-ready asset inventory, including priorities, naming conventions, and dependencies.
>
> Step 3 — create the first real sprites. start with terrain, one headquarters, and one unit. These will establish whether our art style works at actual gameplay scale.
>
> Step 4 — integrate the first assets. validate transparency, alignment, rendering order, selection, and performance in the real game.
>
> Step 5 — expand the pack. Once the first assets look right in Godot, we produce the remaining buildings, units, and environment.
>
> Step 6 — implement the HUD. The gameplay UI deserves its own integration milestone, since it involves layout, interaction, and responsive behavior—not just artwork.
>
> This gives us a reliable feedback loop between visual design and the actual running game.
>
> Let me know what you think. Remember to leverage golden-frijoles methodology to get best results. All of my above needs to be reviewed as it might not be grounded or make any sense.

### Claims

1. The two local concept images establish the desired CDMX battlefield and desktop HUD direction, subject to in-game readability.
2. The Scrabling tiles and critters are desired source material; their geometry, scope, and rights need checking before production use.
3. Discover exact geometry, rendering, anchors, states, UI architecture, and performance constraints before artwork production.
4. Replace the existing colored primitives with a coherent original art pack without changing gameplay, coordinates, collision, or selection.
5. Pilot terrain, one headquarters, and one unit in Godot, then extend only after actual-scale review.
6. Keep a machine-readable asset inventory; assess environment, effects, sound, desktop HUD, and touch UI as later increments.

**Teach-back:** unanswered — You want the current solo skirmish to look and read like Battle for La Roma, while its rules remain stable, and want the art production plan grounded in the renderer and tested at gameplay scale.

## Problem

The 20×20 skirmish can be completed, but its geometric board and text HUD cannot demonstrate the promised Mexico City visual identity. The reference montage depicts a much richer world than the simulation can currently express. Producing its entire pictured inventory before testing scale, rights, layering, and readability would risk expensive unused assets.

## Appetite

**L:** a multi-wave art bet, re-evaluated after a one-terrain/one-building/one-unit in-game pilot. The budget covers the current match's complete battlefield presentation, not all concept-art objects or a new HUD interaction system.

quote: $50–300 (L, n=0, wide)

## Outcome & signal

At 100% and 125% board zoom, a player can identify both factions, worker/melee/ranged roles, own and enemy command/recruitment posts, sources, blocked tiles, the 3×3 La Roma objective, selection, construction, damage and orders in a playable match. Two blind reviewers, one familiar and one unfamiliar with the cultural references, can state both win routes and distinguish friendly/enemy units without art explanation. Record problems, not a fabricated retention lift. Once a real cohort exists, compare first-match completion against its observed baseline using the agreed North Star definition; the 15% later-day target remains provisional.

## Stage-2.5 bucket

**Feature · shaped bet · genuinely new.** The skirmish renderer already draws all gameplay entities and feedback, but there is no production asset pipeline, sprite metadata, sprite rendering, animation state, or designed HUD. A light restyle could improve clarity, but would not establish the distinctive world the owner wants.

## Bill of materials (What / Why)

| What | Why |
| --- | --- |
| Geometry and art contract, then machine-readable manifest | Let artwork fit the simulation before production spending. |
| Small original style pilot in the running match | Test scale, palette, anchors, and gameplay readability before expanding. |
| Terrain, obstacle, source and district art | Make the board and win route legible while preserving pathing. |
| Faction skins for command and recruitment posts | Replace every building primitive that exists today. |
| Worker, melee and ranged skins for both factions | Replace every unit primitive that exists today. |
| Selection, construction, hit and order feedback | Preserve actionable state after removing geometric cues. |
| Rendered QA and baseline comparison | Catch depth, transparency, selection and frame-time regressions. |

The Why column is proposed for owner review. An item without a defensible reason can be cut at the pilot gate.

## Scope

**In v0.1:** the current default Godot solo skirmish only; source artwork and exported transparent PNGs; a JSON manifest with asset IDs, file paths, logical footprints, canvas dimensions, pivots, states, directions, frame timing, provenance and licenses; the six requested concise docs under docs/art/ (pipeline, geometry, manifest, animation, UI architecture, integration plan); a first terrain/building/unit pilot; then all presently rendered gameplay kinds and necessary feedback; a few nonblocking CDMX decorations if legibility survives; comparison of simulation snapshots and contract checks; a rendered owner walkthrough at normal and zoomed board scale.

**Out of v0.1 (no-gos):** a simulation rewrite, TileMapLayer migration by default, new resource types, ages, taquería/depot, motorcycle, expanded map, camera pan, hundreds-of-units promise, a full AoE-style desktop HUD, minimap, touch controls, new command vocabulary, music/voice library, and public release. The older worker-only scene remains outside this match-art scope. The HUD and audio become separately refined milestones after the art pilot.

## Grounded implementation facts and starter dimensions

| Item | Confirmed in code | Initial art recommendation, to lock after pilot |
| --- | --- | --- |
| Map/projection | 20×20 integer tiles. Center = (640,65) + ((x−y)×24,(x+y)×12); inverse uses rounded coordinates. Flat 2:1 diamonds. | Draw terrain to a 48×24 ground diamond; keep art registration at tile center. |
| Zoom/window | Node2D drawing is scaled around (640,305), initially 1.1, clamped 1.0–1.25. UI sits in a CanvasLayer; viewport is 1280×800. | Review pixel edges at both zoom limits; a pixel-perfect claim is not possible at 1.1/1.25 without a new scaling rule. |
| Units | One integer tile per unit; no facing or interpolation field. Current art is about 16 px wide and is drawn 10 px above tile center. | Treat tile center as ground/feet pivot. Trial 48×48 or 48×64 transparent canvases, then set exact shared canvas by readability test. Keep body distinct from selection ring. |
| Buildings | Command post and barracks both occupy 2×2 tiles; entity position is the first/top-left tile. The 2×2 ground diamond spans 96×48 px. Completion and health exist; a dead barracks is removed, while a command post stays at 0 HP for the terminal state. | Trial 96 px ground width with upward art overhang and an explicit ground pivot 12 px below the first tile center. Transparent sprite canvas height remains to be measured. |
| District | The central 3×3 La Roma region is simulation state, not a monument entity. | Tile/overlay artwork may signal ownership and hold state; any monument is decorative and must not obscure occupancy or selection. |
| Terrain | 400 diamonds drawn in a loop; walls are hard-coded. There is no terrain material map, variant logic, elevation or TileMapLayer. | Start with an authored 20×20 visual map and sprite drawing. Do not add transition/road variants until the pilot shows their value. |
| Draw order | Terrain, sources, all buildings by ID, then all units by ID; no Y-depth sorting. | Introduce view-only depth ordering for tall sprites, while retaining tile-based hit testing and simulation IDs. |
| Source pack | Local spritesheet is 352×352, arranged as 32 px cells; provider labels it a 32×32 isometric pack. | Use as a palette/shape reference during pilot. Do not silently stretch it to the 48×24 grid or treat animal critters as human combatants. |

The exact unit/building **canvas** dimensions, directional frame count and animation timings are pilot decisions, not facts inferable from the current primitives. The 48×24 and 96×48 ground dimensions are fixed by the code. Sprite overhang is independent of collision footprint.

## Rabbit holes

- The supplied concept images are visual targets, not pixel-accurate sheets or approved gameplay features. The HUD image shows food, wood, stone, age, population, multi-select, minimap, and mobile controls that the game has not implemented.
- The Scrabling page currently labels the asset CC BY 4.0 while also saying attribution is unnecessary and standalone redistribution is forbidden. Record purchase/download provenance and resolve which terms govern any direct pixels before shipping them. The project can instead use new art influenced by the style without copying pixels.
- Godot has no unit-facing/animation phase; derive temporary facing from prior and next tile in the view layer. Death needs a view-only transient because the simulation removes dead entities. No death animation may delay or change simulation resolution.
- Sprite occlusion, tall buildings and decorative props can block visible units even when tile selection still works. Establish depth and transparency rules in the pilot.
- Fractional zoom softens or unevenly enlarges pixel art. Judge crispness at the existing zoom range and record whether a future zoom policy is needed.
- The current GL Compatibility desktop preview does not prove WebGL 2.0 or mobile performance. Benchmark those targets only when actual exports and target devices exist.
- License every sound individually. Freesound hosts CC0, CC BY and noncommercial sounds; a commercial art milestone should prefer CC0 or clearly attributed CC BY and exclude noncommercial files.

## What already exists (reuse, don't rebuild)

- game/skirmish.gd owns tile positions, walls, 2×2 footprints, faction, construction, HP and deterministic rules. Keep it simulation-only.
- game/skirmish_main.gd owns projection, inverse picking, zoom, board drawing, order feedback, selection and the CanvasLayer text HUD. Replace only the view path in increments.
- game/project.godot pins 1280×800 canvas-item stretch and GL Compatibility; game/skirmish_main.tscn is a single Node2D.
- game/tests and the skirmish contract command already cover gameplay and event behavior; use their baseline hashes/checks at each integration boundary.
- references/6d48808370c32e2ee014d7f429eedefbea650850e24b8536db0ada52bd5621ee.jpg and references/04a1d5324f0edb9c8e41f5a474ec3f49255671b7baf530e4de7f154e661cce23.jpg show the visual direction and HUD concept.
- docs/design-prework/art-audio/06-art-audio.md already records the visual principles and warns against arbitrary sprite dimensions.

## Visuals

~~~mermaid
flowchart LR
  Artist[Artist/source files] --> Export[PNG export + metadata]
  Export --> Manifest[Versioned asset manifest]
  Manifest --> View[Godot skirmish view]
  Rules[Existing simulation: integer tiles and state] --> View
  View --> Player[Playable board and feedback]
  Rules --> Events[Existing test-tagged funnel outbox]
~~~

## Slices and acceptance criteria

| Story / QA stage | Observable acceptance |
| --- | --- |
| A1 · Discover and specify · low · docs review | Six docs/art documents and JSON manifest define current geometry, coordinate/pivot conventions, current kind/state inventory, source rights, import/filter rules, depth approach and unresolved choices. Require/recommend labels are explicit. No renderer or gameplay edit. |
| A2 · Prove a style pilot · low · rendered Godot smoke | One 48×24 terrain family, one command-post skin and one unit role are produced as editable originals and exported PNGs; the game displays them at both zoom limits. Pivot, transparency, depth and selection are checked on the real map before a broader production run. |
| B1 · Finish map surfaces · low · rendered map smoke | All current terrain classes needed by the fixed map, hard-blocked cells, two gold sources and La Roma ownership/contested states read clearly. Variants are limited to visible benefit; visual changes leave walkability and district cells unchanged. |
| B2 · Finish buildings · low · construction/destruction smoke | Both faction skins for command posts and barracks show complete, construction and readable damage/destruction feedback where the simulation supports them. 2×2 placement, tile picking and production still work; destroyed entities disappear on the original tick. |
| B3 · Finish units · low · combat/economy smoke | Worker, melee and ranged roles have readable faction skins and minimal idle/move/attack/gather cues where state exists. Directions and animation conventions are recorded. Orders, attacks, gathering, victory and loss remain unchanged. |
| C1 · Visual completion and performance · low · owner walkthrough | Selection, health, valid/invalid construction and accepted/rejected order feedback remain legible without relying only on blue/red. Owner runs full matches as both factions in a local or restricted preview build, including 100%/125% zoom. Headless simulation/outbox/contract checks match baseline; capture frame and memory observations in the same debug scene without claiming large-map/mobile capacity. |

The art pilot is a review boundary inside the epic. If the selected style fails at gameplay scale, revise or stop before B1–B3; do not make the pack larger to compensate for illegibility.

## UX heuristics & rails check

- **CI guards covering this surface:** Godot headless simulation/skirmish/client checks and npm skirmish contract. No automated visual regression guard found.
- **Audits lens:** no area-02 visual audit found.
- **Design-language debt:** all present board colors and text are hard-coded in game/skirmish_main.gd; current feedback depends heavily on color and a small text block. Keep labels/shapes for faction and district state.

## Measurement and runtime gate

No Golden Frijoles feature flag is proposed: this asset swap has no sensible per-player runtime seam in the local skirmish. Use the existing test-tagged match events for regression only. A later invited cohort can supply the first baseline for first-match completion; do not claim a North Star lift from the pilot or alter the agreed 15% later-day target.

## Open risks / research

- **Owner decision:** Should production ship any Scrabling pixels, subject to recorded licensing terms, or use the pack only as reference for new originals? Recommendation: new originals, retaining provenance for any direct use.
- **Owner decision:** Does this art epic move ahead of the raw release-candidate work after current owner QA, while funded alpha access and comprehension work continue? Recommendation: yes; do not declare an external release from a merge.
- **Owner decision:** Approve L appetite and the v0.1 boundary, with desktop HUD, touch UI and audio as later bets. Recommendation: yes.
- **Source:** Scrabling itch.io listing, checked 2026-10-16: https://scrabling.itch.io/pixel-isometric-tiles .
- **Source:** Freesound license FAQ, checked 2026-10-16: https://freesound.org/help/faq/ .
- **Local truth:** game/skirmish_main.gd, game/skirmish.gd, game/project.godot, game/README.md and the two supplied concept JPGs.
