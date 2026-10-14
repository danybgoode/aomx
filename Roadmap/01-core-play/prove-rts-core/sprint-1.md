---
epic: prove-rts-core
sprint: 1
title: "A1 Command a worker"
risk: low
phase: Shaping
stories_total: 1
stories:
  - id: S1.1
    title: "Select and move a worker"
    as_a: "classic RTS player"
    i_want: "to select a worker and issue a move order"
    so_that: "I can tell whether the game obeyed or rejected my command"
    risk: low
    status: planned
---
# Prove the RTS core — Sprint 1: A1 Command a worker

**Status:** ⬜ not started

## Stories

### Story 1.1 — Select and move a worker

**As a** classic RTS player, **I want** to select a worker and issue a move order, **so that** I can tell whether the game obeyed or rejected my command.

**Acceptance:** A fresh checkout opens the pinned Godot project and an original map. Clicking the worker shows selection; a reachable order moves it to the intended place. An unreachable or invalid order leaves state unchanged and gives visible feedback. Movement and rejection go through a validated fixed-tick command/state boundary; game outcomes do not depend on frame rate or Godot physics. Record the exact engine version and local run commands.

**Risk:** low

## Sprint QA

- **Headless rule check:** Reachable move changes position; invalid and unreachable orders leave position unchanged with a reason.
- **Rendered client smoke:** Mouse selection, command marker, worker movement and rejection feedback are visible in the running Godot client.
- **Review evidence:** Fresh-checkout boot command, pinned version and a short capture or walkthrough of both move paths.

## Sprint 1 — Smoke walkthrough (do these in order)

Env: local Godot project, using the run command recorded by this sprint.

1. Open the original test map and click the worker.
   → The worker is visibly selected and its next order can be issued.
2. Order the worker to a reachable point.
   → It travels there and stops at the intended destination.
3. Order the worker to an unreachable point.
   → It stays on a valid path or position, and the UI explains why the order failed.

If a step fails, record its number and what appeared in the client.
