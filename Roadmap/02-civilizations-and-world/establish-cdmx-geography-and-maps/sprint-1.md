---
epic: establish-cdmx-geography-and-maps
sprint: 1
title: "Source and map contract"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S1.1
    title: "Verify CDMX sources and place registry"
    as_a: "map author"
    i_want: "stable reviewed place references"
    so_that: "visible geography has a traceable source"
    risk: high
    status: planned
  - id: S1.2
    title: "Validate authored map metadata"
    as_a: "map author"
    i_want: "a checked map contract"
    so_that: "decorative and playable geometry cannot be confused"
    risk: high
    status: planned
---
# Establish CDMX geography and map data — Sprint 1: Source and map contract

**Status:** ⬜ not started

## Stories

### Story 1.1 — Verify CDMX sources and place registry
**As a** map author, **I want** stable reviewed place references, **so that** visible geography has a traceable source.
**Acceptance:** Record all 16 alcaldías with stable IDs/names, plus focused Roma Norte and Fuente de Cibeles records. For every candidate source record publisher, resource URL, version/date, license, attribution, coordinate reference and import decision. Uncertain placements remain unresolved. No unreviewed geometry enters runtime content.
**Risk:** high · geographic assertion and commercial redistribution.

### Story 1.2 — Validate authored map metadata
**As a** map author, **I want** a checked map contract, **so that** decorative and playable geometry cannot be confused.
**Acceptance:** Keep the existing `la_roma` map functional while adding stable place/territory references, tile semantics, objective/spawn metadata and localization keys. Deterministically reject unknown IDs, contradictory tile roles and inaccessible starts/objectives. Preserve Narvarte/Copilco loading.
**Risk:** high · shared map and content contract.

## Sprint QA
- **Headless:** source/ID validation and malformed metadata fixtures, existing world-expansion and contract checks.
- **Review:** independent source/license/portrayal read before geography import; inspect a clean content diff.
- **Rendered:** current La Roma, Narvarte and Copilco still start.

## Sprint 1 — Owner smoke walkthrough

Env: local Godot project at `game/project.godot` (no web URL; see `game/README.md`).

1. Open the recorded geography registry and inspect the Cuauhtémoc, Roma Norte and Cibeles entries. → Each displays a source, rights decision and uncertainty status.
2. Start a La Roma skirmish in Godot. → The existing board and Cibeles objective load.
3. Start Narvarte, then Copilco. → Both existing maps still load with valid starting units.

If a step fails, record its number, build/content ID and what appeared.
