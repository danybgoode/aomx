---
epic: establish-cdmx-geography-and-maps
sprint: 3
title: "Compatibility and owner acceptance"
risk: high
phase: Verifying
stories_total: 2
stories:
  - id: S3.1
    title: "Preserve save and replay behavior"
    as_a: "returning player"
    i_want: "explicit version handling"
    so_that: "a map revision does not silently corrupt my match"
    risk: high
    status: done
  - id: S3.2
    title: "Record owner and reader acceptance"
    as_a: "product owner"
    i_want: "real build and comprehension evidence"
    so_that: "I can decide whether the map is ready to broaden"
    risk: low
    status: in-progress
---
# Establish CDMX geography and map data — Sprint 3: Compatibility and owner acceptance

**Status:** 🟡 compatibility verified; Restricted build and owner QA owed

## Stories

### ✅ Story 3.1 — Preserve save and replay behavior
**As a** returning player, **I want** explicit version handling, **so that** a map revision does not silently corrupt my match.
**Acceptance:** Current v5 save/resume and solo/participant replay reproduce state hashes. An incompatible old save or replay reports a clear version/content reason and retains the file. Check multiplayer replay when a compatible Restricted room is available. Record content/build IDs.
**Risk:** high · player data and replay integrity.

### Story 3.2 — Record owner and reader acceptance
**As a** product owner, **I want** real build and comprehension evidence, **so that** I can decide whether the map is ready to broaden.
**Acceptance:** A signed Restricted downloaded build passes map choice, four factions, both victory routes and offline save/replay smoke. After separate invitation approval, familiar and unfamiliar readers locate Cibeles, tell real place from stylized arena and explain both wins without coaching. Record counts and exact confusion; leave QA open when unrun.
**Risk:** low · observational research; invitations remain a separate approval.

## Sprint QA
- **Evidence:** [builder QA record](../../../docs/world/cdmx-geography-qa-2026-10-22.md). The existing v5 content ID and deterministic hashes are unchanged; the new Restricted build and downloaded owner walkthrough remain open.
- **Headless:** save, load, replay and content-hash fixtures; invalid old-content preservation; multiplayer replay if applicable.
- **Real build:** signed Restricted download, offline owner play, both wins and event exclusion/ingest check.
- **Human:** owner portrayal and full-match decision; uncoached familiar/unfamiliar task read after invitation approval.

## Sprint 3 — Owner smoke walkthrough

Env: signed Restricted macOS download from the existing owner channel; record exact build ID and download URL in QA evidence.

1. Download and open the signed build. → Signature and build ID match the release record.
2. Select La Roma with any faction and finish by destroying the enemy command post. → Win screen names the route.
3. Restart, hold Cibeles to victory and save during the match. → Hold timer, result and save file are visible.
4. Quit and resume that save; open a new replay. → State and result reproduce with the expected content ID.
5. Open an incompatible pre-revision save/replay copy. → Clear compatibility error appears and the file remains intact.
6. With separately approved readers, ask each to find Cibeles and explain both wins without coaching. → Record exact answers in the QA record.

If a step fails, record its number, build/content ID and observed result. Owner QA remains owed until the owner performs it.
