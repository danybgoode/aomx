---
epic: readable-battlefield-hud
sprint: 1
title: "Understand the match"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Read the match at a glance"
    as_a: "new player"
    i_want: "a compact status panel with real gold, objective, result and sync state"
    so_that: "I can decide what matters next"
    risk: low
    status: done
  - id: S1.2
    title: "Understand my selection"
    as_a: "player"
    i_want: "a portrait and details for the active unit or building"
    so_that: "I know whom my next order will affect"
    risk: low
    status: done
---
# Readable battlefield HUD — Sprint 1: Understand the match

**Status:** ✅ builder verified in `54a0875`; owner and blind walkthroughs remain open at epic close

## Stories

### ✅ Story 1.1 — Read the match at a glance · `54a0875`
**As a** new player, **I want** a compact status panel with real gold, objective, result and sync state, **so that** I can decide what matters next.
**Acceptance:** The visible panel shows the actual stockpile, match clock, faction, La Roma control/hold, win or loss and queued/offline sync state. It does not show food, ages or population. Match setup and result states remain readable.
**Risk:** low

### ✅ Story 1.2 — Understand my selection · `54a0875`
**As a** player, **I want** a portrait and details for my active unit or building, **so that** I know whom my next order will affect.
**Acceptance:** Clicking each owned worker, fighter and post updates name, role, faction, health and real queue/progress when available; deselection clears stale details. The board ring and panel identify the same actor. Actor death clears or updates selection safely.
**Risk:** low

## Sprint QA
- **Godot spec:** Extend `game/tests/skirmish_client_test.gd` for selection/view state and unchanged model state.
- **Rendered smoke owed:** Yes, local Godot at 1280×800 and small supported window size, plus owner Restricted-download review.
- **Deterministic gate:** Existing Godot rules/client checks, `npm run skirmish:contract`, and asset validation pass.

## Sprint 1 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 · `godot --path game --editor`, then run `skirmish_main.tscn`

1. Choose either faction. → Status shows that faction, actual gold and neutral La Roma state.
2. Click the owned worker, then a fighter and command post. → Selection details and portrait follow the selected board actor; health is readable.
3. Deselect and let the district become contested or held. → Selection empties and objective status updates without overlapping playable actors.
4. Disconnect the ingest route during a test-tagged match. → Pending/offline sync state is visible, with no gameplay interruption.

If any step fails, note the step number + what you saw — that's the bug report.

## Builder QA · 2026-10-16

At 1280×800 and 1024×700, the status showed real gold, faction, clock, La Roma state, result route and saved/synced/attention counts. Selecting the command post showed its existing art, health and available recruitment state; the board ring matched. The client check covers worker selection, portrait, safe deselection on death and read-only HUD refresh. A local preview-channel copy kept invite and support controls visible. The owner Restricted-download walkthrough and offline receipt check remain open.
