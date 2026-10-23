---
epic: build-audio-and-effects-identity
sprint: 2
title: "Match-state pack"
risk: low
phase: Locking architecture
stories_total: 2
stories:
  - id: S2.1
    title: "Notice economy and construction"
    as_a: "skirmish player"
    i_want: "restrained progress cues"
    so_that: "I can follow my economy without alert fatigue"
    risk: low
    status: planned
  - id: S2.2
    title: "Notice threats and objective changes"
    as_a: "skirmish player"
    i_want: "prioritized, visibility-safe danger cues"
    so_that: "I can react during combat without losing the board"
    risk: low
    status: planned
---
# Build the audio and effects identity — Sprint 2: Match-state pack

**Status:** ⬜ planned

## Stories

### Story 2.1 — Notice economy and construction
**As a** skirmish player, **I want** restrained progress cues, **so that** I can follow my economy without alert fatigue.
**Acceptance:** Gather/delivery milestones and friendly construction completion get original, traced cues and visible equivalents. Repeated ticks coalesce or suppress; the pack obeys its voice cap and lower economy priority. Reduced effects preserve readiness labels and non-color-only status.
**Risk:** low

### Story 2.2 — Notice threats and objective changes
**As a** skirmish player, **I want** prioritized, visibility-safe danger cues, **so that** I can react during combat without losing the board.
**Acceptance:** Damage/destruction and objective contest/hold transitions cue only when visible/owned as defined in the contract. Threat/objective interrupts routine economy within the bounded mix. Cosmetic VFX never obscure the unit, selection ring, HUD, fog or command target and never alter rules or replay hash. Muted/reduced-effects paths expose equivalent readable states.
**Risk:** low

## Sprint QA

Godot client tests exercise state transitions, tick repetition limits, priorities, ownership/fog, reduced effects and unchanged rules hash. Capture normal and crowded board states at 100% and 125% zoom; compare measured frame and simultaneous-voice costs to the recorded baseline and owner-approved budgets. No Web/mobile device claim.

## Sprint 2 — Smoke walkthrough

Env: local Godot 4.7.2 `game/project.godot`; repeat on the signed Restricted owner download from https://danybgoode.itch.io/battle-for-la-roma and record build ID.

1. Gather and deliver resources, then complete a building. → Distinct, bounded economy/completion cues accompany visible activity or completion text.
2. Fight near the center until a friendly unit takes damage and the objective changes hands. → Threat and objective cues take precedence; the board and selection remain readable.
3. Mute cues and enable reduced effects; repeat the combat/center observation. → Text and non-color-only markers still identify threat and objective state.
4. Resume a save or seek replay. → Loading the baseline does not replay old warnings.

Record the build, step, action and observed result if a step fails.
