---
epic: enable-measured-private-alpha
sprint: 3
title: "Reconcile and invite a small cohort"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S3.1
    title: "Publish reconciled mature readings"
    as_a: "measurement operator"
    i_want: "auditable Golden Frijoles readings from accepted events"
    so_that: "the first cohort is not distorted by retries or test play"
    risk: high
    status: planned
  - id: S3.2
    title: "Invite and read the first real cohort"
    as_a: "invited player and product owner"
    i_want: "a supported private release and honest outcome read"
    so_that: "we can decide the next game slice using observed play"
    risk: high
    status: planned
---

# Enable a measured private alpha — Sprint 3: Reconcile and invite a small cohort

**Status:** ⬜ not started.

## Stories

### Story 3.1 — Publish reconciled mature readings

**As a** measurement operator, **I want** auditable Golden Frijoles readings from accepted events, **so that** the first cohort is not distorted by retries or test play.

**Acceptance:** Verify the publisher write credential belongs to `aomx` before enabling a live send. Reconcile first-open, first-finish, later-day return, abandoned, duplicate, delayed, test and clock-anomaly paths from raw records through cohort counts to the four agreed input readings. A scheduled job publishes only final numeric days; immature or uncovered days stay missing/pending. A late-upload correction follows a reviewed backfill policy instead of conflicting with Golden Frijoles append-only input values. The flag is evaluated server-side for the same player ID and its served state is checked per environment.

**Risk:** high: North Star integrity and production measurement mutation.

### Story 3.2 — Invite and read the first real cohort

**As an** invited player and product owner, **I want** a supported private release and honest outcome read, **so that** we can decide the next game slice using observed play.

**Acceptance:** A second reviewer signs off on player-data handling, secrets, restore evidence and reconciled measurements. The owner approves the participant notice, first invitation and production flag switch. Invite a limited set of macOS players after the distinctive La Roma objective is readable. Record build ID, invite count and installation/support issues. Keep the first cohort pending until each seven-day window closes; then report numerator, denominator, stage counts, returning-commanders count and observed `return_to_match` baseline. If fewer than 100 first-match completers mature, label the rate directional per the North Star.

**Risk:** high: external release, player privacy and metric claims.

## Sprint QA

- **Deterministic gate:** Existing fixture/cohort tests plus reconciliation against a disposable hosted event set; verify no synthetic value reaches the aomx production metric.
- **Hosted smoke owed:** Second reviewer checks live flag evaluations, operator report and released build. The owner witnesses the first external invitation and first mature cohort read.
- **Review:** Accepted-result trust label, correction history, published-day coverage, participant notice, secret isolation and aomx project identity.

## Sprint 3 — Smoke walkthrough

Environment: restricted download, production aomx HTTPS ingest and Golden Frijoles `aomx`. Record actual links and build ID in the execution log when released.

1. With the flag off, complete one internal test-tagged match. The raw audit records it and every public reading remains unchanged.
2. After owner approval and flag verification, an invited player downloads the released build, opens it, finishes a match offline, reconnects and sees one accepted receipt. The operator sees exactly one eligible first finish.
3. On a later UTC date, the same installation opens and finishes another match. The operator sees the return stages once; an immediate duplicate upload changes no count.
4. Before the seven-day window closes, the cohort displays pending. After maturity and coverage attestation, compare the four Golden Frijoles readings with the raw audit and report the observed baseline with numerator and denominator.

If any step fails, stop new invitations, preserve the audit and outbox, and record the discrepancy before another publish.
