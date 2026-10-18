---
status: in-progress
phase: Building
slug: expand-warfare-and-world
title: "Expand warfare and world"
area: 01-core-play
destination: full-depth-rts
risk: high
type: feature
sprints_total: 3
stories_total: 6
intent_match: null
quote_low_usd: 50
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "Today a classic RTS player can finish the local match, but its small exposed board and few combat roles offer little to discover on a return. A larger readable battlefield with scouting, counters and siege should give them fresh ways to win. We'll know when eligible players finish another match on a later day."
target_metric: return_to_match
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "A classic RTS player who has finished the current skirmish and wants to learn scouting, composition and positioning in another match."
grounded: false
grounded_reason: "No eligible repeat-play cohort or observed later-day completion baseline exists; the 15% launch goal remains provisional."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 11
---

# Epic: Expand warfare and world

> **Area:** 01 Core Play · **Risk:** high · **Class:** Feature · **Scope:** [approved pitch](../../00-ideas/seeds/expand-warfare-and-world.md) · **Destination:** full-depth-rts

## Why

A player who has finished the current skirmish needs new reasons to scout, choose a composition and return. One larger, readable battlefield with predictable counters, costly siege and two clear win routes makes those decisions playable in a complete two-faction match.

## Architecture lock

- **D1 — One simulation.** `game/skirmish.gd` remains the fixed-tick authority for movement, sight, combat, objectives and terminal events. The human UI and AI issue validated commands against the same rules. Art and HUD reflect state; neither decides a battle.
- **D2 — Versioned content.** Extend `game/content/skirmish.v1.json` and `game/rules_content.gd` with stable map, terrain, sight, armor, projectile, siege and objective definitions. Reject invalid references and disconnected critical routes. A new incompatible content version preserves old saves with a clear reason.
- **D3 — Fair information.** Visibility has hidden, explored and currently visible states for both sides. The computer may act on current sight and explicitly remembered last-seen positions, never live hidden positions. Visibility, target loss and projectile timing advance on fixed ticks and round-trip through save/replay.
- **D4 — Terrain and scale.** The authored larger map offers at least one meaningful sight/route choice. Elevation affects passability and sight, not damage or range. Crowd movement must not leave permanent overlap or silent stalls. Declare the owner Mac performance budget before tuning, then record route/tick/frame/memory results for a representative battle; compare the earlier 48×48/163-entity headless case without treating it as release evidence.
- **D5 — Small combat roster.** Preserve worker, melee and ranged roles; add one armored counter and one structure-focused siege role. Armor/bonus values and projectile rules live in versioned content. Add attack-move, stop and hold-position only where approved encounters need them. Garrison, formations and other GDD war inventory remain out.
- **D6 — Two explicit finishes.** Conquest is loss of the final non-rebuildable command post even when other units/buildings survive. La Roma is a fixed uncontested hold, with contest or emptiness resetting progress; its footprint and duration scale to the authored map. Command-post loss takes precedence if simultaneous. A match ID yields one terminal result/event.
- **D7 — Rollout and measurement.** A Restricted build version pins match rules; no mid-match live gameplay flag. Preview events remain test-tagged and excluded from public retention. Real later-day completion uses the existing accepted match-event contract after an eligible cohort exists. No second telemetry or flag store.
- **D8 — Review boundaries.** Use high-risk independent review, Godot/Node/CI checks and a numbered rendered smoke at each sprint. Merging to `master` is integration; a signed Restricted owner download is separately published and verified. No public invitation or AoE2 parity claim follows from this epic.

Architecture locked 2026-10-18 before implementation. The owner Mac target is a 28×28 authored match with up to 80 live units: route p95 ≤ 6 ms, simulation tick p95 ≤ 4 ms, rendered frame p95 ≤ 33.3 ms at 1280×800, and process memory ≤ 512 MiB. Measure over a ten-minute representative battle in a release export; the existing 48×48/163-entity headless case remains a regression comparison. A failed budget requires an explicit scope decision before release.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`: commands, fixed tick, route/occupancy, AI, combat and both terminal reasons.
- `game/rules_content.gd` and `game/content/skirmish.v1.json`: validated versioned rules and map data.
- `game/skirmish_persistence.gd` and `game/skirmish_replay.gd`: canonical save and deterministic replay.
- `game/skirmish_main.gd`, HUD and `game/art_catalog.gd`: rendered selection, orders and presentation.
- `game/tests/`: district, simulation, content, replay, client and scale/hash baselines; the [foundation benchmark](../../../docs/simulation-benchmark-2026-10-16.md) records the earlier debug matrix.
- Existing outbox/ingest and [North Star](../../00-strategy/north-star.md): accepted results, match identity and test exclusion.

## Scope and review boundaries

| Sprint | Stories | Evidence at its boundary |
| --- | --- | --- |
| [1 — Scout and move on a larger map](sprint-1.md) | S1.1 visibility and authored terrain; S1.2 congestion and scale | Content/visibility and crowd cases, save/replay/hash, rendered fog/crowd smoke and declared performance budget. |
| [2 — Counters and siege](sprint-2.md) | S2.1 predictable armor/counters; S2.2 projectiles, siege and minimal orders | Controlled encounters, AI legal orders, projectile edge cases, replay and rendered assault/defense smoke. |
| [3 — Complete both victory routes](sprint-3.md) | S3.1 explicit terminal rules; S3.2 whole-match proof | Terminal/ingest cases, both factions × both victories, signed downloaded build, save/resume and test-event sync. |

L appetite is reviewed at each boundary. Keep optional mechanics out if the complete match is at risk.

## Deployment and verification

Build on `feat/expand-warfare-and-world`, commit per story and review the full assembled diff. Preserve the alpha ingest version contract; deploy ingest support before attempting a new client-version sync if the event contract changes. Run headless Godot rules, content, save/replay, client, scale and cross-platform hash checks plus the Node game-to-ingest contract. Check rendered 1024×700 and 1280×800 views, normal and 120% zoom. Merge to `master` after high-risk review and green checks, then export a signed Restricted macOS preview following `deploy/alpha/README.md`; download and verify it separately. Preview traffic stays excluded from public cohorts.

## Definition of Done

- [ ] All six stories meet their observable acceptance checks; each sprint records a numbered owner smoke with the actual build ID and results.
- [ ] The larger map supports scouting and non-stuck movement; a representative release-build owner Mac performance record states map, units, commands, duration, route/tick/frame/memory values and predeclared budgets.
- [ ] Armor/counter, projectile, siege, visibility, target-loss and terminal cases pass deterministic headless and save/replay checks; the AI uses legal information and commands.
- [ ] A downloaded Restricted build completes Conquest and La Roma as both factions against the computer, including save/resume and one test-tagged sync receipt. No public invitation or retention claim is inferred.
- [ ] Independent high-risk review and required checks pass; the integration branch lands on `master` and the Restricted preview is verified. Record actual release and PR evidence here.
- [ ] Update the poster and generated board, write a dated retrospective at actual close, promote durable findings to `Roadmap/LEARNINGS.md`, and set this README to `status: shipped` only when the above evidence exists.
