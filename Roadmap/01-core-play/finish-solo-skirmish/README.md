---
status: scaffolded   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Shaping       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: finish-solo-skirmish
title: "Finish a solo skirmish"
area: 01-core-play
risk: low
type: feature
sprints_total: 3
stories_total: 3   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Classic RTS players need a complete battle to judge the game. A small solo skirmish with an authored opponent lets them test its economy and combat. We'll know when a fresh Godot checkout produces a win, loss and draw with one test-tagged terminal result each."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "A classic RTS player trying a complete solo match against the computer."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "First-match completion has no observed baseline and this internal match remains test traffic until the launch funnel is released."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 3       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Finish a solo skirmish

> **Area:** 01-core-play · **Risk:** low · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/finish-solo-skirmish.md`](../../00-ideas/seeds/finish-solo-skirmish.md)

## Why

A classic RTS player needs a battle that can end before they can judge the game's economy and combat. This epic adds a small solo conquest match against an authored opponent with clear win, loss, draw and restart outcomes. The owner's 2026-10-14 approval settled the Godot continuation, one-resource/no-age subset, two combat roles, command-post defeat rule and 15-minute draw.

## Platform-first note

Extend the Godot fixed-tick simulation and command log; both sides use the same validation path. The client persists test-tagged match events through the existing offline outbox. The funnel service alone decides which uploads enter player cohorts, and its Golden Frijoles flag stays off during internal play.

## What already exists (reuse, don't rebuild)

- [`game/simulation.gd`](../../../game/simulation.gd) owns pathing, worker economy and construction; [`game/main.gd`](../../../game/main.gd) renders the map and accepts orders.
- [`game/funnel_outbox.gd`](../../../game/funnel_outbox.gd) persists IDs, sequences and receipts; the [funnel contract](../../../docs/launch-funnel-contract.md) names `match_started` and `match_completed`.
- [Combat canon](../../../docs/design-prework/systems/03-combat-units.md) confirms literal unit and building destruction. [ADR 001](../../../docs/architecture-decisions/001-engine-selection.md) records Godot's provisional evidence.

## Scope — stories
| Sprint | Player-visible result | Risk |
|---|---|---|
| [1](sprint-1.md) | Gather, construct a recruitment building and produce melee/ranged units. | low |
| [2](sprint-2.md) | Order units to attack, see damage and destroyed structures alter paths. | low |
| [3](sprint-3.md) | Play an authored opponent to one win/loss/draw result and restart. | low |

## Deploy order

Build all three sprints in one local branch, with headless rules and rendered checks at each boundary. Integrate test-tagged starts/results with the funnel outbox before closing Sprint 3. No deployment rail exists; merging to `master` is not a release. The funnel's accepted-result and live cohort work follows this terminal match.

## Definition of Done (epic)
- [ ] Fresh checkout runs pinned Godot and a complete rendered solo match with a worker economy and two combat roles.
- [ ] Headless checks cover costs, target/range/cooldown, structure destruction, identical-command replay and exactly one terminal result.
- [ ] Win by destroying the opposing command post, lose when one's own falls, draw after 15 unresolved minutes; all three outcomes and restart are observable.
- [ ] The authored opponent uses validated commands. Multi-unit frame and path measurements and engine recommendation are recorded.
- [ ] Test-tagged start/result events survive restart and local sync without entering a public cohort or bundling a credential.
- [ ] Each sprint's smoke walkthrough and review are recorded; the product poster, learnings and retrospective reflect the result. Mark shipped only after the completed work is reviewed and merged. No public release is implied.
