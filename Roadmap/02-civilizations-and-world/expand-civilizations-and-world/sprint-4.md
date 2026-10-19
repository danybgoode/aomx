---
epic: expand-civilizations-and-world
sprint: 4
title: "Media and human read"
risk: high
phase: Building
stories_total: 2
stories:
  - id: S4.1
    title: "Read new factions and maps through original media"
    as_a: "player at gameplay zoom"
    i_want: "legible animation and controllable sound"
    so_that: "I understand identity and state without decoding references"
    risk: low
    status: in-progress
  - id: S4.2
    title: "Verify a downloaded build and uncoached clarity"
    as_a: "product owner"
    i_want: "full-match and human evidence"
    so_that: "I know whether the expansion is ready for further production"
    risk: low
    status: in-progress
---
# Expand civilizations and world — Sprint 4: Media and human read

**Status:** 🏗 Original cue and view-only directional motion pass builder checks; signed download and eight-person human read remain open. See the [world QA record](../../../docs/world-expansion-qa-2026-10-19.md).

## Stories

### Story 4.1 — Read new factions and maps through original media
**As a** player at gameplay zoom, **I want** legible animation and controllable sound, **so that** I understand identity and state without decoding references.
**Acceptance:** A four-direction heading cue and stride/idle motion reuse the project-original unit art without a new raster source. An original order-confirmation WAV has a reproducible generator, recorded hash and runtime path. Gameplay zoom, contrast and non-color ownership cues pass owner inspection. Mute/volume works and no media change alters simulation hashes, picking or collision.
**Risk:** low — presentation.

### Story 4.2 — Verify a downloaded build and uncoached clarity
**As a** product owner, **I want** full-match and human evidence, **so that** I know whether the expansion is ready for further production.
**Acceptance:** The signed Restricted macOS build is fetched and opened, then four factions × three maps are checked with both victory routes, save/resume and one excluded test-tagged sync receipt. For an owner-authorized directional read, four familiar and four unfamiliar participants each explain both routes and identify a selected faction's strength, weakness and counter, then choose whether to start another match. Predeclared marks: at least 3/4 in each group explain both routes, 6/8 identify tradeoff and counter, and 4/8 voluntarily start another match. Record raw counts and failure examples; an unrun test remains open.
**Risk:** low for the QA record; any new invite or data access follows the private-alpha gate and review.

## Sprint QA

- **Specs:** art manifest/provenance validation, audio control, client selection and whole-match tests; Godot/Node event contract and excluded receipt.
- **Rendered smoke:** 100% and 125% gameplay captures at 1280×800 and 1024×700, with a crowded board. Owner performs the downloaded-build walkthrough and cultural portrayal check.
- **Review:** independent review of any ingest/security changes. Report exact sample counts without a retention or public-release claim.

## Sprint 4 — Smoke walkthrough (do these in order)
Env: signed Restricted owner macOS download from `danybgoode/battle-for-la-roma:mac-private-alpha` after the reviewed merge; exact build ID is recorded at execution.

1. Download and open the signed Restricted app.
   → The displayed build ID matches its signed manifest.
2. Start one match using each new faction and map.
   → Every name, ownership cue, objective and available technology is legible without color alone.
3. Adjust sound to zero, then restore it and move a unit in each direction.
   → Sound follows the control and directional motion remains readable at gameplay zoom.
4. Save and resume, finish by each victory route, then open Menu → Sync.
   → The match state returns and one test-tagged terminal receipt is accepted but excluded from public cohorts.
5. Run the owner-authorized eight-person comprehension protocol after the alpha invitation gate.
   → Raw answers and second-match choices are recorded against the predeclared marks.

If any step fails, note the step number and what appeared.
