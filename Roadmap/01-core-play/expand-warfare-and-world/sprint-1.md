---
epic: expand-warfare-and-world
sprint: 1
title: "Scout and move on a larger map"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Scout an authored larger battlefield"
    as_a: "classic RTS player"
    i_want: "to reveal routes and threats on a larger map"
    so_that: "exploration changes my plan without hiding the objective"
    risk: high
    status: in-progress
  - id: S1.2
    title: "Move an army through congestion"
    as_a: "classic RTS player"
    i_want: "my group to reach a lane or receive a clear no-route result"
    so_that: "movement orders remain trustworthy in a larger battle"
    risk: high
    status: in-progress
---

# Expand warfare and world — Sprint 1: Scout and move on a larger map

**Status:** 🏗 In progress — owner reports crowd stalls; S1.2 requires reproduction and repair before downloaded-build smoke.

### Story 1.1 — Scout an authored larger battlefield

**As a** classic RTS player, **I want** to reveal routes and threats on a larger map, **so that** exploration changes my plan without hiding the objective.

**Acceptance:** One authored map offers balanced starting access, traversable lanes and a visible central objective. Current sight, explored ground and hidden ground are distinct. Elevation affects passability and sight only. Human and AI receive the same fair-information rules; orders against a lost target have explicit feedback. Save/replay preserves visibility. At 1024×700 and 1280×800, normal and 120% zoom, the owner can find units and the district without knowing a cultural reference.

**Risk:** high — shared simulation, content and save state.

### Story 1.2 — Move an army through congestion

**As a** classic RTS player, **I want** my group to reach a lane or receive a clear no-route result, **so that** movement orders remain trustworthy in a larger battle.

**Acceptance:** Seeded opposing crowds resolve without permanent overlap or a silent stuck unit. Building placement/destruction and restore trigger the expected route response. Declare the owner Mac target and route/tick/frame/memory budgets before tuning; measure the representative larger battle in debug/headless and rendered release builds. Retain the existing 48×48/163-entity matrix as comparison evidence.

**Owner failure to resolve, 2026-10-23:** workers and other units can remain blocked against each other. Capture a saved/replayable owner case if available, and reproduce worker delivery/gathering and mixed-group lane conflicts beyond the current wait/abort thresholds. When a legal alternate route exists, units progress without permanent overlap. With no route, the failure remains visible in selected-unit status rather than silently becoming idle; a worker carrying resources has an explicit recoverable state. Verify swaps, same-destination orders, production exits, obstacle changes, restore/replay and cross-platform hashes. The [owner review](../../00-ideas/audits/2026-10-23-owner-interface-movement-map.md) records the plausible code mechanism and wider acceptance contract.

**Risk:** high — pathing and performance of every match.

## Sprint QA

- **Deterministic specs:** content/map validation, sight/visibility, lost target, crowd/reroute, save/replay and macOS/Linux hash cases. Assert observable command results and state.
- **Rendered smoke:** local Godot and signed Restricted owner preview at both declared desktop sizes and zoom states; capture fog, objective and a crowded crossing.
- **Gate:** Godot 4.7.2 headless suite, Node game-to-ingest contract, representative benchmark with declared budgets and independent high-risk review.

## Sprint 1 — Smoke walkthrough

Environment: the signed Restricted macOS preview; record its actual build ID and download source.

1. Open the downloaded app, choose Regios and start the larger map. → The district and starting area are clear while distant enemy ground is hidden.
2. Send a scout across the elevated crossing. → The route and enemy approach reveal locally; explored ground remains distinct when the scout leaves.
3. Select a newly hidden enemy target and try Attack. → The declared lost-target response appears without revealing its live position.
4. Move a group through a crowded lane, then place or destroy an obstacle and repeat. → The group passes or reports no route; none remains silently overlapped or stuck.
5. Save, quit, resume and revisit the crossing. → Visibility and positions resume consistently; no second match start is emitted.

Record each step's result and failure by number. The owner checks the downloaded build; headless assertions alone do not close this sprint.

**2026-10-18 checkpoint:** `preview-c5e705309257` was signed and uploaded to the Restricted channel as build #2157380; it is processing. Local rendered fog/crowd captures and deterministic checks passed. Downloaded-app steps 1–5 are pending owner execution and must be recorded individually before this sprint closes.

**2026-10-23 repair checkpoint:** Occupancy-aware replanning now makes a moving unit detour around a parked ally and lets a gatherer approach a crowded source from another side. Both seeded cases assert no overlap and eventual progress in the Godot warfare suite; the game-to-ingest contract also passes. The owner crowd case, blocked-cargo recovery, larger-map benchmark, restore/replay and downloaded-app walkthrough remain open acceptance work.
