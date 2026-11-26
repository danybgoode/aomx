---
status: scaffolded
phase: Shaping
slug: la-roma-en-30-turnos
title: "La Roma en 30 Turnos: the micro turn-based 4X"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: medium
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 34
---

# La Roma en 30 Turnos: the micro turn-based 4X

## Why

This is the closest translation of the RTS for strategy fans on phones, and it stays playable on a bus. A hex map of CDMX where each colonia is a city, 30-turn games, and the four factions, ages and resources carried over almost as-is. It can be played pass-and-play or asynchronously with friends through room codes.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Turn-based CDMX](sprint-1.md) (3 stories)
- [Sprint 2 · Play with friends](sprint-2.md) (2 stories)

## Notes

Needs #26 and #27. Reuses the geography data and the private-room codes on the match host. Branch: `feat/la-roma-en-30-turnos` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board.
