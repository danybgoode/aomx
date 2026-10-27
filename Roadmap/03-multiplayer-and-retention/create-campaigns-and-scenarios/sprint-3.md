---
epic: create-campaigns-and-scenarios
sprint: 3
title: "Play and measure"
risk: high
phase: Verifying
stories_total: 3
stories:
  - id: S3.1
    title: "Finish the three-map chapter"
    as_a: "campaign player"
    i_want: "a complete path into a La Roma battle"
    so_that: "each learned choice leads to a finishable final contest"
    risk: high
    status: in-progress
  - id: S3.2
    title: "Measure adoption and eligible results"
    as_a: "product owner"
    i_want: "served campaign exposure and honest match events"
    so_that: "tutorial play does not distort the North Star"
    risk: high
    status: in-progress
  - id: S3.3
    title: "Read uncoached chapter comprehension"
    as_a: "product owner"
    i_want: "players to explain goals without prompting"
    so_that: "I can judge whether the chapter teaches the game"
    risk: low
    status: planned
---

# Create the first campaign chapter — Sprint 3: Play and measure

**Status:** 🟡 Verifying — local chapter, flag and funnel contracts pass; independent review and owner download remain open.

### Story 3.1 — Finish the three-map chapter

**As a** campaign player, **I want** a complete path into a La Roma battle, **so that** each learned choice leads to a finishable final contest.

**Acceptance:** Copilco, Narvarte and the owner-accepted La Roma Large pilot run as one chapter on the existing fixed-tick rules. The first two teach visible goals; the final mission is a full battle with an existing terminal route and no scripted advantage. Save/resume and replay preserve objective/result state. Old skirmishes and maps still work. The owner finishes the chapter on an independently fetched signed Restricted build.

**Risk:** high — full simulation, compatibility and release.

### Story 3.2 — Measure adoption and eligible results

**As a** product owner, **I want** served campaign exposure and honest match events, **so that** tutorial play does not distort the North Star.

**Acceptance:** The alpha backend evaluates campaign.chapter_enabled for the same pseudonymous user ID used by the game outbox, reports user-level evaluations, and serves only decision/version to the client. Every environment has an explicit off version before rollout. The first verified Copilco win emits one campaign_mission_completed adoption event; later mission wins can repeat within seven days. The first two guided missions are excluded. Only a full human final battle with supported version, accepted start and terminal finish, and no test/bot marker may enter eligible first-match completion. Replay, duplicate, abandon and flag-off paths cannot inflate it. Offline cached access and next-online disable behavior are evidenced.

**Risk:** high — flag, identity, backend integrity and North Star reporting.

### Story 3.3 — Read uncoached chapter comprehension

**As a** product owner, **I want** players to explain goals without prompting, **so that** I can judge whether the chapter teaches the game.

**Acceptance:** After separate invitation approval, at least one classic RTS player familiar with Mexican references and one unfamiliar player attempts the chapter uncoached. Record the build, objective understanding, where each got stuck and whether each reaches the final battle. Do not claim a retention effect from this small read. Leave this story open if it has not been run.

**Risk:** low — research, subject to owner invitation decision.

## Sprint QA

- **Headless specs:** chapter end to end, old-map and save/replay regression, cross-platform hashes where supported, flag/offline cache, user-level evaluation, adoption dedupe and all funnel eligibility/exclusion cases.
- **Rendered smoke:** yes, signed Restricted macOS download from the reviewed commit; owner completes the chapter and separate skirmish. Record actual archive hash, signature, build ID and first-event receipts.
- **Review:** independent high-risk simulation/data review, required CI, then owner QA and authorized uncoached reads. No public invitation or baseline claim.

## Sprint 3 — Smoke walkthrough

Environment: signed Restricted macOS download on the owner channel; record build ID, SHA-256, source commit and user profile.

1. Open the downloaded game online with campaign flag served on for this test profile. → Campaign appears with Arrival available and a recorded user-level flag evaluation.
2. Finish the Copilco lesson, then Narvarte. → Each win records progress once and unlocks only the next mission.
3. Start the La Roma Large finale, save during an active objective, quit, reopen and resume. → The same match and objective state return.
4. Finish the full battle and inspect the result and test-tagged receipts. → One terminal result appears; first two guided missions are excluded and the final battle follows the approved eligibility checks.
5. Disable the preview flag and check again online; then repeat once from an offline cached session. → New online starts stop; the offline cached limitation matches D6.
6. Open Skirmish and finish an ordinary match. → Existing maps/factions and the normal terminal funnel remain intact.
7. With separately authorized familiar and unfamiliar readers, ask each to explain the current goal and La Roma win route before any hint. → Record exact answers, confusion and completion without claiming cohort lift.

Record every failure by step, build ID and receipt. Only actual owner and reader evidence closes the last two acceptance gates.

## Local verification · 2026-10-27

- Node funnel, flag, invite-bound route and adoption publisher contracts pass. The full `npm test` run passes 41 tests; three database integration tests are skipped without the CI database.
- Godot mission, progress, flag cache, native client, save, replay and cross-platform hash checks pass on macOS. The final battle client check queues a start, terminal event and adoption in order; tutorial completion queues adoption only. These are test-tagged local events.
- Native captures at [1024×700 and 1280×800](../../../docs/screenshots/campaign/README.md) show the chapter entry and first goal. The first compact goal clipped; the revised copy fits in the final capture.
- This does not close the signed Restricted download, independent high-risk review, #24 large-map owner decision, owner full-match play or separately authorized comprehension reads.
