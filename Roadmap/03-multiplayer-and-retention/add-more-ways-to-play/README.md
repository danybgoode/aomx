---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Building       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: add-more-ways-to-play
title: "Add more ways to play"
area: 03-multiplayer-and-retention
destination: shared-and-authored-play
risk: high
type: feature
sprints_total: 3
stories_total: 5   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Today returning skirmish players get the same two simultaneous win routes every match. Let them choose a clear objective, including a new monument contest, so another battle asks for a different plan. We'll know when an owner completes each objective and later eligible players return to finish another match."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players choosing a fresh solo battle after finishing a skirmish, including players unfamiliar with Mexican references."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The later-day completion input is agreed, but no eligible play cohort, observed baseline or mode-demand evidence exists."   # only with grounded: false
flag_key: modes.wonder_enabled   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: everyone   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: wonder_match_completed
retained_event: wonder_match_completed
retention_days: 7
satisfied_event: null
build_order: 24      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Add more ways to play

> **Area:** 03-multiplayer-and-retention · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/add-more-ways-to-play.md`](../../00-ideas/seeds/add-more-ways-to-play.md)

## Why

A returning skirmish player chooses a clear objective that changes how the next battle is planned. Conquest and La Roma separate today's combined routes; Wonder adds an economic build-and-defend contest. The player can finish each against fair AI and understand the rules without knowing CDMX references. Later-day retention remains unmeasured until an eligible cohort exists.

## Platform-first note

The fixed-tick Godot simulation remains the only rules authority. Versioned content owns objective IDs, cost and timers; snapshots and replays carry selected mode and progress. The existing outbox and ingest own accepted match results, while Golden Frijoles serves the Wonder enablement flag through the alpha backend. No parallel rules, flag or event store.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`, `game/rules_content.gd` and `game/content/skirmish.v1.json`: existing post and district terminal paths, validated commands, AI and content.
- `game/skirmish_main.gd` and `game/ui/battle_hud.gd`: setup, mode entry, objective widget and result copy.
- `game/skirmish_persistence.gd`, `game/skirmish_replay.gd` and ADR 003: save/replay/hash compatibility.
- `game/funnel_outbox.gd`, `src/funnel/ingest.mjs` and the North Star: match identity, mode, accepted result and test exclusion.
- `src/alpha/campaign-flags.mjs` and `game/campaign_flag_cache.gd`: server-served decision and offline cache pattern.

## Architecture lock

