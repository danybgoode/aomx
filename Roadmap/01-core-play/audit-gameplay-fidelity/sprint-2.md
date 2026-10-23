---
epic: audit-gameplay-fidelity
sprint: 2
title: "Compare playable behavior"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Trace the current game"
    as_a: "product owner"
    i_want: "a scenario matrix with source and build evidence"
    so_that: "I can tell working behavior from aspiration"
    risk: low
    status: done
---
# Audit gameplay fidelity against a pinned RTS reference — Sprint 2: Compare playable behavior

**Status:** 🟡 builder evidence complete; owner reference and exception review owed

## Stories

### ✅ Story 2.1 — Trace the current game
**As a** product owner, **I want** a scenario matrix with source and build evidence, **so that** I can tell working behavior from aspiration.
**Acceptance:** Sample all ten scoped domains; each row has exact source/test references, commands/results, a build ID for rendered claims and verified/partial/planned/absent/unknown classification.
**Risk:** low

## Sprint QA
Run representative Godot economy, warfare, world, replay and AI checks; record versions and failures. Observe selected cases in a real local game build.

## Sprint 2 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. Open the matrix and pick three rows: gathering, fog and a terminal outcome. Re-run the named test or play the stated action; compare the recorded observation to the visible result.

If a step fails, record the step, build, action and observed result.

## Builder evidence · 2026-10-22

- Ten-domain source/test matrix recorded at docs/fidelity/audit-2026-10-22.md; twelve Godot suites passed. Downloaded-build observations remain owed.
