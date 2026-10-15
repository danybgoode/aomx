---
epic: track-launch-play-funnel
sprint: 2
title: "Offline client outbox"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S2.1
    title: "Save first-open and match-start events offline"
    as_a: "solo player"
    i_want: "my first session saved even when I have no connection"
    so_that: "my play can be counted after it syncs"
    risk: high
    status: in-progress
  - id: S2.2
    title: "Show and retry pending sync"
    as_a: "solo player"
    i_want: "to see whether my saved play has synced"
    so_that: "I know when it is pending or needs attention"
    risk: high
    status: in-progress
---

# Track the launch play funnel — Sprint 2: Offline client outbox

**Status:** A Godot client now saves test-tagged first-open and prototype match-start events, survives restart, retries automatically after the loopback ingest returns and shows pending/synced states. The local rendered walkthrough produced three `test_account` exclusions with stable IDs and no public cohort count. The [client run and outbox check commands](../../../game/README.md) are available. Both stories remain in progress: there is no eligible match start, the rejected/quarantined state has only a headless check, and there is no deployable authenticated ingest.

## Stories

### Story 2.1 — Save first-open and match-start events offline

**As a** solo player, **I want** my first session saved even when I have no connection, **so that** my play can be counted after it syncs.

**Acceptance:** A clean installation creates one stable pseudonymous installation ID. The first game open and eligible solo match start are written durably before the client acknowledges them. Closing and reopening offline preserves queued events, IDs, claimed UTC times, local sequence and build/content version. A restart does not manufacture a second first open. Sync retries use Sprint 1's contract and can be repeated without raising counts. Developer/test sessions are tagged and cannot enter a public cohort. No Golden Frijoles credential is included in the Godot export.

**Risk:** high — local durability, identity and player data.

### Story 2.2 — Show and retry pending sync

**As a** solo player, **I want** to see whether my saved play has synced, **so that** I know when it is pending or needs attention.

**Acceptance:** The client displays plain pending, accepted and needs-attention states for the queued match events. Loss of connectivity or an unavailable service leaves the game playable and the event pending. Reconnect retries in order; an accepted receipt clears the pending state, and a rejected or quarantined record names a next action without deleting the local copy. The wording is understandable without Mexican cultural context. The local client walkthrough shows all three states; the owner can inspect the corresponding audit records.

**Risk:** high — false success would corrupt launch measurement.

## Sprint QA

- **Headless checks:** Durable write before acknowledgement, restart persistence, ordered retry, duplicate receipt handling and outage recovery.
- **Rendered client smoke:** Run the pinned Godot client from E1; observe first-open/match-start status while offline and after reconnect.
- **Review:** A second reviewer checks saved identifiers, exports, sync status and credential absence.

## Sprint 2 — Smoke walkthrough (do these in order)

Env: local Godot client using [these run commands](../../../game/README.md); local ingest from Sprint 1. Press **T** for a test-tagged prototype start and **F** to sync. The eligible-match version of this walkthrough waits for E2.

1. Disconnect, start the game from a clean installation and start an eligible solo match.
   → The game stays playable and shows that the session is saved and pending sync.
2. Close and reopen the game while still offline.
   → The same installation and event IDs remain queued; no second first open appears.
3. Reconnect and let sync retry, then inspect the ingest audit output.
   → The prototype client shows synced test traffic; the audit has one first open and one test start from that run. An eligible start waits for E2.
4. Exercise the rejected or quarantined fixture response.
   → The client shows needs attention and retains the local event.

If a step fails, record its number and the client state plus matching audit receipt.
