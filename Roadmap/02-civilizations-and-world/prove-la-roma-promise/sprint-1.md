---
epic: prove-la-roma-promise
sprint: 1
title: "Choose counterable factions"
risk: low
phase: Verifying
stories_total: 1
stories:
  - id: S1.1
    title: "Choose two counterable factions"
    as_a: "solo RTS player"
    i_want: "to choose a faction with a visible rule difference"
    so_that: "my opening strategy and counterplay change"
    risk: low
    status: done
---
# Prove the La Roma promise — Sprint 1: Choose counterable factions

**Status:** ✅ builder verified; owner comprehension check remains in Sprint 3

## Player outcome

A player chooses Regios or Poblanos before the solo match, reads each faction's plain-language advantage and weakness, then plays against the other faction. This is the first runnable slice of the [approved pitch](../../00-ideas/seeds/prove-la-roma-promise.md).

## Stories

### ✅ Story 1.1 — Choose two counterable factions

**As a** solo RTS player, **I want** to choose a faction with a visible rule difference, **so that** my opening strategy and counterplay change.

**Acceptance:**

- The setup explains both factions without requiring knowledge of a regional joke. The chosen faction is shown during play and after restart; the computer uses the other.
- Regios deliver five resource per worker trip rather than four, while melee and ranged each cost one extra resource. Poblanos use baseline economy and combat costs; their command post has 60 health and recruitment post has 36 health, each 20% over baseline.
- The same rules apply whether a faction is human or computer controlled. Command validation, deterministic replay and the existing conquest terminal rule still work.
- The owner can complete a local match as either faction and identify an advantage, weakness and counter for each. Names describe fictional play styles, not actual people.

**Risk:** low. Rule and copy changes in a local game prototype; no new player data boundary.

## Sprint QA

- **Headless rule checks:** Extend `game/tests/skirmish_test.gd` or a dedicated Godot rules test for faction selection, worker delivery, costs, building health, side symmetry and same-command state hashes. Run the commands in [game/README.md](../../../game/README.md).
- **Contract check:** Run `npm run skirmish:contract`; the test-tagged start and completion still use stable IDs and a faction/content version that the local ingest accepts.
- **Rendered smoke:** Builder follows the walkthrough below on Godot 4.7.2 and records the result. The owner reviews the faction wording and plays one match with each choice. No browser smoke applies to this desktop scene.

## Sprint 1 — Smoke walkthrough (do these in order)

Env: local Godot 4.7.2 · project `game/` · scene `res://skirmish_main.tscn`. Set `GODOT_BIN` to the installed Godot 4.7.2 executable, then run `"$GODOT_BIN" --path game`.

1. Launch the game.
   → The setup shows Regios and Poblanos with their strength, cost and both win routes in readable text.
2. Choose Regios.
   → The match starts with Regios named as your faction and Poblanos named as the opponent.
3. Order the starting worker to gather one delivery.
   → Your stockpile rises by five resource.
4. Gather enough resource, build the recruitment post, and queue a melee unit.
   → The queue accepts the unit at the displayed Regio cost of four resource.
5. Restart and choose Poblanos.
   → The new match names Poblanos as your faction; selecting your command post shows 60 health.
6. Build a recruitment post and select it.
   → It shows 36 maximum health and a baseline melee cost of three resource.

If a step fails, record its number and what appeared. The owner records whether the words explain the trade-off without a cultural reference.

## Builder QA record · 2026-10-15

- Godot 4.7.2 headless faction, skirmish and client checks passed for both faction assignments, five-versus-four gold deliveries, unit costs, 50/60 command-post health, 30/36 recruitment-post health and deterministic replay.
- In the rendered debug scene, Regios gathered gold, built a 30-health recruitment post and queued melee for four gold. After restart, Poblanos delivered four gold, showed a 60-health command post and 36-health recruitment post, and queued melee for three gold. The setup named both win routes before either choice.
- `npm run skirmish:contract` passed with one test-tagged start/completion and the chosen faction. The owner-facing uncoached wording check is part of the planned eight-player test; no participant answer has been recorded.
