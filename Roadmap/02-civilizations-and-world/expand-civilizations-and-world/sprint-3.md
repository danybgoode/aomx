---
epic: expand-civilizations-and-world
sprint: 3
title: "Two new authored maps"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S3.1
    title: "Fight on Narvarte"
    as_a: "solo RTS player"
    i_want: "a balanced street-grid map"
    so_that: "expansion routes change without an unfair start"
    risk: high
    status: planned
  - id: S3.2
    title: "Fight on Copilco"
    as_a: "solo RTS player"
    i_want: "readable chokepoints and alternate routes"
    so_that: "positioning changes while counterplay remains possible"
    risk: high
    status: planned
---
# Expand civilizations and world — Sprint 3: Two new authored maps

**Status:** ⬜ not started

## Stories

### Story 3.1 — Fight on Narvarte
**As a** solo RTS player, **I want** a balanced street-grid map, **so that** expansion routes change without an unfair start.
**Acceptance:** Narvarte has authored, versioned starts, four-resource placements, passability, sight and an identifiable La Roma zone. Both sides can reach comparable early resources and center and attack each other. Every faction and AI level can complete both victory routes. Save/replay pins map ID and hash.
**Risk:** high — map/rules contract.

### Story 3.2 — Fight on Copilco
**As a** solo RTS player, **I want** readable chokepoints and alternate routes, **so that** positioning changes while counterplay remains possible.
**Acceptance:** Copilco has at least two usable approaches to each critical objective, comparable starts and no unavoidable blocked route. The same faction/AI/victory matrix passes. Crowded routes meet the previously declared release-build owner Mac budget or the deviation is recorded for review before release.
**Risk:** high — pathing, AI and performance.

## Sprint QA

- **Specs:** map schema, start/resource reachability, path/visibility, AI route scenarios, save/replay and cross-platform hash checks.
- **Rendered smoke:** both maps at 100% and 125% zoom, minimap and district cues; full local matches including both victory routes.
- **Review:** independent high-risk map/rules review and owner fairness read.

## Sprint 3 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 from `game/README.md`; Restricted owner preview after merge.

1. Choose Narvarte with any faction and start.
   → Its street-grid layout, starts, resources and La Roma objective are visible.
2. Finish Narvarte by Conquest, then restart it and finish by La Roma hold.
   → Both routes give one terminal result and no units remain stuck at the center.
3. Choose Copilco and move a group by each main route toward La Roma.
   → Both routes remain passable and the minimap agrees with the board.
4. Save and resume on Copilco, then complete a match.
   → The same map, faction, match ID and objective progress return.

If any step fails, note the step number and what appeared.
