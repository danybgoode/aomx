---
epic: finish-solo-skirmish
sprint: 1
title: "Recruit an army"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S1.1
    title: "Produce a small army from the economy"
    as_a: "solo RTS player"
    i_want: "to gather, construct and recruit worker, melee and ranged units"
    so_that: "I can choose when to invest in my economy or army"
    risk: low
    status: done
---

# Finish a solo skirmish — Sprint 1: Recruit an army

**Status:** Implemented on `master` through integration PR #12. Headless economy/production checks pass; rendered smoke showed gathering, construction, melee and ranged recruitment. Owner display-readability feedback remains open in Sprint 3.

### ✅ Story 1.1 — Produce a small army from the economy

**As a** solo RTS player, **I want** to gather, construct and recruit worker, melee and ranged units, **so that** I can choose when to invest in my economy or army.

**Acceptance:** Both sides start with a command post and worker on one original map. One resource pays for a recruitment building and unit queues. The building produces light melee and ranged units with stable IDs; the command post can produce workers. Costs are charged once, insufficient stockpile is rejected, occupied spawn tiles do not create units, and population/queue state is visible. No age advance or faction bonus is active.

## Sprint QA

- **Headless rules:** Production costs, queue timing, rejection, resource conservation, occupied spawn and deterministic IDs.
- **Rendered client:** See the worker gather, place the recruitment building, queue each role and read unaffordable feedback.
- **Review:** Fresh Godot checkout and test run; ensure the opponent will be able to use the same command interface.

## Sprint 1 — Smoke walkthrough

Env: local Godot 4.7.2 client; run commands in [game/README.md](../../../game/README.md).

1. Start the client, select the worker and gather the single resource.
   → The source falls and stockpile rises after delivery.
2. Construct the recruitment building and order one light melee and one ranged unit.
   → The stockpile drops once per accepted order and two distinct units appear after their queue times.
3. Order a unit with too little stockpile and try to spawn into blocked space.
   → The order gives a reason and creates no free unit.

Record the step and visible state if one fails.
