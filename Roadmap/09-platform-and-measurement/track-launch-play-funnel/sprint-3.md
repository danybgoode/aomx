---
epic: track-launch-play-funnel
sprint: 3
title: "Accepted result and cohort read"
risk: high
phase: Building
stories_total: 3
stories:
  - id: S3.1
    title: "Accept a terminal offline solo result"
    as_a: "solo player"
    i_want: "my finished match counted after I reconnect"
    so_that: "an offline win or loss can contribute to the launch goal"
    risk: high
    status: in-progress
  - id: S3.2
    title: "Reconcile mature launch cohorts"
    as_a: "product owner"
    i_want: "stage counts and rates derived from accepted events"
    so_that: "I can see where players stop and whether they return"
    risk: high
    status: in-progress
  - id: S3.3
    title: "Publish the agreed Golden Frijoles readings"
    as_a: "product owner"
    i_want: "the four input readings in the aomx product"
    so_that: "the North Star can be reviewed from the same audited cohort data"
    risk: high
    status: planned
---

# Track the launch play funnel — Sprint 3: Accepted result and cohort read

**Status:** Partial implementation: the [solo skirmish](../../01-core-play/finish-solo-skirmish/README.md) has a local terminal match and saves one test-tagged result. The Godot-to-Node ingest check passes with stable retry and zero public completions. Local cohort/correction checks, an amended offline acceptance definition and a dry-run input publisher exist. The owner enabled the aomx flag in all three environments on 2026-10-15. Eligible client trust, a real cohort and hosted-reading walkthroughs remain open; isolated authenticated ingest is staged on the VM. Run `npm ci && npm test && npm run skirmish:contract && npm run funnel:report && npm run funnel:publish` for local evidence; `skirmish:contract` also needs `GODOT_BIN`.

## Stories

### Story 3.1 — Accept a terminal offline solo result

**As a** solo player, **I want** my finished match counted after I reconnect, **so that** an offline win or loss can contribute to the launch goal.

**Acceptance:** The E2 client saves one terminal result for a match and shows pending until accepted sync. The product-side boundary validates version, identity, match state, sequence, integrity and time confidence. Try versioned replay if E1/E2 evidence supports it; otherwise accept and label client-reported results under the approved policy. Keep claimed play and server receipt times. Quarantine unresolved clock or integrity anomalies; never-synced results stay pending and outside aggregate counts. A duplicate upload, same-match second result, bot, tutorial, abandoned or test-tagged match cannot add an eligible completion. Create and verify `telemetry.play_funnel_enabled` in Golden Frijoles for every environment as an enablement flag; it starts off, resolves only on the server for the same pseudonymous user ID, and records flag evaluations. No flag read key enters the client.

**Risk:** high — offline trust, reporting integrity and secret placement.

### Story 3.2 — Reconcile mature launch cohorts

**As a** product owner, **I want** stage counts and rates derived from accepted events, **so that** I can see where players stop and whether they return.

**Acceptance:** A reproducible report lists all six funnel stages, distinct pseudonymous player counts, denominators, conversion rates, exclusions, trust labels and pending seven-day windows. The same accepted log yields Returning commanders and the four North Star inputs. A first finish followed by a second finish on another UTC date within seven days counts once; a same-day second finish does not. Late accepted sync creates a versioned correction with both old and new counts; clock anomalies remain quarantined until resolved. Zero, pending and no data are distinct. Display the first observed cohort baseline without treating the provisional 15% goal as an observed fact.

**Risk:** high — North Star calculation and cohort dates.

### Story 3.3 — Publish the agreed Golden Frijoles readings

**As a** product owner, **I want** the four input readings in the aomx product, **so that** the North Star can be reviewed from the same audited cohort data.

**Acceptance:** Publish one daily numeric reading for `new_players`, `first_match_completion`, `return_to_match` and `match_completion` through Golden Frijoles `external_push` after each input's eligibility window closes. Retry without making a duplicate day count. Compare every pushed number with the local audit report for the scripted first-open, offline finish, later-day finish, abandoned, duplicate, clock-change and delayed-sync paths. Verify the selected Golden Frijoles product is `aomx` before writing; hold credentials only on the server. Enable the flag for an invited cohort only after this reconciliation passes.

**Risk:** high — external metrics and product selection.

## Sprint QA

- **Headless checks:** Replay or labelled client-report acceptance; deduplication, exclusions, date boundaries, mature cohort windows, late corrections and deterministic aggregate readings.
- **Rendered client smoke:** Offline terminal result moves from pending to accepted or needs attention after reconnect.
- **Golden Frijoles check:** Confirm aomx product selection, per-environment served flag state and the four numeric readings against the audit report. Use test-tagged fixtures until the owner opens an invited cohort.
- **Review:** A second reviewer checks privacy, time policy, trust labels, key placement and every North Star calculation.

## Sprint 3 — Smoke walkthrough (do these in order)

Env: local Godot client and product ingest; aomx Golden Frijoles console at https://goldenfrijoles.com/app?project=aomx for the measurement comparison.

1. Play a finishable solo match offline, close the game, reopen it and reconnect.
   → The same terminal result moves from pending to accepted once; its trust and time status can be inspected.
2. Finish a second eligible match on a later UTC date in the scripted cohort, then upload a duplicate and an abandoned match.
   → The audit report counts one Returning commander, excludes the duplicate and has no completion for the abandoned match.
3. Inspect the six-stage report and the four daily aomx input readings after the cohort windows mature.
   → Counts, denominators and readings agree; immature cohorts say pending.
4. Exercise a delayed upload and clock anomaly.
   → The delayed accepted event produces a visible correction; the unresolved anomaly remains quarantined.

If a step fails, record its number and the client state, audit row and aomx reading observed.
