---
epic: integrate-owned-art-library
sprint: 2
title: "Godot scale pilot"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Compare tiles, building and critter at game scale"
    as_a: "visual reviewer"
    i_want: "a Godot comparison at real board zoom"
    so_that: "I can approve a usable style and identify seam problems"
    risk: low
    status: done
---
# Integrate the owned art library — Sprint 2

### Story 2.1 — Compare tiles, building and critter at game scale ✅

**Acceptance:** `game/art_pilot.tscn` shows a raised earth and grass tile, flower prop, current and concept-derived command posts, and a boar idle animation at 100% and 125%. Left/right cycles all four directions. `game/tests/art_pipeline_test.gd` checks frame and pivot contracts.

## Sprint QA

Run the headless pilot test and inspect the rendered scene. Record owner palette, scale and seam judgment separately from automated checks.

The owner reviewed the 100%/125% comparison and chose to keep the boar, raised tiles and concept command post in the pilot. The boar needs stronger contrast at match scale, and raised sidewalls do not join the flat board cleanly. The flower prop alone is approved for match decoration in this slice.

## Sprint 2 — Smoke walkthrough

1. Run Godot with `--path game res://art_pilot.tscn`.
   → The two comparison scales and isolated sprites render.
2. Press Left and Right.
   → The boar cycles SE, SW, NW and NE idle frames without moving any game entity.
