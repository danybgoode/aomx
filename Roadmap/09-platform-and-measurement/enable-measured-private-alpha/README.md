---
status: scaffolded   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Shaping       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: enable-measured-private-alpha
destination: trusted-launch-measurement
title: "Enable a measured private alpha"
area: 09-platform-and-measurement
risk: high
type: feature
sprints_total: 3
stories_total: 7   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Invited RTS players need an installable solo match whose offline results form a trustworthy cohort. We will know this works when a downloaded match, later-day return, duplicate and rejected path reconcile in Golden Frijoles, with test traffic excluded."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # no numeric improvement target before the first observed baseline
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "An invited classic RTS player installing and finishing a solo match, and the operator checking the first cohort."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "This enables the agreed North Star inputs, but no eligible cohort or observed baseline exists from which to set an improvement target."   # only with grounded: false
flag_key: telemetry.play_funnel_enabled   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: everyone   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: match_result_synced
retained_event: later_day_match_completed
retention_days: 7
satisfied_event: null
build_order: 4       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Enable a measured private alpha

> **Area:** 09-platform-and-measurement · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/enable-measured-private-alpha.md`](../../00-ideas/seeds/enable-measured-private-alpha.md)

## Why

An invited classic RTS player needs a complete game they can install and revisit. This epic makes the existing Godot solo match a small macOS alpha whose offline results can become an auditable first cohort. The first observed later-day completion baseline remains unknown until eligible players finish and their seven-day windows mature.

## Platform-first note

Golden Frijoles remains the flag, roadmap and input-reading destination. The game owns the offline outbox; the aomx service owns accepted-event decisions and durable receipts in a dedicated Supabase Free Postgres project. The existing Oracle VM is the proposed HTTPS service host, subject to a live capacity and isolation check. No Supabase credential or Golden Frijoles secret enters a game export.

## What already exists (reuse, don't rebuild)

- [`game/skirmish_main.gd`](../../../game/skirmish_main.gd) and [`game/funnel_outbox.gd`](../../../game/funnel_outbox.gd) provide a finishable local match and ordered offline events.
- [`src/funnel/ingest.mjs`](../../../src/funnel/ingest.mjs), [`src/funnel/http.mjs`](../../../src/funnel/http.mjs) and [`scripts/funnel-report.mjs`](../../../scripts/funnel-report.mjs) provide validation, local receipts and cohort logic.
- The [funnel contract](../../../docs/launch-funnel-contract.md) and [North Star](../../00-strategy/north-star.md) define event eligibility, deduplication and mature readings.
- `telemetry.play_funnel_enabled` already exists in Golden Frijoles `aomx`, serving off in all environments.
- The owner's sibling `fluxonline/deploy/` demonstrates Oracle VM, Docker, Caddy and OCI object backup operations; `editorial-panfleto/` demonstrates Supabase Postgres use. This epic creates isolated aomx resources.

## Approved boundaries

- **Audience and order:** Start with invited macOS classic RTS players. Build this after the current funnel/core/skirmish draft stack, before the distinctive La Roma playtest; invite testers only when the game objective and measurement walkthrough are ready.
- **Database:** Use a dedicated Supabase Free project for the first real cohort. Monitor its 500 MB database quota and inactivity warnings. Run a meaningful daily cohort or health read, but treat this as activity rather than a guarantee against pausing. Keep the outbox retryable through outages.
- **Recovery:** Before real invitation, prove daily logical export to OCI Object Storage and a restore into a disposable database. A missed backup, pause warning, sustained ingest failure or 80% quota use stops new invitations until an operator resolves it. Alert at 50% quota use.
- **Spend:** No paid database upgrade is authorized by this bet. Revisit the plan if capacity, pause or recovery burden affects the cohort.
- **Trust:** The server validates version, identity, sequence, match transition, time confidence and available integrity evidence. Until replay validation exists, accepted results are labeled `client_reported`; test, bot, tutorial, quarantined and rejected traffic stays out of public cohorts.
- **Release:** A restricted distribution page and a repeatable game export are required. Test signing and installation on another macOS machine before invitation. Do not claim a merge to `master` is a release.

## Scope — stories

| Sprint | Player or operator result | Stories | Risk |
| --- | --- | --- | --- |
| [1 · Package the first desktop build](sprint-1.md) | A known macOS build installs and completes a solo match; the restricted page is ready. | S1.1–S1.2 | Low export; high distribution |
| [2 · Host accepted ingest and durable audit](sprint-2.md) | Offline uploads reach a recoverable aomx audit through HTTPS on isolated services. | S2.1–S2.3 | High |
| [3 · Reconcile and invite a small cohort](sprint-3.md) | Accepted results produce reviewed Golden Frijoles readings and a limited invited release. | S3.1–S3.2 | High |

## Deploy order

Keep `telemetry.play_funnel_enabled` off while building and rehearsing. First make and inspect a reproducible macOS export, without inviting players. Then migrate the audit to Supabase Free, establish backups/restore and start the isolated VM service behind HTTPS. Point a test-tagged build at staging and prove offline retry and exclusions. Sprints 1–2 and Story 3.1 can finish before the [La Roma playtest](../../00-ideas/seeds/prove-la-roma-promise.md); Story 3.2's invitation waits for that distinctive objective. This is the per-sprint dependency exception to epic-mode execution. Only after a second data/security review, approved participant notice, aomx key verification and release smoke should the owner authorize invitations and the production flag switch. The cohort read follows its real seven-day maturity; pending is not zero.

## Definition of Done (epic)

- [ ] All seven stories pass their acceptance checks, CI/headless checks and sprint smoke walkthroughs, with commit refs recorded in each sprint.
- [ ] A downloaded macOS build installs, completes and restarts a solo match; its offline events survive restart and sync with stable receipts. No project secret is bundled.
- [ ] The separate aomx service and Supabase Free audit survive restart; a daily off-project backup and disposable restore pass. Capacity, quota, write failure, pause and backup alerts have a named operator response.
- [ ] Duplicates, test accounts, bots, unsupported versions, incomplete matches and clock anomalies are excluded or quarantined according to the agreed contract; only accepted paths count.
- [ ] The aomx publisher key is verified, a second reviewer checks player data and reporting integrity, and four mature readings reconcile with raw events. Immature cohorts remain pending; the first observed baseline is reported only when real windows mature.
- [ ] The served Golden Frijoles flag state is checked in every environment; production eligibility changes only after the approved walkthrough. The owner approves the participant notice and external invitation.
- [ ] The deployed build is smoke-tested at the actual distribution and ingest endpoints. The sprint docs, product poster, learnings and retrospective reflect the outcome; mark `status: shipped` only after review, merge, release and verification.
