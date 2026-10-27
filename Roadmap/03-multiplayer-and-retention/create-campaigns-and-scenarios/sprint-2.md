---
epic: create-campaigns-and-scenarios
sprint: 2
title: "Chapter path"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S2.1
    title: "Choose a mission and read its lock"
    as_a: "campaign player"
    i_want: "to see the chapter and why a mission is locked"
    so_that: "I know what to play next"
    risk: low
    status: in-progress
  - id: S2.2
    title: "Keep unlocks across restarts"
    as_a: "campaign player"
    i_want: "verified wins to unlock the next mission once"
    so_that: "my progress survives without changing skirmish"
    risk: high
    status: in-progress
---

# Create the first campaign chapter — Sprint 2: Chapter path

**Status:** 🟡 Building — Godot contracts pass; rendered smoke, data review and owner download remain open.

### Story 2.1 — Choose a mission and read its lock

**As a** campaign player, **I want** to see the chapter and why a mission is locked, **so that** I know what to play next.

**Acceptance:** The existing native setup exposes Campaign separately from Skirmish. Copilco starts available; Narvarte and La Roma Large explain prerequisites. In-match goal/result copy is readable at 1024×700 and 1280×800, with the same meaning when muted or using reduced effects. Skirmish maps and all four faction choices stay independent.

**Risk:** low — native presentation.

### Story 2.2 — Keep unlocks across restarts

**As a** campaign player, **I want** verified wins to unlock the next mission once, **so that** my progress survives without changing skirmish.

**Acceptance:** A versioned local ledger atomically records one verified completion per mission. Loss, exit, replay, duplicate result and damaged ledger do not grant or erase progress. Restart restores availability. The ledger is separate from the match save, invite state and funnel outbox; incompatible data remains on disk with a clear recovery path.

**Risk:** high — local player data and save compatibility.

## Sprint QA

- **Headless specs:** lock/prerequisite graph, win/loss/exit/replay idempotence, atomic write failure, corrupt/unsupported ledger and existing save/outbox isolation.
- **Rendered smoke:** yes, local native game at both supported desktop sizes; owner repeats restart and menu checks on the signed download.
- **Review:** independent review of player-data path; run Godot client, persistence, replay and UI capture checks.

## Sprint 2 — Smoke walkthrough

Environment: local Godot 4.7.2 in a disposable user profile; record the profile and build ID.

1. Open Campaign before any win. → Arrival is available and the next two missions show a plain lock reason.
2. Win Arrival, then return to the chapter screen. → Foothold in Narvarte becomes available exactly once.
3. Quit the game, reopen the same profile and open Campaign. → The same mission availability appears.
4. Replay the completed Arrival mission and then open Skirmish. → No duplicate unlock appears; every standalone map remains selectable.
5. Open a profile with damaged chapter progress. → A readable error appears, and the good match save remains present.

Record failed step, profile and observed result.

## Local verification · 2026-10-27

Godot `campaign_progress_test.gd` and `campaign_client_test.gd` pass in a disposable profile: initial locks, verified unlock, duplicate, restart, damaged ledger, final map selection and unchanged skirmish entry. The [native captures](../../../docs/screenshots/campaign/README.md) show the setup at both desktop sizes. Owner downloaded-build checks and independent player-data review remain open.
