---
epic: deepen-strategic-play
sprint: 1
title: "Complete worker economy"
risk: high
phase: Locking architecture
stories_total: 1
stories:
  - id: S1.1
    title: "Gather four resources and grow a settlement"
    as_a: "returning skirmish player"
    i_want: "physical resource routes, construction, repair and housing"
    so_that: "worker allocation changes what I can build next"
    risk: high
    status: planned
---

# Deepen strategic play — Sprint 1

### Story 1.1 — Gather four resources and grow a settlement

As a returning player, I can send workers to Comida, Materiales, Varos and vacant-lot Terrenos sources, watch cargo reach a valid drop-off, recover from exhaustion or lost drop-off, and build/repair with multiple workers. Housing raises a population cap that constrains recruitment. Each resource is required by at least one useful choice in the same match.

**Acceptance:** Fixed-tick scenarios cover exact stockpile/cargo accounting, bounded replenishment, lost source/drop-off, invalid placement, multi-builder speed, repair, cancellation/refund and population cap. Save/replay reproduce the state. The rendered two-faction match shows understandable routes and disabled reasons.

## Sprint QA

Run `game/tests/` simulation, content, persistence, replay and client checks, `npm run skirmish:contract`, and a rendered economy walkthrough. Record the exact commands and results below before marking the story done.

## Sprint 1 — Smoke walkthrough

1. Open the Godot skirmish and choose each faction in turn. Select a worker and order each of the four sources.
   → The worker visibly carries and deposits the named resource; the stockpile changes only on delivery.
2. Exhaust a source, then wait for its bounded refresh or switch sources; remove a valid drop-off in a controlled scenario.
   → The worker exposes a recoverable state and never creates unearned resources.
3. Build a depot, housing, registry and recruitment post with legal placement; add a second builder, damage and repair a post.
   → Progress and health respond deterministically; invalid placement and insufficient resources explain why.
4. Fill the population cap, then finish housing and recruit again.
   → Recruitment is blocked, then allowed at the new cap; save/replay retain stockpiles, cargo and structures.
