---
epic: prove-multiplayer
sprint: 2
title: "Restricted shared match and recovery"
risk: high
phase: Restricted host QA
stories_total: 2
stories:
  - id: S2.1
    title: "Finish a match through the Restricted host"
    as_a: "pair of invited players"
    i_want: "one playable shared battle"
    so_that: "we can finish a fair result together"
    risk: high
    status: done
  - id: S2.2
    title: "Recover the same slot after disconnect"
    as_a: "disconnected player"
    i_want: "to return to the server's current battle"
    so_that: "a brief outage does not discard our match"
    risk: high
    status: done
---
# Prove multiplayer and replays — Sprint 2: Restricted shared match and recovery

**Status:** ✅ Restricted live service and owner checks passed. The current `aomx-match:0d29ed3` host passed a delayed second join, baseline and symmetric 150 ms/loss native macOS/Linux full matches, same-slot recovery within 60 seconds and visible `reconnect_expired` no-result for both clients. Each completed match produced one two-participant record and fogged replays; expiry produced none. The owner completed a downloaded-build GUI match, and the corrected replay-file build passed independent itch fetch and owner valid/bad-file checks. The owner's final GUI retry showed admission disabled; revoked-code behavior is separately covered by tests and a live rotation probe. Admission is off in every environment. See [current QA](../../../docs/multiplayer-qa-2026-10-21.md).

## Stories

### ✅ Story 2.1 — Finish a match through the Restricted host

**As a** pair of invited players, **I want** one playable shared battle, **so that** we can finish a fair result together.

**Acceptance:** Two separate macOS/Linux clients use distinct scoped codes to reach an isolated, TLS-protected match service on the existing Oracle VM. The service runs the current rules and orders both players' semantic commands; clients reconcile to authoritative snapshots, display the same objectives and reach exactly one identical terminal result. Run a complete match with both baseline and 150 ms RTT/1% loss profiles. Record build/host image, CPU, memory, network volume, command acknowledgements and state checks. Revoking a code blocks new joins without changing an active match. Health checks, service caps, owner-only operator files and updated participant notice pass review before second-person access.

**Risk:** high — remote authority, invite access, shared VM and privacy; independent security and deployment review.

### ✅ Story 2.2 — Recover the same slot after disconnect

**As a** disconnected player, **I want** to return to the server's current battle, **so that** a brief outage does not discard our match.

**Acceptance:** A reconnect within 60 seconds restores the bound slot from an authoritative snapshot and last accepted order index. Retries do not repeat an order or a terminal event. Another code or installation cannot take the slot. Both clients see reconnect status; expiry gives both a visible no-result with no completion event. Test loss before and after an accepted command and during terminal transition; diagnose first divergent tick if state disagrees.

**Risk:** high — session integrity and result lifecycle; second reviewer.

## Sprint QA

- **Specs:** server/client protocol, authoritative command ordering, terminal result, disconnect/rejoin, expired session, invalid binding and duplicate event tests. Existing Godot rules/save/replay and Node ingest suites stay green.
- **Rendered smoke owed:** actual two-client full match and reconnect through the Restricted TLS route. Owner verifies download, readability, invite revocation and no-result wording. Capture both clients and server evidence.
- **Gate:** no claim of reliability until the impaired full match passes. Stop and re-scope on failure.

## Sprint 2 — Smoke walkthrough

Env: Restricted host and signed preview clients; fill the exact HTTPS host URL, build ID, code issuance references and VM image in the QA record. Never paste code values into docs.

1. Download the two Restricted builds and enter separate issued invite codes on macOS and Linux.
   → Both connect to the same match, in distinct slots, with identical version and objective labels.
2. Play through Conquest or La Roma under the declared 150 ms RTT/1% loss profile.
   → Commands acknowledge, both clients remain synchronized and show the same server terminal result.
3. Start another match, drop one client's connection and reconnect within 60 seconds.
   → The same player returns to the same slot at the server's current state; no command or event duplicates.
4. Drop again and let 60 seconds expire; attempt the old connection and a revoked code.
   → Both clients show no result; neither attempt creates a new finish or takes a slot.

Record each failure with build ID, host image, packet profile and relevant server/client logs stripped of secrets.
