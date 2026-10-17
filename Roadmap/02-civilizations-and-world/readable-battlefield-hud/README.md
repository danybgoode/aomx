---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Verifying       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: readable-battlefield-hud
title: "Readable battlefield HUD"
area: 02-civilizations-and-world
destination: fight-for-la-roma
risk: low
type: feature
sprints_total: 3
stories_total: 6
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "We believe a legible match HUD and contextual commands for first-time skirmish players will improve first-match completion because players can understand selection, resources, objectives and orders without memorizing keys; we will check uncoached tasks and the first-match funnel when real play data exists."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "first_match_completion"
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "A new classic RTS player trying to finish a first La Roma skirmish"   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "First-match completion is a North Star input, but there is no real player baseline or evidence isolating the HUD effect."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 11      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Readable battlefield HUD

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/readable-battlefield-hud.md`](../../00-ideas/seeds/readable-battlefield-hud.md)
<!-- Class (above) is the Stage-2 classification: Feature, Spike, Bug, or Chore — see SKILL.md's
     Stage 2 table; sourced from scaffold-epic.mjs's --type flag (a fixed 4-value enum, not free
     text — a longer description belongs in the Why section below, not here; this comment never names
     that heading literally, so an edit anchored on it cannot land inside the comment).
     Optional: if this epic was ALSO tagged with an archetype at refining (see spike-role-archetypes.md),
     append " · **Archetype:** <Prototyper|Builder|Sweeper|Grower|Maintainer>" after Class. Omit entirely
     for the Builder default — untagged is fine.
     Scope-seed link: always points at seeds/ — lifecycle lives in the seed's `status:` frontmatter, not
     in a folder path (see 00-ideas/README.md). If this epic was scaffolded from a doc that has no seeds/
     entry, link that doc instead and migrate it to seeds/ when convenient — don't fabricate a seeds/ file
     that doesn't exist. -->

## Why
First-time players should see what they have selected, what the current match needs, and which orders are possible without memorizing a dense hotkey line. The HUD brings the approved control concept into the playable solo match, using its actual rules and art.

## Architecture lock

- `game/skirmish.gd` remains the only authority for resources, actions, targets, health, queue and outcomes. HUD state is a read-only projection; buttons issue the same existing commands as keys and pointer input.
- Keep the board's sprite alpha picking, selection ring, tile coordinates and camera zoom. UI panels may not steal pointer input intended for the board.
- Build reusable Godot `Control` components with anchors/containers, scalable text and focus states. Use existing art for portraits where suitable; do not make a single flattened HUD texture.
- Show only current mechanics: one gold stockpile, district hold, selected actors, real build/train actions, last order, result and sync state. Keep private invite and support controls in a visible-on-demand alpha menu.
- No new telemetry schema or enablement flag in this slice; existing test-tagged match events and North Star definition remain authoritative. A real cohort baseline is still unknown.

## What already exists (reuse, don't rebuild)
- `game/skirmish.gd`: deterministic solo model and validated `issue()` orders.
- `game/skirmish_main.gd`: CanvasLayer, actor selection, hover/picking, hotkeys, order feedback, match and outbox text.
- `game/art_catalog.gd` and `game/assets/`: entity/faction art for the selection panel.
- `game/funnel_outbox.gd`: local pending, accepted and attention state.
- `docs/art/ui-component-spec.md`: component boundary and unsupported concept features.

## Scope — stories
| Sprint | Stories | Outcome | Risk |
|---|---|---|
| 1 · Understand the match | S1.1, S1.2 | A clear status area and selection panel for the real match. | low |
| 2 · Give contextual commands | S2.1, S2.2, S2.3 | Visible legal orders, confirmation and desktop layout QA. | low |
| 3 · Visual RTS HUD | S3.1 | Approved reference hierarchy, responsive icon commands, minimap, objective and support areas. | low |

## Deploy order
The first two sprints were merged on `feat/readable-battlefield-hud`. Sprint 3 is the follow-up on `feat/readable-battlefield-hud-s3`. Verify rules, HUD interactions, exports and rendered desktop/mobile states before merging. A merge to `master` is separate from a signed Restricted owner preview; update that channel under its existing runbook. Owner and blind playthrough evidence remain needed before this epic is marked shipped.

## Builder result · 2026-10-16

Commit `54a0875` adds the match, selection and contextual order panels and the client checks. The Godot rules/client suite, event contract, art manifest and Node tests pass. Rendered local checks at 1280×800 and 1024×700, including 120% board zoom, show readable panels and intact board picking. An isolated preview-channel copy shows the invite and support controls alongside the HUD. This is local builder evidence; the Restricted download and uncoached human tasks remain open.

The merged `master` commit `b453e05` was exported separately as `preview-b453e0523b1d` (source ZIP SHA-256 `16d72fb177f65a29e6c0b59aefef798e3b49ad2ee2a5a9ddb05b75018b97ca3b`) and uploaded to the Restricted owner itch channel as build `#2141043`. The extracted signed app launched locally and showed that exact build ID with the new HUD. Follow [the owner download QA](../../../docs/alpha-local-qa.md) after Butler marks the upload ready; the owner will share it with two blind reviewers later. No owner or reviewer task result has been recorded yet.

