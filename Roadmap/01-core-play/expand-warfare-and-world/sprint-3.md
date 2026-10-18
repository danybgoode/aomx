---
epic: expand-warfare-and-world
sprint: 3
title: "Complete both victory routes"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S3.1
    title: "Finish by explicit Conquest or La Roma rules"
    as_a: "classic RTS player"
    i_want: "each victory route to resolve clearly"
    so_that: "I know what to defend and why the match ended"
    risk: high
    status: in-progress
  - id: S3.2
    title: "Finish the larger match as either faction"
    as_a: "classic RTS player"
    i_want: "a complete match against the computer"
    so_that: "the new battlefield is a replayable game, not isolated mechanics"
    risk: high
    status: in-progress
---

# Expand warfare and world — Sprint 3: Complete both victory routes

**Status:** 🟦 In review — deterministic victory rules and ingest contract pass; four downloaded-build matches remain open.

### Story 3.1 — Finish by explicit Conquest or La Roma rules

**As a** classic RTS player, **I want** each victory route to resolve clearly, **so that** I know what to defend and why the match ended.

**Acceptance:** Destroying the final non-rebuildable command post ends Conquest even if other units/buildings survive. The adapted central La Roma footprint and fixed hold duration are versioned, visible, uncontested and reset on contest or empty ground. A simultaneous post loss takes precedence. Draw and one-terminal-event semantics remain explicit; save/resume cannot duplicate a completion.

**Risk:** high — terminal state and measured results.

### Story 3.2 — Finish the larger match as either faction

**As a** classic RTS player, **I want** a complete match against the computer, **so that** the new battlefield is a replayable game, not isolated mechanics.

**Acceptance:** The legal-command computer can scout, counter, defend and attack both objectives without seeing hidden live state. In a downloaded Restricted build the owner finishes four faction×victory combinations, including one save/resume and test-tagged event sync. A representative release-build owner Mac performance record meets the declared budget or records the gap and deliberate scope decision. The signed archive and downloaded app match; no public cohort or invitation is claimed.

**Risk:** high — whole-match correctness, AI, performance and result integrity.

## Sprint QA

- **Deterministic specs:** terminal precedence, contest/empty reset, legal AI information, two faction×two victory scenarios, save/replay hashes and one match-completed event through the existing game-to-ingest contract.
- **Rendered smoke:** complete downloaded matches on the signed Restricted owner build, both desktop sizes/zoom states, including counters, siege and each terminal reason.
- **Gate:** full Godot/Node/CI suite, release-build performance evidence, independent high-risk review, PR/merge verification and downloaded-build checksum/signature check.

## Sprint 3 — Smoke walkthrough

Environment: the signed Restricted macOS preview; record actual build ID, checksum and download source.

1. Download, open and start as Regios; destroy the last enemy command post with surviving enemy units elsewhere. → Conquest ends once with its stated reason.
2. Start as Poblanos; occupy La Roma, then let an enemy fighter contest it. → The timer resets and the contest is shown.
3. Clear La Roma, hold it for the configured duration and finish. → The La Roma result appears once with correct timer and terminal event.
4. Repeat the alternate victory route as each faction. → All four faction×route combinations finish without stuck armies or unreadable feedback.
5. Save, quit, resume, finish and sync the test event. → Match ID persists, one test-tagged completion is accepted and public cohort counts exclude it.

Record one result per step and any owed gap. A merged PR alone does not complete the sprint or epic.
