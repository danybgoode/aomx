---
status: scaffolded   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Shaping       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: prove-rts-core
title: "Prove the RTS core"
area: 01-core-play
risk: low
type: feature
sprints_total: 3
stories_total: 4   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Classic RTS players cannot yet judge the game through play. Give them a worker to move, a resource to gather and a structure to build, so we can test controls and engine before combat. We'll know when a fresh checkout runs those loops and replays the same commands to the same state."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "A classic RTS player testing whether the basic controls and economy respond clearly."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "There is no playable game or first-match cohort; this prototype tests the foundation needed before the first-match completion input can move."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 1       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Prove the RTS core

> **Area:** 01-core-play · **Risk:** low · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/prove-rts-core.md`](../../00-ideas/seeds/prove-rts-core.md)

## Why

Classic RTS players cannot yet judge Battle for La Roma through play. This epic gives a tester a worker to command, a resource to gather and a structure to build, with clear feedback when an order fails. The resulting demo lets the owner decide whether the game controls and Godot prototype are sound enough to invest in combat and a computer opponent.

## Platform-first note

There is no game runtime to reuse. Keep one command/state simulation as the source of truth and make Godot scenes a view and input layer. Save local replay metadata as test traffic; Golden Frijoles remains the later measurement destination, not the prototype's gameplay system.

## What already exists (reuse, don't rebuild)

- [Design prework](../../../docs/design-prework/README.md) and [prototype plan](../../../docs/prototype-plan.md) describe the worker, resource and structure proof.
- [Engine ADR](../../../docs/architecture-decisions/001-engine-selection.md) recommends Godot provisionally and records the openage spike.
- [North Star](../../00-strategy/north-star.md) and [funnel idea](../../00-ideas/seeds/track-launch-play-funnel.md) define later match events and test exclusions.
- [Build order](../../00-ideas/BUILD-ORDER.md) is the generated roadmap; [solo skirmish](../../00-ideas/seeds/finish-solo-skirmish.md) and [offline funnel](../../00-ideas/seeds/track-launch-play-funnel.md) are later backlog ideas.

## Scope — stories

| Sprint | Player-visible result | Stories | Risk |
| --- | --- | --- | --- |
| [1 · Command a worker](sprint-1.md) | A worker can be selected, ordered to move and shown why an unreachable order failed. | S1.1 | low |
| [2 · Gather and deliver](sprint-2.md) | A worker converts a depleting source into a visible stockpile without duplication. | S2.1 | low |
| [3 · Build and replay](sprint-3.md) | The player spends stockpile on a structure; the team replays the loop and reviews the engine. | S3.1, S3.2 | low |

One worker, one resource, one structure and one original test map are enough. Combat, opponent behavior, a terminal match, real cohort events and final art remain outside this epic. Its local IDs, version and test tags establish an event contract; they do not imply a completed match.

## Deploy order

There is no deployment rail. Build and review each sprint locally from a fresh checkout on a feature branch. Merge to `master` only after its headless checks and rendered client walkthrough pass; a merge is not a game release. Review Godot, replay and small-scale performance evidence after sprint 3 before shaping E2.

## Definition of Done (epic)

- [ ] A fresh checkout boots the pinned Godot project with original content and documented commands.
- [ ] A tester completes the three rendered walkthroughs in the local game client; failures have a visible reason.
- [ ] Headless checks cover movement rejection, resource accounting, placement and repeatable local replay.
- [ ] The sprint 3 review records frame time, pathing limits, replay result and a continue/revisit decision on Godot.
- [ ] No prototype event is counted as a real match; no Golden Frijoles ingest secret is in the client or repository.
- [ ] The completed work is reviewed and merged to `master`; update sprint statuses, this README, the product poster and `RETROSPECTIVE.md`. Mark `status: shipped` only after that close-out; there is no deployment to claim.
