---
epic: harden-rts-simulation
sprint: 2
title: "Save, replay and versioning"
risk: high
phase: Verifying
stories_total: 1
stories:
  - id: S2.1
    title: "Save, resume and replay a complete skirmish"
    as_a: "solo skirmish player"
    i_want: "to resume a saved match and replay its decisions"
    so_that: "a longer battle remains trustworthy across sessions"
    risk: high
    status: in-progress
---
# Harden the RTS simulation — Sprint 2: Save, replay and versioning

**Status:** Local implementation and regression QA passed; review and downloaded-build walkthrough remain.

## Stories

### Story 2.1 — Save, resume and replay a complete skirmish

**As a** solo skirmish player, **I want** to resume a saved match and replay its decisions, **so that** a longer battle remains trustworthy across sessions.

**Acceptance:**

- Add an in-game save and resume path for the current match. A save captures schema/content versions, seed/RNG state, logical clock, objective timers, queued work, entities, resources and valid pending commands; it excludes private invite tokens and telemetry outbox contents.
- A saved match reopened after quitting produces the same canonical state as uninterrupted play, then reaches each terminal route. Loading never emits a duplicate match-start or terminal funnel event.
- Replay a versioned seed/command stream through the authoritative simulation and compare checkpoints and terminal hashes. A hash mismatch reports the first divergent logical tick and relevant version/build.
- Corrupt, unsupported and older-version saves follow an explicit migration or rejection policy with readable feedback and no silent reset or data loss. Preserve a fixture for every supported format.

**Risk:** high — persisted player data and event integrity. Second reviewer required.

## Sprint QA
- **Headless specs:** save/load round trips at early, contested and near-terminal states; malformed/old-version fixtures; replay checkpoint hashes; event deduplication in `outbox_test.gd` and client checks.
- **Rendered smoke owed:** yes, save/quit/resume/finish in local and owner downloaded macOS build. Check readable incompatible-save feedback.
- **Gate:** headless fixture matrix, actual build walkthrough and save format/version note before review.

## Sprint 2 — Smoke walkthrough (do these in order)
Env: downloaded macOS preview from the sprint commit; use the local debug build first. Record build identifier and save schema version.

1. Start either faction, gather, build and train, then save while a queue or district timer is active. → The game confirms the save and names the match.
2. Quit the game entirely, reopen it and resume that match. → Units, stockpile, queued work, timer and faction match the saved state.
3. Finish once by command-post destruction; repeat with a district win in a separate saved match. → Each result appears once as a test-tagged local event.
4. Try a deliberately unsupported or corrupt fixture in a disposable test profile. → The game explains the incompatibility and preserves the original file without starting a misleading fresh match.
5. Run replay against the recorded command stream. → Checkpoint and terminal hashes match the fixture; a deliberate changed command reports divergence.

Record a failed step with build, save version and observed result. Keep test fixtures out of a real player profile.

## Builder evidence · 2026-10-16

- The in-game Menu and faction screen now expose one local v1 save slot and resume. [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md) specifies the envelope, version rejection, data exclusions and power-loss limit.
- `skirmish_persistence_test.gd`, `skirmish_replay_test.gd` and `skirmish_save_client_test.gd` passed on Godot 4.7.2 macOS, including round-trip continuation, corrupt/unsupported files, command divergence and match event deduplication. A rendered Godot probe saved, returned to setup and resumed the same match ID; the settings panel showed both controls and the saved status.
- The replay verifier is a diagnostic API and test tool; there is no player-facing replay viewer in this slice. The owner downloaded-build save/quit/resume and both terminal paths remain owed.
