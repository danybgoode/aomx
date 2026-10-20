---
epic: prove-multiplayer
sprint: 3
title: "Replay result integrity and acceptance"
risk: high
phase: Shaping
stories_total: 3
stories:
  - id: S3.1
    title: "Watch a participant replay"
    as_a: "match participant"
    i_want: "a compatible post-match playback"
    so_that: "I can review the same battle and result"
    risk: high
    status: planned
  - id: S3.2
    title: "Keep online results auditable"
    as_a: "operator"
    i_want: "server and client outcomes reconciled"
    so_that: "forged or duplicate results never inflate measurement"
    risk: high
    status: planned
  - id: S3.3
    title: "Accept the Restricted build and host"
    as_a: "product owner"
    i_want: "a downloaded two-client walkthrough"
    so_that: "I know what actually works before any wider invitation"
    risk: high
    status: planned
---
# Prove multiplayer and replays — Sprint 3: Replay result integrity and acceptance

**Status:** ⬜ Planned; local replay and result exclusion checks exist, remote acceptance awaits a verified shared match.

## Stories

### Story 3.1 — Watch a participant replay

**As a** match participant, **I want** a compatible post-match playback, **so that** I can review the same battle and result.

**Acceptance:** A new multiplayer replay records initial state/version/content, both sides' accepted orders, checkpoints and terminal outcome. Both participants can open and play/pause the recording after the match, with each participant's fog view preserved. Verification reproduces the server result and names the first divergent tick. Corrupt, oversized or unsupported files fail with a readable reason and remain intact. Existing solo replays continue to verify under their prior schema.

**Risk:** high — untrusted input parsing, state disclosure and persistence; second reviewer.

### Story 3.2 — Keep online results auditable

**As an** operator, **I want** server and client outcomes reconciled, **so that** forged or duplicate results never inflate measurement.

**Acceptance:** The authoritative service emits at most one terminal record per human slot and stores its match, player, version, result and sequence. The existing ingester continues to mark unverified client reports `client_reported`; a reviewed server-to-ingest contract must be in place before any online result is promoted to trusted/eligible. Duplicate, forged, wrong-version, bot and preview/test cases are rejected or excluded and auditable without leaking invite codes. Two-player accepted-for-audit traffic contributes zero public events.

**Risk:** high — North Star integrity, identity and private data; independent data/security review.

### Story 3.3 — Accept the Restricted build and host

**As the** product owner, **I want** a downloaded two-client walkthrough, **so that** I know what actually works before any wider invitation.

**Acceptance:** A source-commit-traceable signed macOS build and declared Linux client connect to a deployed, healthy Restricted service with two independently issued codes. Follow the numbered walkthrough below for full match, impaired profile, rejoin, expiry, replay, excluded receipt and revocation. Confirm TLS, VM capacity, backup/restore, flag switch state, participant notice and no public access. Record exact build IDs, host image, commands, observations and gaps; a merge is not a release.

**Risk:** high — Restricted release and external access; owner acceptance and second review.

## Sprint QA

- **Specs:** multiplayer replay version/limits/hash, participant fog, both-side outcome, ingest duplicate/forged/test exclusion and client/server contract checks.
- **Rendered smoke owed:** signed download from the Restricted owner channel, separate macOS/Linux clients and remote host. Owner repeats join, match, reconnect and playback blind from the steps below.
- **Gate:** source commit is on `origin/master`; separately verify host deployment, signed client fetch, flag state and recorded result before marking the epic shipped.

## Sprint 3 — Smoke walkthrough

Env: Restricted download and HTTPS match host. Fill exact URLs, source commit, build IDs and service image in the QA record at execution; keep invite values in operator-only files.

1. Fetch the signed Restricted macOS build and the declared Linux client from the approved channel.
   → Each build ID matches its manifest and the current host versions.
2. Issue two separate scoped invite codes and join from two profiles.
   → Each participant controls one opposing slot and a revoked or wrong code cannot join.
3. Finish a match under baseline and another under 150 ms RTT/1% loss.
   → Both clients show the same server result; the match record has one terminal result per slot.
4. Disconnect and rejoin within 60 seconds, then repeat and allow expiry.
   → The first restores the same slot; the second visibly ends with no result and no completion event.
5. Open the finished replay on both profiles, pause it, then try a corrupt/incompatible copy.
   → Valid playback reaches the recorded result with participant fog; bad files show a reason and remain intact.
6. Sync test-tagged receipts, revoke both codes and retry join.
   → Audit shows excluded preview events, no public cohort increment and denied new access.

Record each step as pass/fail with exact observations and sanitized logs; any open step keeps the epic in progress.
