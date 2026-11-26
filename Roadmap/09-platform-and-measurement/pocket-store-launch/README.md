---
status: scaffolded
phase: Shaping
slug: pocket-store-launch
title: "La Roma Pocket in the stores, measured and fair"
area: 09-platform-and-measurement
destination: accessible-cross-platform-release
type: feature
risk: high
sprints_total: 2
stories_total: 5
underwritten_by: wave-2026-11
build_order: 37
---

# La Roma Pocket in the stores, measured and fair

## Why

This epic ships Pocket natively on Android and iOS with fair money: cosmetics and the pass only, with no stat power for sale. Public builds send eligible events, so the first measured cohort can finally read the North Star. Each owner gate (store accounts, iOS signing, pricing, privacy) is named, never assumed.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Fair money](sprint-1.md) (2 stories)
- [Sprint 2 · Ship to the stores](sprint-2.md) (3 stories)

## Notes

Owner gates: D8 (money), D9 (accounts and signing) and D5 (counting pocket runs). The builder prepares everything up to each gate and records what's waiting. Branch: `feat/pocket-store-launch` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `master`; Android and iOS store builds from the merged commit live in their stores and verified on physical phones; receipts verified server-side; privacy labels and data-safety forms filed; public pocket events accepted by ingest and reconciling in the funnel report per mode; owner sign-off on D5, D8 and D9. Then set `status: shipped` here and sync the board.
