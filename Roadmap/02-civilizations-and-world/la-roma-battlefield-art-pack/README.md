---
status: in-progress
phase: Verifying
slug: la-roma-battlefield-art-pack
title: "La Roma battlefield art pack v0.1"
area: 02-civilizations-and-world
destination: fight-for-la-roma
risk: low
type: feature
sprints_total: 3
stories_total: 6
intent_match: null
quote_low_usd: 50
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "We believe original, readable CDMX battlefield art will help classic RTS players understand and enjoy the current La Roma match because primitives hide its setting and state. We'll know from blind comprehension checks now and first-match completion after an observed cohort."
target_metric: null
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Classic RTS players trying the existing solo skirmish, including players unfamiliar with Mexican cultural references."
grounded: false
grounded_reason: "The agreed first-match completion input has no real cohort baseline, and no evidence yet isolates the effect of production art."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 7
---

# Epic: La Roma battlefield art pack v0.1

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [Approved pitch](../../00-ideas/seeds/la-roma-battlefield-art-pack.md) · **Destination:** fight-for-la-roma

## Why

A classic RTS player should recognize a Mexico City inspired battlefield, both factions, the playable roles, and the La Roma objective while playing the existing solo match. The present colored primitives cannot demonstrate that visual promise. The first pilot tests art at actual game scale before the full pack is produced.

## Architecture lock

- **D1 · Geometry authority:** Keep the existing 48×24 diamond projection, tile inverse and 20×20 integer simulation grid. A sprite's canvas may overhang its tile or 2×2 footprint; its ground pivot and visible bounds are manifest data, not a collision change.
- **D2 · View seam:** Place an asset catalog and view-only animation state between the simulation snapshot and Godot drawing. The simulation remains unaware of textures, facing, frame timing and depth.
- **D3 · Visual map:** Author terrain choices for the fixed 20×20 board without creating pathing or resource data in the art layer. Decorative objects may overhang but do not block or select.
- **D4 · Depth and picking:** Sort visual entities by projected ground depth, with stable IDs as a tie break. Preserve tile-based entity_at selection, 2×2 placement, and command targets.
- **D5 · Source and rights:** Newly authored source files and transparent exports are the v0.1 production pack. On 2026-10-16 the owner confirmed commercial rights to the local isometric tileset, critters and new concept boards; direct use in a later pack still requires per-asset provenance, actual-scale visual and geometry review, and a traced export into `game/assets/`.
- **D6 · UI boundary:** Keep the present CanvasLayer status and commands readable. Define reusable Control components for a later desktop/touch HUD, without adding unimplemented resources, camera movement or commands now.
- **D7 · Verification and release:** Headless checks defend the unchanged rules and outbox; rendered Godot checks defend art readability at both existing zoom limits. A merge is not a deployed build or a public invitation.

- Preserve game/skirmish.gd as the authority for the 20×20 integer grid, commands, collisions, health, win conditions and event versions. Art metadata never changes simulation outcomes.
- Keep the present Node2D projection and tile picking: a 48×24 flat diamond centered at (640,65) + ((x−y)×24,(x+y)×12), with 100%–125% board zoom around (640,305). A 2×2 building ground footprint is 96×48 pixels. Source sprite canvas and pivot specifications are set in Sprint 1 after actual-scale review.
- A render-only asset manifest maps existing kinds and faction to textures, pivots, state and timing. Draw visual terrain and entities with view-only depth ordering; keep selection and placement tile based. No TileMapLayer migration is presumed.
- The scope is the current skirmish only: worker, melee, ranged, command post, barracks, resource source, walls and the 3×3 district. The concept HUD's extra resources, ages, minimap and motorcycle are not gameplay facts.
- The final in-game artwork is newly authored. The Scrabling pack is a visual reference; any direct source pixels require a recorded rights decision. Keep cultural motifs clear without making regional stereotypes into rules.
- The existing HUD text, selection feedback, construction validity, order feedback and match/sync status must remain readable. A new desktop or mobile HUD and sound library are separate milestones.
- The approved plan has no runtime flag seam. Existing test-tagged match events remain unchanged; the first-match-completion baseline is still unknown.

