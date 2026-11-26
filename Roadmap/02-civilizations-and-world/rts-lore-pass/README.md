---
status: scaffolded
phase: Shaping
slug: rts-lore-pass
title: "RTS lore pass: archetypes, the city economy and the four-act campaign"
area: 02-civilizations-and-world
destination: fight-for-la-roma
type: feature
risk: high
sprints_total: 3
stories_total: 7
underwritten_by: wave-2026-11
build_order: 30
---

# RTS lore pass: archetypes, the city economy and the four-act campaign

## Why

The review found the lore on the landing page and none of it in the rules. Units are 'Melee fighter' and 'Registry', the faction picker is a stat sheet, and the campaign is a tutorial checklist. This epic puts the canon on the battlefield: archetype units and barks, rent that rises every age, the quincena, rush hour and the Metro, age-up choice cards, and the four-act story you already wrote.

**Plan:** [La Roma, reimagined](../../00-ideas/seeds/la-roma-reimagined.md) · **Design:** [review and pocket prototype](../../00-ideas/sketches/mobile-reimagined/index.html) (open locally) · **Canon:** `game/content/canon.v1.json` (from #26)

## Sprints

- [Sprint 1 · Archetypes on the battlefield](sprint-1.md) (3 stories)
- [Sprint 2 · The city economy](sprint-2.md) (3 stories)
- [Sprint 3 · De la caguama al maridaje](sprint-3.md) (1 stories)

## Notes

Needs #25 and #26. Bumps the content version again (D1). Branch: `feat/rts-lore-pass` (add `-sN` per sprint if useful). The builder may re-cut later sprints once an earlier one ships; record the re-cut here.

## Done means

Merged to `main`; public Web and macOS builds from the merged commit uploaded through the [public release runbook](../../../docs/release/public-release-runbook.md) and `npm run public:verify` passing; the match host redeployed on the same content version when rules changed; ES and EN; owner read-through in a real match. Then set `status: shipped` here and sync the board.
