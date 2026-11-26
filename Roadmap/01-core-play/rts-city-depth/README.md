---
status: scaffolded
phase: Shaping
slug: rts-city-depth
title: "RTS city depth: faction verbs, city events and a contested Cibeles"
area: 01-core-play
destination: full-depth-rts
type: feature
risk: high
sprints_total: 2
stories_total: 4
underwritten_by: wave-2026-11
build_order: 32
---

# RTS city depth: faction verbs, city events and a contested Cibeles

## Why

Each faction gets one verb and each archetype one ability, all of them things AoE2 can't have. The city fights back with events that have counterplay, and Cibeles becomes escalating control you fight over instead of a timer you sit on. This is where the RTS gets depth that belongs to La Roma.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Verbs](sprint-1.md) (2 stories)
- [Sprint 2 · The city fights back](sprint-2.md) (2 stories)

## Notes

Needs #30. The opponent scenario report gates balance. Branch: `feat/rts-city-depth` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `master`; public Web and macOS builds from the merged commit uploaded through the [public release runbook](../../../docs/release/public-release-runbook.md) and `npm run public:verify` passing; the match host redeployed on the same content version when rules changed; ES and EN; owner read-through in a real match. Then set `status: shipped` here and sync the board.
