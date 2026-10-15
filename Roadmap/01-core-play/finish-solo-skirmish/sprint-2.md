---
epic: finish-solo-skirmish
sprint: 2
title: "Fight for the command post"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Command literal unit and structure combat"
    as_a: "solo RTS player"
    i_want: "to attack with two readable combat roles"
    so_that: "I can make a tactical choice and see its effect"
    risk: low
    status: done
---

# Finish a solo skirmish — Sprint 2: Fight for the command post

**Status:** Implemented on `master` through integration PR #12. Headless combat, destruction, range and deterministic replay checks pass; rendered client shows unit and command-post damage. Owner display-readability feedback remains open in Sprint 3.

### ✅ Story 2.1 — Command literal unit and structure combat

**As a** solo RTS player, **I want** to attack with two readable combat roles, **so that** I can make a tactical choice and see its effect.

**Acceptance:** Validated attack orders target an opposing unit or building. Fixed-tick range, damage, cooldown and health rules make controlled encounters repeatable. Melee must close to attack; ranged can fire at a distance but is vulnerable nearby. Death and structure destruction are visible and remove occupancy. Orders against dead, friendly or unreachable targets fail or resolve with clear feedback. An identical command log reaches the same state hash on the pinned build.

## Sprint QA

- **Headless rules:** Melee/ranged range, cooldown, death, building destruction, target invalidation, reroute after destruction and replay equality.
- **Rendered client:** Select units, attack an opposing unit and command post, read health/damage feedback, and observe the cleared footprint.
- **Review:** Measure declared unit counts and path latency; keep combat stylized and non-graphic.

## Sprint 2 — Smoke walkthrough

Env: local Godot 4.7.2 client; run commands in [game/README.md](../../../game/README.md).

1. Recruit melee and ranged units, then order each to attack an opposing unit.
   → Melee closes range, ranged attacks from farther away, and both show health changes.
2. Destroy an opposing building and move through its old footprint.
   → The building disappears and its tile becomes traversable.
3. Order an attack on an invalid or unreachable target.
   → The order produces a reason and never damages a different target.

Record the step and visible state if one fails.
