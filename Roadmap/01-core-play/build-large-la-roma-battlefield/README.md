---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: In review       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: build-large-la-roma-battlefield
title: "Build a large La Roma battlefield"
area: 01-core-play
destination: full-depth-rts
risk: high
type: feature
sprints_total: 3
stories_total: 3   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "A genuinely expansive La Roma skirmish with separated resources and a starting bicitaxi scout will give classic RTS players meaningful exploration and expansion decisions; check an owner-completed match and uncoached route/resource comprehension now, then later-day match completion after an eligible cohort exists."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "return_to_match"   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players who want to scout, expand and plan routes in a solo CDMX skirmish."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The return-to-match input is defined, but there is no eligible play cohort or observed baseline, and a map comparison has not been run."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 24      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Build a large La Roma battlefield

> **Area:** 01-core-play · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/build-large-la-roma-battlefield.md`](../../00-ideas/seeds/build-large-la-roma-battlefield.md)
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
Classic RTS players need enough room to scout, choose an expansion and stage an attack. This epic adds one genuinely large La Roma solo battlefield, separated resource journeys and a bicitaxi starting scout, then proves that both sides can finish a complete match without shrinking units to fit the whole map on screen.

## Architecture and design lock

- **D1 · One authority:** `game/skirmish.gd` remains the sole fixed-tick authority. `game/rules_content.gd` validates a new map ID and versioned content; the client and AI issue existing semantic commands. No UI-only scouting or hidden AI information.
- **D2 · One pilot:** keep `la_roma`, `narvarte` and `copilco` at 28×28 with their established save behavior. Add one `la_roma_large` authored variant at 96×96 for the first playable comparison. A 128×128 stress candidate informs the final size but is not a second shipped map. Do not claim AoE II: DE numerical parity.
- **D3 · Resource geography:** each side has safe, reachable starting sources, two distinct scouting routes and separated expansion resources. The central objective and contested resources have fair approach options. Validate traversable lanes and both sides' first-gather and expansion access before balance tuning.
- **D4 · Starting scout:** one bicitaxi per side at match start, faster and farther-sighted than a worker, fragile and non-combat. It may move/stop and reveal legal fog; it cannot attack, gather, build, carry passengers or be trained in this slice. The art reads as a bicycle-powered passenger vehicle at normal camera scale. Pin exact stats in versioned content and give AI the same sight rules.
- **D5 · Camera:** begin at a readable unit size centered on the human start. The minimap, panning and zoom expose the larger geography; fit-whole-map remains an explicit action, not the opening view. HUD scale remains separate from board zoom.
- **D6 · Compatibility:** use a distinct map/content identity. Save/replay and cross-platform hashes preserve deterministic state; old saved 28×28 matches either continue on their prior content or fail explicitly without deleting data. The private-match version contract must reject incompatible peers rather than silently diverge.
- **D7 · Performance:** before tuning, use a ten-minute representative 96×96 owner-Mac release export with up to 80 live entities and mixed scouting, gathering, building and combat. Initial budgets: route p95 ≤ 12 ms, simulation tick p95 ≤ 8 ms, rendered frame p95 ≤ 33.3 ms at 1280×800, process memory ≤ 768 MiB. Record actual route/tick/frame/memory and compare the old 28×28 case plus the existing 48×48/163 headless fixture. A failed budget triggers a scope decision, not a silent shrink.
- **D8 · Delivery:** fix the separately tracked #11 crowd-stall and #18 UI-scale regressions before the large-map full-match gate. Review this shared simulation/content work as high risk. Merge to `master` only after required checks; export a signed Restricted preview, independently download and verify it, then record owner play as a separate acceptance step. No public invitation or eligible-cohort claim follows.

## What already exists (reuse, don't rebuild)
- `game/content/skirmish.v1.json`, `game/content/maps/` and `game/rules_content.gd`: versioned rules, map overlays and reachability validation.
- `game/skirmish.gd`: fixed-tick commands, AI, visibility, movement, both victories and entity IDs.
- `game/skirmish_main.gd` and `game/ui/minimap_panel.gd`: start camera, zoom/pan, fog-aware drawing and selection.
- `game/skirmish_persistence.gd`, `game/skirmish_replay.gd` and Godot hash/content tests: compatibility contract.
- [Owner review](../../00-ideas/audits/2026-10-23-owner-interface-movement-map.md), [#11 warfare](../expand-warfare-and-world/README.md), [#18 interface](../../02-civilizations-and-world/complete-game-interfaces/README.md) and [scope seed](../../00-ideas/seeds/build-large-la-roma-battlefield.md): open acceptance and design boundaries.

## Scope — stories
| Sprint | Story | Outcome | Risk |
|---|---|---|---|
| [1 · Large playable start](sprint-1.md) | S1.1 | Playable 96×96 La Roma variant, readable camera and one bicitaxi scout per side. | high |
| [2 · Resource journeys](sprint-2.md) | S2.1 | Fair starts, separated expansion resources, legal AI scouting and reliable routes. | high |
| [3 · Complete match proof](sprint-3.md) | S3.1 | Both victory routes, compatibility, performance and Restricted owner proof. | high |

## Deploy order
Keep current 28×28 matches and private-match host version stable while the new map/content ID is built locally. Add the matching ingest/version allowlist only if the accepted event contract changes, then verify test-tagged exclusion before attempting in-app sync from a Restricted client. Run Godot rules/content/client/save/replay/hash checks and release-export performance; obtain independent high-risk review. Land the assembled diff on `master`, export the signed macOS preview following `deploy/alpha/README.md`, independently fetch and verify the exact archive, then perform the sprint walkthroughs on the downloaded app. A merge is integration; the preview is a separate release.

## Definition of Done (epic)
- [ ] One large La Roma match supports scouting, separated resources, fair AI, the bicitaxi and both victory routes without stuck or overlapped units; existing maps still work.
- [x] Save/resume, replay, content/version validation, cross-platform hashes and required Godot/Node/CI checks pass; the independent high-risk review is resolved.
- [x] A representative 96×96 owner-Mac release export reports route/tick/frame/memory against D7's predeclared budgets; any change in final dimensions or budget is recorded before acceptance.
- [ ] Signed Restricted preview is independently fetched, byte/signature/startup checked and used for numbered smoke steps. The owner accepts or requests revision on Large-map feel, resource spacing and pace; an uncoached player identifies the scout and objective.
- [ ] Poster, generated board, retrospective and durable learning record the actual result. Keep `status: in-progress` while owner downloaded-build QA is owed; set `shipped` only after the full outcome is accepted and synced.
