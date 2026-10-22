---
epic: produce-cohesive-cdmx-art
sprint: 3
title: "Units and state"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S3.1
    title: "Read roles and factions in a dense match"
    as_a: "RTS player"
    i_want: "distinct unit roles and faction cues during movement and combat"
    so_that: "I can command the right unit without relying on color or local jokes"
    risk: low
    status: in-progress
---

# Produce cohesive CDMX game art — Sprint 3: Units and state

**Status:** 🟦 In review — builder role/faction matrix captured; owner clarity QA owed.

## Stories

### Story 3.1 — Read roles and factions in a dense match

**As an** RTS player, **I want** distinct unit roles and faction cues during movement and combat, **so that** I can command the right unit without relying on color or local jokes.
**Acceptance:** The existing worker, melee, ranged, armored and siege roles have readable silhouettes and an internally consistent current-action treatment. All four selectable factions have recognizable marks beyond team color while friendly/enemy ownership stays unmistakable. Selection, hover, health, order, fog and damage cues remain legible in crowded fights at 100%, 125% and fit zoom. The unit assets add no collision, rule or ability.
**Risk:** low. **QA:** inspect current-role/faction matrix in Godot, check selection of partly obscured bodies, manifest/animation validation, simulation/save/replay hashes and client checks.

**Builder evidence:** [Four actual-scene faction captures](../../../docs/screenshots/cdmx-art/README.md) include both teams and all five current roles. Neutral source sprites gain a small faction letter/shape plus blue/red ownership border; armored and siege retain role marks. Facing, movement bob, HP, selected/hovered, combat, construction and damage overlays follow current state. The existing client test confirms alpha worker selection; a partly obscured-unit manual check and uncoached readability remain open.

## Sprint QA

- Capture all five roles across four faction choices in a fixed match state, including selected, damaged and moving examples.
- Run deterministic export/art/client tests and compare before/after rule and replay hashes.
- Browser smoke: none. Owner role and faction clarity review remains owed.

## Sprint 3 — Smoke walkthrough

Environment: local Godot scene `res://skirmish_main.tscn` on La Roma.

1. Start as each selectable faction in turn. → Its non-color emblem or shape cue appears while friendly/enemy cues stay distinct.
2. Recruit or view the five current unit roles. → Worker, melee, ranged, armored and siege are distinguishable by silhouette and function cue.
3. Select a unit partly covered by another actor or prop. → The intended unit is selected and its ring, health and order feedback remain visible.
4. Move and attack in a crowded-center fixture. → Unit motion and damage read without obscuring the Cibeles control state.

Record every misidentified role or failed selection for the final uncoached read.
