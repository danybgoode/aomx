---
epic: build-strategic-opponent
sprint: 2
title: "Adaptive plans and objectives"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S2.1
    title: "Scout and compose"
    as_a: "solo player"
    i_want: "the opponent to respond to discoveries"
    so_that: "counterplay matters"
    risk: high
    status: planned
  - id: S2.2
    title: "Defend and choose an objective"
    as_a: "solo player"
    i_want: "the opponent to defend and change its plan"
    so_that: "both victory routes stay meaningful"
    risk: high
    status: planned
---

# Build a strategic opponent — Sprint 2: Adaptive plans and objectives

**Status:** ⬜ not started

## Stories

### Story 2.1 — Scout and compose
**As a** solo player, **I want** the opponent to respond to discoveries, **so that** composition and counterplay matter.
**Acceptance:** A scout reveals a threat before it changes production; the same threat hidden behind fog does not. Seeded melee/ranged/armored/siege encounters demonstrate production, attack and defense decisions using visible or remembered evidence and legal commands.
**Risk:** high

### Story 2.2 — Defend and choose an objective
**As a** solo player, **I want** the opponent to defend and change its plan, **so that** I can win through a better choice rather than exploiting a script.
**Acceptance:** It contests La Roma, protects a threatened command post, attacks when viable and can switch between Conquest and district pressure after a countered opening. Both routes terminate under the existing precedence rules and remain replayable.
**Risk:** high

## Sprint QA

- Headless Godot specs: visibility changes, four-role counters, defense, failed opening, both objective routes and replay.
- Rendered checks: one assault and one district contest with readable orders and objective feedback.
- Existing warfare performance and client/ingest contracts remain green.

## Sprint 2 — owner smoke walkthrough

Run on the actual Restricted build ID after export; record the ID and result beside each step. A local debug run may check behavior earlier but does not close downloaded-build acceptance.

1. Start a Standard match and scout an enemy production area. → The computer's plan changes only after a visible discovery; the seeded command trace identifies it.
2. Pressure the computer's command post. → Its fighters defend or the report explains why defense was impossible.
3. Contest La Roma, then withdraw. → The district timer resets and the computer can resume or switch to a legal Conquest attack.
