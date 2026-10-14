---
epic: prove-rts-core
sprint: 3
title: "A3 Build and replay"
risk: low
phase: Shaping
stories_total: 2
stories:
  - id: S3.1
    title: "Spend stockpile on a structure"
    as_a: "classic RTS player"
    i_want: "to place and construct one useful structure"
    so_that: "my economic work changes the map"
    risk: low
    status: planned
  - id: S3.2
    title: "Replay the prototype and review the engine"
    as_a: "product owner"
    i_want: "a repeatable run and measured prototype limits"
    so_that: "I can decide whether to continue into the solo skirmish"
    risk: low
    status: planned
---
# Prove the RTS core — Sprint 3: A3 Build and replay

**Status:** ⬜ not started

## Stories

### Story 3.1 — Spend stockpile on a structure

**As a** classic RTS player, **I want** to place and construct one useful structure, **so that** my economic work changes the map.

**Acceptance:** The player previews a footprint, spends the required stockpile once and orders a worker to build. Unaffordable, blocked or overlapping placements are rejected without spending. Construction progresses to a complete structure with visible feedback. Its footprint affects subsequent movement; a blocked path is rerouted or rejected clearly.

**Risk:** low

### Story 3.2 — Replay the prototype and review the engine

**As a** product owner, **I want** a repeatable run and measured prototype limits, **so that** I can decide whether to continue into the solo skirmish.

**Acceptance:** A versioned local test record contains stable run and command IDs, content/build version, sequence and a test flag. Replaying a scripted move/gather/build sequence on the pinned development build ends with the same positions, source amount, stockpile and building state. No eligible match start or result is emitted. Record fresh-checkout boot steps, frame time and pathing observations at a declared small scale; write a continue/revisit decision against ADR 001 with the evidence and limitations.

**Risk:** low

## Sprint QA

- **Headless rule checks:** Construction costs are charged once; invalid placement leaves stockpile unchanged; the completed footprint changes movement; two runs of the same command fixture end at the same state.
- **Rendered client smoke:** Preview, rejection, construction completion and a route around or rejection at the new structure are visible.
- **Review evidence:** Replay state comparison, pinned Godot/build/content versions, frame-time and pathing notes, and the recorded engine decision.

## Sprint 3 — Smoke walkthrough (do these in order)

Env: local Godot project, using the run command recorded by sprint 1.

1. Gather enough resource and open the one-structure placement preview.
   → The footprint and cost are visible before committing.
2. Try an overlapping or unaffordable placement, then place a valid structure and order the worker to construct it.
   → Invalid placement spends nothing; valid placement spends once and construction completes.
3. Order the worker across the completed footprint.
   → It goes around the structure or receives a clear unreachable-order reason.
4. Run the documented replay fixture twice.
   → The reported end-state values match, and the run is marked as test traffic with no match completion.

If a step fails, record its number and what appeared in the client.
