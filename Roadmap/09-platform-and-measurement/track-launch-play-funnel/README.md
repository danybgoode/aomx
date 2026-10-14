---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Building       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: track-launch-play-funnel
title: "Track the launch play funnel"
area: 09-platform-and-measurement
risk: high
type: feature
sprints_total: 3
stories_total: 7   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "New players can finish solo battles offline, but we cannot yet see where they stop or if they return. Capture their journey from first open through a later-day finish so launch decisions use complete cohorts. We'll know when offline, abandoned, duplicate and return paths reconcile with the reported metrics."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "A new Battle for La Roma player trying a solo match and deciding whether to return."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "This makes the agreed North Star inputs measurable, but there is no observed cohort baseline or credible claim that instrumentation itself improves retention."   # only with grounded: false
flag_key: telemetry.play_funnel_enabled   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: everyone   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: match_result_synced
retained_event: later_day_match_completed
retention_days: 7
satisfied_event: null
build_order: 1       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Track the launch play funnel

## Build progress · 2026-10-14

The fixture-tested contract, local ingest, outbox reference, audit report and dry-run publisher are in draft PR #6. Draft PR #10 supplies a finishable local Godot solo skirmish with test-tagged first-open, later-day open, match-start and terminal-result events. A real Godot-to-Node contract check confirms stable retry and zero public events. The epic remains in progress: hosted authenticated ingest, an eligible released client, approved publish-key identity, a first mature real cohort and the four hosted readings are still required.

> **Area:** 09-platform-and-measurement · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/track-launch-play-funnel.md`](../../00-ideas/seeds/track-launch-play-funnel.md)

## Why

The launch funnel is the **first build**. New players must be measurable from their first open, including a solo match played offline and synced later. Without this path, the first invited cohort would be lost and the agreed Returning commanders metric could not be audited. This epic establishes the event contract first, then connects it to the game and verifies completed-match cohorts before any external invitation.

## Build progress · 2026-10-14

Sprint 1's versioned event contract, durable local ingest, test-tagged fixture runner, stable retry receipts and audit checks are implemented and passed an independent fresh-checkout review. A Node outbox reference, cohort report with correction history, and dry-run Golden Frijoles input publisher cover parts of Sprints 2–3. The aomx `telemetry.play_funnel_enabled` flag exists and was verified serving **off** in development, preview and production. The [contract and commands](../../../docs/launch-funnel-contract.md) document the local boundary.

The solo skirmish now supplies a real local terminal state, but no deployed authenticated ingest, real mature cohort, hosted four-reading reconciliation or release has occurred. The second review of the Godot client found and verified fixes to later-day opens and ordered upload blocking. The publisher is dry run only until a key can be verified as aomx scoped; no synthetic reading was sent to aomx. The first observed baseline remains unknown.

## Platform-first note

Golden Frijoles is the aomx roadmap, flag and input-metric destination. The game owns local event persistence and an accepted-event log; a product-side aggregation publishes the four agreed daily readings through `external_push`. No client secret or parallel feature-flag store belongs in the game. The first build uses fixtures because no game runtime or backend exists yet; the architecture lock chooses the smallest service boundary that can later accept real offline uploads.

## What already exists (reuse, don't rebuild)

- The agreed [North Star](../../00-strategy/north-star.md) defines six funnel stages, eligibility, seven-day windows, deduplication and the four input readings.
- The [approved pitch](../../00-ideas/seeds/track-launch-play-funnel.md) records the offline acceptance, identity, clock and flag decisions.
- The [RTS core epic](../../01-core-play/prove-rts-core/README.md) supplies the first Godot client and local command metadata. The [funded solo-skirmish epic](../../01-core-play/finish-solo-skirmish/README.md) supplies a local terminal match result.
- A local client, service route, event store and report now exist. There is no hosted authenticated service or game deployment rail.

## Scope — stories

| Sprint | Observable result | Stories | Dependency |
|---|---|---|---|
| [1 · Event contract and fixture ingest](sprint-1.md) | A scripted first open, start and result are accepted once and audited. | S1.1–S1.2 | None; **build this first**. |
| [2 · Offline client outbox](sprint-2.md) | The Godot client saves first open and match start offline and shows pending sync. | S2.1–S2.2 | E1's first usable client slice. |
| [3 · Accepted result and cohort read](sprint-3.md) | A finishable solo match syncs; mature cohorts and aomx readings reconcile. | S3.1–S3.3 | E2 terminal match and the approved offline trust policy. |

## Execution order

1. Build funnel Sprint 1 first, before game mechanics, to lock and test the launch event contract.
2. Build the [RTS core](../../01-core-play/prove-rts-core/README.md) as the next epic. Integrate funnel Sprint 2 when its Godot client is usable.
3. Refine and build the [solo skirmish](../../00-ideas/seeds/finish-solo-skirmish.md); then complete funnel Sprint 3 against its terminal result.
4. Refine and build the [La Roma playtest](../../00-ideas/seeds/prove-la-roma-promise.md). Invite the first measured testers only when the finishable, distinctive match and funnel pass their walkthroughs.

The dependency changes the next sprint's implementation surface, so this epic uses the refine skill's **per-sprint exception** rather than one uninterrupted epic build. Sprint 1 can merge before the epic is complete. There is no deployment rail today; merging to `master` is not a public game release.

## Measurement and risk decisions

- Persistent pseudonymous installation ID is the first solo cohort's identity proxy. State that reinstall and cross-device play may split a person; do not claim verified distinct humans.
- Offline results count only after accepted sync. Try versioned replay when E2 is available; otherwise label client-reported acceptance after integrity checks. Preserve both claimed play time and server receipt time, quarantine unresolved clock anomalies, and show late corrections.
- Before a real cohort, revise the [North Star](../../00-strategy/north-star.md) wording that currently requires a backend-authoritative event at play time. Keep the metric's distinct-day and seven-day definitions intact.
- `telemetry.play_funnel_enabled` is a Golden Frijoles enablement flag. Create it in every environment during the build, serve it off until reconciliation passes, evaluate on the server for the same pseudonymous user ID used by the events, and report evaluations. Never put the read key in the game client. Verify the served switch state per environment; a flag definition alone is insufficient.
- Changes to player identity, privacy, accepted-result policy or North Star wording go through the [working agreement](../../WAYS-OF-WORKING.md) escalation rule. Have a second reviewer check player data and reporting integrity.

## Definition of Done (epic)

- [ ] All seven stories pass their named checks, with a fresh-checkout command and observable walkthrough in each sprint.
- [ ] Offline first-open, start and terminal-result paths survive restart and sync once; rejected or pending events never raise an eligible count.
- [ ] A scripted same-day finish, later-day finish, abandoned match, duplicate, late upload, test identity and clock anomaly reconcile against the raw event log, cohort report and four aomx readings.
- [ ] The first mature cohort is reported with counts and its observed baseline; the 15% later-day goal remains provisional until real data is read.
- [ ] The agreed North Star wording is amended for accepted offline results before inviting players. A second reviewer checks player data, trust labels, secrets and reporting integrity.
- [ ] The Golden Frijoles flag exists and has a served switch state in each environment; production is only enabled after the reconciliation walkthrough. No credential is committed or bundled in the client.
- [ ] Sprint status, this README, [product poster](../../README.md), [learnings](../../LEARNINGS.md) and `RETROSPECTIVE.md` reflect the result. Set `status: shipped` only after the real build is verified and released through an established process; a docs merge is not shipment.
