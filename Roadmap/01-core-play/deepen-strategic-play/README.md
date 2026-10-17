---
status: scaffolded
phase: Locking architecture
slug: deepen-strategic-play
title: "Deepen strategic play"
area: 01-core-play
destination: full-depth-rts
risk: high
type: feature
sprints_total: 3
stories_total: 3
intent_match: null
quote_low_usd: 50
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "We believe a complete four-resource, four-age economy for classic RTS players will make repeated La Roma matches worth mastering because resource routes, construction and research create choices the current gold-only match cannot; we'll look for later-day match completion after an eligible cohort exists."
target_metric: return_to_match
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "A classic RTS player who has finished the first skirmish and wants meaningful economic and progression choices in another match."
grounded: false
grounded_reason: "No eligible first-match cohort or later-day completion baseline exists; the 15% return goal is provisional, not an observed effect of this feature."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 1
---

# Epic: Deepen strategic play

> **Area:** 01-core-play · **Risk:** high · **Class:** Feature · **Scope:** [approved pitch](../../00-ideas/seeds/deepen-strategic-play.md) · **Destination:** full-depth-rts

## Why

A player who finishes the current gold-only skirmish has little economic or progression choice on a return match. This epic makes worker routes, settlement growth, research and age advancement meaningful in one finishable two-faction battle.

## Architecture lock

- **D1 — One simulation.** `game/skirmish.gd` remains the fixed-tick authority. The view sends validated commands; the AI uses the same command, cost, population, queue and prerequisite path. No second rules engine or UI-only stockpile exists.
- **D2 — Content first.** Extend `game/content/skirmish.v1.json` through `game/rules_content.gd` with stable resource, building, tech and age IDs. Reject unknown references and cycles. Costs, duration, effects and replenishment are versioned data, not scattered view constants.
- **D3 — Physical economy.** Comida, Materiales, Varos and Terrenos each have finite source stock, worker carry, valid drop-off and bounded replenishment. Terrenos is survey packets from vacant lots, delivered to the command post or registry. Source/drop-off loss must leave workers in an inspectable, recoverable state.
- **D4 — Small roster.** Keep worker, melee and ranged roles. Add general depot, housing and registry roles around existing command and recruitment posts. Research nodes are `carry_capacity_i` (Universitaria), `construction_rate_i` (Godín), `combat_training_i` (Gentrificación). Foránea → Universitaria requires housing and depot; → Godín requires registry and the carry tech; → Gentrificación requires the recruitment post and construction tech. Final display names can change without changing IDs.
- **D5 — Deterministic progression.** Building/repair, population, unit/research queues and age transitions advance on fixed ticks. Cancel/refund and disabled reasons are explicit. Saves and replay preserve IDs, remaining time, worker cargo and effects; incompatible old saves report a reason without deletion.
- **D6 — Preserve outcomes.** The existing command-post and La Roma hold terminal rules, test-account event lifecycle and match ID deduplication remain unchanged. Do not add a telemetry pipeline.
- **D7 — Preview boundary.** Core offline rules use one content version per match; no live gate switches a running simulation. Check a signed Restricted build and roll back by build version. No public invitation or numerical AoE2 parity claim follows from this epic.
- **D8 — Scope boundary.** Fog, siege, scouting AI, expanded combat, new factions, maps, multiplayer and campaigns stay in later ideas. The age/economy AI here must obey rules and finish a match, without pretending to be the later strategic-opponent epic.

## What already exists

`game/skirmish.gd` has commands, worker carry, construction, combat, AI and both victories. `game/rules_content.gd` validates versioned content. `game/skirmish_persistence.gd` and `game/skirmish_replay.gd` hold the save/replay seam. `game/skirmish_main.gd` and `game/ui/battle_hud.gd` render the match. `game/tests/` and `npm run skirmish:contract` provide deterministic checks. Preserve the owned-art view-only prop and existing funnel outbox.

## Scope and review boundaries

| Sprint | Story | Observable result | Risk |
| --- | --- | --- | --- |
| 1 | S1.1 · Complete worker economy | All four physical resources, construction/repair, population and recovery from depletion work in one match. | High |
| 2 | S2.1 · Four-age progression | A legal small tech graph and all three transitions change available actions and survive save/replay. | High |
| 3 | S3.1 · Integrated two-faction match | AI pays the same costs, HUD explains choices, and both factions can finish both victory routes in a downloaded build. | High |

## Deployment and verification

Build in one orchestrated run on `feat/deepen-strategic-play`, committing per story. Run Godot simulation/content/save/replay/client tests and the Node contract after each boundary; perform rendered checks at desktop and enlarged zoom. Open one integration PR to `master`, route independent high-risk review, merge on green, then export and verify a signed Restricted owner preview through `deploy/alpha/README.md`. A merge alone is not a release. Keep the owned-art closeout independent until its own downloaded-build wins are observed.

## Definition of Done

- [ ] All three stories and their smoke walkthroughs pass, including seeded economy/tech/AI, persistence/replay and event cases.
- [ ] A real downloaded Restricted build is played to fourth age as both factions and completes both victory routes; record build ID, save/quit/resume and test-event behavior.
- [ ] High-risk independent review and required checks pass; the integration PR reaches `master` and the Restricted preview is verified.
- [ ] The poster, board, retrospective and durable learnings are updated; this README changes to `status: shipped` only with the above evidence.
