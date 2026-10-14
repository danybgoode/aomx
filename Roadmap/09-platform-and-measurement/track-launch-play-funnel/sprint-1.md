---
epic: track-launch-play-funnel
sprint: 1
title: "Event contract and fixture ingest"
risk: high
phase: In review
stories_total: 2
stories:
  - id: S1.1
    title: "Define the launch event contract"
    as_a: "product owner"
    i_want: "one versioned record for first open, match start and terminal result"
    so_that: "the game can capture the agreed funnel from its first playable build"
    risk: high
    status: done
  - id: S1.2
    title: "Accept and deduplicate fixture events"
    as_a: "product owner"
    i_want: "a reproducible ingest path for scripted play events"
    so_that: "I can inspect which records count before a game client exists"
    risk: high
    status: done
---

# Track the launch play funnel — Sprint 1: Event contract and fixture ingest

**Status:** Verified locally and in an independent fresh checkout on 2026-10-14; ready for PR review and merge. The reviewer ran `npm ci --offline`, `npm test` (11/11), and `npm run funnel:fixtures` twice with identical receipts and no extra rows. The fixture report had zero accepted public events, no cohort readings and no observed baseline. Inspect `.funnel-local/fixture-audit.jsonl` and [the contract](../../../docs/launch-funnel-contract.md). No game client exists for this sprint.

## Stories

### Story 1.1 — Define the launch event contract

**As a** product owner, **I want** one versioned record for first open, match start and terminal result, **so that** the game can capture the agreed funnel from its first playable build.

**Acceptance:** Document a product-owned event contract with stable pseudonymous installation ID, event ID, match ID where relevant, claimed UTC time, local sequence, build/content version, mode, faction, test marker and terminal result. Name the six agreed funnel stage signals exactly as the [North Star](../../00-strategy/north-star.md) does. Keep server receipt time separate from claimed play time. Provide valid and invalid fixture examples. A malformed, unsupported-version or impossible transition has a named rejection reason; a tutorial, bot or test event can be stored for audit without entering a public cohort. Record the identity limitation: an installation ID is a proxy for a human, not verified cross-device identity.

**Risk:** high — player identity and North Star semantics.

### Story 1.2 — Accept and deduplicate fixture events

**As a** product owner, **I want** a reproducible ingest path for scripted play events, **so that** I can inspect which records count before a game client exists.

**Acceptance:** From a fresh checkout, a local fixture runner sends first-open, match-start and terminal-result records through the same validation boundary later used by the client. It persists an accepted/rejected audit record and returns a stable receipt/status for retries. Repeating an event ID or player/match/event-type combination cannot increase an eligible count. An abandoned match has no accepted completion. The fixture data are test tagged and cannot enter the first real cohort. Record the selected storage/service boundary and its local run command in this sprint; no hosted analytics write or production data is needed to pass.

**Risk:** high — shared ingest boundary and event integrity.

## Sprint QA

- **Headless contract checks:** Valid, malformed, unknown-version, duplicate, abandoned and excluded fixtures produce the expected accepted/rejected records and stable receipts.
- **Fresh-checkout check:** A second person runs the documented fixture command and inspects the audit output without using any credential.
- **Rendered client smoke:** None; no game client exists in Sprint 1. The fixture output is the owner walkthrough.
- **Review:** A second reviewer checks identity fields, exclusions, deduplication and secrets before merge.

## Sprint 1 — Smoke walkthrough (do these in order)

Env: local fresh checkout. This sprint records the exact fixture-runner command and output path when they exist; there is no game URL yet.

1. Run the documented fixture command for first open, match start and terminal result.
   → The audit output shows three distinct accepted event types under one pseudonymous player and match.
2. Run the same fixture again, then the duplicate and abandoned fixtures.
   → Receipts remain stable; no extra eligible completion is counted, and the abandoned match has none.
3. Run the test-tagged and malformed fixtures.
   → The test event is excluded from public cohorts and the malformed event has a named rejection reason.

If a step fails, record its number, fixture name and the observed receipt or audit row.
