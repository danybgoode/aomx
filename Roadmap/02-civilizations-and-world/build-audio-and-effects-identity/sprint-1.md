---
epic: build-audio-and-effects-identity
sprint: 1
title: "Contract and first cue"
risk: low
phase: QA
stories_total: 2
stories:
  - id: S1.1
    title: "Confirm an order"
    as_a: "skirmish player"
    i_want: "distinct accepted and rejected order feedback"
    so_that: "I know whether my command took effect"
    risk: low
    status: done
  - id: S1.2
    title: "Read the same result while muted"
    as_a: "player without sound"
    i_want: "persistent visible order status and saved cue controls"
    so_that: "I can act without hearing the game"
    risk: low
    status: done
---
# Build the audio and effects identity — Sprint 1: Contract and first cue

**Status:** ✅ builder checks passed; downloaded-build check remains in epic QA

## Stories

### ✅ Story 1.1 — Confirm an order
**As a** skirmish player, **I want** distinct accepted and rejected order feedback, **so that** I know whether my command took effect.
**Acceptance:** A documented mapper consumes an accepted command result, emits at most one matching cue, and pairs it with the current flash/notice. A rejected order has a different sound/shape and a plain reason. Multiplayer acknowledgement and local input use the same visible result; replay/resume baseline emits none. Gameplay legality and state hash do not change.
**Risk:** low

### ✅ Story 1.2 — Read the same result while muted
**As a** player without sound, **I want** visible order status and saved cue controls, **so that** I can act without hearing the game.
**Acceptance:** Mute, zero volume and the saved v1 preference silence every gameplay cue, including a new rejected cue. A visual accepted/rejected signal and reason remain. Preferences survive restart; reduced effects do not hide the result.
**Risk:** low

## Sprint QA

Godot client checks for accepted/rejected, one-shot, mute/volume persistence, replay/resume suppression and unchanged simulation hash. Inspect a local rendered order flash at normal zoom. No browser gate in this native slice. The product owner repeats the walkthrough on the signed Restricted build at epic close.

## Sprint 1 — Smoke walkthrough

Env: local Godot 4.7.2 `game/project.godot`; repeat on the signed Restricted owner download from https://danybgoode.itch.io/battle-for-la-roma and record build ID.

1. Start a solo match, select a worker, issue Gather on a visible resource. → One accepted cue plays and the order flash names the action.
2. Issue an illegal build or unaffordable order. → A distinct rejected cue plays and the visible reason explains the failure.
3. In Menu, mute cues and repeat steps 1–2. → No cue plays; both results and reasons stay visible.
4. Close and reopen the game. → Mute persists and no match-state cue plays merely from loading.

Record the build, step, action and observed result if a step fails.
