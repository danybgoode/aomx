---
epic: readable-battlefield-hud
sprint: 3
title: "Visual RTS HUD"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Build the approved gameplay interface in Godot"
    as_a: "solo skirmish player"
    i_want: "a visual, contextual HUD across desktop and mobile"
    so_that: "I can understand the match and issue orders without reading debug prose"
    risk: low
    status: done
---
# Readable battlefield HUD — Sprint 3: Visual RTS HUD

**Status:** ✅ builder verified in `3bd83c0`; owner and two uncoached reviews remain open at epic close

### ✅ Story 3.1 — Build the approved gameplay interface in Godot · `3bd83c0`

Replace the alpha's three prose-heavy panels with a responsive top bar and contextual bottom command bar. Add sprite portraits, health, icon orders with available/disabled/active states, a real minimap, objective progress, notifications, group selection, production context, and a hidden alpha support area. Preserve the one-resource economy, validated command semantics, outbox and invite flow. Cover desktop, web, mobile landscape and portrait, and provide four actual game captures next to the approved reference.

**Acceptance evidence:** `game/tests/skirmish_client_test.gd`, the Godot rules tests, Node tests, Web export browser capture, and `docs/screenshots/readable-hud/`. Owner and two uncoached reviewers still need to play the downloaded Restricted build before the epic can close.

## Sprint QA

- Godot rules/client, Node, art manifest and event contract checks passed. The signed macOS export from merged `1d1349249f14` passed strict signature verification and started locally.
- Desktop and mobile viewport captures are linked in the screenshot README. The Web release export rendered in Chrome at desktop and 390×844; a mobile touch tap selected a worker.
- [Downloaded-build walkthrough](../../../docs/alpha-local-qa.md) and two uncoached reviewer playthroughs remain owner evidence.

## Sprint 3 — Local walkthrough

1. Start `skirmish_main.tscn`, choose Regios and select a worker. Confirm the top gold counter, sprite portrait, HP and Move/Gather/Build icons. Build starts disabled at zero gold with its reason in the construction area.
2. Click Gather, then the friendly cart. Confirm the worker's existing order and gold counter update after delivery. Re-select the worker, choose Build and inspect valid/invalid placement colors; Escape cancels.
3. Select the command post, recruit a worker and confirm queue and gold changes. Select a fighter, then shift-click another and tap a group portrait to select one member. Only shared legal commands should appear for a group.
4. Click two minimap locations and confirm the battlefield camera moves. Collapse/expand Objectives, pause/resume, and open **...** for invite, support and event history.
5. Repeat at 1536×960, 1920×1080, 844×390 and 390×844. In portrait, use **Options** to reveal context. Compare the resulting screenshots to the approved reference and record clipped or unclear elements.
