---
epic: harden-rts-simulation
sprint: 1
title: "Contract and migration seam"
risk: high
phase: Shaping
stories_total: 1
stories:
  - id: S1.1
    title: "Migrate the playable match to versioned rules contracts"
    as_a: "classic RTS player"
    i_want: "the current two-faction match to keep the same commands and outcomes"
    so_that: "future content can grow without breaking my game"
    risk: high
    status: planned
---
# Harden the RTS simulation — Sprint 1: Contract and migration seam

**Status:** ⬜ not started

## Stories

### Story 1.1 — Migrate the playable match to versioned rules contracts

**As a** classic RTS player, **I want** the current two-faction match to keep the same commands and outcomes, **so that** future content can grow without breaking my game.

**Acceptance:**

- Record an architecture decision for canonical state, semantic command payloads, stable entity/content IDs, content and simulation versions, tick/update ordering, seeded RNG, and the scene adapter. It includes a migration path from `game/skirmish.gd`, not a duplicate rules engine.
- Move costs, units, buildings, faction modifiers and objective parameters used by the current match into validated definitions. Unknown IDs, invalid prerequisites and malformed data fail with actionable errors before play.
- Preserve existing move, gather, build, train, attack, selection feedback and both faction differences in the rendered match. No view asset or frame delta determines a simulation outcome.
- A recorded baseline command stream reaches the same canonical end state and both win routes before and after migration. Existing funnel/outbox checks remain green and test-tagged.

**Risk:** high — shared simulation authority and content migration. Second reviewer required.

## Sprint QA
- **Headless specs:** extend `game/tests/skirmish_test.gd`, `faction_test.gd` and `district_test.gd` with before/after command fixture, schema rejection and state hash checks. Run `npm run skirmish:contract` plus existing Godot tests.
- **Rendered smoke owed:** yes, local Godot build for both factions and both win routes; owner checks a downloaded build when available. A browser URL is not this native game's QA surface.
- **Gate:** headless tests and actual rendered walkthrough before review; record Godot version and commit.

## Sprint 1 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 debug build from the sprint commit (`"$GODOT_BIN" --path game`), then the downloaded macOS preview when available. Record the build identifier.

1. Start as Regios, order a worker to gather, build a recruitment post, and train melee and ranged units. → Stockpile, construction and queue behave as the baseline match; unavailable orders explain why.
2. Finish by destroying the opposing command post. → The match records the expected victory once, with a test-tagged local result.
3. Start as Poblanos and contest La Roma with a living fighter; clear an enemy contest. → The district timer follows the baseline and reaches the expected terminal result.
4. Repeat the same command fixture in headless mode. → The canonical state hash matches the recorded baseline.

Record a failed step with build, faction, command and observed state.
