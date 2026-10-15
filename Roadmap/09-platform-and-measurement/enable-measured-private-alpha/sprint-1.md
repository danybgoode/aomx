---
epic: enable-measured-private-alpha
sprint: 1
title: "Package the first desktop build"
risk: high
phase: Shaping
stories_total: 2
stories:
  - id: S1.1
    title: "Export a reproducible macOS match"
    as_a: "builder"
    i_want: "a versioned macOS export from a fresh checkout"
    so_that: "the invited build has known rules and passes the solo-match checks"
    risk: low
    status: planned
  - id: S1.2
    title: "Prepare an installable restricted build"
    as_a: "invited player"
    i_want: "a restricted download that installs and restarts on my Mac"
    so_that: "I can play again without a developer present"
    risk: high
    status: planned
---

# Enable a measured private alpha — Sprint 1: Package the first desktop build

**Status:** ⬜ not started. No invitations in this sprint.

## Stories

### Story 1.1 — Export a reproducible macOS match

**As a** builder, **I want** a versioned macOS export from a fresh checkout, **so that** the invited build has known rules and passes the solo-match checks.

**Acceptance:** Pin Godot and export templates. CI or a repeatable local command runs the existing headless economy, combat, replay, terminal and client tests, creates a release ZIP, records commit/game/content versions and a checksum, and proves a fresh exported copy can finish and restart a match. The export contains no `.env.local`, Golden Frijoles key or Supabase credential.

**Risk:** low for export code; a release artifact still requires a high-risk review before distribution.

### Story 1.2 — Prepare an installable restricted build

**As an** invited player, **I want** a restricted download that installs and restarts on my Mac, **so that** I can play again without a developer present.

**Acceptance:** Prepare an itch.io Restricted page and access-key process without distributing a build yet. Test the downloaded ZIP on a second macOS machine, including launch, match result, restart, offline outbox persistence and clear pending-sync copy. Record the signing/notarization route; if a credential or paid Apple account is needed, the owner decides it before invitation. A build ID and installation support steps are visible to testers.

**Risk:** high at the external distribution boundary.

## Sprint QA

- **Deterministic gate:** Existing Godot headless tests, Godot-to-Node contract check, `npm test`, export checksum and a fresh-export launch.
- **Rendered smoke owed:** Owner or second reviewer walks the downloaded macOS build on a different machine and records screenshots of start, result, restart and pending sync.
- **Review:** Check exported files for secrets and confirm the restricted page cannot be found or downloaded without an invite.

## Sprint 1 — Smoke walkthrough

Environment: downloaded candidate ZIP on a clean macOS test account; record the itch.io restricted page URL and build ID in the execution log when they exist.

1. Use an invite key to download the candidate ZIP, verify its checksum, and open the app. The title/build ID and menu appear without a developer setup step.
2. Disconnect networking, play to a terminal result and restart the app. The result and pending event remain saved locally.
3. Restore networking only after Sprint 2's staging ingest exists. The same event ID uploads once and the HUD changes from pending to synced.

If any step fails, record the build ID, step and observed result; do not issue invitations.
