---
epic: build-large-la-roma-battlefield
sprint: 2
title: "Resource journeys"
risk: high
phase: In review
stories_total: 1
stories:
  - id: S2.1
    title: "Expand beyond the starting economy"
    as_a: "classic RTS player"
    i_want: "safe starting resources and separate contested expansion sites"
    so_that: "scouting and positioning change my plan"
    risk: high
    status: in-progress
---

# Build a large La Roma battlefield — Sprint 2: Resource journeys

**Status:** 🟦 In review — route/resource simulation checks pass; downloaded-build and owner observation remain open

### Story 2.1 — Expand beyond the starting economy

**As a** classic RTS player, **I want** safe starting resources and separate contested expansion sites, **so that** scouting and positioning change my plan.

**Acceptance:** Each side has reachable starter sources for all four resources and at least two separated expansion choices reached by distinct traversable routes. Neither side gets hidden AI knowledge. The AI can scout, gather, build and attack legally on the large map; a player can choose a forward site and defend it. Crowded bicitaxi, worker and army movement has no silent permanent stall or overlap, building removal reopens routes, and save/resume preserves the result. Record first-gather and expansion travel times, buildable area and contested-site access before declaring the layout fair.

**Risk:** high — economy, AI, routing and complete-match pacing.

## Sprint QA

- **Deterministic:** source and spawn validation, per-side route access, fog, AI commands, crowd recovery, building placement/destruction, save/replay and macOS/Linux hash cases.
- **Rendered:** start, two expansion routes, selected bicitaxi/worker and crowded crossing at 1280×800 and 1024×700.
- **Performance:** representative 96×96 case against D7's declared budget; revise the map/rules only with a recorded scope decision if the budget fails.

## Sprint 2 — Smoke walkthrough

Environment: signed Restricted macOS preview, record its exact build ID and download source.

1. Scout from home to two separated resource sites. → The minimap and revealed ground make the alternate journeys distinct.
2. Send workers to gather at a newly revealed site and build a forward support structure. → Orders are legal, the route works and the starting economy remains viable.
3. Move a bicitaxi and mixed group through a crowded crossing; then place or destroy an obstacle and repeat. → Units progress by an alternate route or retain a visible, actionable no-route result.
4. Save, quit and resume. → Positions, fog, orders and resources match the saved state.

Record every failure by step and build ID; a synthetic crowd check alone is insufficient.

**2026-10-23 builder checkpoint:** Starter and expansion sites have symmetric route lengths; the four expansion stocks save and replay independently. The AI bicitaxi now receives legal scouting waypoints, and workers select an expansion only after normal sight has explored it. Blocked workers preserve cargo, redirect after a drop-off is destroyed, deposit at an adjacent valid drop-off and release an exhausted source order. Static obstacle and parked-unit reroutes pass deterministic checks. An independent reviewer verified district and enemy-post routes from both homes and exercised the AI conquest path. The owner crossing, spacing and downloaded-build observations remain open.
