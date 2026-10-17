---
epic: harden-rts-simulation
sprint: 3
title: "Scale and sync decision"
risk: high
phase: Shaping
stories_total: 1
stories:
  - id: S3.1
    title: "Profile representative battles and decide the sync model"
    as_a: "RTS player"
    i_want: "crowded battles to remain controllable and consistent"
    so_that: "larger maps and later shared play can be built on evidence"
    risk: high
    status: planned
---
# Harden the RTS simulation — Sprint 3: Scale and sync decision

**Status:** ⬜ not started

## Stories

### Story 3.1 — Profile representative battles and decide the sync model

**As an** RTS player, **I want** crowded battles to remain controllable and consistent, **so that** larger maps and later shared play can be built on evidence.

**Acceptance:**

- Define a repeatable matrix before tuning: current 20×20/12-unit baseline plus larger maps, moving crowds, route contention, build/train pressure and a long complete match. Record target device, Godot build, debug/release mode, duration, unit count, tick/frame/memory budgets and measured distribution.
- Improve routing/occupancy only where the matrix shows failure; preserve semantic commands, saves and replay hashes. One representative crowded match is visibly playable without stuck groups or hidden rule changes.
- Replay long command streams on at least two available target environments (for example macOS and Linux headless, then Web if export is ready), with versioned checkpoint hashes. Record any divergence and its first tick.
- Write an ADR comparing deterministic lockstep, authoritative simulation and hybrid approaches against the observed results, reconnect requirements and platform costs. It may defer final transport choice with a named missing experiment; do not implement network transport here.

**Risk:** high — shared simulation performance and future protocol choice. Second reviewer required.

## Sprint QA
- **Headless specs:** replay/hash fixture matrix and extended `game/tests/skirmish_benchmark.gd`; archive machine-readable run settings and results. Existing rules/save tests stay green.
- **Rendered smoke owed:** yes, desktop crowded-state control/readability check. Web or mobile smoke only for an environment actually tested; record omissions.
- **Gate:** benchmark report, cross-environment comparison, ADR and rendered build evidence before review.

## Sprint 3 — Smoke walkthrough (do these in order)
Env: local desktop build for the representative stress fixture, with Godot version, build mode and device noted in the report.

1. Load the declared crowded-match fixture and issue move, gather and attack orders to multiple groups. → Selection, acknowledgements and movement remain readable; units do not stall indefinitely.
2. Save during route contention, quit and resume. → The same groups, orders and resources return; play continues to a terminal result.
3. Run the identical command stream on each declared headless environment. → Checkpoint hashes agree, or the report names the first divergent tick and chosen mitigation.
4. Read the benchmark and sync ADR. → Both name the tested battle size, budgets, evidence, chosen next approach and remaining unknowns.

Record a failed step with fixture, device, build and command sequence.
