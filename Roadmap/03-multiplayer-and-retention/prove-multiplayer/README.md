---
status: in-progress
phase: Restricted host QA
slug: prove-multiplayer
title: "Prove multiplayer and replays"
area: 03-multiplayer-and-retention
destination: shared-and-authored-play
risk: high
type: feature
sprints_total: 3
stories_total: 7
intent_match: null
quote_low_usd: 50
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "Today classic RTS players can finish only a solo match. A reliable private match and replay could give friends a reason to play and return together. We'll know first when two people finish a real network match and can watch the same outcome; later-day completion needs an eligible cohort."
target_metric: return_to_match
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Classic RTS players who want to finish a shared match with a friend and review what happened."
grounded: false
grounded_reason: "Internal scripted remote matches now exist, but no eligible player cohort, repeat-play baseline or measured multiplayer demand exists; this remains a feasibility bet before a retention target."
flag_key: multiplayer.private_match_enabled
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 14
---

# Epic: Prove multiplayer and replays

**Current state (2026-10-21):** The Restricted host runs reviewed image `aomx-match:0d29ed3` with the delayed-join and excluded-receipt repairs. The owner completed a signed downloaded-build GUI match and watched its fogged replay. On the current host, native macOS/Linux clients completed baseline and symmetric impaired full matches with matching terminal records/replays, and verified same-slot rejoin plus 60-second no-result expiry. A disposable copy of the current image passed the 50-entity native cross-OS baseline, 100 ms and 150 ms/loss network matrix. Replay-file parsing, offline playback and control placement are merged in PRs #67/#68 and passed signed local GUI checks. [Current QA](../../../docs/multiplayer-qa-2026-10-21.md), [earlier remote QA](../../../docs/multiplayer-remote-qa-2026-10-20.md), and [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) record measurements and limits. The corrected signed build is processing as owner-only itch build #2181405; independent fetch and owner file-open/denial walkthrough remain. Admission is off in every environment. The epic remains in QA until those release checks pass.

> **Area:** 03 Multiplayer and retention · **Risk:** high · **Class:** Feature · **Scope:** [approved pitch](../../00-ideas/seeds/prove-multiplayer.md) · **Destination:** shared-and-authored-play

## Why

A classic RTS player can finish a solo battle but cannot share one with a friend. One reliable, invite-only match and a replay they can both watch should make a second battle worth arranging. The first proof is a complete shared match; later-day return remains unmeasured until an eligible cohort exists.

## Architecture lock

- **D1 — One authority.** Run the current Godot rules on a server process; both clients send validated semantic orders and render authoritative state. The scene, local clock and telemetry never decide outcomes. Revisit [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) with the Sprint 1 matrix before committing to transport details.
- **D2 — Version and slot contract.** Negotiate protocol, game, command, simulation and content versions/hashes before a match starts. Two human slots have stable opposing team IDs and no diplomacy. Bind each slot to an individual, revocable invite code and pseudonymous installation ID; reject cross-slot commands, stale/duplicate sequences and malformed packets before mutation. Never put a provider, database or VM key in a client.
- **D3 — Restricted host.** Use the existing Oracle VM's TLS ingress, isolated alpha services and invite-code store with least-privilege access. Keep the match process separate from the ingest/database authority and cap rooms, payloads, rate and runtime. A code is issued per participant; neither an open signup nor a shared room password is in scope. Update participant notice for IP/session/replay data and verify revocation before invitation.
- **D4 — Reconnect and divergence.** The server stores the last accepted order and authoritative snapshot. A disconnected participant has 60 seconds to rejoin the same slot; otherwise both see no result. A reconnect resends state and acknowledges commands without duplicating them. Checkpoint hashes, first divergent tick and network metrics are diagnostics, not authenticity proof.
- **D5 — Replays.** Record both sides' accepted orders, starting state/content, ordered checkpoints and terminal result under a new multiplayer replay version. A participant can play/pause after completion with their fog view preserved. Corrupt/unsupported files return a clear error and remain intact; old solo replay behavior stays valid.
- **D6 — Results and measurement.** The server issues one terminal record per participant. Test traffic is excluded. The existing alpha ingest labels client results `client_reported`; do not promote online trust or cohort eligibility until a reviewed backend acceptance contract binds server result, player, match, version and deduplication. No retention inference from this preview.
- **D7 — Flag and release.** `multiplayer.private_match_enabled` is a server-side enablement gate at admission, disabled by default in every Golden Frijoles environment. Switching it off stops new sessions without changing a live match. Record each environment's served version. Merge is integration; deploy the host and signed Restricted build separately, verify the actual download and real two-client match, then record build IDs and results.

