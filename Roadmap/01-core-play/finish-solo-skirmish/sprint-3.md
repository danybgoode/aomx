---
epic: finish-solo-skirmish
sprint: 3
title: "Finish against the computer"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S3.1
    title: "Finish and restart a rule-based solo match"
    as_a: "solo RTS player"
    i_want: "to play a complete battle against the computer"
    so_that: "I can judge the economy, combat and win condition together"
    risk: low
    status: done
  - id: S3.2
    title: "Read the board and see orders take effect"
    as_a: "solo RTS player"
    i_want: "legible controls and visible confirmation of my orders"
    so_that: "I can understand what happened after selecting or commanding a unit"
    risk: low
    status: done
---

# Finish a solo skirmish — Sprint 3: Finish against the computer

**Status:** The owner completed a downloaded preview match and saw the pending-sync prompt on 2026-10-15. The follow-up client slice adds board zoom, window scaling, larger HUD/instructions and visible order feedback. Local rendered selection, gathering, zoom and fullscreen checks passed, as did the four Godot suites, Node tests and Godot-to-ingest contract. A new downloaded preview and owner sync receipt remain epic close-out evidence.

### ✅ Story 3.1 — Finish and restart a rule-based solo match

**As a** solo RTS player, **I want** to play a complete battle against the computer, **so that** I can judge the economy, combat and win condition together.

**Acceptance:** The authored opponent uses the same validated gather, build, produce, move and attack commands as the human. It follows the approved opening: gather, build, recruit mixed units, attack the command post, replace losses when affordable. Destroying its command post wins; losing yours loses; a 15-minute unresolved battle draws. One terminal result is shown and saved once with stable test-tagged IDs. Restart creates a fresh match without duplicate completion. Offline start/result events survive restart and sync to the local audit as test exclusions, never a public cohort.

### ✅ Story 3.2 — Read the board and see orders take effect

**As a** solo RTS player, **I want** legible controls and visible confirmation of my orders, **so that** I can understand what happened after selecting or commanding a unit.

**Acceptance:** The macOS preview scales to the window and offers a discoverable board zoom control. The HUD, instructions, and invite control remain readable at the normal window size and when expanded. Selection is visible on the board; successful and rejected move, gather, build, train and attack orders produce short, distinct feedback at the relevant tile and a readable reason in the HUD. Mouse hit testing remains accurate at every supported zoom level. The existing simulation and test-tagged event contract remain unchanged.

## Sprint QA

- **Headless rules:** Opponent command legality, win/loss/draw, one-result invariant, restart, replay state equality and outbox deduplication.
- **Rendered client:** Demonstrate a win, loss and draw from controlled local scenarios and a normal opponent opening; inspect visible result and restart.
- **Readability and orders:** At normal and full-screen sizes, inspect the board, HUD and controls. Select a worker, give a gather order, observe its tile marker and Last action line; zoom and repeat the click. Check a rejected build has red feedback and a reason. The headless client check covers tile hit testing at 100%, 110% and 125%.
- **Measurement:** Check local audit IDs/receipts and no eligible cohort count. Record multi-unit frame/path evidence and Godot continue/revisit decision.
- **Review:** Second reviewer checks player-data fields, local durability, secrets and match-result integrity with the funnel contract.

## Sprint 3 — Smoke walkthrough

Env: local Godot 4.7.2 client and loopback ingest; run commands in [game/README.md](../../../game/README.md).

1. Play a solo match while ingest is offline, destroy the opposing command post and reopen the client.
   → A win result and its stable event ID remain saved and pending.
2. Reconnect and inspect the local audit.
   → One test-tagged start and one test-tagged completion sync for that match; neither enters public cohorts.
3. Exercise a controlled loss and a 15-minute draw, then restart.
   → Each result appears once; restart has new match state and ID.
4. Inspect the multi-unit performance and replay check.
   → The recorded device, unit count, map size, frame time and final state hashes support an explicit engine review.
5. At normal window size and fullscreen, select a blue worker, order gold gathering, zoom and click a visible tile again.
   → The selection and order marker follow the clicked tile; HUD and controls remain readable, and rejected build placement has a distinct reason.

Record the step and visible state if one fails.
