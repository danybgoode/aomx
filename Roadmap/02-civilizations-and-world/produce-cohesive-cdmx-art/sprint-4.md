---
epic: produce-cohesive-cdmx-art
sprint: 4
title: "Playable art acceptance"
risk: low
phase: Verifying
stories_total: 2
stories:
  - id: S4.1
    title: "Verify the signed art build"
    as_a: "owner"
    i_want: "a downloadable art-complete match with unchanged rules"
    so_that: "I can judge the work in the real client"
    risk: low
    status: in-progress
  - id: S4.2
    title: "Record uncoached visual comprehension"
    as_a: "product owner"
    i_want: "answers from culturally familiar and unfamiliar players"
    so_that: "I know which art cues still confuse players"
    risk: low
    status: planned
---

# Produce cohesive CDMX game art — Sprint 4: Playable art acceptance

**Status:** 🏗 In progress — local verification passed; Restricted fetch and owner QA pending.

## Stories

### Story 4.1 — Verify the signed art build

**As the** owner, **I want** a downloadable art-complete match with unchanged rules, **so that** I can judge the work in the real client.
**Acceptance:** Review and merge all art/source/manifest changes, export a signed Restricted macOS build from the landed commit, independently fetch it and check archive identity and signature. Record frame/memory comparison under identical match/zoom conditions. In the downloaded build, verify four factions, both victory routes, save/resume, replay, center selection and test-event exclusion. The owner personally completes the visual and full-match walkthrough; keep that checkbox open until observed.
**Risk:** low. **QA:** Godot/Node contract suite, manifest, source ZIP hash, strict signature, independent fetch and real downloaded-build smoke. No public invitation.

**Evidence:** See [QA record](QA-2026-10-22.md) for the complete local check list and, after landing, the Restricted build ID, checksum and independent download. Owner full-match verification remains open.

### Story 4.2 — Record uncoached visual comprehension

**As the** product owner, **I want** answers from culturally familiar and unfamiliar players, **so that** I know which art cues still confuse players.
**Acceptance:** After the existing invitation notice/access gates, four familiar and four unfamiliar players attempt the same tasks without coaching: find the objective, distinguish friend/enemy and worker/fighter, identify a resource, select a partly obscured unit, and explain both win routes. At least 3/4 in each group complete objective/role and route tasks; at least 6/8 complete resource and selection tasks. Record raw answers, failures and accessibility needs. Do not mark this done if the test is unrun.
**Risk:** low. **QA:** owner-run directional study with exact count and examples; no inference of retention or art-only causality.

## Sprint QA

- Complete headless art, rules, client, save/replay and event contract checks, then owner-Mac rendered and signed-download checks.
- Compare frame time, memory and texture costs on the same match/zoom setup; list unmeasured platforms.
- Browser smoke: owner-only itch download access and independent fetch. Human comprehension is owed to the owner after invitation gates.

## Sprint 4 — Smoke walkthrough

Environment: owner-only `danybgoode/battle-for-la-roma:mac-private-alpha` Restricted itch channel; record the exact build ID in the QA log.

1. Download the current signed macOS build through the owner channel. → The package opens and displays the expected build ID.
2. Start La Roma as each of the four factions. → Its role and faction art appears with readable friend/enemy and Cibeles cues.
3. Finish a La Roma match by destroying the opposing post; start another and win by holding the center. → Both terminal routes display their expected result.
4. Save, quit, resume and play a replay. → The match resumes or replays with the same rules and art state.
5. Retry a local test-event sync. → Only test-tagged/excluded receipts are recorded; no eligible cohort count changes.

The owner records exact build ID, steps passed, failures and the separate uncoached task counts.
