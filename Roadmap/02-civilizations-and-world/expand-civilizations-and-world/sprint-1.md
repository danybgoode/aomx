---
epic: expand-civilizations-and-world
sprint: 1
title: "Content contract and roster"
risk: high
phase: Locking architecture
stories_total: 2
stories:
  - id: S1.1
    title: "Approve four faction doctrines and map briefs"
    as_a: "player choosing another skirmish"
    i_want: "clear strengths, weaknesses and map identities"
    so_that: "the next match offers a fair new plan"
    risk: high
    status: planned
  - id: S1.2
    title: "Version faction, map and technology choices"
    as_a: "player saving a match"
    i_want: "my chosen rules and map preserved"
    so_that: "resume and replay cannot silently change my result"
    risk: high
    status: planned
---
# Expand civilizations and world — Sprint 1: Content contract and roster

**Status:** ⬜ not started

## Stories

### Story 1.1 — Approve four faction doctrines and map briefs
**As a** player choosing another skirmish, **I want** clear strengths, weaknesses and map identities, **so that** the next match offers a fair new plan.
**Acceptance:** Regios and Poblanos keep current rules. Oaxaqueños use a fictional resource-efficiency/support plan and Veracruzanos use a fictional mobility/trade plan, as approved by the owner on 2026-10-19. Each has a versioned technology choice, weakness and counter in a written roster. Narvarte and Copilco briefs state starts, routes, resources, La Roma access and visual identity. Names and humor never state regional stereotypes as facts. Exact numerical values are recorded and checked against match scenarios before lock.
**Risk:** high — core rules and portrayal.

### Story 1.2 — Version faction, map and technology choices
**As a** player saving a match, **I want** my chosen rules and map preserved, **so that** resume and replay cannot silently change my result.
**Acceptance:** Content validation rejects unknown faction/map IDs, invalid tech prereqs and invalid starts. Match creation pins content and map IDs. Save/replay verify the IDs and hash; an incompatible old save remains on disk with a clear reason. Existing current-map cases still pass.
**Risk:** high — shared simulation and persistence contract.

## Sprint QA

- **Specs:** `game/tests/rules_content_test.gd`, `game/tests/skirmish_persistence_test.gd`, `game/tests/skirmish_replay_test.gd` and the current hash fixtures.
- **Rendered smoke:** Godot local faction/map setup at 1280×800 and 1024×700; owner checks names and strategy descriptions before Sprint 2.
- **Review:** independent high-risk review of content IDs, version migration and portrayal record.

## Sprint 1 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 from `game/README.md`; Restricted owner preview after merge.

1. Start the Godot skirmish and open the setup screen.
   → Four faction names and three map names are visible with distinct, plain-language descriptions.
2. Choose Regios and La Roma, then start a match.
   → The familiar match begins with its existing resource and objective rules.
3. Save the match, return to setup and choose Resume.
   → The same faction, map, match ID and rules return.
4. Try a save from an unsupported content version.
   → The client explains the mismatch and leaves the file available for recovery.

If any step fails, note the step number and what appeared.
