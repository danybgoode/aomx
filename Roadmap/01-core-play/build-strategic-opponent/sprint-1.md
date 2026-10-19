---
epic: build-strategic-opponent
sprint: 1
title: "Fair planner and recovery"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Fair planner and level choice"
    as_a: "solo player"
    i_want: "to choose an explained opponent level"
    so_that: "I know the challenge and it follows my rules"
    risk: high
    status: in-progress
  - id: S1.2
    title: "Economy and recovery"
    as_a: "solo player"
    i_want: "an opponent that recovers from economic setbacks"
    so_that: "a match stays contestable"
    risk: high
    status: in-progress
---

# Build a strategic opponent — Sprint 1: Fair planner and recovery

**Status:** 🟦 In review — local level UI, hidden-information, recovery, save/replay and contract checks pass; downloaded-build owner steps remain open.

## Stories

### Story 1.1 — Fair planner and level choice
**As a** solo player, **I want** to choose an explained level, **so that** I know the challenge and can trust its rules.
**Acceptance:** Three named levels appear with plain descriptions before a match. The chosen level survives save/resume and replay. The planner issues only validated commands and cannot react to an unseen live enemy; a last-seen location only guides a search.
**Risk:** high

### Story 1.2 — Economy and recovery
**As a** solo player, **I want** the opponent to recover from setbacks, **so that** the match stays contestable.
**Acceptance:** It allocates workers among four resources, builds and advances legally, and revises plans after depletion, lost drop-off, blocked placement, unavailable route, population cap or unaffordable queue. A genuine dead end is classified in a report instead of silently repeated.
**Risk:** high

## Sprint QA

- Headless Godot specs: setup/visibility, legal command trace, physical economy disruption, persistence and replay hashes for both factions.
- Rendered checks: level selection and save/resume in Godot 4.7.2 at normal and enlarged zoom.
- Contract gate: existing Godot suite and `npm run skirmish:contract` remain green.

## Sprint 1 — owner smoke walkthrough

Run on the actual Restricted build ID after export; record the ID and result beside each step. A local debug run may check behavior earlier but does not close downloaded-build acceptance.

1. Open the downloaded app and choose each level on the faction screen. → Its plain behavior description appears before match start.
2. Start a Standard match, save through Menu, quit and choose Resume saved match. → The match resumes with Standard and its previous economy intact.
3. In a controlled test build, remove the computer's current resource or drop-off. → It resumes a legal route or the scenario report gives a specific dead-end reason.
