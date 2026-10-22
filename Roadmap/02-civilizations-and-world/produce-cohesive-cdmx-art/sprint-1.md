---
epic: produce-cohesive-cdmx-art
sprint: 1
title: "Contract and pilot"
risk: low
phase: Shaping
stories_total: 2
stories:
  - id: S1.1
    title: "Audit current scale and source coverage"
    as_a: "game artist"
    i_want: "one current art contract and source inventory"
    so_that: "new images fit the live match"
    risk: low
    status: planned
  - id: S1.2
    title: "Play a four-asset style pilot"
    as_a: "RTS player"
    i_want: "a readable tile, building, unit and Cibeles in the match"
    so_that: "the art direction can be judged at game scale"
    risk: low
    status: planned
---

# Produce cohesive CDMX game art — Sprint 1: Contract and pilot

**Status:** ⬜ not started

## Stories

### Story 1.1 — Audit current scale and source coverage

**As a** game artist, **I want** one current art contract and source inventory, **so that** new images fit the live match.
**Acceptance:** Reconcile all twelve local concept boards against the five-board inventory, identify tracked originals and owned pilot candidates, and record rights, projection, current map/roster, canvas, pivots, layer/picking and performance baseline. Separate production assets from optional mechanics. Flag the old 20×20 geometry and narrow zoom claims as historical.
**Risk:** low. **QA:** source count, manifest/rights audit and current code inspection; owner reviews the compact contract.

### Story 1.2 — Play a four-asset style pilot

**As a** RTS player, **I want** a readable tile, building, unit and Cibeles in the match, **so that** the art direction can be judged at game scale.
**Acceptance:** Transparent traced sources and deterministic exports render together in a live La Roma match at 100%, 125%, fit view and a crowded center. Show ground contact, seam, palette, silhouette, landmark identity, control cue and selection. Record accept/revise/reject with screenshots and source/build IDs; owner approval remains owed until actually given.
**Risk:** low. **QA:** art-manifest validation, Godot art/client checks, rendered capture, builder pilot decision and owner visual review.

## Sprint QA

- Godot 4.7.2 import, art pipeline test and skirmish client test; compare simulation hash to the pre-art baseline.
- Render the actual match and pilot at 100%, 125% and fit zoom. Capture a dense-center selection and frame/memory baseline.
- Browser smoke: none for local pilot. Owner visual inspection is owed on the actual build/captures.

## Sprint 1 — Smoke walkthrough

Environment: local Godot project at `game/project.godot` and scene `res://skirmish_main.tscn`.

1. Open the La Roma match in Godot and choose any faction. → The new ground, building, unit and Cibeles appear together.
2. Set board zoom to 100%, then 125%. → The four assets keep their ground anchors and readable silhouettes at both scales.
3. Select a fighter next to Cibeles. → The objective cue and selection ring remain visible and the selected fighter receives the order.

If a step fails, record its number and what appeared. Owner style acceptance is recorded separately.
