---
epic: complete-game-interfaces
sprint: 1
title: "Choose and recover"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Choose an available match"
    as_a: "new player"
    i_want: "clear faction, map, difficulty and mode choices"
    so_that: "I can start without developer guidance"
    risk: low
    status: done
  - id: S1.2
    title: "Recover or join privately"
    as_a: "returning player"
    i_want: "visible save, replay and Restricted join states"
    so_that: "I can resume or understand why I cannot join"
    risk: low
    status: done
---
# Complete the game interfaces — Sprint 1: Choose and recover

**Status:** 🟡 builder verified; signed owner walkthrough owed

## Stories

### ✅ Story 1.1 — Choose an available match
**As a** new player, **I want** clear faction, map, difficulty and mode choices, **so that** I can start without developer guidance.
**Acceptance:** Only implemented choices appear. Available solo setup explains factions, maps, objectives and difficulty without requiring cultural knowledge.
**Risk:** low

### ✅ Story 1.2 — Recover or join privately
**As a** returning player, **I want** visible save, replay and Restricted join states, **so that** I can resume or understand why I cannot join.
**Acceptance:** Resume and replay paths handle missing, incompatible and bad files with useful text. Private join shows admission-off honestly and preserves existing invite policy.
**Risk:** low

## Sprint QA
Run Godot client, save and replay checks. Capture setup at 1024x700 and 1280x800; owner repeats on a signed download.

Builder result: setup now labels difficulty, battlefield and opponent; the interface size selector is available before play; resume is visible with an explicit no-save disabled state. Existing save/replay/private paths and client checks pass locally. See [interface review](../../../docs/interface-review/qa.md). The admission-off path and a real downloaded save/replay remain owner QA.

## Sprint 1 — Smoke walkthrough
Env: local Godot 4.7.2 at game/project.godot; repeat on the signed Restricted owner build where applicable and record its build ID.

1. Open the downloaded game. Choose a faction, map and difficulty, start, save, quit and resume. Return to setup, open a replay, then inspect admission-off private join; each action has a visible result or reason.

If a step fails, record the step, build, action and observed result.
