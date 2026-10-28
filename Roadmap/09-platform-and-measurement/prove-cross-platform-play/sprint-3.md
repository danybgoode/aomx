---
epic: prove-cross-platform-play
sprint: 3
title: "Restricted shared play and support decision"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S3.1
    title: "Join a Restricted match from desktop Web"
    as_a: "invited player"
    i_want: "join, command, reconnect and replay against a native peer"
    so_that: "browser shared play has real authority-backed proof"
    risk: high
    status: planned
  - id: S3.2
    title: "Publish only tested support claims"
    as_a: "product owner"
    i_want: "an evidence ledger and limited support statement"
    so_that: "release candidate work knows the real platform boundary"
    risk: low
    status: planned
---
# Prove cross-platform play — Sprint 3: Restricted shared play and support decision

**Status:** ⬜ not started

Desktop Web online play is a separate claim from Web solo export. The existing match service remains authoritative; its current deployed join route failed a locally served Web origin preflight. This sprint permits an exact Restricted origin for internal testing, verifies denial paths, and leaves admission off afterward. No public invitation or eligible cohort is created.

## Stories

### Story 3.1 — Join a Restricted match from desktop Web

**As an** invited player, **I want** to join, command, reconnect and replay against a native peer, **so that** browser shared play has authority-backed proof.

**Acceptance:** Preflight and join succeed only from the named Restricted origin with valid scoped code and matching game/content version. Bad origin, missing/revoked code and mismatch are rejected. A real Web/native pair completes a full match; both see the server terminal record, reconnect works within the defined grace, and replay verifies. Test-tagged receipts remain excluded. Turning off the served preview admission switch stops new joins; live or already completed records follow the existing contract.

**Risk:** high: auth, shared host and result integrity. **QA:** exact-origin/CORS and bad-code tests, version/reconnect/replay contracts, real Web/native full-match smoke, independent security/data review, served Golden Frijoles flag state check in every environment. No credential enters a Web bundle.

### Story 3.2 — Publish only tested support claims

**As the** product owner, **I want** an evidence ledger and limited support statement, **so that** release candidate work knows the real platform boundary.

**Acceptance:** Every proposed OS/browser/device row names source commit, build, scenario, full-match, save, audio/input, frame/memory, online (if claimed), result, reviewer and evidence path. Mark pass, fail or unverified distinctly. The support statement includes only passing rows and says solo versus online explicitly. The #23 release-candidate seed receives the supported matrix and remaining gates without implying a public release.

**Risk:** low. **QA:** compare the ledger against build hashes and QA artifacts, run one owner fresh-install walkthrough per claimed row, review open failures and check the roadmap/poster against actual release state.

## Sprint QA

- Run Node match integration, CORS/auth, replay and funnel acceptance contracts; run Godot client/worker tests.
- Use two distinct scoped test codes and a Restricted host; record browser/native build hashes, server image, origin and match IDs.
- Check served admission flag versions before and after the smoke and revoke both codes. Keep development/preview/production switches recorded.
- Obtain a fresh independent review of auth, origin allowlist and player-result paths before merge.
- Merge to master, deploy host and publish Restricted client separately; verify each from its real endpoint/artifact.

## Sprint 3 — Smoke walkthrough

Env: approved Restricted Web origin and https://alpha-api.159.54.158.4.sslip.io behind the existing allowlist; owner download at https://danybgoode.itch.io/battle-for-la-roma. Record the actual Web preview URL before the walkthrough.

1. Open the approved Web preview and the Restricted native download on separate devices.
   → Both display the matching game/content version.
2. With two fresh scoped test codes and preview admission on, create/join the same room from Web and native.
   → Each sees its own side and valid commands; a bad origin/code is refused.
3. Complete a match, disconnect/reconnect once within grace, then open the retained replay.
   → Both see one server terminal record and a replay that verifies to the same result.
4. Inspect the test-tagged ingest receipts.
   → They are excluded; accepted public cohort counts do not increase.
5. Revoke both codes and turn preview admission off; retry a new join.
   → New admission is refused while the prior result/replay remains intact.
6. Read the support ledger with the owner.
   → Every claimed row has a passing real-device match and save check; missing rows say unverified.

If a step fails, capture its number, origin, build, match ID and observed response before any support claim.
