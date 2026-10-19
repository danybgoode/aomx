---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Building       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: expand-civilizations-and-world
title: "Expand civilizations and world"
area: 02-civilizations-and-world
destination: fight-for-la-roma
risk: high
type: feature
sprints_total: 4
stories_total: 8   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "Today players have two factions on one map, limiting reasons to replay. Two more counterable factions, two fair maps and original media give classic RTS players new strategies and settings. We'll check uncoached second-match choice, then eligible later-day completions when a real cohort exists."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "return_to_match"   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players choosing another solo skirmish, including players unfamiliar with Mexican references."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The agreed later-day completion input has no eligible cohort baseline, and no test yet isolates the effect of a new faction or map."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 13      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Expand civilizations and world

> **Area:** 02-civilizations-and-world · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/expand-civilizations-and-world.md`](../../00-ideas/seeds/expand-civilizations-and-world.md)
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

Classic RTS players have only two factions and one map in the current match. This epic makes Oaxaqueños and Veracruzanos, Narvarte and Copilco playable alongside the existing content. Each new choice changes a strategy with readable counterplay and an original Mexico City identity. It tests whether players understand and choose another battle; no retention lift is claimed before a mature eligible cohort.

## Architecture and design lock

- **One simulation.** Extend the existing validated, fixed-tick rules and versioned content. A match pins faction IDs, a map ID and a content ID at start. Save/replay preserves or explicitly rejects incompatible content without deleting a save. Views and audio do not own collision or outcomes.
- **Four candidate factions.** Regios and Poblanos retain their approved prototype rules. The owner approved Oaxaqueños as fictional resource efficiency/support and Veracruzanos as fictional mobility/trade. Sprint 1 records exact strengths, weaknesses, tech choices and counterplay before gameplay implementation. They are play doctrines, not claims about regional people. No GDD number is automatically approved.
- **Three authored maps.** La Roma remains the current map. Narvarte uses a balanced street grid and Copilco uses readable chokepoints with alternative routes. All keep Conquest and a marked central hold route. Starting resource access, center access, AI navigation and sight must be checked before decor.
- **Version and event integrity.** Match-start and completion remain test-tagged in Restricted previews. The ingest's content allowlist must be updated and smoke-tested before a new preview attempts sync. Real eligible cohort rules and the agreed North Star remain unchanged.
- **Production media.** Reuse the traced owned-art export and manifest; add only assets with per-source rights and scale checks. Audio is original and controllable. Media never defines faction stats or pathing. No unlicensed music or flattened concept board becomes a playable map.
- **Review boundaries.** L appetite is revisited after each sprint. High-risk changes to rules, persistence or ingest get independent review. The owner checks portrayal, a downloaded build and cultural clarity. External invitations still use the private-alpha gates.

### Decision record · 2026-10-19

- **D1 · Content model:** Keep one canonical rules engine. Add four stable faction IDs and three stable map IDs to validated content. Each match pins the selected content and map ID at creation; the game creates no partly switched match.
- **D2 · Save and replay:** Version 5 records map and opponent choices and verifies the content hash before reconstructing state. Version-4 saves return `unsupported_save_version` and remain on disk; incompatible version-5 content returns `content_version_mismatch`. No silent substitution.
- **D3 · Faction doctrine:** Keep Regios and Poblanos intact. Oaxaqueños get a fictional efficiency/support tradeoff; Veracruzanos get a fictional mobility/trade tradeoff. Exact integer parameters and tech effects are declared in content and reviewed with scenario evidence, not inferred from regional identity. Each weakness has a usable opposing response.
- **D4 · Map contract:** La Roma, Narvarte and Copilco are authored, not random. Map definitions include dimensions, blocked/elevated/cliff tiles, two starts, four resource locations per side, center footprint and AI targets. Validation and route tests reject inaccessible starts/resources/center before a map is selectable.
- **D5 · AI and terminals:** All factions/maps use the same command validation, sight, costs, combat and two terminal rules. Classic rival defaults to a different faction; an explicit opponent selection can make a mirror match. AI gains no hidden faction or map privilege. Same match ID yields one terminal event.
- **D6 · Presentation:** The setup and HUD state strengths, costs, objectives and counters in plain words; shape, heading, outlines and labels supplement color. Existing project-original unit sprites animate through view-only stride/idle and a four-direction heading marker. An original generated WAV cue has reproducible source, hash and mute/volume controls. None affects simulation.
- **D7 · Measurement and rollout:** Match events retain the existing schema and test exclusion. Bump the content version consistently in Godot, Node contract, preview ingest allowlist and export manifest. Server support precedes preview sync. No runtime flag changes a match; versioned Restricted builds are the rollback unit.
- **D8 · Verification:** Each sprint has headless contracts, a rendered local smoke and a numbered owner walkthrough. The release gate is a signed Restricted macOS download with full-match, save/resume and excluded sync evidence. The eight-person cultural read requires the existing owner invitation gate and records failures verbatim.

### Sprint build contracts

- **S1:** Pin the roster/map IDs, exact rule proposal, content schema and save/replay policy; retain the existing match. Validate malformed definitions and old-save failure behavior before new factions are made selectable.
- **S2:** Add Oaxaqueños and Veracruzanos through content-driven rules and the same AI path. Check each faction's strength, cost, counter, mirror and cross-faction matchups under replay.
- **S3:** Add Narvarte and Copilco as selectable authored maps. Check reachability, four-resource opening equity, both objectives, all three AI levels, save/replay and release-build budgets.
- **S4:** Integrate traced animation/audio, run the four-faction/three-map matrix and downloaded-build smoke, then record owner and human clarity evidence. Do not infer a human pass from automated tests.

## What already exists (reuse, don't rebuild)

- `game/content/skirmish.v1.json` and `game/rules_content.gd`: current content schema, factions, technology and map validation.
- `game/skirmish.gd`, `game/skirmish_main.gd`: canonical commands, fixed tick, AI, setup, HUD and both victories.
- `game/skirmish_persistence.gd`, `game/skirmish_replay.gd`: content-pinned save and deterministic replay.
- `game/art_catalog.gd`, `game/assets/manifest.v0.1.json`, `scripts/export-owned-art.sh`: sourced visual exports.
- `game/funnel_outbox.gd`, the Node ingest contract and Restricted preview rail: existing test-tagged results and version enforcement.
- Prior [La Roma](../prove-la-roma-promise/README.md), [art](../la-roma-battlefield-art-pack/README.md) and [owned-art](../integrate-owned-art-library/README.md) epics: current proof, geometry and open human QA.

## Scope — stories

| Sprint | Stories | Playable or reviewable outcome |
| --- | --- | --- |
| [1 · Content contract and roster](sprint-1.md) | S1.1 roster/tech decisions; S1.2 versioned faction/map content | Approved fictional roles and a content contract that protects the old match. |
| [2 · Two new playable factions](sprint-2.md) | S2.1 Oaxaqueños; S2.2 Veracruzanos | Both new factions can finish, counter and be countered under the same rules. |
| [3 · Two new authored maps](sprint-3.md) | S3.1 Narvarte; S3.2 Copilco | Three selectable maps with fair starts, legal AI and both victory routes. |
| [4 · Media and human read](sprint-4.md) | S4.1 original media; S4.2 downloaded and uncoached QA | Traceable animation/audio and exact comprehension observations. |

## Build and release order

Build on `feat/expand-civilizations-and-world` after this planning commit. At each sprint boundary, run the relevant Godot headless suite, Node event contract and a numbered rendered owner smoke. Merge reviewed code to `master` only after the full diff and checks pass. A merge does not deploy a game build. Separately export and verify a signed macOS Restricted owner preview under `deploy/alpha/README.md`; keep preview traffic excluded. Any invite codes or wider access wait for the separate alpha gates.

## Definition of Done

Builder implementation and exact technical evidence are in the [world expansion QA record](../../../docs/world-expansion-qa-2026-10-19.md). Owner full-match, downloaded-build and eight-person comprehension evidence remain open until actually performed.

- [ ] Eight story outcomes pass their acceptance checks, with a numbered smoke and actual result in each sprint file.
- [ ] Four factions and three authored maps are selectable in a downloaded Restricted build; each new faction has a viable opening, weakness and visible counter. All maps retain fair resources, routes, legal AI and both victories.
- [ ] Content validation, old/new save/replay behavior, deterministic hashes and test-tagged event exclusion pass. Ingest version support precedes client sync.
- [ ] Original media has traced rights, readable scale, animation/audio controls and no simulation effect.
- [ ] Owner records portrayal review and an authorized uncoached eight-person comprehension/second-choice read with the predeclared marks. Unrun human work remains open, never inferred from builder QA.
- [ ] Independent high-risk review, checks and merge to `master` pass; a separate signed Restricted preview is fetched, opened and verified. Record build and artifact IDs.
- [ ] Update the poster and generated board, date the retrospective at actual close, promote durable learnings, and set `status: shipped` only after these results exist.
