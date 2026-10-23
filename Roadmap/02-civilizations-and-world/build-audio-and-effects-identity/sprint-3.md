---
epic: build-audio-and-effects-identity
sprint: 3
title: "Outcome and human read"
risk: low
phase: Building
stories_total: 2
stories:
  - id: S3.1
    title: "Understand the result"
    as_a: "player"
    i_want: "a clear terminal cue paired with its cause"
    so_that: "I know how the battle ended and what to do next"
    risk: low
    status: in-progress
  - id: S3.2
    title: "Decide from human recognition"
    as_a: "product owner"
    i_want: "uncoached sound-on and muted observations"
    so_that: "I can decide whether the pack is readable before widening it"
    risk: low
    status: planned
---
# Build the audio and effects identity — Sprint 3: Outcome and human read

**Status:** 🟨 building; human recognition remains open

## Stories

### Story 3.1 — Understand the result
**As a** player, **I want** a clear terminal cue paired with its cause, **so that** I know how the battle ended and what to do next.
**Acceptance:** Victory, defeat and draw use distinct original cues and visible result/cause text; both victory routes work. A terminal event sounds once, not again on replay seek, reopening a result, resume or network duplicate. Mute and reduced effects retain the cause and next action. Telemetry remains test-tagged in the Restricted build.
**Risk:** low

### Story 3.2 — Decide from human recognition
**As a** product owner, **I want** uncoached sound-on and muted observations, **so that** I can decide whether the pack is readable before widening it.
**Acceptance:** A signed Restricted desktop download is fetched and checked against the source build. Owner completes both win routes, save/resume, replay, mute/volume and reduced-effects checks with build ID. Two uncoached players attempt prewritten order, threat, objective and result recognition in sound-on and muted conditions; record correct recognition, misses, masking, confusion and unfamiliar cultural references. Resolve severe findings before epic close; never infer human evidence from automated tests.
**Risk:** low

## Sprint QA

Godot client and save/replay tests check terminal one-shot behavior, mute/reduced effects and no extra completion event. Native signed export, authenticated owner download, full-match walkthrough, excluded test-event receipt and human task sheet are distinct QA records. Keep this story open until the humans complete it.

## Sprint 3 — Smoke walkthrough

Env: signed Restricted owner download from https://danybgoode.itch.io/battle-for-la-roma; record its build ID and matching source hash.

1. Finish a solo match by destroying the opposing command post. → The result cue plays once; visible copy names the victory and cause.
2. Finish a new solo match by uncontested district hold. → The result names district hold and plays one result cue.
3. Save/resume and open a replay, then seek past the terminal frame. → Files remain usable and old terminal cues do not replay on seek.
4. Mute and enable reduced effects, then inspect an order, threat, objective and result. → Their meaning remains visible without sound or motion.
5. Give two uncoached reviewers the prewritten sound-on and muted tasks. → Record each observation; owner signs off only after severe confusion is resolved.

Record the build, step, action and observed result if a step fails.
