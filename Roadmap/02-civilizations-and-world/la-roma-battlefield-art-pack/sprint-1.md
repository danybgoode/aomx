---
epic: la-roma-battlefield-art-pack
sprint: 1
title: "Art contract and style pilot"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Specify the current renderer and asset contract"
    as_a: "game artist"
    i_want: "an exact geometry and asset manifest"
    so_that: "my sprites fit the existing match"
    risk: low
    status: done
  - id: S1.2
    title: "Prove one terrain, building and unit at gameplay scale"
    as_a: "RTS player"
    i_want: "a small coherent visual sample in the real match"
    so_that: "the team can approve readability before making the full pack"
    risk: low
    status: done
---

# La Roma battlefield art pack v0.1 — Sprint 1: Art contract and style pilot

**Status:** ✅ Shipped — asset pipeline merged to `master` in PR #22; art outcome QA continues in Sprint 3.

## Stories

### Story 1.1 — Specify the current renderer and asset contract ✅ a55c9c8

**As a** game artist, **I want** an exact geometry and asset manifest, **so that** my sprites fit the existing match.

**Acceptance:** Produce concise docs/art/art-pipeline-spec.md, isometric-geometry.md, asset-manifest-v0.1.md, sprite-animation-spec.md, ui-component-spec.md and art-integration-plan.md, plus a machine-readable manifest. Separate confirmed requirements from trial recommendations. Record tile/footprint geometry, world/screen inverse, zoom, present draw and selection order, current role/state inventory, canvas and pivots, directions, frame timing, file naming, import/filtering, atlas strategy, desktop HUD architecture and target limits. Name unresolved decisions. No renderer, gameplay or balance edits in this story.

**QA:** Review every fact against game/skirmish_main.gd, game/skirmish.gd and game/project.godot; validate manifest syntax and file paths. No browser smoke.

### Story 1.2 — Prove one terrain, building and unit at gameplay scale ✅ 2e97911

**As an** RTS player, **I want** a small coherent visual sample in the real match, **so that** the team can approve readability before making the full pack.

**Acceptance:** Author editable original sources and transparent exports for one terrain family, one faction command post and one unit role. Register them through the manifest and draw them in the running skirmish at 100% and 125% zoom, with existing tile selection and order feedback intact. Compare transparent edges, overhang, occlusion and palette against the approved references. Record accepted canvas sizes and pivots or revise the pilot before Sprint 2.

**QA:** Headless skirmish and client checks; rendered Godot smoke on the pilot. No browser smoke.

**Pilot review, 2026-10-16:** The original blue command post, blue worker and one grass tile variant appeared in the local Godot match. At 100%, 110% and 125% board zoom their ground anchors stayed aligned. Tile selection and training continued to use the existing simulation; the client check passed. The sparse terrain pilot reads as a checkerboard, and labels can cross nearby tall art. Sprint 2 replaces the sparse map treatment and resolves depth/overlay spacing before acceptance of the complete pack.

## Sprint 1 — Smoke walkthrough

Env: local Godot 4.7.2 · game/ · res://skirmish_main.tscn.

1. Launch the game and choose either faction.
   → The pilot terrain, command post and unit appear in the match while the remaining primitives still function.
2. Select the pilot unit and issue a move, then zoom to 100% and 125%.
   → The sprite stays anchored to its tile, the selection marker remains visible and edges remain acceptable at both scales.
3. Select the pilot command post and train a worker.
   → Tile-based picking and production still work; the sprite does not hide the selected/health feedback.
4. Place a recruitment post or finish a match.
   → The pilot art causes no rule or event change. Record the style review decision before continuing.
