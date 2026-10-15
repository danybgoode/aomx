---
epic: finish-solo-skirmish
sprint: 3
title: "Finish against the computer"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Finish and restart a rule-based solo match"
    as_a: "solo RTS player"
    i_want: "to play a complete battle against the computer"
    so_that: "I can judge the economy, combat and win condition together"
    risk: low
    status: done
---

# Finish a solo skirmish — Sprint 3: Finish against the computer

**Status:** Implemented on `master`. Headless AI, terminal and restart checks pass; controlled rendered win/loss/draw states and a normal authored opening were observed. The Godot-to-ingest contract syncs test traffic with zero public events. A second reviewer verified two outbox fixes. On 2026-10-15 the owner reported completing a downloaded preview match and seeing the pending-sync prompt. The board and instructions were too small on the owner's screen and had no zoom control; this readability defect and the remaining owner sync evidence keep close-out open.

### ✅ Story 3.1 — Finish and restart a rule-based solo match

**As a** solo RTS player, **I want** to play a complete battle against the computer, **so that** I can judge the economy, combat and win condition together.

**Acceptance:** The authored opponent uses the same validated gather, build, produce, move and attack commands as the human. It follows the approved opening: gather, build, recruit mixed units, attack the command post, replace losses when affordable. Destroying its command post wins; losing yours loses; a 15-minute unresolved battle draws. One terminal result is shown and saved once with stable test-tagged IDs. Restart creates a fresh match without duplicate completion. Offline start/result events survive restart and sync to the local audit as test exclusions, never a public cohort.

## Sprint QA

- **Headless rules:** Opponent command legality, win/loss/draw, one-result invariant, restart, replay state equality and outbox deduplication.
- **Rendered client:** Demonstrate a win, loss and draw from controlled local scenarios and a normal opponent opening; inspect visible result and restart.
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

Record the step and visible state if one fails.
