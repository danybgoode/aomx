---
epic: build-large-la-roma-battlefield
sprint: 1
title: "Large playable start"
risk: high
phase: Locking architecture
stories_total: 1
stories:
  - id: S1.1
    title: "Scout a readable large La Roma"
    as_a: "classic RTS player"
    i_want: "a bicitaxi and a readable home view on a much larger map"
    so_that: "I can choose where to explore before committing my economy or army"
    risk: high
    status: planned
---

# Build a large La Roma battlefield — Sprint 1: Large playable start

**Status:** ⬜ Planned — architecture and baseline comparison before implementation

### Story 1.1 — Scout a readable large La Roma

**As a** classic RTS player, **I want** a bicitaxi and a readable home view on a much larger map, **so that** I can choose where to explore before committing my economy or army.

**Acceptance:** A new large La Roma map loads at 96×96 for all current factions while the original maps remain selectable. Both sides begin with one non-combat bicitaxi; it has greater movement speed and sight than a worker but no attack, gathering, building or passenger action. The opening camera shows readable units at the player's start; fog, minimap and commands expose the wider field without leaking unseen enemies. A 128×128 stress candidate is compared for performance only before final size lock. Save/replay and current 28×28 behavior remain explicit.

**Risk:** high — versioned content, roles, fog, camera, AI and saves.

## Sprint QA

- **Deterministic:** map ID/dimensions, starts, role legality, fog, AI information, save/replay/content hash and old-map compatibility.
- **Rendered:** Godot 4.7.2 at 1280×800 and 1024×700, new readable 100% HUD and default/start/fit board zoom; bicitaxi is pickable and visibly distinct.
- **Review:** independent high-risk pass and measured 96×96/128×128 scale probe before claiming a final size. Owner downloaded-build observation remains open until a signed preview exists.

## Sprint 1 — Smoke walkthrough

Environment: signed Restricted macOS preview, record its exact build ID and download source.

1. Start La Roma Large as Regios. → The base and bicitaxi are readable at a useful default unit size; the whole map is not compressed into the opening view.
2. Select the bicitaxi and issue Move along each side route. → Fog reveals only around its legal sight and the minimap tracks the new position.
3. Try Attack, Gather and Build with the bicitaxi. → The client explains that these actions are unavailable; no rule state changes.
4. Start the old La Roma map, then save and resume. → Its original size and save behavior remain intact.

Record every failure by step and build ID; local captures alone do not close owner QA.
