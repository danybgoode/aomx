---
epic: prove-multiplayer
sprint: 1
title: "Model and session contract"
risk: high
phase: Restricted host QA
stories_total: 2
stories:
  - id: S1.1
    title: "Measure and select the network model"
    as_a: "builder"
    i_want: "a representative cross-environment model comparison"
    so_that: "the shared match has a defensible authority design"
    risk: high
    status: in-progress
  - id: S1.2
    title: "Join a versioned, invited session"
    as_a: "invited player"
    i_want: "my own authorized slot and validated commands"
    so_that: "a stranger or incompatible client cannot control my match"
    risk: high
    status: in-progress
---
# Prove multiplayer and replays — Sprint 1: Model and session contract

**Status:** 🔧 In progress; the versioned, invite-bound contract passed local and Restricted-host tests. Native macOS/Linux join and recovery and an impaired scripted terminal passed. The 162-entity fixture matched hashes but failed native ARM64 route/tick p95 budgets under the live CPU cap. Resolve that scale gate; Web and the 100 ms/symmetric 150 ms network matrix remain open. See [remote QA](../../../docs/multiplayer-remote-qa-2026-10-20.md).

## Stories

### Story 1.1 — Measure and select the network model

**As a** builder, **I want** a representative cross-environment model comparison, **so that** the shared match has a defensible authority design.

**Acceptance:** Pin Godot, OS, build mode, map, faction, seed, four-resource/fog/large-army workload, command burst and duration. Run the same ordered command stream on macOS and Linux and a Web feasibility case; compare hashes or authoritative reconciliation. Probe baseline, 100 ms RTT/no loss and 150 ms RTT/1% loss. Record server tick CPU, memory, bandwidth, divergence/desync count and first divergent tick. Update ADR 004 with the measured model and why. If the scenario cannot support the proposed model, stop and re-scope before transport work.

**Risk:** high — shared simulation and model choice; independent architecture review.

### Story 1.2 — Join a versioned, invited session

**As an** invited player, **I want** my own authorized slot and validated commands, **so that** a stranger or incompatible client cannot control my match.

**Acceptance:** A server process owns one match and two stable opposing slots/teams. Join checks individual revocable invite code, pseudonymous installation ID, protocol/game/command/simulation/content versions and capacity before sending state. A scoped code cannot take the other slot. Commands carry match, slot, tick and sequence; reject malformed, unauthorized, stale or duplicate orders before mutation. Cap payloads/rates and avoid logging codes or credentials. Create the Golden Frijoles enablement flag in each environment, off by default; gate server admission only and inspect served switch versions. A two-client headless session proves join, denial and accepted command ordering.

**Risk:** high — authorization, protocol and shared infrastructure; independent security review.

## Sprint QA

- **Specs:** Godot cross-OS command/hash fixture plus Node protocol and invite tests with rejected packets, replayed sequences and revoked codes. Use the existing simulation and alpha invite store.
- **Rendered smoke owed:** a native client shows join, version mismatch and denial states; the owner checks the Restricted connection wording. No gameplay release at this boundary.
- **Gate:** benchmark report, ADR and independent review before Sprint 2.

## Sprint 1 — Smoke walkthrough

Env: local match server and two local debug clients; record exact commit and Godot version. The Restricted URL is added after host deployment.

1. Start the match server with admission enabled for two test codes, then join from two separate client profiles.
   → Each receives one different team/slot and the same map, seed and rules versions.
2. Attempt a third join, a revoked code and a mismatched content version.
   → Each receives a readable rejection; the match state and first two slots remain unchanged.
3. Send one legal command, then resend it and send one cross-slot command.
   → The legal order is accepted once; duplicates and cross-slot orders are rejected without state change.
4. Run the pinned stress fixture on each declared environment and read ADR 004.
   → The report contains hashes/reconciliation, packet profiles, resource use and an explicit model decision.

Record failed steps with build ID, session ID (no code), OS and expected/actual response.
