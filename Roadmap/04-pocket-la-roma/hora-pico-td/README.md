---
status: scaffolded
phase: Shaping
slug: hora-pico-td
title: "Hora Pico: defend your flat (roguelite tower defense)"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: medium
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 31
---

# Hora Pico: defend your flat (roguelite tower defense)

## Why

Streets and traffic make natural tower-defense paths. Gentrification arrives in waves (Airbnb hosts, valets, brokers, El Desarrollador) down real CDMX streets, and you hold the intersections with taquerías, marches and bicitaxis. After each wave you pick one card. It's quick to build, plays with one thumb, and uses the shared canon and pocket services.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Defend your flat](sprint-1.md) (3 stories)
- [Sprint 2 · Roguelite and daily](sprint-2.md) (2 stories)

## Notes

Needs #26 and #27. Map paths come from the existing CDMX geography data. Branch: `feat/hora-pico-td` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board.
