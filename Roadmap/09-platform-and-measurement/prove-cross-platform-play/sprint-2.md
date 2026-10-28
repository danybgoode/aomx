---
epic: prove-cross-platform-play
sprint: 2
title: "Designed touch and mobile proof"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S2.1
    title: "Give touch players deliberate commands"
    as_a: "touch player"
    i_want: "select, order, cancel and navigate without accidental commands"
    so_that: "I can control the same battle on a phone"
    risk: low
    status: in-progress
  - id: S2.2
    title: "Decide native and mobile Web support from devices"
    as_a: "game operator"
    i_want: "full-match evidence on named Android and iOS devices and browsers"
    so_that: "mobile support claims describe reality"
    risk: high
    status: planned
---
# Prove cross-platform play — Sprint 2: Designed touch and mobile proof

**Status:** 🔄 touch dispatch implemented and headless tested; physical phone QA open

The owner approved continuous execution across the waves. The Android phone and iPhone are available in principle; exact models, OS versions and connection to this Mac are owed at QA. Android Chrome and iPhone Safari are mobile Web candidates, and Android native depends on local SDK setup. iOS native signing is unavailable, so that row is unverified and cannot become a support claim in this run. Retain the same rules/content and declared match scenario.

## Stories

### Story 2.1 — Give touch players deliberate commands

**As a** touch player, **I want** to select, order, cancel and navigate without accidental commands, **so that** I can control the same battle on a phone.

**Acceptance:** Single touch selects; visible command controls enter order targeting; Cancel leaves targeting; drag/two-finger pan and pinch zoom do not issue an order; command-strip and drawer scrolling do not touch the battlefield. Group selection, minimap navigation, save and menu remain reachable in landscape and portrait. Selected action, rejection and order progress are visible. Physical-device uncoached tasks include near-edge targets and interruption/resume.

**Risk:** low. **QA:** extracted input-state specs for gesture and command dispatch, Godot client tests, rendered touch-device smoke and owner/uncoached task read. A simulated mouse tap is only a test aid.

### Story 2.2 — Decide native and mobile Web support from devices

**As a** game operator, **I want** full-match evidence on named Android and iOS devices and browsers, **so that** mobile support claims describe reality.

**Acceptance:** For each available candidate, record device model, OS, GPU/RAM where available, native or browser build, browser version, source/build hash, load, sustained frame p95, peak memory, audio unlock, touch conflicts, OS interruption, save/restart and full terminal match. A target is pass, fail with reason, or unverified for missing device/signing. Only passing targets enter the support statement. Same-command rules fixtures and saves use the shared contract.

**Risk:** high: installation/signing and player data. **QA:** local Android/iOS export checks, physical-device full-match and storage matrix, independent review of distribution/profile and saved-data behavior. Do not equate a simulator launch with a device pass.

## Sprint QA

- Review Sprint 1 findings before consuming the mobile wave's appetite.
- Run touch adapter/state tests and existing simulation/save suites after every input change.
- Capture actual phone screen recordings and frame/memory samples during a full match; record any unsupported target explicitly.
- Keep install packages private and test-tagged. Store signing credentials outside the repo.

## Sprint 2 — Smoke walkthrough

Env: local native test installs and Restricted mobile Web preview at http://127.0.0.1:8765/ on the named physical devices. Record the exact build and device in the evidence ledger.

1. Install the native test package on the named Android device, then open the same-version Web build in Chrome.
   → Both show the same setup choices and version.
2. Repeat on the named iPhone with a locally signed test build and Safari, if signing/device access exists.
   → Both launch; otherwise the row is marked unverified with the missing dependency.
3. Select a worker, give Gather and Build, cancel an order, pan/zoom and use the minimap in landscape and portrait.
   → Only intended commands reach the match and the HUD remains readable.
4. Interrupt the app/browser, resume or import the same-version save, and finish the match.
   → State and terminal reason are preserved; there is no duplicate result.
5. Review frame p95, peak memory, load and audio activation for each native/browser row.
   → Only rows that pass the declared budget and full-match checks are called supported.

If a device or signing path is absent, record that fact; do not substitute a simulator or remote screenshot.