The owner approved the [pitch's rule card](../../00-ideas/seeds/add-more-ways-to-play.md#scope) on 2026-10-27: Conquest is post defeat only; La Roma remains the old post-or-center default; Wonder adds one buildable project per side on the 28×28 La Roma map, at `godin`, costing 16 comida, 20 materiales, 20 varos and 12 terrenos, with 180 build ticks and 900 hold ticks. Post defeat takes precedence; simultaneous posts or Wonder finishes draw. Public objective timing does not reveal fogged units. The 9000-tick draw limit remains. If whole-match evidence contradicts this rule card, revise with the owner before widening scope.

Solo mode selection must be pinned in save/replay and cannot change the Restricted 1v1 or campaign finale implicitly. A content or game-version change has explicit old-file handling and a compatible ingest contract. Wonder is off by default under `modes.wonder_enabled` until a served version is verified in every environment. The alpha backend evaluates it per the existing pseudonymous player ID and records that evaluation; no provider key enters the game.

### D1–D7 · Implementation contract

- **D1 · Objective identity:** `la_roma` is the absent-field/default objective to preserve old snapshot and network hashes. `conquest` and `wonder` are explicit, validated solo IDs. Campaign forces its own mission objective, and the current private 1v1 remains on `la_roma`. No objective can change mid-match.
- **D2 · Versioned Wonder content:** The base `la-roma-world-5` JSON and its hash stay unchanged for existing play. A separate, checked Wonder overlay on the 28×28 La Roma map adds the building and timer with a distinct content ID/hash. Reject Wonder on other maps or without the overlay. This prevents an additive solo mode from silently altering all four maps or the online host.
- **D3 · Fixed-tick terminal order:** Resolve simultaneous post destruction first, then a mode-specific center or Wonder condition, then the existing 9000-tick draw. Wonder progress derives only from a completed living project; destruction clears it, and simultaneous completed timers draw. A worker's ordinary validated build command pays the approved cost and obeys placement, age and one-active-project rules.
- **D4 · Save/replay compatibility:** Add objective and Wonder state only to nondefault snapshots; old `la_roma` snapshots stay byte-equivalent. Save and replay restore the selected objective from a validated field, select the matching content hash, and reject malformed/incompatible files without deletion. The ordinary local save slot and match ID remain unchanged.
- **D5 · Fair AI and readable view:** AI gathers, reaches `godin`, builds and defends its project through the same orders/costs, and attacks an observed opposing project through normal sight. The UI offers Conquest/La Roma on all old solo maps and Wonder only on 28×28 La Roma when the served flag allows it. Setup, HUD and result describe the selected terminal rule.
- **D6 · Measurement:** Keep the North Star's existing `match_started`/`match_completed` transition and per-player-match deduplication. Add a validated objective field to those records; `wonder_match_completed` follows a matched, accepted Wonder finish only. Client test traffic remains excluded. After a successful user-level evaluation, the backend signs a proof bound to player, environment and flag version. It verifies that proof and the current served-on version before accepting a Wonder start. A previously accepted match may finish after the flag turns off.
- **D7 · Rollout isolation:** The new solo preview uses the separate Restricted pilot channel until its simulation hash and version contract are reviewed with the match host. The old Restricted online channel stays pinned and admission off; the pilot may show its private-match entry as incompatible until the host is deliberately updated. This narrows the pitch's same-build private-start expectation to a verified old-channel regression plus explicit pilot incompatibility, because the current host pins `skirmish.gd` bytes in `SIMULATION_HASH`.

## Scope — stories

| Sprint | Stories | QA boundary |
| --- | --- | --- |
| [1 · Select a solo objective](sprint-1.md) | S1.1 versioned selection and legacy default; S1.2 readable setup/HUD/result | Terminal precedence, compatibility, rendered 1024×700/1280×800 smoke. |
| [2 · Build and measure Wonder](sprint-2.md) | S2.1 construction, AI and countdown; S2.2 served flag and accepted event contract | Four-faction fixtures, AI scenarios, hash/save/replay, provider and ingest audit. |
| [3 · Prove whole matches](sprint-3.md) | S3.1 complete Restricted owner walkthrough | Signed download, mode matrix, Wonder save/resume, campaign and 1v1 isolation. |

## Deploy order

Land versioned rules, compatibility and ingest allowlist with test traffic before a new client sync. Keep `modes.wonder_enabled` served off in development, preview and production until the signed Restricted build passes owner QA. The campaign and online match remain on their pinned rules. Merging to `master` does not deploy a game; export, upload, fetch, verify and owner play are separate evidence.

## Definition of Done (epic)
- [ ] All five stories meet the [pitch's acceptance checks](../../00-ideas/seeds/add-more-ways-to-play.md#acceptance-criteria), with independent high-risk review of simulation, save/replay, flag and funnel integrity.
- [ ] All three sprint walkthroughs record a source/build ID, expected and observed results. The downloaded Restricted owner build finishes every objective, resumes Wonder and preserves campaign/private-match starts.
- [ ] Headless Godot, Node ingest and cross-platform hash cases pass; rendered 1024×700 and 1280×800 checks and a normal AI match are recorded.
- [ ] `modes.wonder_enabled` exists with a served off version in every Golden Frijoles environment; user-level evaluations and accepted Wonder adoption work without a client credential. A release decision to turn it on is recorded separately.
- [ ] Reviewed code lands on `master`; a signed Restricted export is uploaded, fetched, hash/signature checked and played. No public release or retention claim follows.
- [ ] Update the poster and generated board, write a dated retrospective only at actual close, promote durable project findings to `Roadmap/LEARNINGS.md`, and set this README `status: shipped` only when all evidence above exists.
