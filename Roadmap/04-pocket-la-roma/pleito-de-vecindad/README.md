---
status: scaffolded
phase: Shaping
slug: pleito-de-vecindad
title: "Pleito de Vecindad: the auto-battler"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: high
sprints_total: 2
stories_total: 7
underwritten_by: wave-2026-11
build_order: 28
---

# Pleito de Vecindad: the auto-battler

## Why

This is the hero pocket mode, and the format the review recommended. Buy urban archetypes at the tianguis, merge three copies to upgrade, place them, then watch the fight. Six rounds across four ages, a city event each round, rising rent, and a boss called El Desarrollador. An auto-battler mode drove Clash Royale's 2025 comeback. Traits make a natural home for the satire, and ghost boards avoid needing a live player base. The playable prototype is in the review sketch.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · The run](sprint-1.md) (4 stories)
- [Sprint 2 · Real neighbours](sprint-2.md) (3 stories)

## Notes

Needs #26 S1 and #27. The HTML prototype in the sketch is the reference for feel and starting numbers, not the code. Branch: `feat/pleito-de-vecindad` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `master`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board.
