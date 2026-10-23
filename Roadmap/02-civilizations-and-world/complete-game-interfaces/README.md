---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Verifying       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: complete-game-interfaces
title: "Complete the game interfaces"
area: 02-civilizations-and-world
risk: low
type: feature
sprints_total: 3
stories_total: 8   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: 73   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "Readable text and controls with clear selection and feedback across setup, match and result flows will help new players finish a match; check uncoached tasks now and first-match completion after a real cohort matures."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "first_match_completion"   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "New skirmish and multiplayer players using mouse/keyboard, then supported touch devices."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The existing HUD is builder-verified, but uncoached comprehension and platform-specific completion evidence are open."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 18      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Complete the game interfaces

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/complete-game-interfaces.md`](../../00-ideas/seeds/complete-game-interfaces.md)
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
Players need to read and operate the game at a normal viewing distance. The current small HUD hides otherwise playable choices, commands and recovery paths. This epic makes the existing rules understandable from setup to result.

## Architecture and design lock
- **D1 — Authority:** `game/skirmish.gd` and versioned content remain the sole rule authority; UI projects state and issues semantic commands through `skirmish_main.gd`.
- **D2 — Scale:** keep critical 18-unit and secondary 16-unit text at 100%; 44×44 logical targets; offer 100/125/150/200% settings. At 200%, cap the HUD footprint at 150% and grow text the remaining amount so board picking survives.
- **D3 — Flow:** reuse setup, persistence, replay, Restricted join and current result events. Explain unavailable paths; do not create public mode or a new funnel event.
- **D4 — Evidence:** local client checks and rendered captures are builder proof. Signed Restricted download, owner and two uncoached reads are the acceptance gate and remain owed.
- **Sprint contracts:** S1 makes existing choices/recovery clear; S2 makes match information and commands readable without changing legality or fog; S3 makes the result and accessibility options explicit, then records human QA.
- game/skirmish.gd and versioned content remain the only gameplay authority. UI projects state and issues existing semantic commands.
- Reuse game/ui/battle_hud.gd, command_button.gd, minimap_panel.gd and hud_skin.gd; rebuild only what their current structure cannot present readably.
- The owner's small text, button and selection finding is an open check in the original HUD epic. Transfer or close it explicitly; do not count it twice.
- Keep minimap and board visibility identical. Never expose unseen opponents, new game rules or unavailable public modes.
- Desktop keyboard/mouse is the proof surface. Touch gesture design is included; device certification belongs to cross-platform play.
- User-facing text lives outside flattened concept art. Alpha invite, support ID and sync diagnostics remain accessible in settings.
- The current versioned Restricted owner channel is the safety rail. No new feature flag or measurement schema; the North Star baseline is unknown.

## What already exists (reuse, don't rebuild)
- game/skirmish_main.gd: setup, input adapter, save/resume, replay, audio and Restricted join.
- game/ui/: responsive HUD, command feedback, queue, objective and minimap.
- game/tests/skirmish_client_test.gd and related save/replay/online tests.
- HUD epic, current run guide and art coverage review: existing behavior and concept limits.

## Scope — stories
| Sprint | Stories | Outcome | Risk |
| --- | --- | --- | --- |
| 1 · Choose and recover | S1.1–S1.2 | Available setup, save/replay recovery and honest Restricted state. | low |
| 2 · Read select and command | S2.1–S2.3 | Human-scale HUD, selection, legal orders, progress and fair minimap. | low |
| 3 · Finish and verify | S3.1–S3.3 | Clear result, keyboard/accessibility paths and uncoached read. | low |

## Delivery order
Build a local desktop slice, check current Godot client and simulation contracts, then capture 1024×700 and 1280×800 at 100%, 150% and 200% UI scale. A signed Restricted download and owner/uncoached tasks are separate QA; a merge alone does not ship the interface. The L appetite is approved for this run, with review boundaries between sprints.

## Definition of Done (epic)
- [x] Builder implementation for setup, match, result, scale and reduced motion is recorded in the [current component spec](../../../docs/art/ui-component-spec.md).
- [x] Local Godot client checks, including result, UI scaling, selection and board/minimap separation, pass; existing save/replay, fog and event contracts remain intact.
- [ ] Owner accepts rendered size, contrast and no clipped essential actions at specified windows/scales on the signed download.
- [ ] Owner and two uncoached reviewers complete the scripted readability and command tasks; record misclicks, unreadable labels, hesitation and failures.
- [ ] A signed downloaded Restricted build passes both victory routes, save/resume and replay; preserve test-event exclusions and admission policy.
- [ ] Ten-heuristic findings are recorded and severe findings resolved or explicitly re-scoped.
- [ ] Poster, generated board, retrospective and durable learnings reflect the actual result. Keep status in-progress while owner QA is owed.

## Builder evidence · 2026-10-22

- [Interface review package](../../../docs/interface-review/qa.md) contains local screenshots, a ten-heuristic inspection and the exact owner/uncoached tasks.
- `game/tests/skirmish_client_test.gd` passed on Godot 4.7.2 after the code changes. The 1024×700 and 1280×800 graphical captures show default and enlarged layouts; these are local debug captures, not signed owner-build evidence.
- The owner readability finding in the earlier HUD epic is transferred to this epic for the implementation and human acceptance pass. That epic's historical downloaded-build and blind-task obligations remain separate.
