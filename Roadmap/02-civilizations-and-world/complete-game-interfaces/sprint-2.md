---
epic: complete-game-interfaces
sprint: 2
title: "Read select and command"
risk: low
phase: Verifying
stories_total: 3
stories:
  - id: S2.1
    title: "Read the battlefield"
    as_a: "player"
    i_want: "human-sized resources, age, population and objective state"
    so_that: "I can plan without squinting or losing board access"
    risk: low
    status: done
  - id: S2.2
    title: "Select and issue orders"
    as_a: "player"
    i_want: "clear single/group selection and contextual commands"
    so_that: "I know what will act and whether an order worked"
    risk: low
    status: done
  - id: S2.3
    title: "See progress without hidden information"
    as_a: "player"
    i_want: "queue, research, objective, alerts and fog-aware minimap"
    so_that: "I can track progress and threats fairly"
    risk: low
    status: done
---
# Complete the game interfaces — Sprint 2: Read select and command

**Status:** 🟡 builder verified; human readability and signed-build QA owed

## Stories

### ✅ Story 2.1 — Read the battlefield
**As a** player, **I want** human-sized resources, age, population and objective state, **so that** I can plan without squinting or losing board access.
**Acceptance:** At 100% UI scale, critical HUD text is at least 18 logical units, secondary text at least 16, and essential controls at least 44x44. A player-selectable scale reaches 200% without clipping essential actions at 1024x700 and 1280x800.
**Risk:** low

### ✅ Story 2.2 — Select and issue orders
**As a** player, **I want** clear single/group selection and contextual commands, **so that** I know what will act and whether an order worked.
**Acceptance:** Selection shows identity/count and non-color cue. Buttons, shortcuts and board input share semantic commands. Targeting, cancel, accepted/rejected feedback and block reasons are visible; simulation legality remains authoritative.
**Risk:** low

### ✅ Story 2.3 — See progress without hidden information
**As a** player, **I want** queue, research, objective, alerts and fog-aware minimap, **so that** I can track progress and threats fairly.
**Acceptance:** Queue/research progress and prerequisites reflect current state. Minimap uses the same visibility policy as battlefield; hidden enemies never leak. Text contrast targets 4.5:1 normal, 3:1 large and non-text states.
**Risk:** low

## Sprint QA
Run Godot client, simulation and fog checks. Capture and measure real rendered labels/targets at 100%, 150% and 200%; verify keyboard focus, resize, zoom, picking and no clipped essential action.

Builder result: full resource names, larger labels and targets, a horizontally scrollable command strip, readable selection, scrollable context and preserved fog-aware minimap are in the [current component spec](../../../docs/art/ui-component-spec.md). The local client test checks 100/150/200% geometry at 1024×700; representative graphical captures at 1024×700 and 1280×800 are in the [review package](../../../docs/interface-review/qa.md). Human readability, measured contrast and signed-build interaction remain open.

## Sprint 2 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. Open a match at 1024x700. Read all four resources and objective, select one and multiple units, command gather/build/attack and cancel targeting. Set UI scale to 150% then 200%; repeat selection and read disabled reasons. Check 1280x800 and fog minimap.

If a step fails, record the step, build, action and observed result.
