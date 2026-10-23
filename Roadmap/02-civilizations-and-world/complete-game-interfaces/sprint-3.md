---
epic: complete-game-interfaces
sprint: 3
title: "Finish and verify"
risk: low
phase: Shaping
stories_total: 3
stories:
  - id: S3.1
    title: "Understand the result"
    as_a: "player"
    i_want: "clear victory, defeat and draw screens"
    so_that: "I can tell why the match ended and what to do next"
    risk: low
    status: planned
  - id: S3.2
    title: "Operate without color or audio alone"
    as_a: "keyboard or low-vision player"
    i_want: "focus, scale, reduced motion and redundant status cues"
    so_that: "I can use essential controls"
    risk: low
    status: planned
  - id: S3.3
    title: "Read the human QA result"
    as_a: "product owner"
    i_want: "uncoached task and heuristic findings"
    so_that: "I can decide whether the interface is readable"
    risk: low
    status: planned
---
# Complete the game interfaces — Sprint 3: Finish and verify

**Status:** ⬜ not started

## Stories

### Story 3.1 — Understand the result
**As a** player, **I want** clear victory, defeat and draw screens, **so that** I can tell why the match ended and what to do next.
**Acceptance:** Both victory routes and loss/draw render a stated cause, replay or new-match action and no duplicate completion. Save/resume and replay stay compatible.
**Risk:** low

### Story 3.2 — Operate without color or audio alone
**As a** keyboard or low-vision player, **I want** focus, scale, reduced motion and redundant status cues, **so that** I can use essential controls.
**Acceptance:** Essential controls have focus, keyboard path, visible selection and status, non-color cues and reduced-motion/caption hooks where supported.
**Risk:** low

### Story 3.3 — Read the human QA result
**As a** product owner, **I want** uncoached task and heuristic findings, **so that** I can decide whether the interface is readable.
**Acceptance:** Owner and two uncoached reviewers attempt prewritten setup, select, gather/build, age/research, objective, save/replay and result tasks at normal viewing distance; record passes, misclicks, unreadable labels, hesitation and failure. Inspect all ten NN/g heuristics and resolve severe findings.
**Risk:** low

## Sprint QA
Run client result, focus, save/replay and event checks. Signed Restricted download with full matches and owner/uncoached read remains owed until humans perform it.

## Sprint 3 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. On the signed downloaded build, finish both victory routes, save/resume and open replay. Use keyboard to reach setup, settings and orders. Two fresh players attempt the prewritten tasks; record every unreadable label or missed target.

If a step fails, record the step, build, action and observed result.
