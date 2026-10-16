---
epic: la-roma-battlefield-art-pack
sprint: 2
title: "Complete current-match battlefield"
risk: low
phase: Shaping
stories_total: 3
stories:
  - id: S2.1
    title: "Make the fixed map readable"
    as_a: "RTS player"
    i_want: "distinct terrain, obstacles, sources and objective states"
    so_that: "I can plan movement and understand La Roma"
    risk: low
    status: done
  - id: S2.2
    title: "Replace both factions' building primitives"
    as_a: "RTS player"
    i_want: "anchored command and recruitment post art"
    so_that: "I can recognize ownership, construction and damage"
    risk: low
    status: done
  - id: S2.3
    title: "Replace both factions' unit primitives"
    as_a: "RTS player"
    i_want: "readable worker, melee and ranged art"
    so_that: "I can distinguish roles and threats during play"
    risk: low
    status: done
---

# La Roma battlefield art pack v0.1 — Sprint 2: Complete current-match battlefield

**Status:** ✅ Shipped — battlefield rendering merged to `master` in PR #23; blind comprehension QA continues in Sprint 3.

The complete current-match map and all existing unit/building kinds now use catalogued sprites. The fixed 20×20 tile and 2×2 building geometry, picking, orders and simulation remain unchanged. Four environment sprites mark the existing sources, walls and objective or decorate quiet tiles; their positions do not affect pathing. The view uses deterministic terrain variants, faction-based skins, ground-depth sorting, mirrored facing, movement/attack/carry cues, construction progress and health bars. The retained source atlases, repeatable exports and manifest contain 30 transparent PNGs. Rendered Poblanos and Regios starts showed both faction colors, sources, the objective, barriers and zoomed anchors. Headless Godot rule/faction/district/client/outbox checks and the Node contract passed; Sprint 3 owns the complete visual QA record.

## Stories

### Story 2.1 — Make the fixed map readable ✅ a635d78

**As an** RTS player, **I want** distinct terrain, obstacles, sources and objective states, **so that** I can plan movement and understand La Roma.

**Acceptance:** Replace plain terrain diamonds with authored 48×24 ground art on the existing 20×20 map. Visually distinguish walkable ground, hard walls, the two gold sources, the 3×3 district and neutral/hold/contested states without changing any simulation tile. Avoid obvious repetition with a small deterministic variant set. Any decorative CDMX props are nonblocking, carry a view-only anchor and never hide a selectable entity. Manifest and docs match exported files.

**QA:** Compare walkability and district tests before/after, then inspect both spawn routes and contested center in rendered Godot. No browser smoke.

### Story 2.2 — Replace both factions' building primitives ✅ a635d78

**As an** RTS player, **I want** anchored command and recruitment post art, **so that** I can recognize ownership, construction and damage.

**Acceptance:** Produce blue and red faction skins for command posts and barracks. Both retain 2×2 ground footprints, tile selection and placement validity. Visual construction progress and damage reflect existing model fields only; a destroyed barracks vanishes on its original tick, and the dead command post presents a terminal state. Tall art uses view-only depth ordering and does not change collision.

**QA:** Building/placement rule checks plus rendered construction, selection, damage and destruction smoke. No browser smoke.

### Story 2.3 — Replace both factions' unit primitives ✅ a635d78

**As an** RTS player, **I want** readable worker, melee and ranged art, **so that** I can distinguish roles and threats during play.

**Acceptance:** Produce original faction-readable worker, melee and ranged skins on shared pivots. Minimal idle, movement, attack and worker-gather cues use existing view state; facing is derived in the view without adding simulation fields. Selection, HP, accepted/rejected orders and combat results remain visible. Dead units disappear on the original simulation tick; any transient effect cannot delay it. Record sprite direction and animation metadata in the manifest.

**QA:** Headless economy/combat/district tests plus rendered full-match smoke for both faction choices. No browser smoke.

## Sprint 2 — Smoke walkthrough

Env: local Godot 4.7.2 · game/ · res://skirmish_main.tscn.

1. Start a match as Regios, then restart and choose Poblanos.
   → Terrain, both sides' sources and command posts, and the district are identifiable in both starts.
2. Select a worker, gather gold and build a recruitment post.
   → Source, worker, valid/invalid 2×2 placement and construction feedback are visible; stockpile and collision behavior match the original game.
3. Train melee and ranged units, then contest La Roma.
   → Both factions' roles and the neutral, hold and contested district states remain understandable without relying only on color.
4. Destroy the opposing command post or complete a district hold.
   → The original terminal result occurs; no decorative sprite changes selection, pathing or win timing.
