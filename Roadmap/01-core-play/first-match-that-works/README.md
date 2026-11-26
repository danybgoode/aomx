---
status: scaffolded
phase: Shaping
slug: first-match-that-works
title: "A first match that works"
area: 01-core-play
destination: complete-solo-battle
type: feature
risk: medium
sprints_total: 1
stories_total: 4
underwritten_by: wave-2026-11
build_order: 25
---

# A first match that works

## Why

In the 2026-11-25 review, a newcomer lost the default La Roma match at 3:09 without seeing a fight. They started with one worker and nothing in stock, couldn't tell three identical resource stalls apart, and the AI took Cibeles with a 75-second hold it started at 1:55. Meanwhile the HUD covered more than half the screen. The first ten minutes decide whether anyone comes back, so they come first.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · The first ten minutes](sprint-1.md) (4 stories)

## Notes

Changes rules and content, so it bumps the content version (D1). It is independent of the canon work and can run in parallel with #26. Branch: `feat/first-match-that-works` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `master`; public Web and macOS builds from the merged commit uploaded through the [public release runbook](../../../docs/release/public-release-runbook.md) and `npm run public:verify` passing; the match host redeployed on the same content version when rules changed; ES and EN; owner read-through in a real match. Then set `status: shipped` here and sync the board. Two uncoached newcomers each reach a first fight before minute 4.
