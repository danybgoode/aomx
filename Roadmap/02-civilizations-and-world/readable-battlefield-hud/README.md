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
sprints_total: 2
stories_total: 5
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
- Show only current mechanics: one gold stockpile, district hold, selected actor, real build/train actions, last order, result and sync state. Keep private invite controls visible in alpha builds.
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

## Deploy order
Build on `feat/readable-battlefield-hud` after the art-pack branch. Each sprint is a review and rollback boundary in one orchestrated run. Verify headless Godot behavior and rendered local desktop states before merging. A reviewed merge to `master` is separate from a signed Restricted owner preview; update that channel only under its existing runbook. Owner and blind playthrough evidence remain needed before this epic is marked shipped.

## Builder result · 2026-10-16

Commit `54a0875` adds the match, selection and contextual order panels and the client checks. The Godot rules/client suite, event contract, art manifest and Node tests pass. Rendered local checks at 1280×800 and 1024×700, including 120% board zoom, show readable panels and intact board picking. An isolated preview-channel copy shows the invite and support controls alongside the HUD. `npm run alpha:export` produced a locally verified, signed preview ZIP for commit `1deb8dbfbda7`; it was not uploaded. This is local builder evidence; the Restricted download and uncoached human tasks remain open.

## Definition of Done (epic)
- [x] Five story outcomes have commit refs and each sprint has a reproducible local Godot walkthrough.
- [x] Existing rules, selection/picking, offline outbox and content versions pass their checks.
- [x] The current desktop HUD works at normal and supported zoom/window sizes, including private invite controls in a local preview-channel copy.
- [ ] Owner and two arranged blind reviewers attempt the uncoached command tasks; record results without inventing a retention lift.
- [ ] Reviewed code lands on `master`; any Restricted preview is verified separately.
- [ ] Retrospective, product poster, useful learnings and generated board reflect the observed outcome. Mark `status: shipped` only after these checks.
