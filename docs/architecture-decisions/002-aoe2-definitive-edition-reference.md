# ADR 002 — Age of Empires II: Definitive Edition as fidelity reference

**Status:** Accepted by the product owner, 2026-10-16
**Scope:** Design and test reference for Battle for La Roma's standalone RTS; no claim of current parity.

## Decision

Use **Age of Empires II: Definitive Edition** as the reference edition for mechanical, behavioral and experiential fidelity. Every system that claims close fidelity must identify the particular DE build/balance patch, scenario setup, observed behavior, tolerance and any intentional deviation. Pin that build when the first numerical scenario baseline is authored. Do not use an unspecified moving live patch as a numerical contract.

The project's rules, content, code and shipping expression remain independently authored. A fidelity reference does not grant permission to bundle proprietary AoE2 assets or data.

## Rationale and consequences

One edition makes comparisons coherent across economy, ages, combat, pathing and pacing. The exact build/patch and the exception policy remain design decisions because both affect fixture values. Until those are recorded, use qualitative DE comparisons and describe gameplay as inspired by AoE2; do not report numerical parity.

The [GDD](../design/GDD.md) remains the global design target. The [full-game build path](../../Roadmap/full-game-build-path.md) orders implementation, and each funded epic defines its own acceptance scope.
