---
epic: prove-cross-platform-play
sprint: 1
title: "Desktop and browser solo proof"
risk: high
phase: Building
stories_total: 3
stories:
  - id: S1.1
    title: "Name the matrix and produce traceable builds"
    as_a: "game operator"
    i_want: "native desktop and Web artifacts tied to one source and content version"
    so_that: "every test names exactly what ran"
    risk: low
    status: in-progress
  - id: S1.2
    title: "Finish the same battle on desktop and Web"
    as_a: "player"
    i_want: "the same commands and terminal result across my tested desktop targets"
    so_that: "platform choice does not change the game"
    risk: low
    status: planned
  - id: S1.3
    title: "Carry a safe solo save between native and Web"
    as_a: "player"
    i_want: "export, import and resume a same-version match"
    so_that: "browser storage loss does not erase my progress"
    risk: high
    status: in-progress
---
# Prove cross-platform play — Sprint 1: Desktop and browser solo proof

**Status:** 🔄 local builds and save path implemented; real-device full-match and transfer QA open

This is the first end-to-end slice. The owner approved the 28×28 La Roma Standard / 24 population-per-side proof scenario and a p95 frame target of 33.3 ms or less. Device-specific memory ceilings are recorded with each actual machine before a support claim. The owner Mac and one Windows PC form the available desktop candidates; the Windows model and OS are still owed. There is no physical Linux PC. Chrome/Firefox on Windows and Safari on Mac are desktop Web browser candidates. Missing hardware yields an unverified row.

## Stories

### Story 1.1 — Name the matrix and produce traceable builds

**As a** game operator, **I want** native desktop and Web artifacts tied to one source and content version, **so that** every test names exactly what ran.

**Acceptance:** Each artifact records source commit, Godot and template version, game/content version, OS/architecture, browser build where relevant, file hash and install/serve path. A fresh native launch and served Web launch display the matching game version. Internal builds remain test-tagged. A CI export is recorded separately from a downloaded or served launch.

**Risk:** low. **QA:** export/import checks on macOS and available Windows/Linux runners, plus a rendered launch on every physical machine used for a claim.

### Story 1.2 — Finish the same battle on desktop and Web

**As a** player, **I want** the same commands and terminal result across my tested desktop targets, **so that** platform choice does not change the game.

**Acceptance:** On each claimed native/browser target the player can select/group, gather, build, attack, zoom, hear enabled audio, finish the declared match and read its terminal reason. Same-command fixtures match canonical state hashes, while frame p95, load time and peak memory are recorded over a full match. Browser audio activation and a clear failure message are checked. An export launch alone cannot pass.

**Risk:** low. **QA:** Godot command/hash specs, browser rendered smoke and one full real-device/browser match per claimed row. Compare results, not render-frame hashes.

### Story 1.3 — Carry a safe solo save between native and Web

**As a** player, **I want** to export, import and resume a same-version match, **so that** browser storage loss does not erase my progress.

**Acceptance:** Save/export/import/resume preserves match ID, legal state and single terminal result between native and Web. Corrupt or unsupported versions show a useful error and leave the original file untouched. Export contains no invite token, ingest secret or telemetry outbox. Browser site-data removal is explicitly tested, and an imported save still finishes once.

**Risk:** high: player data. **QA:** save/replay schema, corruption, version and event-dedup specs; manual downloaded-build to browser transfer and storage-clear walkthrough; independent data review.

## Sprint QA

- Run the existing Godot simulation, save/replay, cross-platform hash and client tests, plus Node funnel contracts.
- Run the pinned 4.7.2 export/import checks and browser smoke; record exact binary/template and source hashes.
- Capture the real-device full-match matrix with pass/fail, p95 frame, load and memory measurements. A virtual runner is supplemental.
- Review S1.3's data and credential boundary before merge. Merge to master and Restricted publication are separate events.

## Sprint 1 — Smoke walkthrough

Env: local Web at http://127.0.0.1:8765/ and owner-only native download at https://danybgoode.itch.io/battle-for-la-roma. Record the exact build IDs used.

1. Open the Restricted page and download the named native build on each available desktop OS.
   → Its displayed version and file hash match the evidence ledger.
2. Open http://127.0.0.1:8765/ in each named browser.
   → The same content version loads; sound begins after a player gesture.
3. Start the declared La Roma Standard match on each target, gather, build and attack until terminal.
   → The player sees the same legal commands and a clear win/loss/draw reason; frame and memory samples are recorded.
4. Save a native match, export it and import it in Web; then clear browser site data and import again.
   → The match resumes at the saved state and finishes once, with no duplicate completion.
5. Try a damaged and an old-version save.
   → Both are rejected with an error, and the good save remains available.

If any step fails, record its number, device, build and observed result before making that platform claim.
