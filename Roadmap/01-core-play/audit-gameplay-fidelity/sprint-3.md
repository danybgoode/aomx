---
epic: audit-gameplay-fidelity
sprint: 3
title: "Decide gaps and exceptions"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Order the follow-on work"
    as_a: "product owner"
    i_want: "ranked gaps and proposed rule exceptions"
    so_that: "I can choose the next mechanics bet"
    risk: low
    status: done
---
# Audit gameplay fidelity against a pinned RTS reference — Sprint 3: Decide gaps and exceptions

**Status:** 🟡 builder evidence complete; owner reference and exception review owed

## Stories

### ✅ Story 3.1 — Order the follow-on work
**As a** product owner, **I want** ranked gaps and proposed rule exceptions, **so that** I can choose the next mechanics bet.
**Acceptance:** Rank each gap by player impact, dependency and evidence; route it to an existing epic or new seed; separate mechanical, behavioral and experiential fidelity. Mark Terrenos, local objectives and neighborhood modifiers as owner decisions.
**Risk:** low

## Sprint QA
Review matrix provenance and replayable scenarios. Owner decision on exception policy remains owed. No gameplay code changes in this spike.

## Sprint 3 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. Open the decision record. For each top priority, follow its matrix row and evidence; accept or revise the proposed exception and next home.

If a step fails, record the step, build, action and observed result.

## Builder evidence · 2026-10-22

- Ranked follow-on and exception decision recorded at docs/fidelity/decision.md; owner acceptance remains owed.