The owner approved a Restricted remote host via invite code, the 60-second no-result policy, participant-only fog-preserving replay, and merges and Restricted releases for this epic on 2026-10-19. The L appetite is reviewed after each sprint. New core rules, public invitations, ranked play and a production cohort remain out of scope.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`, `game/rules_content.gd`, `game/content/skirmish.v1.json`: validated commands, fixed tick, stable IDs, content hashes and both terminal routes.
- `game/skirmish_persistence.gd`, `game/skirmish_replay.gd`: canonical state, local save and divergent-tick diagnostics.
- `game/skirmish_main.gd` and HUD: native input and presentation; extend with network/replay states without a second rules engine.
- `src/funnel/postgres.mjs`, `scripts/alpha-invite.mjs`, `deploy/alpha/`: existing invite storage, alpha VM, TLS and Restricted distribution.
- `game/funnel_outbox.gd`, `src/funnel/ingest.mjs`, `docs/launch-funnel-contract.md`: match identity, receipts, duplicate guards and test exclusion.
- [Foundation benchmark](../../../docs/simulation-benchmark-2026-10-16.md) and [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md): narrow cross-OS evidence and the provisional server-authoritative direction.

## Scope and review boundaries

| Sprint | Stories | Evidence at boundary |
| --- | --- | --- |
| [1 · Model and session contract](sprint-1.md) | S1.1 model proof; S1.2 versioned, invited session contract | Representative cross-OS/Web feasibility and delay/loss matrix, updated ADR, protocol/authorization tests and independent review. |
| [2 · Restricted shared match and recovery](sprint-2.md) | S2.1 remote full match; S2.2 reconnection | Separate invited macOS/Linux clients, TLS/VM and resource evidence, 150 ms RTT/1% loss full match, revocation and recovery smoke. |
| [3 · Replay, integrity and acceptance](sprint-3.md) | S3.1 replay; S3.2 result integrity; S3.3 Restricted QA | Participant playback, version/error tests, server/client result audit, signed download and numbered owner walkthrough. |

## Deploy order

1. Lock protocol/game/content versions and commit the server/client contract. Review the high-risk authority, invite and data surfaces before merge.
2. Deploy the isolated match service behind TLS with admissions disabled and a health route. Verify backup/restore and resource caps. Create the Golden Frijoles enablement flag and set each environment's switch explicitly.
3. Publish a signed Restricted client built from the reviewed source, fetch it independently, then enable only the approved preview environment. Issue distinct scoped codes from operator-only storage; never commit or display code values in logs.
4. Run a real two-client match, disconnect/rejoin, replay and excluded receipt smoke. Record source commit, build ID, host image, packet profile and outcome. Revocation must close further joins. No public invitation is implied.

## Definition of Done

- [ ] Seven stories meet their acceptance checks, with independent review for protocol, authorization, replay parsing and result integrity.
- [ ] A representative model matrix records declared devices/Godot build, map, units, duration, seed, RTT/loss, command bursts, first divergence, server CPU/memory and bandwidth; ADR 004 is updated with the measured decision.
- [ ] Two distinct invited clients on macOS and Linux complete a full match through the Restricted remote host in baseline and 150 ms RTT/1% loss conditions, with identical server terminal results and no unexplained divergence.
- [ ] A disconnect/rejoin within 60 seconds restores the same slot without duplicate orders/results; expiry produces a visible no-result for both clients.
- [ ] Both participants can play/pause a compatible recorded match with fog preserved; malformed/old versions fail clearly without deleting files.
- [ ] The online result and existing ingest contract are reviewed: test events are excluded, duplicate/forged claims do not become eligible, and no unverified `client_reported` event is relabeled trusted.
- [ ] The Restricted host, TLS route, separate revocable codes, participant notice, resource and backup checks, signed client download and numbered owner smoke are evidenced. The flag exists with an explicit served switch in every environment.
- [ ] Merge is verified on `origin/master`; actual host deployment and signed build are independently verified. Update poster, generated board and retrospective with facts, promote durable learnings, then set `status: shipped`.
