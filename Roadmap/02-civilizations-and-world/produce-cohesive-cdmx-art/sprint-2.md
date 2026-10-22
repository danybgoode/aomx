---
epic: produce-cohesive-cdmx-art
sprint: 2
title: "Place and economy"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Make La Roma a coherent playable place"
    as_a: "RTS player"
    i_want: "recognizable ground, Cibeles, structures and resource sites"
    so_that: "I can read the place and economy while playing"
    risk: low
    status: in-progress
---

# Produce cohesive CDMX game art — Sprint 2: Place and economy

**Status:** 🔎 Builder place pass captured; owner place QA owed.

## Stories

### Story 2.1 — Make La Roma a coherent playable place

**As an** RTS player, **I want** recognizable ground, Cibeles, structures and resource sites, **so that** I can read the place and economy while playing.
**Acceptance:** All current La Roma terrain classes and joins have seam-safe 48×24 top geometry. The center reads as Cibeles and its existing neutral/contested/held states remain obvious. Current building kinds, construction/damage feedback, four resource sites and a restrained set of view-only street props use consistent palette, light and depth. Existing fog, pathing, alpha picking and HUD readability hold. No new role, amount, objective or map location comes from concept art.
**Risk:** low. **QA:** deterministic export and manifest checks; Godot rendered fog, dense-center, construction, resource selection and both objective-state cases; no rule/save/replay hash change.

**Builder evidence:** The separate CDMX pack supplies seam-preserving variants for all four terrain classes, Cibeles and five distinct building silhouettes. The [place capture](../../../docs/screenshots/cdmx-art/place-and-buildings.png) shows construction and damage; resource sites have four shape cues and retain letter/amount labels. Cibeles follows current exploration and district state. Existing jacaranda and flower props remain decorative. Machine contracts pass; owner in-game acceptance is pending.

## Sprint QA

- Check every integrated file's rights, source/export hash, canvas, pivot, footprint, state and runtime role.
- Run Godot rules, client and art checks plus a rendered 100%/125% crowded-board pass.
- Browser smoke: none. Owner in-game place/landmark review remains owed.

## Sprint 2 — Smoke walkthrough

Environment: local Godot scene `res://skirmish_main.tscn` on the La Roma map.

1. Start La Roma and pan across the street and plaza joins. → Ground tiles join without raised seams or false blockers.
2. Select each visible resource site and order a worker to gather. → The site is identifiable and the existing gather order works.
3. Build a structure near the center. → Its construction state, ground contact and selected outline remain visible without hiding units.
4. Contest and then hold Cibeles in the debug district fixture. → The existing contested and held cues are readable; the hold rule does not change.

Record any failed step and a screenshot at the failing zoom.