## What already exists (reuse, don't rebuild)

- game/skirmish.gd: deterministic model, faction/kind, integer positions, 2×2 footprints, construction, health and objective states.
- game/skirmish_main.gd: projection, inverse picking, zoom, board rendering, commands and CanvasLayer HUD.
- game/project.godot and game/skirmish_main.tscn: 1280×800 canvas-item stretch, GL Compatibility and one Node2D scene.
- game/tests and npm skirmish contract: rules, client and outbox checks.
- The supplied concept JPGs and docs/design-prework/art-audio/06-art-audio.md: art direction and readable-silhouette criteria, not production-ready sprites.

## Scope — stories

| Sprint | Stories | Outcome |
| --- | --- | --- |
| 1 · Art contract and style pilot | S1.1, S1.2 | Exact asset contract and a terrain/building/unit pilot reviewed in Godot. |
| 2 · Complete current-match battlefield | S2.1, S2.2, S2.3 | Terrain, building and unit primitives replaced for the existing match. |
| 3 · Visual QA and integration | S3.1 | Gameplay and rendering checks, owner walkthrough and recorded limitations. |

The Sprint 1 pilot is a review boundary. If style or readability fails at gameplay scale, revise before expanding; the L appetite is re-evaluated between waves without silently widening scope.

## Sprint build contracts

- **S1:** Document the live geometry and all current rendered states, then ship a one-terrain/one-command-post/one-unit visual pilot with explicit pivots and a rendered scale check. Any failed readability check changes art direction before S2.
- **S2:** Add only current-match terrain, buildings, units and state feedback from the approved manifest. Each asset is reachable from the catalog; visual map edits cannot change walkability or entity selection.
- **S3:** Run the existing deterministic checks and two-faction rendered walkthrough, inspect crowded depth/zoom cases, and record blind comprehension, provenance and performance observations before close-out.

## Deploy order

Build on feat/la-roma-battlefield-art-pack. Verify each sprint locally in Godot 4.7.2 and keep source assets, exports, manifest and docs together. A reviewed merge to master is a code landing, not a game deployment. A restricted preview export or update, if used for owner QA, follows deploy/alpha/README.md with unchanged test exclusion and content-version handling. No participant invitation or public release is implied.

## Definition of Done (epic)

The [new local artwork inventory](../../../docs/art/reference-inventory.md) records owner-rights-cleared `newArtWork`, `critters` and `isometric tileset` sources added after this v0.1 scope. They inform the next production-content decision; this already funded epic is not silently expanded to integrate every new asset or concept-board mechanic.

The [technical QA record](../../../docs/art/visual-qa-v0.1.md) separates observed game behavior from the remaining blind and downloadable-build checks.

- [ ] Six story outcomes and each sprint's blind local Godot smoke walkthrough are recorded with commit refs.
- [x] Required specs and machine-readable manifest describe every integrated asset, pivot, footprint, state, direction and provenance.
- [ ] The current solo match can be played to either win route as both factions; tile selection, placement, health, construction, orders and event sync behavior are preserved.
- [x] Headless Godot rules/client checks and the skirmish contract pass; rendered checks at 100% and 125% zoom record legibility, depth, transparency, frame time and memory.
- [ ] At least one culturally familiar and one unfamiliar blind reviewer attempt the two win-route and friend/enemy identification checks; record exact observations rather than infer a North Star lift.
- [x] Art source rights and any third-party inclusions are documented. No secret, local Golden Frijoles state or unreviewed reference download enters the commit.
- [ ] Review and merge to master, then separately verify any authorized restricted preview. Record real remaining QA and release gates in the retrospective.
- [ ] Update the product poster, durable learnings and generated board from authoritative status. Mark shipped only after this epic's outcome checks, not from a merge alone.
