---
epic: establish-cdmx-geography-and-maps
sprint: 2
title: "Playable Roma Norte/Cibeles map"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S2.1
    title: "Explain and select La Roma"
    as_a: "skirmish player"
    i_want: "clear map choice"
    so_that: "I can choose the battlefield with any faction"
    risk: low
    status: planned
  - id: S2.2
    title: "Play the revised fair map"
    as_a: "skirmish player"
    i_want: "a recognizable and fair Cibeles arena"
    so_that: "I can win by either stated route"
    risk: high
    status: planned
---
# Establish CDMX geography and map data — Sprint 2: Playable Roma Norte/Cibeles map

**Status:** ⬜ not started

## Stories

### Story 2.1 — Explain and select La Roma
**As a** skirmish player, **I want** a clear map choice, **so that** I can choose the battlefield with any faction.
**Acceptance:** The existing setup identifies Roma Norte/Cibeles as a stylized arena and states both win routes. Every current faction can start the map; no campaign progress gates it. Existing map choices remain.
**Risk:** low · non-commerce UI.

### Story 2.2 — Play the revised fair map
**As a** skirmish player, **I want** a recognizable and fair Cibeles arena, **so that** I can win by either stated route.
**Acceptance:** Authored streets, blockers, decorations, resources, spawns and Cibeles references match the approved contract. Both sides have viable resource/objective access under matched seeds. AI, fog/LOS, selection and both victory routes pass deterministic checks and full rendered matches.
**Risk:** high · shared simulation/map behavior.

## Sprint QA
- **Headless:** path/access, resource distance, AI command, fog, selection and both terminal routes under matched seeds; current world-expansion and replay checks.
- **Rendered:** setup at supported sizes and full La Roma play under both victory routes.
- **Owner:** compare visible names and portrayal with the verified record; record any rule or cultural decision.

## Sprint 2 — Owner smoke walkthrough

Env: local Godot project at `game/project.godot`; repeat on the signed Restricted build in Sprint 3.

1. Open skirmish setup and select La Roma. → Roma Norte/Cibeles context and both win routes are visible.
2. Choose each of the four factions in turn and start a match. → Each loads the same map without a mission gate.
3. Command units toward Cibeles and nearby resources. → Routes, selection and fog reveal work without hidden blockers.
4. Finish by destroying the opposing command post. → A terminal win appears.
5. Restart and finish by holding Cibeles. → The hold timer and terminal win appear.

If a step fails, record its number, seed, side, build/content ID and observed result.
