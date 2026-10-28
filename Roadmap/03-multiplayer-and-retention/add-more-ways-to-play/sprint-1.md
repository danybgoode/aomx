---
epic: add-more-ways-to-play
sprint: 1
title: "Select a solo objective"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S1.1
    title: "Choose a versioned solo objective"
    as_a: "returning skirmish player"
    i_want: "Conquest or La Roma rules fixed at match start"
    so_that: "my strategy has a predictable finish"
    risk: high
    status: done
  - id: S1.2
    title: "Read the active win condition"
    as_a: "solo player"
    i_want: "plain setup, progress and result copy"
    so_that: "I can tell how to win without cultural context"
    risk: low
    status: done
---

# Add more ways to play — Sprint 1: Select a solo objective

**Status:** 🟨 Builder verified — signed Restricted owner walkthrough owed at epic close.

### Story 1.1 — Choose a versioned solo objective ✅ `80af1a8`

**As a** returning skirmish player, **I want** to choose Conquest or La Roma before play, **so that** I can plan toward a predictable finish.

**Acceptance:** Conquest permits post defeat but never center-hold victory; La Roma keeps the old combined rules and is the default for legacy saves/new setup. Selection is a validated stable objective ID in canonical state, save/replay and state hash. Post loss and simultaneous-post draw retain precedence. Campaign and Restricted 1v1 keep their prior objectives and version contract.

**Risk:** high — shared simulation and compatibility.

### Story 1.2 — Read the active win condition ✅ `1904b5d`

**As a** solo player, **I want** the setup, HUD and result to name the current win rule, **so that** I know my next action without understanding CDMX references.

**Acceptance:** Both choices explain their post and center rules in plain English, show only relevant progress, survive reset/resume, fit 1024×700 and 1280×800, and differ visibly from a disabled Wonder choice.

**Risk:** low — native presentation.

## Sprint QA

- **Headless specs:** mode ID and content validation, post/hold precedence, legacy save/replay/hash and campaign/1v1 isolation.
- **Rendered smoke:** yes, Godot native setup, HUD and result at 1024×700 and 1280×800; owner repeats on signed Restricted download at epic close.
- **Review:** independent high-risk simulation/compatibility review; run `game/README.md` Godot suites and `npm run skirmish:contract` before merge.

## Sprint 1 — Smoke walkthrough

Environment: local Godot 4.7.2 from `game/README.md`; record source commit and build/content IDs.

1. Start a solo Conquest match and hold the center beyond its old timer in a controlled fixture. → No center victory; the HUD names post destruction.
2. Destroy the opponent's post. → One Conquest victory and one test-tagged terminal result.
3. Start La Roma and hold the center uncontested. → The old center timer and victory work.
4. Save, quit and resume a selected mode. → The same objective, progress and match ID return; the campaign and private-match entries retain their original rules.

**Builder checkpoint · 2026-10-27:** `objective_mode_test.gd` passed Conquest hold exclusion, post terminal, legacy snapshot, save and replay hash; `district_test.gd`, `skirmish_client_test.gd` and the macOS cross-platform hash fixture passed. The client test confirmed the Conquest explanation and disabled Wonder choice. The Restricted owner download and independent review remain owed.
