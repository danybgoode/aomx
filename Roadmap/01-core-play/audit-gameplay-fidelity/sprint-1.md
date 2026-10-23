---
epic: audit-gameplay-fidelity
sprint: 1
title: "Pin reference contract"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S1.1
    title: "Pin an observable reference"
    as_a: "product owner"
    i_want: "an exact DE build, setup and tolerance policy"
    so_that: "I can judge every later comparison"
    risk: low
    status: done
---
# Audit gameplay fidelity against a pinned RTS reference — Sprint 1: Pin reference contract

**Status:** 🟡 builder evidence complete; owner reference and exception review owed

## Stories

### ✅ Story 1.1 — Pin an observable reference
**As a** product owner, **I want** an exact DE build, setup and tolerance policy, **so that** I can judge every later comparison.
**Acceptance:** Record actual installed build or mark numerical comparison unavailable; document one economy and one combat scenario with mode, settings, setup, timing and evidence location.
**Risk:** low

## Sprint QA
Check official DE release notes, ADR 002 and the observed installed build. Owner decides any exception before it becomes a rule.

## Sprint 1 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. Open the audit contract. Confirm the DE build field and reproduce the economy and combat setups; each has an observation and tolerance, or an explicit unknown.

If a step fails, record the step, build, action and observed result.

## Builder evidence · 2026-10-22

- Reference contract recorded at docs/fidelity/reference-contract.md; the observed DE installation and owner exception approval remain owed.
