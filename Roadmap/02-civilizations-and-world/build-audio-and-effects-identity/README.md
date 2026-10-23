---
status: scaffolded
phase: Locking architecture
slug: build-audio-and-effects-identity
title: "Build the audio and effects identity"
area: 02-civilizations-and-world
risk: low
type: feature
sprints_total: 3
stories_total: 6
intent_match: 51
quote_low_usd: 20
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "A small original, event-driven cue pack will help skirmish players recognize orders, threats and outcomes in crowded matches while giving the game a distinct voice; we will check uncoached recognition with sound on and muted, then read first-match completion after an eligible cohort matures."
target_metric: "first_match_completion"
target_from: null
target_to: null
read_date: null
verdict: null
verdict_actual: null
verdict_evidence: null
verdict_at: null
persona: "Classic RTS players issuing orders and reading crowded skirmishes, including players unfamiliar with Mexican references and players using no sound."
grounded: false
grounded_reason: "No uncoached audio/effects comparison or eligible cohort establishes a baseline or numeric lift target for first-match completion."
flag_key: null
target_segment: null
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 19
destination: fight-for-la-roma
---

# Epic: Build the audio and effects identity

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [build-audio-and-effects-identity.md](../../00-ideas/seeds/build-audio-and-effects-identity.md)

## Why

Players should notice important orders, threats and outcomes in a crowded battle, with a recognizable sound and effects style that remains understandable when muted or reduced. This M bet makes a small original presentation pack and checks it on a signed Restricted build before widening the media library.

## Architecture and design lock

- **Authority:** `game/skirmish.gd` and versioned content own rules. A client-side presentation mapper consumes accepted command results and visibility-safe state changes. Cue playback, effects and settings never enter saves, replay hashes, network commands or match results.
- **Event policy:** Every cue has a stable key, owner/visibility rule, priority and repetition limit. Routine economy cues yield to threat, objective and terminal cues. Baseline state on start, resume and replay seek is silent; transitions after baseline may cue once. The same visible state supplies a text/shape equivalent.
- **Sound and effects:** Original/generated assets have source, rights and export hashes. Use existing mute/volume and reduced-motion settings, retaining v1 preferences. Bound simultaneous voices and transient effect lifetime; no board occlusion, camera shake or flash. Set measured native budgets from baseline before close.
- **Evidence:** Godot client/contract checks and rendered local captures are builder proof. Signed downloaded macOS build, both win routes, save/replay, owner read and two uncoached sound-on/muted reads are separate acceptance gates. Do not count another epic's open QA as this epic's pass.
- **Boundary:** Native desktop first. #18 owns interface layout and caption hooks; #22 owns Web/mobile audio activation and device budgets. No new gameplay, North Star event schema, public release, invitation or music/voice/ambience wave.

## What already exists (reuse, don't rebuild)

- `game/skirmish_main.gd` has an order-confirm tone, accepted/rejected order flash, HUD notices for readiness, attacks and district control, and terminal copy.
- `game/ui/battle_hud.gd` has mute, volume and reduced-motion controls. `game/tests/skirmish_client_test.gd` exercises the current audio control. `scripts/generate-game-audio.mjs` produces an original WAV reproducibly.
- `game/skirmish.gd` is the fixed-tick rule authority; existing save/replay and Restricted export/channel are the compatibility and delivery rails.

## Scope — stories

| Sprint | Stories | Outcome | Risk |
| --- | --- | --- | --- |
| 1 · Contract and first cue | S1.1–S1.2 | Accepted/rejected order response and muted equivalent from a documented cue policy. | low |
| 2 · Match-state pack | S2.1–S2.2 | Readable economy, construction, combat and objective transitions under priority/visibility limits. | low |
| 3 · Outcome and human read | S3.1–S3.2 | Clear terminal cue and real-build comprehension evidence. | low |

## Delivery order

Implement the local desktop contract and one vertical cue first, then broaden the match-state catalog and finish the result/replay behavior. Record source and rights with every asset. Run local Godot and Node gates, inspect normal and dense captures, export a signed preview to the existing Restricted macOS owner channel, then run downloaded-build and human recognition checks. Keep admission off and telemetry test-tagged. A merge to `master` is source integration; a Butler upload is the Restricted owner release.

## Definition of Done (epic)

- [ ] All six stories pass their behavior checks; story and sprint statuses match the evidence.
- [ ] Original assets have source/export/rights records, with no copied samples or game-rule change.
- [ ] Accepted/rejected orders, economy/construction, threat/objective and result remain intelligible when muted and with reduced effects; fog and replay rules pass.
- [ ] Godot client and simulation/save/replay checks, Node contract, local captures and a recorded native performance comparison pass.
- [ ] Signed downloaded Restricted macOS build passes both win routes, save/resume, replay and sound/mute/reduced-effects walkthrough, with build ID and test-tagged sync check.
- [ ] Owner and two uncoached reviewers complete the prewritten recognition tasks; record misses/confusion and resolve severe findings before close. No human pass is inferred from automation.
- [ ] Source branch is merged to `master`, Restricted owner release is verified, retrospective and poster updated, generated board synced. Mark `status: shipped` only after the real-build and human gates.