## Visual redesign follow-up · 2026-10-16

Owner feedback accepted the isometric battlefield and requested the gameplay interface match the [approved HUD direction](../../../references/04a1d5324f0edb9c8e41f5a474ec3f49255671b7baf530e4de7f154e661cce23.jpg). Sprint 3 implements the [Godot component design](../../../docs/art/ui-component-spec.md) and [four actual captures](../../../docs/screenshots/readable-hud/README.md). Only supported simulation resources and actions appear. Alpha invite and diagnostics remain available in the menu. The native Godot HUD test covers selection, group orders, minimap navigation, pause, contextual commands, building placement and the four viewport bounds. A single-threaded Web export loaded to the gameplay screen in Chrome. Owner download QA and two uncoached reviews remain unrecorded.

PR [#32](https://github.com/danybgoode/aomx/pull/32) passed project checks and CodeQL, and merged as `1d1349249f14`. The signed macOS owner preview built from that commit is `preview-1d1349249f14` (source ZIP SHA-256 `0e78ed5540d00b3266fdb8b73433a58aa626504e6acb5127bbbc9457ab3329e6`). The extracted app passed strict code signature verification and a local headless launch. It was uploaded to the existing Restricted itch channel as build `#2142419`; Butler processing and owner download QA are tracked in the [walkthrough](../../../docs/alpha-local-qa.md).

Owner QA found that resizing the window no longer zoomed the battlefield after the responsive canvas change. PR [#34](https://github.com/danybgoode/aomx/pull/34) restored resize-based board scaling while keeping the HUD responsive and preserving manual wheel/key zoom across resizes. The client test covers the resize signal, tile picking and reset. A Web export was resized live from 1024×700 to 1536×960 in Chrome and both layouts rendered correctly. The replacement signed Restricted preview is `preview-4827e70dc52a` (itch build `#2142751`; source ZIP SHA-256 `73e455b1e194b8287d2f2c358b597d9b5c7d957b777c43e7ed8dc700aa11245e`); its extracted app launched locally. Owner download QA and two uncoached reviews remain open.

## Definition of Done (epic)
- [x] Six story outcomes have commit refs and each sprint has a reproducible local Godot walkthrough.
- [x] Existing rules, selection/picking, offline outbox and content versions pass their checks.
- [x] The redesigned desktop and mobile HUD is captured at the four requested sizes; private invite controls remain in the alpha support menu.
- [ ] Owner and two arranged blind reviewers attempt the uncoached command tasks; record results without inventing a retention lift.
- [x] Reviewed code lands on `master`; the signed Restricted preview export and local launch are verified separately.
- [ ] Retrospective, product poster, useful learnings and generated board reflect the observed outcome. Mark `status: shipped` only after these checks.
