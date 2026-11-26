---
status: scaffolded
phase: Shaping
slug: bronca-en-la-glorieta
title: "Bronca en la Glorieta: the real-time lane duel"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: high
sprints_total: 3
stories_total: 8
underwritten_by: wave-2026-11
build_order: 33
---

# Bronca en la Glorieta: the real-time lane duel

## Why

This is the live PvP mode: three-minute duels with an eight-card deck of archetypes, Varos that regenerate like elixir, and each side's posts and Cibeles to take. It's the most demanding format (live opponents, netcode, ranked balance), so it comes after the async modes have proved the canon and services. It runs on the existing match host.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · A duel against the machine](sprint-1.md) (3 stories)
- [Sprint 2 · Live PvP](sprint-2.md) (3 stories)
- [Sprint 3 · Decks and spectating](sprint-3.md) (2 stories)

## Notes

Needs #27, and reuses battle code from #28. Server cost and player numbers are watched (D7). Branch: `feat/bronca-en-la-glorieta` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board. Ranked play runs on the public host with reconnect verified on two physical phones.
