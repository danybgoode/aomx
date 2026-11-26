---
status: scaffolded
phase: Shaping
slug: del-cuarto-al-rooftop
title: "Del cuarto de azotea al rooftop: the meta and the idle layer"
area: 03-multiplayer-and-retention
destination: reasons-to-return
type: feature
risk: medium
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 29
---

# Del cuarto de azotea al rooftop: the meta and the idle layer

## Why

Nothing in the game today brings a player back tomorrow, yet the North Star is returning commanders. Your own lore line already describes the progression: the character didn't change, their rent did. A persistent apartment moves from a rooftop room through a shared flat and a Narvarte flat to a rooftop bar with reservations. It's fed by every mode, it unlocks archetypes and cosmetics but never stat power, and it adds an idle tycoon layer for quick check-ins. This replaces a standalone 4X/tycoon game.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · The apartment](sprint-1.md) (3 stories)
- [Sprint 2 · The idle layer](sprint-2.md) (2 stories)

## Notes

Needs #27. Rewards from the RTS arrive through the profile on Web; native RTS builds are out of scope. Branch: `feat/del-cuarto-al-rooftop` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; shipped in every client it touches (Pocket Web, and the RTS builds where noted) from the merged commit and verified live; host redeployed when the server changed; ES and EN; owner read-through. Then set `status: shipped` here and sync the board.
