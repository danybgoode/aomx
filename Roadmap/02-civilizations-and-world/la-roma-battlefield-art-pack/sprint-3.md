---
epic: la-roma-battlefield-art-pack
sprint: 3
title: "Visual QA and integration"
risk: low
phase: QA
stories_total: 1
stories:
  - id: S3.1
    title: "Verify the art pack in complete matches"
    as_a: "product owner"
    i_want: "a checked and readable art build"
    so_that: "I can decide whether it represents La Roma well enough for alpha"
    risk: low
    status: in_progress
---

# La Roma battlefield art pack v0.1 — Sprint 3: Visual QA and integration

**Status:** 🟦 In review — technical checks complete; blind and downloadable-build QA pending. See [technical QA record](../../../docs/art/visual-qa-v0.1.md).

The original player-visible match, selection tile, collision, construction and event rules remain intact. Automated Godot and Node checks pass. Local rendered checks covered both faction choices, neutral and contested district art, a district loss and win, selection and attack feedback in the crowded center, 100%/125% board zoom, alpha transparency and a displayed-frame probe. The art is code-complete; exact blind-review answers and the owner-Mac download walkthrough remain required before this story can be marked done.

## Stories

### Story 3.1 — Verify the art pack in complete matches

**As a** product owner, **I want** a checked and readable art build, **so that** I can decide whether it represents La Roma well enough for alpha.

**Acceptance:** Run all Godot rule, faction, district, client and outbox checks plus the skirmish contract. Play complete matches as both factions at 100% and 125% board zoom. Record any clipping, transparency, occlusion, hit-testing or selection failures, and fix those within scope. Capture debug frame-time and memory observations in the same scene as the pre-art baseline; do not assert hundreds-of-units, WebGL or mobile performance. Check imported texture resources, provenance and manifest completeness. Ask one culturally familiar and one unfamiliar blind reviewer to identify both win routes and friend/enemy roles; record exact results and unresolved issues. Keep the restricted preview and invitation gates distinct from a code merge.

**QA:** Deterministic checks, rendered Godot smoke, owner walkthrough and artifact/provenance review. No browser smoke is owed for the local Godot scene. A restricted downloadable preview, if used, follows the existing separate alpha QA runbook.

## Sprint 3 — Smoke walkthrough

Env: local Godot 4.7.2 · game/ · res://skirmish_main.tscn, then the exact versioned restricted owner preview only if one is produced.

1. Play a full match as Regios, including gathering, construction, melee/ranged training and one win route.
   → The match completes once, all roles and structures read at normal and 125% zoom, and sync status still reports test traffic.
2. Restart and play as Poblanos, using the other win route.
   → Faction identity, health, district state and terminal feedback remain clear without a cultural explanation.
3. At a crowded center, select units and issue attack and move orders beside tall art.
   → The intended tiles/entities are picked; selection, HP and order feedback remain visible.
4. Restart offline, then exercise the local outbox sync path from game/README.md.
   → Saved test-tagged events survive restart and retain their original receipt behavior.
5. Record the two blind reviewers' answers to both win routes and friend/enemy identification.
   → Exact observations and any confusion are written down before the art milestone is closed.
