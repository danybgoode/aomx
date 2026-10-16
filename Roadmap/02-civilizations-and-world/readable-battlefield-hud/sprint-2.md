---
epic: readable-battlefield-hud
sprint: 2
title: "Give contextual commands"
risk: low
phase: Verifying
stories_total: 3
stories:
  - id: S2.1
    title: "Issue visible legal orders"
    as_a: "player"
    i_want: "contextual buttons for my selected actor"
    so_that: "I can gather, build, recruit, move and attack without memorizing keys"
    risk: low
    status: done
  - id: S2.2
    title: "Know why an order did not happen"
    as_a: "player"
    i_want: "target prompts, disabled reasons and brief feedback"
    so_that: "I can correct a failed action quickly"
    risk: low
    status: done
  - id: S2.3
    title: "Keep the battlefield usable"
    as_a: "player on a desktop window"
    i_want: "panels that fit around the board and remain keyboard accessible"
    so_that: "I can still select and command at supported sizes"
    risk: low
    status: done
---
# Readable battlefield HUD — Sprint 2: Give contextual commands

**Status:** ✅ builder verified in `54a0875`; owner and blind walkthroughs remain open at epic close

## Stories

### ✅ Story 2.1 — Issue visible legal orders · `54a0875`
**As a** player, **I want** contextual buttons for the selected actor, **so that** I can gather, build, recruit, move and attack without memorizing keys.
**Acceptance:** The panel shows only relevant current-match orders. Worker gather targets the existing gold cart; posts recruit the actual units at current costs; move and attack use the existing target flow. Mouse buttons, hotkeys and right click reach the same simulation intent. No rules or costs change.
**Risk:** low

### ✅ Story 2.2 — Know why an order did not happen · `54a0875`
**As a** player, **I want** target prompts, disabled reasons and brief feedback, **so that** I can correct a failed action quickly.
**Acceptance:** Unaffordable or unavailable commands explain why; target-required commands show the next click and can be canceled; a successful or rejected order is announced briefly and accessibly.
**Risk:** low

### ✅ Story 2.3 — Keep the battlefield usable · `54a0875`
**As a** player on a desktop window, **I want** panels that fit around the board and remain keyboard accessible, **so that** I can still select and command at supported sizes.
**Acceptance:** At 1280×800 and supported zoom/window sizes, text is not clipped, panels do not intercept board sprites, focus states are visible, and private-alpha invite/support controls remain usable. Contrast and status do not depend on faction color alone.
**Risk:** low

## Sprint QA
- **Godot specs:** Extend client tests for command parity, cancel and unchanged `issue()` result, plus existing rules suite.
- **Rendered smoke owed:** Yes, local Godot at target and supported zoom/window sizes; owner and two arranged blind reviewers attempt uncoached commands on the Restricted download.
- **Deterministic gate:** Godot rules/client, `npm run skirmish:contract`, art manifest validation and export check pass.

## Sprint 2 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 · `godot --path game --editor`, then run `skirmish_main.tscn`

1. Select a worker and choose Gather. → The panel asks for a gold target; clicking the cart starts the existing gathering behavior.
2. Select a post and choose an affordable recruit action. → Gold falls by the existing cost and the unit joins the existing queue.
3. Attempt a costly action with too little gold. → The control explains the cost and no order is issued.
4. Select a fighter, choose Attack, then cancel and choose it again. → Cancel restores normal pointer behavior; a valid enemy click gives order feedback.
5. Resize or zoom, then click a unit near each panel edge. → Selection still works and no interface text is cut off.

If any step fails, note the step number + what you saw — that's the bug report.

## Builder QA · 2026-10-16

The contextual buttons call the existing `issue()` path used by keys and right click. The client check covers gather-button targeting and cancel, a left click on the visible cart, insufficient-gold explanation, actual recruitment cost and queue, build placement, attack targeting, selection loss and read-only refresh. The complete rules/client suite, event contract, art manifest, Node tests and signed macOS preview export pass. Rendered local checks at 1280×800 and 1024×700, including 120% zoom, showed legible focusable controls and uncovered board actors. The local preview-channel copy showed invite and support controls. Uncoached owner and two blind reviewer tasks on a downloaded Restricted build remain open.
