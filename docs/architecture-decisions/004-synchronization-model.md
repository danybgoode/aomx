# ADR 004: Use a server-authoritative private-match prototype

**Date:** 2026-10-16
**Status:** Prototype selected; release gate remains open

## Decision

Continue the solo game with the versioned, replayable simulation in [ADR 003](003-simulation-contract.md). The private-match prototype runs one Godot simulation in a server process. Each client sends semantic orders and renders only its authoritative, fog-filtered view. A reconnect receives the latest state and order sequence. A server-verified replay streams only the participant's view. The host admits two individual invite codes and one match per process. This is the selected implementation model for a bounded Restricted test, not a proven reliability claim.

Deterministic lockstep is attractive because it transmits commands cheaply, but a single divergent client can corrupt the shared match, and reconnect requires an agreed state/history transfer. The two 700-tick faction fixtures matched on macOS and Linux with pinned Godot 4.7.2; that narrow result does not establish cross-device determinism. Web, mobile, differing Godot revisions, long generated maps and reconnect are untested. A hybrid model still needs an authority and reconciliation rules, so it is not a shortcut yet. Server authority has operating costs and latency tradeoffs, but isolates game outcomes from client frame rates and gives reconnect a concrete source of truth.

## Evidence added 2026-10-20

The local macOS arm64 Godot 4.7.2 worker completed 1,000 ticks on La Roma, seed 1, four starting entities, four resources and fog. Request latency averaged 7.024 ms (p95 9.110 ms, max 30.964 ms), with 136,592 KiB worker RSS and 2,158/2,354-byte side views. Its final canonical hash was `4d6266cbe25b249d14570136fecc20961863f33338e20a0d7f02021b80844905`. The same 1,000-tick run in the pinned Linux amd64 image under Docker Desktop emulation matched the hash. The image also passed a nonroot, read-only, resource-limited worker init/tick and a complete terminal replay verification. Two native Godot clients locally joined opposite slots, received fogged state, ordered and rejoined; a separate full terminal recording replayed as 103 side-specific frames for each participant. [Local evidence and gaps](../multiplayer-prototype-evidence-2026-10-20.md) lists commands and limits.

These runs support the authority design and local feasibility. They do not measure native Linux versus macOS devices, a large army over the network, Web joining, 100/150 ms RTT, 1% loss, or a remote TLS match. The existing [163-entity solo matrix](../simulation-benchmark-2026-10-16.md) covers local rule performance only.

## Next decision gate

Before enabling a remote invitation or declaring Sprint 1 complete, benchmark a representative four-resource, fogged, large-army match on native macOS and Linux and check Web joining. Include reconnect, command bursts, baseline, 100 ms RTT and 150 ms RTT/1% loss. Record tick CPU, worker memory, network volume, command acknowledgement delay, divergence count and first divergent tick. Revisit this ADR with those measurements and a real player/device target. Keep the server admission flag off until the gate passes.
