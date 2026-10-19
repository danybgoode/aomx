---
status: in-progress
phase: Verifying
slug: build-strategic-opponent
title: "Build a strategic opponent"
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
hypothesis: "We believe a fair, legible difficulty ladder for solo RTS players will make a second La Roma match worth playing because each level asks for a stronger plan without changing the rules; we'll know when eligible first-match completers finish another match on a later day."
target_metric: return_to_match
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Solo RTS players who have completed a skirmish and want a clear next challenge."
grounded: false
grounded_reason: "No eligible repeat-play cohort or observed baseline exists; the 15% launch goal is provisional, not this feature's measured effect."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 12
---

# Epic: Build a strategic opponent

> **Area:** 01 Core Play · **Risk:** high · **Class:** Feature · **Scope:** [approved pitch](../../00-ideas/seeds/build-strategic-opponent.md) · **Destination:** full-depth-rts

## Why

A solo player who has finished one La Roma skirmish needs a clear next challenge. Three fair, explained levels give the existing computer distinct strategic behavior while preserving the same rules, information and two finishable victory routes.

## Architecture lock

- **D1 — One authority and command path.** `game/skirmish.gd` owns fixed-tick state. AI policy reads a restricted observation and issues only `issue(COMPUTER, ...)` commands; UI and replay never run a second planner.
- **D2 — Fair observation.** Own state is available; enemy state is current visible state or explicit last-seen memory with its age. Hidden live entities, resources and commands do not influence AI decisions. An attack requires visibility; memory may guide movement.
- **D3 — Three content-defined presets.** Learner, Standard and Challenger share costs, stats, sight, population, age and victory rules. Document exact differences in reaction cadence, planning horizon, composition and objective decisions. Level is selected at match start and stays fixed through save/replay; no mid-match live flag.
- **D4 — Bounded planning and recovery.** Economy, construction, scouting, production, defense and objective plans use existing legal actions. Rejected orders, depleted resources, lost drop-offs, population caps and blocked routes have bounded replan behavior and classified failures. AI work must fit the current owner Mac route/tick/frame/memory budgets; measure against the warfare baseline before release.
- **D5 — Deterministic state.** Persist level, planner memory, chosen opening and any random state. Pin content/save/replay versions and reject incompatible old saves without deleting them. Scenario seeds and command logs reproduce hashes on macOS and Linux headless runs.
- **D6 — Scope and measurement.** Use the existing two factions, authored map, win rules, outbox and test exclusions. No new gameplay rule, telemetry pipeline, remote inference or client-embedded flag key. A signed Restricted build is separate from merging to `master`; no public invitation or retention claim follows.
- **D7 — Dependency and review.** Confirm warfare and strategic-economy contracts from current source at implementation lock. Independent high-risk review covers shared simulation, persistence, visibility and client changes. Each sprint has headless and rendered evidence plus a numbered owner smoke; final acceptance includes a downloaded build and an approved human read.

The owner approved the plan on 2026-10-18. The implementation uses 40/20/10-tick reaction cadences, 4/6/8-fighter caps, visible-role countering in Standard/Challenger, seed-selected opening order and a version-4 save/replay pair. The [dated QA record](../../../docs/opponent-qa-2026-10-18.md) contains the 12-case matrix and owner-Mac debug performance results. The existing warfare target on the owner Mac is a 28×28 match with up to 80 units: route p95 ≤ 6 ms, simulation tick p95 ≤ 4 ms, rendered frame p95 ≤ 33.3 ms at 1280×800, and memory ≤ 512 MiB for a ten-minute release-export battle. Release-export and minimum-device measurements remain open.

## What already exists

`game/skirmish.gd` has validated commands, fixed ticks, visibility and authored AI. `game/content/skirmish.v1.json` and `game/rules_content.gd` validate rules. `game/skirmish_persistence.gd` and `game/skirmish_replay.gd` provide versioned save/replay. `game/skirmish_main.gd` provides faction setup. `game/tests/`, `npm run skirmish:contract` and the warfare probes provide deterministic, client and performance checks. Reuse the alpha outbox and test exclusion.

## Scope and review boundaries

| Sprint | Stories | Evidence at boundary |
| --- | --- | --- |
| [1 — Fair planner and recovery](sprint-1.md) | S1.1 choice/legal observation; S1.2 economy recovery | Hidden-information, command, depletion, save/replay and setup checks. |
| [2 — Adaptive plans and objectives](sprint-2.md) | S2.1 scout/composition; S2.2 defense/objectives | Seeded counters and comeback, both win routes and rendered full-match checks. |
| [3 — Difficulty ladder and human read](sprint-3.md) | S3.1 matrix/report; S3.2 human clarity | Three-level report, signed downloaded build, owner QA and approved uncoached read. |

Review the L appetite after each sprint. Do not add new units, maps, campaign behavior or online bot policy to rescue a weak case.

Local headless and rendered evidence is recorded for all three slices. PR #50 passed Linux/CodeQL checks, including the version-4 hash fixture, and independent general and scoped security reviews. It merged as `c40b0f5adc5c`; the compatible ingest and signed Restricted `preview-c40b0f5adc5c` are live. The authenticated fetched build matches the source ZIP, has a valid strict signature and starts headlessly. The [QA record](../../../docs/opponent-qa-2026-10-18.md) holds checksums and release evidence. Downloaded-build owner walkthroughs, excluded in-app sync and the approved [four-player read](../../../docs/opponent-human-read-protocol.md) remain open. These are not inferred from automated victories.

## Build and release

Use `feat/build-strategic-opponent` off current `master`, path-scoped commits per story, one integration PR, independent high-risk review and green checks. Merge to `master`, then export, publish, authenticated-download and verify a signed Restricted owner preview by `deploy/alpha/README.md`. If the game/content version changes, deploy compatible ingest before in-app sync QA. Keep preview traffic test-tagged. Run Godot simulation/content/visibility/persistence/replay/client/hash/performance checks, Node contract and rendered setup/full-match checks. The human read waits for the private-alpha notice and invitation gates.

## Definition of Done

- [ ] Six stories pass their specified headless checks and numbered owner sprint walkthroughs.
- [ ] Both factions, all three levels and both victory routes work in a signed downloaded Restricted build; save/resume, replay and an excluded test-tagged sync receipt pass.
- [ ] Scenario report records versions, seeds, legal/rejected commands, stalls, outcomes, durations and AI performance against the declared budgets, without claiming statistical balance.
- [ ] Four approved uncoached players try all three levels; at least three rank their challenge order and name a counter. Record exact observations and fix or explicitly re-scope failures.
- [ ] Independent high-risk review and required CI pass; integration commit is reachable from `origin/master`; Restricted download evidence is recorded. Merge alone is not a release.
- [ ] Update the poster and generated board, write a dated retrospective and durable learnings at actual close. Set `status: shipped` only after every outcome check passes.
