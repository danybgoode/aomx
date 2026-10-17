# ADR 004: Defer multiplayer transport; plan an authoritative simulation

**Date:** 2026-10-16
**Status:** Provisional architecture direction

## Decision

Continue the solo game with the versioned, replayable simulation in [ADR 003](003-simulation-contract.md). For future multiplayer design, start from a server authoritative simulation with client commands, snapshots and reconciliation. Do not implement transport in this epic. Keep command schemas and replay hashes useful for diagnosis and automated comparison.

Deterministic lockstep is attractive because it transmits commands cheaply, but a single divergent client can corrupt the shared match, and reconnect requires an agreed state/history transfer. Local fixed ticks and macOS hashes do not establish cross-device determinism. Linux CI compares the two 700-tick fixtures; Web, mobile, differing Godot revisions, long generated maps and reconnect are untested. A hybrid model still needs an authority and reconciliation rules, so it is not a shortcut yet. Server authority has operating costs and latency tradeoffs, but isolates game outcomes from client frame rates and gives reconnect a concrete source of truth.

## Next decision gate

Before funding online play, benchmark a representative four-resource, fogged, large-army match on two OSes and Web, including save/reconnect, command bursts, latency and rollback/reconciliation behavior. Record server CPU and memory per match, network volume, desync count and first divergent tick. Revisit this ADR with those measurements and a real player/device target. The [current scale report](../simulation-benchmark-2026-10-16.md) supports local solo performance only.
