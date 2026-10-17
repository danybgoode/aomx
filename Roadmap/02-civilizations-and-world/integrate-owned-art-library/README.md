---
status: in-progress
phase: Verifying
slug: integrate-owned-art-library
title: "Integrate the owned art library"
area: 02-civilizations-and-world
destination: fight-for-la-roma
risk: low
type: feature
sprints_total: 3
stories_total: 3
intent_match: null
quote_low_usd: 20
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "We believe a traced, scale-tested art pipeline will help players recognize the La Roma battlefield and its units while playing the existing match because the supplied source art is stronger than the current primitives; we'll know from owner visual checks and later first-match completion evidence."
target_metric: first_match_completion
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Players trying the existing La Roma battle and later maps, including players unfamiliar with local references."
grounded: false
grounded_reason: "No eligible first-match cohort or blind comprehension result isolates the effect of these new assets."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 10
---

# Epic: Integrate the owned art library

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [Approved pitch](../../00-ideas/seeds/integrate-owned-art-library.md) · **Destination:** fight-for-la-roma

## Why

Players and reviewers need to see whether the owner's tiles, critters and Mexico City concept direction work at actual skirmish scale. This epic makes a repeatable route from owned sources to in-engine visuals, then checks that selected decoration does not change the match.

## Architecture lock

- The 20×20 simulation grid, 48×24 ground diamond, 2×2 building footprint, picking, commands and objectives remain authoritative in `game/skirmish.gd` and `game/skirmish_main.gd`.
- All production source copies live under `game/assets/source/owned/`; ignored `references/` is never a build input. Each export has rights, source hash, export hash, dimensions, pivot and runtime role in the manifest.
- The selected raised 32×32 tile blocks are scale candidates in `art_pilot.tscn`. Their 48×24 top projection does not make their tall sides suitable to replace flat battlefield terrain without a further seam review.
- Boar animation remains a pilot candidate by owner decision. Its dark silhouette needs contrast work before any match role is reconsidered. It has no match entity, collision, target, behavior or cultural association.
- A transparent command post derivative follows the `newArtWork/BUILDINGS.jpg` direction. Its isolated source is retained; the flattened board and its proposed mechanics never enter the game.
- `prop_owned_flowers` is the only selected owned asset placed in the match, as view-only decoration. Runtime flags and telemetry event changes are unnecessary for this visual pilot.

## What already exists (reuse, don't rebuild)

`game/art_catalog.gd`, `game/assets/manifest.v0.1.json`, `scripts/export-art.sh`, the current skirmish drawing and visual-picking path, and headless Godot plus `skirmish:contract` checks.

## Scope — stories

| Sprint | Story | Outcome |
| --- | --- | --- |
| 1 · Source audit and export contract | S1.1 | Reproducible, traceable small asset set and budget guard. |
| 2 · Godot scale pilot | S2.1 | 100%/125% comparison, four-direction boar idle preview, geometry test. |
| 3 · Match integration and verification | S3.1 | Decorative match asset and preserved match behavior, with honest owner review status. |

## Deploy order

Build on `feat/integrate-owned-art-library`. Review and merge to `master`, then verify any signed Restricted owner preview through `deploy/alpha/README.md`. A merge is not a game release. No public or cohort invitation is part of this epic.

## Definition of Done

- [x] Per-asset owned rights, source/export hashes, anchor, canvas, role and memory budget are validated.
- [x] The pilot loads selected tiles, a transparent concept derivative and four-direction idle critter animation at 100% and 125% scale.
- [x] A selected owned flower prop appears in the match without changing simulation or selection.
- [x] Rendered owner visual review at normal zoom records palette, readability and raised-tile seams. The owner kept the boar, raised tiles and concept post as pilot candidates.
- [ ] Complete matches as both factions and both victory routes are checked in a downloadable build; save and test-tagged event behavior remain intact.
- [x] Merge to `master`, verify the authorized Restricted preview, and record the result in the retrospective and roadmap.

## Closeout state, 2026-10-17

The downloaded preview passed flower rendering, core commands, offline save/quit/resume and local test-tagged outbox checks. The required wins by both factions and both victory routes have not passed on this build; Sprint 3 and this epic remain in progress. See the [Sprint 3 QA log](sprint-3.md#downloaded-build-qa-2026-10-17) and [retrospective](RETROSPECTIVE.md#open-evidence). The generated board's **Ready** column describes the remaining work after the merged code PR, not this epic's completion status.
