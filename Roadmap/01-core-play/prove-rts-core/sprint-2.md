---
epic: prove-rts-core
sprint: 2
title: "A2 Gather and deliver"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Gather and bank one resource"
    as_a: "classic RTS player"
    i_want: "my worker to gather and deliver a resource"
    so_that: "I can turn a map choice into a visible economic gain"
    risk: low
    status: in-progress
---
# Prove the RTS core — Sprint 2: A2 Gather and deliver

**Status:** Local headless checks and rendered walkthrough passed; independent fresh-checkout review and merge pending. Run commands: [game/README.md](../../../game/README.md).

## Stories

### Story 2.1 — Gather and bank one resource

**As a** classic RTS player, **I want** my worker to gather and deliver a resource, **so that** I can turn a map choice into a visible economic gain.

**Acceptance:** On the existing map, the selected worker can reach a resource, gather up to its carry limit, return to a drop-off and increase the visible stockpile once. The source visibly depletes. Interrupting and resuming gathering preserves carried and source amounts; a full or empty edge case does not create resources. Invalid orders show feedback. Use the sprint 1 command/state rules rather than a separate resource simulation.

**Risk:** low

## Sprint QA

- **Headless rule check:** Source, carried amount and stockpile conserve resources through delivery, interruption, depletion and repeated orders.
- **Rendered client smoke:** The worker travels, gathers, delivers and the visible stockpile changes exactly once.
- **Review evidence:** A before/after resource ledger from a scripted scenario and the local game walkthrough.

## Sprint 2 — Smoke walkthrough (do these in order)

Env: local Godot project, using the run command recorded by sprint 1.

1. Select the worker and order it to the resource source.
   → It reaches the source and begins gathering, with carried amount visible.
2. Let it deliver to the drop-off.
   → The stockpile rises by the carried amount and the source falls by the same amount.
3. Start another gather order, interrupt it with a move, then resume gathering until the source is empty.
   → No resource is counted twice; the worker receives clear feedback when the source is depleted.

If a step fails, record its number and what appeared in the client.
