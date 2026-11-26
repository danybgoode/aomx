---
status: scaffolded
phase: Shaping
slug: pocket-shell
title: "La Roma Pocket: the shell and its services"
area: 04-pocket-la-roma
destination: pocket-la-roma
type: feature
risk: high
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 27
---

# La Roma Pocket: the shell and its services

## Why

Mobile can't be the desktop HUD shrunk. In the review, the battlefield got about 15% of a portrait phone screen. La Roma Pocket is a separate portrait shell in the same Godot project (D2). It's built for one thumb, it reads the shared canon, and it's backed by services that make async play fair: ghost boards, daily seeds and leaderboards that the server re-simulates before accepting.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · The shell](sprint-1.md) (3 stories)
- [Sprint 2 · Pocket services](sprint-2.md) (2 stories)

## Notes

Needs #26 S1 for content. Every pocket mode (#28, #31, #33, #34, #35) plugs into this hub. Branch: `feat/pocket-shell` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; La Roma Pocket Web built from the merged commit, uploaded and verified live on iPhone Safari and Android Chrome; the match host redeployed when `src/pocket/` or migrations changed; ES and EN; every run emits `match_started` / `match_completed` with its `mode`; owner read-through (D3). Then set `status: shipped` here and sync the board.
