---
epic: prove-la-roma-promise
sprint: 2
title: "Fight for La Roma"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S2.1
    title: "Contest the La Roma district"
    as_a: "solo RTS player"
    i_want: "to contest a visible central district"
    so_that: "I can win by holding it or by command-post conquest"
    risk: low
    status: done
  - id: S2.2
    title: "Face a countering opponent"
    as_a: "solo RTS player"
    i_want: "the computer to pursue and deny both win routes"
    so_that: "the district victory is earned rather than automatic"
    risk: low
    status: done
---
# Prove the La Roma promise — Sprint 2: Fight for La Roma

**Status:** ✅ builder verified; owner comprehension check remains in Sprint 3

## Player outcome

The center of the existing solo map becomes a contested La Roma district. A player can fight for a 60-second uninterrupted hold or destroy the enemy command post, while the computer responds to both threats.

## Stories

### ✅ Story 2.1 — Contest the La Roma district

**As a** solo RTS player, **I want** to contest a visible central district, **so that** I can win by holding it or by command-post conquest.

**Acceptance:**

- A central 3×3 La Roma zone is clearly marked, reachable from both starts and unavailable for construction. Only living melee and ranged units count toward a hold.
- The HUD and board distinguish neutral, your hold, enemy hold, contested, reset and terminal states in plain language with text or shape as well as color. The threatened side sees a warning.
- Sole presence advances that side's timer; an enemy combat unit or empty zone resets it. Sixty continuous seconds of sole presence produces one win or loss. The existing command-post win/loss and 15-minute unresolved draw still work.
- On the same tick, simultaneous post destruction resolves as a draw, otherwise post defeat resolves before district completion. One terminal result freezes later orders and emits one test-tagged completion.
- Debug-only smoke fixtures make hold, contest/reset and post victory visible on demand and do not ship in release exports.

**Risk:** low. Local rules and UI, with no new external data boundary.

### ✅ Story 2.2 — Face a countering opponent

**As a** solo RTS player, **I want** the computer to pursue and deny both win routes, **so that** the district victory is earned rather than automatic.

**Acceptance:**

- The computer can send combat units into the district, contest a human hold, respond to an enemy hold warning, and still threaten or defend command posts. It uses the same validated order path as the human and obeys the selected faction rules.
- Deterministic scenarios for each faction show a reachable path to center, a successful computer contest and a possible player win by each route. Neither side wins a passive 60-second hold because the opponent is idle.
- The original mirrored resource starts remain fair. A rendered full match shows the opponent reacting to center control without becoming stuck or breaking the 15-minute terminal rule.

**Risk:** low. Authored game AI on the existing local simulation.

## Sprint QA

- **Headless rule checks:** Cover blocked build footprint, zone eligibility, neutral/hold/contest/reset transitions, exact 600-tick hold, both terminal routes, simultaneous endings, AI center paths and replay state hashes in Godot rules tests.
- **Contract check:** Run `npm run skirmish:contract` with both faction choices and the new content version. The local audit accepts test events and excludes them from public cohorts; duplicate completion still contributes once.
- **Rendered smoke:** Builder runs the debug-only fixtures and a normal full match, recording outcomes. The owner follows the walkthrough and confirms the goal and counterplay read clearly. No browser smoke applies to this desktop scene.

## Sprint 2 — Smoke walkthrough (do these in order)

Env: local Godot 4.7.2 · project `game/` · scene `res://skirmish_main.tscn`. Set `GODOT_BIN` to Godot 4.7.2. The builder supplies debug-only `SKIRMISH_SMOKE_SCENARIO=district_hold` and `district_contest` fixtures.

1. Run `SKIRMISH_SMOKE_SCENARIO=district_hold "$GODOT_BIN" --path game`, then choose Regios.
   → La Roma is marked at center and your hold timer is visible.
2. Let the hold fixture reach 60 seconds.
   → The match ends in a district win exactly once and further orders are disabled.
3. Run `SKIRMISH_SMOKE_SCENARIO=district_contest "$GODOT_BIN" --path game`, then choose Poblanos.
   → The district shows “Contested” and its hold progress resets when both armies are present.
4. In the same fixture, remove the opposing combat unit.
   → A new hold begins at zero with a visible warning to the other side.
5. Run `SKIRMISH_SMOKE_SCENARIO=win "$GODOT_BIN" --path game`, then choose either faction.
   → Command-post defeat still produces one win, showing that conquest remains available.
6. Launch a normal match with `"$GODOT_BIN" --path game`, train combat units and move one into La Roma.
   → The computer moves to contest or threatens your post rather than allowing a passive hold.

If a step fails, record its number and what appeared. The owner records whether the district state and next counter are understandable without a cultural reference.

## Builder QA record · 2026-10-15

- Godot district checks passed for both faction assignments: workers cannot hold, construction cannot overlap the zone, enemy presence and absence reset it, exactly 600 uninterrupted ticks win, command-post outcomes take precedence, and AI orders and replay stay deterministic.
- The rendered `district_contest` fixture showed “Contested”; a player-issued ranged attack removed the defender, started a visible hold, and resolved once to a district win. The same scene showed the warning and terminal reason in text, not color alone.
- A normal rendered Regios-versus-Poblanos match reached an AI district victory at 01:35. The computer built a post, recruited fighters, held the center and damaged the human command post. Headless rules also covered human post conquest and the 15-minute draw. The eight-player comprehension test remains open.
