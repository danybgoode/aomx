---
epic: deepen-strategic-play
sprint: 2
title: "Four-age progression"
risk: high
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Research and advance through four ages"
    as_a: "returning skirmish player"
    i_want: "army-versus-research choices and legal age advancement"
    so_that: "each phase changes my next plan"
    risk: high
    status: in-progress
---

# Deepen strategic play — Sprint 2

**Status:** 🏗 In progress — merged implementation; downloaded-build progression walkthrough remains open.

### Story 2.1 — Research and advance through four ages

As a player, I can inspect a compact mechanics-first tree, queue/cancel research, see its cost, time and effect, and advance Foránea → Universitaria → Godín → Gentrificación only after explicit prerequisites. Spending on army competes with advancement.

**Acceptance:** Content rejects unknown IDs, prerequisite cycles and invalid effects. Fixed-tick scenarios verify cost/time/refund, each effect applied once, all three age gates, insufficient-resource and missing-prerequisite reasons, save/load and replay hash. The HUD remains readable at 1024×700 and enlarged zoom.

## Sprint QA

Run content, simulation, save/replay, cross-platform hash and client checks. Perform a rendered progression walkthrough with a real queue and disabled reason.

## Sprint 2 — Smoke walkthrough

1. In Foránea, inspect the next age before and after housing and a depot complete.
   → The control names each missing prerequisite, then offers a priced, timed transition.
2. Advance to Universitaria; research `carry_capacity_i`, then build a registry and advance to Godín.
   → Worker carry rises once, and the next gate opens only after its requirements pass.
3. Research `construction_rate_i`, build a recruitment post, advance to Gentrificación and research `combat_training_i`.
   → Each effect and age is visible, charged once, and preserved after save/quit/resume.
4. Cancel a queued research or age transition in a controlled scenario.
   → The declared refund applies and replay reaches the same hash.

## QA record, 2026-10-17

`strategic_progression_test.gd` passed all age prerequisites, three technology effects, costs, queue/cancel/refund and gates. Persistence/replay tests passed strategic state round-trip, deterministic continuation and explicit rejection of older saves without deletion. Client tests exercised player cancellation of paid age and research orders and save/resume through an active age queue and completed technology. Downloaded-build observation remains open.
