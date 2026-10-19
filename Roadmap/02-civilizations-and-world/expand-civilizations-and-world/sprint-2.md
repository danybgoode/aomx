---
epic: expand-civilizations-and-world
sprint: 2
title: "Two new playable factions"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S2.1
    title: "Play Oaxaqueños with resource support"
    as_a: "solo RTS player"
    i_want: "a resource-efficiency strategy with a visible cost"
    so_that: "I can choose and counter a different opening"
    risk: high
    status: in-progress
  - id: S2.2
    title: "Play Veracruzanos with mobility and trade"
    as_a: "solo RTS player"
    i_want: "a mobile trade strategy with a visible counter"
    so_that: "a second faction changes map-control decisions"
    risk: high
    status: in-progress
---
# Expand civilizations and world — Sprint 2: Two new playable factions

**Status:** 🏗 Faction effects, legal research, AI, save and replay pass builder checks; natural full-match and owner counterplay reads remain open. See the [world QA record](../../../docs/world-expansion-qa-2026-10-19.md).

## Stories

### Story 2.1 — Play Oaxaqueños with resource support
**As a** solo RTS player, **I want** a resource-efficiency strategy with a visible cost, **so that** I can choose and counter a different opening.
**Acceptance:** The setup states a fictional strength, cost and counter in plain language. The efficiency and technology effect change a legal economy or support decision under canonical rules. Oaxaqueños can win and lose against each other and both existing factions; the AI pays the same costs and sees only legal information. Save and replay reproduce outcomes.
**Risk:** high — combat/economy rules.

### Story 2.2 — Play Veracruzanos with mobility and trade
**As a** solo RTS player, **I want** a mobile trade strategy with a visible counter, **so that** a second faction changes map-control decisions.
**Acceptance:** The setup states a fictional strength, cost and counter. Mobility/trade and technology effects change opening and counterplay without a hidden AI bonus. Veracruzanos can win and lose against all factions by Conquest and La Roma. Their ownership cue is understandable without color alone; save/replay remains deterministic.
**Risk:** high — simulation and AI.

## Sprint QA

- **Specs:** faction matchups and controlled economy/combat scenarios in `game/tests/faction_test.gd` and `game/tests/strategic_progression_test.gd`; AI legal-information and replay checks.
- **Rendered smoke:** full local match as each new faction at gameplay zoom, showing strength, weakness, tech choice and counter feedback.
- **Review:** independent high-risk rules review and owner portrayal read.

## Sprint 2 — Smoke walkthrough (do these in order)
Env: local Godot 4.7.2 from `game/README.md`; Restricted owner preview after merge.

1. Choose Oaxaqueños and La Roma, then start.
   → Setup and HUD describe the resource-support advantage and its cost in words.
2. Complete an Oaxaqueño match using its technology choice.
   → The logged research and terminal result survive save/resume.
3. Return to setup, choose Veracruzanos and start.
   → Mobility/trade and its weakness are explained without relying on a regional joke.
4. Contest La Roma and finish the Veracruzano match.
   → The AI responds through normal commands and one test-tagged result is saved.

If any step fails, note the step number and what appeared.
