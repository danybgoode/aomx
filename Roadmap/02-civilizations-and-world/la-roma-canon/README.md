---
status: scaffolded
phase: Shaping
slug: la-roma-canon
title: "The La Roma canon: archetypes, traits, events and voice"
area: 02-civilizations-and-world
destination: fight-for-la-roma
type: feature
risk: medium
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 26
---

# The La Roma canon: archetypes, traits, events and voice

## Why

Every mode in this wave, the RTS and all five pocket games, tells the same jokes. One canon file holds the archetypes, traits, city events, ages, rent curve, rival names, barks and art, and every mode reads its rules from it. Without it, each mode reinvents the lore and they drift apart. The satire targets urban archetypes and the gentrification machine. Factions stay playful strategies and never become claims about real regional people.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · The canon file and its voice](sprint-1.md) (3 stories)
- [Sprint 2 · Archetype art](sprint-2.md) (2 stories)

## Notes

Prerequisite for #28 onward. The art sprint can start once the S1.1 roster is frozen. Branch: `feat/la-roma-canon` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `master`; canon validator in `npm test`; the RTS and the Pocket shell both load the canon in a released build (#25 or #27, whichever ships first); ES and EN; owner cultural read-through of the roster and barks (D3). Then set `status: shipped` here and sync the board.
