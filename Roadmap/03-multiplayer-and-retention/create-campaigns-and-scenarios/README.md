---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Building       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: create-campaigns-and-scenarios
title: "Create the first campaign chapter"
area: 03-multiplayer-and-retention
destination: shared-and-authored-play
risk: high
type: feature
sprints_total: 3
stories_total: 7   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Today classic RTS players face standalone battles with no path into La Roma. A short chapter lets them learn the rules and unlock a final battle on the same maps. We'll know when an uncoached player finishes that battle and the accepted first-match funnel can be read."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "first_match_completion"   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players learning this game's economy, objectives and CDMX setting, including players unfamiliar with Mexican references."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "First-match completion is agreed, but no real cohort or baseline exists and a campaign-to-skirmish effect has not been tested."   # only with grounded: false
flag_key: campaign.chapter_enabled   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: everyone   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: campaign_mission_completed
retained_event: campaign_mission_completed
retention_days: 7
satisfied_event: null
build_order: 24      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Create the first campaign chapter

> **Area:** 03-multiplayer-and-retention · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/create-campaigns-and-scenarios.md`](../../00-ideas/seeds/create-campaigns-and-scenarios.md)
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

Players can finish standalone battles but have no guided route through this game's economy, expansion and La Roma objective. This chapter gives them three linked battles on existing maps, with visible goals and progress they can trust across restarts. The first test is whether uncoached players finish the final full battle and understand how they won.

## Platform-first note

The Godot simulation is the sole rules authority. Mission data selects an existing map and observes canonical fixed-tick state; it cannot replace orders, AI or victory logic. The local chapter ledger is a separate player-progress record, and the existing outbox and backend remain the authority for accepted funnel events. The alpha backend resolves the Golden Frijoles campaign flag for the same pseudonymous player ID; no provider key enters the game client.

## Architecture lock · 2026-10-27

- **D1 · Bounded mission data:** A versioned manifest lists three stable mission IDs, existing map IDs, prerequisite IDs, faction choice, plain objective copy, and only declared condition kinds. Reject unknown IDs, cycles, unbounded triggers, unsupported actions and duplicate unlocks before entering a match. No executable script or new game rule.
- **D2 · One fixed-tick authority:** Mission conditions read canonical match state at ordered tick boundaries. The simulation owns objective state and terminal result; the scene displays it. Any scripted order uses the validated command path. AI uses normal sight and legal orders.
- **D3 · Finale dependency:** Copilco and Narvarte use existing playable maps. The full final battle uses la_roma_large only after #24's owner accept/revise decision passes. If that decision changes the map, return to the owner before modifying the approved finale.
- **D4 · Save, replay and progress:** Mission ID, manifest/content hash and objective state are versioned with the match snapshot and replay. Resume preserves match ID. A separate atomic local ledger records a verified mission win once; replay, loss, abandon or duplicate result cannot unlock twice. Corrupt/unsupported files remain intact with a readable error. Old skirmish saves/replays keep their declared compatibility.
- **D5 · Measurement eligibility:** The first two guided missions are excluded tutorials. Only the final full battle may count as an eligible match after validating a real human start-to-terminal battle without scripted advantage, supported version, accepted outbox transitions and non-test identity. An adoption event is emitted on each verified mission win; the first occurrence is the Copilco win. The current North Star and its provisional 15% target are unchanged.
- **D6 · Campaign flag:** campaign.chapter_enabled is a Golden Frijoles enablement flag, off until rollout. The alpha backend resolves it per stable pseudonymous player ID and reports user-level evaluation. A no-key client receives decision/version only; before first served decision it defaults off, and offline it uses the last served choice. Disabling the flag blocks new online starts at the next check but cannot revoke an already offline session. Verify a served off version in every environment.
- **D7 · Release evidence:** Run headless simulation/content/save/replay/funnel contracts, rendered native UI checks, an independent high-risk review and a signed Restricted download. The owner completes a chapter and separate skirmish on that download. Cultural comprehension tests need separately authorized participants; no public release or cohort inference follows from a merge or export.

## What already exists (reuse, don't rebuild)

- game/rules_content.gd and existing Copilco, Narvarte and La Roma Large content provide validated maps and four faction choices.
- game/skirmish.gd owns fixed-tick rules, snapshots, AI and terminal results; game/skirmish_main.gd owns native setup, HUD and results.
- game/skirmish_persistence.gd and game/skirmish_replay.gd preserve match identity, content hashes and deterministic playback under [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md).
- game/funnel_outbox.gd, src/funnel/ingest.mjs and the [North Star](../../00-strategy/north-star.md) define accepted match events and tutorial exclusion.
- The [approved pitch](../../00-ideas/seeds/create-campaigns-and-scenarios.md), [#16 map work](../../02-civilizations-and-world/establish-cdmx-geography-and-maps/README.md), [#18 interface work](../../02-civilizations-and-world/complete-game-interfaces/README.md) and [#24 large map](../../01-core-play/build-large-la-roma-battlefield/README.md) define content, view and dependency boundaries.

## Scope — stories

| Sprint | Stories | Risk |
|---|---|---|
| [1 · Mission contract](sprint-1.md) | S1.1 validate bounded definitions; S1.2 advance deterministic objectives | high · high |
| [2 · Chapter path](sprint-2.md) | S2.1 select and understand missions; S2.2 persist unlocks safely | low · high |
| [3 · Play and measure](sprint-3.md) | S3.1 finish the three-map chapter; S3.2 measure flag/adoption and final eligibility; S3.3 record uncoached comprehension | high · high · low |

## Deploy order

1. Lock the mission vocabulary, canonical state and compatibility plan against current code. Prove ordinary skirmish hashes and map selection still pass before showing a campaign entry.
2. Build the first playable mission on the fixed-tick rules, then local progression and all three authored missions. Keep a dedicated profile for development and a Restricted preview; do not migrate a real player's save silently.
3. Add the server-side flag and event contract with test traffic excluded. Create campaign.chapter_enabled in Golden Frijoles with an off served version in development, preview and production; verify each row. Keep production off. No provider key reaches an export.
4. Run required CI, independent review, native rendered checks and a signed Restricted export. Fetch the actual archive independently, compare hash/signature and start it. Owner full-match and uncoached acceptance remain separate evidence. Merging to master alone does not release a game build.

## Definition of Done

- [ ] Seven stories meet the [pitch's acceptance checks](../../00-ideas/seeds/create-campaigns-and-scenarios.md#acceptance-criteria), with independent review for shared simulation, local progress, flag and funnel integrity.
- [ ] Every sprint's numbered walkthrough is recorded against a real build. Copilco and Narvarte guided missions, a complete La Roma Large battle, save/quit/resume, replay and an unchanged skirmish all pass.
- [ ] The final battle's match eligibility reconciles accepted start/finish once. Tutorial, replay, duplicate, abandon, bot and test traffic remain excluded. No numeric cohort lift is asserted before one exists.
- [ ] campaign.chapter_enabled exists with an explicit served off version in every Golden Frijoles environment. Per-user evaluation and first-mission adoption work without a client credential; online disable and cached-offline limits are verified.
- [ ] A signed Restricted archive is independently fetched, hash/signature/startup checked and played by the owner. #24's large-map acceptance is recorded before this finale is called done. Separate owner-authorized familiar/unfamiliar player reads are recorded or kept explicitly open.
- [ ] Reviewed source is merged to master, the resulting build is released to the approved Restricted channel, and the source commit/build ID are recorded. This is not a public release.
- [ ] The retrospective, product poster and durable learnings record the actual result. Mark status shipped only when all owner and real-build checks close; regenerate and sync the roadmap.
