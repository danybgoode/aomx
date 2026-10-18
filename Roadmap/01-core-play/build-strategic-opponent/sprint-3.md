---
epic: build-strategic-opponent
sprint: 3
title: "Difficulty ladder and human read"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S3.1
    title: "Ladder and scenario report"
    as_a: "solo player"
    i_want: "levels with observable strategic differences"
    so_that: "I can choose my next challenge"
    risk: high
    status: planned
  - id: S3.2
    title: "Human clarity read"
    as_a: "solo player"
    i_want: "difficulty descriptions that match play"
    so_that: "I can trust the choice"
    risk: low
    status: planned
---

# Build a strategic opponent — Sprint 3: Difficulty ladder and human read

**Status:** ⬜ not started

## Stories

### Story 3.1 — Ladder and scenario report
**As a** solo player, **I want** observable differences between levels, **so that** I can choose my next challenge.
**Acceptance:** Content documents the exact policy deltas with identical unit/economy/sight rules. A fixed matrix spans both factions, three levels, multiple openings and at least two scenario seeds; its versioned report includes legal/rejected commands, stalls, outcomes, duration, resource/army trajectories and AI performance. Save/replay and macOS/Linux headless hashes agree on declared cases.
**Risk:** high

### Story 3.2 — Human clarity read
**As a** solo player, **I want** difficulty descriptions that match play, **so that** the choice feels fair.
**Acceptance:** After notice/invitation approval, four uncoached players (two culturally familiar, two unfamiliar) try all three levels. At least three rank the intended challenge order and name one counter. Record exact fairness objections, fixes and remaining gaps; no fabricated cohort or retention result.
**Risk:** low

## Sprint QA

- Headless Godot batch and report audit; regression suite, cross-platform hash, performance and Node event contract.
- Signed Restricted macOS download, full-match checks for both factions/levels/routes, save/resume and excluded test-event receipt.
- Human protocol and results require approved private-alpha access; report any unrun portion as owed.

## Sprint 3 — owner smoke walkthrough

Run on the actual Restricted build ID after export; record the ID and result beside each step. A local debug run may check behavior earlier but does not close downloaded-build acceptance.

1. Download the signed Restricted build using the approved owner channel and start each level. → The descriptions match the distinct reaction and composition seen in its scenario report.
2. Finish a full match as Regios and Poblanos across Conquest and La Roma routes. → Each terminal result appears once and save/resume keeps the chosen level.
3. Sync one preview completion through Menu after ingest compatibility is deployed. → One stable test receipt appears and public cohort count remains unchanged.
4. With approved notice and invitations, run the four-player uncoached protocol. → The recorded rankings, counter explanations and fairness objections are available for review.
