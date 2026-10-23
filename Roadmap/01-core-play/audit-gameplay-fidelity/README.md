---
status: scaffolded   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Shaping       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: audit-gameplay-fidelity
title: "Audit gameplay fidelity against a pinned RTS reference"
area: 01-core-play
risk: low
type: spike
sprints_total: 3
stories_total: 3   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "A pinned, reproducible comparison will let the owner choose the most valuable RTS rule gaps before broader mechanics work; success is an accepted exception policy and ordered, evidence-backed follow-on list."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "The product owner deciding which RTS mechanics and exceptions to build next."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "This is a design/engineering decision artifact rather than a direct measured retention bet."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 17      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Audit gameplay fidelity against a pinned RTS reference

> **Area:** 01-core-play · **Risk:** low · **Class:** Spike · **Scope seed:** [`00-ideas/seeds/audit-gameplay-fidelity.md`](../../00-ideas/seeds/audit-gameplay-fidelity.md)
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
The owner needs a reproducible decision about which classic RTS behaviors to reproduce and which La Roma differences to keep before broader rules work consumes the budget.

## Architecture and reference lock
- This spike changes documents and evidence only. It never copies DE code, game data or assets and never changes game mechanics.
- ADR 002 defines the reference edition. Numerical comparison requires an actually observed build ID, mode, settings, setup, observation, tolerance and dated source. If unavailable, mark the row unknown.
- Current project behavior comes from the current source, tests and a versioned local or Restricted build, not from the 2026-10-16 architecture baseline.
- Keep mechanical, behavioral and experiential findings separate. Terrenos, local objectives and neighborhood modifiers are proposals until the owner decides them.
- The North Star baseline remains unknown and this spike creates no new telemetry.

## What already exists (reuse, don't rebuild)
- game/skirmish.gd and game/rules_content.gd: command, state and versioned content authority.
- game/map_geography.gd and game/tests/: map, economy, warfare, AI, persistence and replay fixtures.
- ADR 002, the GDD, full-game build path and funded gameplay epics: design direction and prior decisions.

## Scope — stories
| Sprint | Outcome | Risk |
| --- | --- | --- |
| 1 · Pin reference contract | Exact reference or explicit numerical unknown; repeatable sample setups. | low |
| 2 · Compare playable behavior | Ten-domain matrix with current source, test and build evidence. | low |
| 3 · Decide gaps and exceptions | Ranked follow-on work and owner exception decisions. | low |

## Delivery order
Complete the reference contract before recording any numerical comparison. Run current project checks and sample a real build before classifying present behavior. Deliver the decision record last; an owner review remains owed before an exception changes a competitive rule. No game release is created by this spike.

## Definition of Done (epic)
- [ ] All three stories have reproducible evidence and no unsupported parity claim.
- [ ] The comparison covers the ten scoped domains and separates observed, planned and unknown behavior.
- [ ] Owner reviews the reference build, exception policy and ranked next work.
- [ ] Update poster, generated board and retrospective only after the decision is accepted. Keep status in-progress while owner review is owed.
