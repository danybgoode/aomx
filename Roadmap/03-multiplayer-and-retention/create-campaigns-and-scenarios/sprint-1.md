---
epic: create-campaigns-and-scenarios
sprint: 1
title: "Mission contract"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S1.1
    title: "Validate bounded mission definitions"
    as_a: "campaign author"
    i_want: "a checked format for missions on existing maps"
    so_that: "bad objectives cannot enter a match"
    risk: high
    status: done
  - id: S1.2
    title: "Advance objectives on fixed ticks"
    as_a: "campaign player"
    i_want: "mission goals that follow my actual orders"
    so_that: "progress and results feel fair and repeatable"
    risk: high
    status: in-progress
---

# Create the first campaign chapter — Sprint 1: Mission contract

**Status:** 🟨 In progress — manifest validation and fixed-tick goals pass; native rendered walkthrough remains open.

### Story 1.1 — Validate bounded mission definitions ✅ 4a66f9d

**As a** campaign author, **I want** a checked format for missions on existing maps, **so that** bad objectives cannot enter a match.

**Acceptance:** A versioned manifest describes three stable mission IDs, map IDs, prerequisites, objective conditions and plain copy. Loading rejects unknown/duplicate IDs, cycles, malformed conditions and unsupported actions with a reason before starting. Existing map content and solo setup still load.

**Risk:** high — shared content and simulation contract.

### Story 1.2 — Advance objectives on fixed ticks

**As a** campaign player, **I want** mission goals that follow my actual orders, **so that** progress and results feel fair and repeatable.

**Acceptance:** The first Copilco mission observes gathering, construction and recruitment through canonical state, with bounded ordered transitions. The scene displays state but cannot grant a win. Mission state enters snapshots, saves and replay hashes. AI remains legal and has no hidden vision.

**Risk:** high — deterministic rules, persistence and replay.

## Sprint QA

- **Headless specs:** valid/invalid manifest fixtures, fixed-tick objective ordering, duplicate trigger, legacy skirmish hash, save/replay round trip and malformed/old-version retention.
- **Rendered smoke:** yes, local native Godot 4.7.2 at 1024×700 and 1280×800; owner repeats on the signed Restricted build at epic close.
- **Review:** independent high-risk review before merge; run the game/README.md Godot suites and npm run skirmish:contract.

## Sprint 1 — Smoke walkthrough

Environment: local Godot 4.7.2, launched from the repository root with the command in game/README.md; record build/content IDs.

1. Open the campaign entry and select Arrival in Copilco. → The map and goal appear before the match starts.
2. Gather the named resource, construct a recruitment building and recruit a unit. → Each corresponding goal advances once after the real order completes.
3. Save, quit Godot, reopen and resume the same mission. → Goal state, entities, match ID and progress remain intact.
4. Load an intentionally invalid mission fixture in a test profile. → The game rejects it with a reason and leaves the good saved match intact.

Record failed step, build ID and observed result.

**Builder checkpoint · 2026-10-27:** The three-mission manifest rejects invalid prerequisites, unsupported conditions and excessive thresholds. Fixed-tick mission goals, conditional snapshot state, save restore and legal-command replay pass game/tests/campaign_missions_test.gd. Existing skirmish, replay, persistence, cross-platform hash and Godot-to-ingest checks pass. The rendered owner walkthrough and independent review are still owed before sprint close.
