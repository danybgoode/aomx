---
status: scaffolded
phase: Shaping
slug: la-mudanza
title: "La Mudanza: the packing puzzle with a renovation meta"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: medium
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 35
---

# La Mudanza: the packing puzzle with a renovation meta

## Why

Puzzle is the biggest-earning category on phones, and moving house in this city is a puzzle already. You pack the moving boxes, then renovate the block with the stars you earn. The joke is that you're the gentrifier. It reaches the widest casual audience the canon can attract.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Pack and renovate](sprint-1.md) (3 stories)
- [Sprint 2 · Endless boxes](sprint-2.md) (2 stories)

## Notes

Needs #26 and #27. Monetization follows D8 (default: no ads, no paid lives). Branch: `feat/la-mudanza` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board.
