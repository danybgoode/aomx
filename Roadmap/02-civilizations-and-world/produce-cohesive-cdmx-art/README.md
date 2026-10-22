---
status: scaffolded
phase: Shaping
slug: produce-cohesive-cdmx-art
title: "Produce cohesive CDMX game art"
area: 02-civilizations-and-world
destination: fight-for-la-roma
risk: low
type: feature
sprints_total: 4
stories_total: 6
intent_match: 78
quote_low_usd: 50
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "We believe a coherent, readable Roma Norte/Cibeles battlefield for classic RTS players will make the existing match and its objective easier to understand and more inviting to finish; we will check uncoached comprehension and completed downloaded-build matches before looking for a first-match-completion signal in an eligible cohort."
target_metric: first_match_completion
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Classic RTS players playing a CDMX skirmish, including players unfamiliar with Mexican references."
grounded: false
grounded_reason: "The North Star input is defined, but no eligible cohort baseline or controlled art comparison supports a numeric completion target."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 15
---

# Epic: Produce cohesive CDMX game art

> **Area:** 02 Civilizations and world · **Risk:** low · **Class:** Feature · **Scope:** [approved pitch](../../00-ideas/seeds/produce-cohesive-cdmx-art.md) · **Destination:** fight-for-la-roma

## Why

Classic RTS players should recognize the battle for La Roma and its objective, factions, resources and unit roles while they make real decisions. A coherent Roma Norte/Cibeles art pass makes the current playable match feel like one place without requiring local cultural knowledge to read its rules. Its effect on eligible first-match completion remains unmeasured.

## Architecture lock

- **D1 · Rules boundary:** Existing simulation, map definitions and HUD own rules, pathing, entity IDs, objective state, controls and text. This art wave maps those states to visuals; no concept-board mechanic enters content.
- **D2 · Live geometry:** The live 28×28 match uses a 48×24 ground diamond and a wider fit/manual zoom than the older v0.1 art notes. Measure current canvas, pivots, unit scale, layering, selection and fog in Godot before exporting variants.
- **D3 · Source and exports:** Keep transparent production sources in tracked game assets. Every integrated export has rights/source, hash, deterministic recipe, pivot, footprint, state/direction/frame timing and a manifest entry. Ignored local references are direction only.
- **D4 · Objective identity:** Cibeles identifies the existing central control objective. Do not claim real geography until the separate #16 map-data bet verifies placement. El Ángel is not substituted for Cibeles.
- **D5 · Role and faction grammar:** Four faction identities and current worker/melee/ranged/armored/siege roles must read without color alone. Use a role-first grammar and simple faction marks; retain the current accessible HUD.
- **D6 · Picking and occlusion:** Tall architecture and props cannot block selection or hide units. Art does not set collision, resource amounts or victory timing. Simulated state and replay hashes stay unchanged.
- **D7 · Pilot decision:** One tile, building, unit and landmark render in the actual game at 100%, 125%, fit zoom and a crowded center before volume production. Record builder evidence; owner visual acceptance remains owed until inspection.
- **D8 · Measurement and release:** No new art runtime flag is planned. Existing event and content/build identity may support a later eligible first-match-completion read; Restricted/test traffic stays excluded.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`, `game/content/skirmish.v1.json`, `game/skirmish_main.gd`: authoritative match state and drawing/picking.
- `game/art_catalog.gd`, `game/assets/manifest.v0.1.json`, `scripts/export-art.sh`, `scripts/export-owned-art.sh`, `scripts/validate-art-manifest.mjs`: production export and manifest seam.
- `game/art_pilot.tscn`, `game/tests/art_pipeline_test.gd`, `game/tests/art_render_probe.gd`: scale, provenance and gameplay checks.
- [Owned-art pipeline](../../../docs/art/owned-art-pipeline.md), [geometry](../../../docs/art/isometric-geometry.md), [visual QA](../../../docs/art/visual-qa-v0.1.md), [coverage review](../../00-ideas/art-world-coverage-2026-10-21.md): candidates, seam risk and source crosswalk.

## Scope — stories

| Sprint | Stories | Outcome |
| --- | --- | --- |
| [1 · Contract and pilot](sprint-1.md) | S1.1 audit; S1.2 four-asset pilot | A scale-tested style contract and go/revise decision. |
| [2 · Place and economy](sprint-2.md) | S2.1 terrain, place and resource art | Consistent ground, Cibeles, structures, resource sites and props. |
| [3 · Units and state](sprint-3.md) | S3.1 roles and faction cues | Roles, ownership and current action/damage states read in play. |
| [4 · Playable art acceptance](sprint-4.md) | S4.1 downloaded-build verification; S4.2 uncoached read | Source-matched Restricted build and recorded human observations. |

## Sprint build contracts

- **S1:** Audit the current scene and all twelve boards; deliver a traced tile/building/unit/Cibeles pilot in the real match. Review scale, seams, depth and identity before expanding.
- **S2:** Complete the La Roma place/economy layer through the existing art catalog. Every visual follows simulation state and passes fog, selection, construction and resource checks.
- **S3:** Cover the current five unit roles and four faction treatments with non-color cues, clear motion/state and crowded-board selection. Preserve rule and replay hashes.
- **S4:** Run local and signed downloaded-build QA, merge/release evidence, and the owner-authorized uncoached task read. Keep owner-only checks open until actually performed.

## Deploy order

Build on `feat/produce-cohesive-cdmx-art` as one orchestrated epic with sprint commits. Run headless invariants and rendered checks at each boundary; review the complete diff and merge to `master` after checks pass. Export and upload a signed Restricted owner build from landed source, fetch it independently, and record exact IDs. Merges and Restricted releases were owner-authorized on 2026-10-22. Owner visual, downloaded-match and uncoached task QA remain owed. No public invitation or eligible cohort was authorized.

## Definition of Done

- [ ] Six story outcomes and each sprint's numbered smoke walkthrough have evidence and commit refs.
- [ ] Pack has current-match coverage, source rights, manifest hashes and deterministic exports; old five-board inventory reconciles twelve concepts.
- [ ] Pilot and final rendered comparisons show scale, seams, selection, objective/role/faction readability and frame/memory costs at declared zooms.
- [ ] Existing rule/client/save/replay and excluded-event checks pass; both win routes and four factions remain playable in a downloaded build.
- [ ] Owner visual decision, downloaded-build full-match walkthrough and authorized familiar/unfamiliar uncoached read are recorded. Unrun owner QA stays open.
- [ ] Reviewed branch is merged to `origin/master`, signed Restricted build is fetched and checked separately, retrospective and poster are updated; then mark this epic shipped.
