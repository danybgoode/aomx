---
status: shipped   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Shipped       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: harden-rts-simulation
title: "Harden the RTS simulation"
area: 01-core-play
risk: high
type: feature
sprints_total: 3
stories_total: 3   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "We believe classic RTS players will be able to finish and resume a growing La Roma match because versioned rules, content and replay share one verified simulation. We'll know when saved and replayed matches preserve outcomes as new content loads."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # no observed baseline yet; match completion remains the later product signal
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players playing a growing solo skirmish, and builders adding rules to that match."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The first real match cohort has not matured, and architecture correctness is a prerequisite rather than a directly observed retention lift."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 8       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
destination: full-depth-rts
---

# Epic: Harden the RTS simulation

> **Area:** 01-core-play · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/harden-rts-simulation.md`](../../00-ideas/seeds/harden-rts-simulation.md)
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

Players should be able to finish and resume the existing solo match as the game gains more civilizations, economy and combat. Builders need one reliable rules path so each new mechanic behaves the same after a save, a replay and on a supported device. This epic turns the current prototype into that durable base while preserving its playable experience. It advances [full-depth-rts](../../horizon.md#full-depth-rts--a-complete-strategic-rts), not a claim that the full GDD is implemented.

## Platform-first note

`game/skirmish.gd` already owns the match rules, fixed tick, command IDs, snapshots and hashes. Extract contracts from that rules source. `game/skirmish_main.gd` remains a Godot input/view adapter; it must not become the source of truth for collision, costs or victory. The render manifest stays separate from gameplay content. The existing funnel outbox remains a distinct, test-tagged measurement system. No new public cohort event or Golden Frijoles flag is needed for this internal migration.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`: validated `issue`, fixed `tick`, stable entity IDs, command log, snapshot and state hash.
- `game/skirmish_main.gd`: current two-faction input, HUD and rendered board; preserve its command behavior.
- `game/tests/skirmish_test.gd`, `faction_test.gd`, `district_test.gd` and `skirmish_benchmark.gd`: baseline rule cases and the 12-unit benchmark.
- `game/assets/manifest.v0.1.json`: view-only asset lookup; do not turn sprite metadata into rules.
- [ADR 001](../../../docs/architecture-decisions/001-engine-selection.md): Godot remains the engine pending representative evidence.
- [GDD v0.3](../../../docs/design/GDD.md) and [ADR 002](../../../docs/architecture-decisions/002-aoe2-definitive-edition-reference.md): intended rules and chosen reference edition. Pin a specific DE patch when numerical fixtures begin.

## Scope — stories
| Sprint | Player/builder result | Risk and exit evidence |
|---|---|---|
| [1](sprint-1.md) | Existing match runs through stable commands, versioned content and canonical state. | High; baseline match, invalid-definition cases and rendered two-faction smoke. |
| [2](sprint-2.md) | Save and resume a match; replay its commands to the same terminal state with explicit version handling. | High; round trip, malformed/old save cases, replay hashes and owner resume walkthrough. |
| [3](sprint-3.md) | A representative stress match and cross-environment results inform pathing and network synchronization. | High; reproducible benchmark matrix, real-window smoke and a written sync-model decision. |

## Architecture lock · 2026-10-16

- **D1 · One authority:** `game/skirmish.gd` remains the rules authority. Input, HUD, art and telemetry consume state or issue semantic commands. Do not create a second match engine. Existing `issue(side, kind, actor_id, target)` remains a compatibility adapter while the versioned command envelope is introduced.
- **D2 · Stable contracts:** The command envelope carries schema version, logical issue tick, sequence, side, actor ID, kind and a typed target. Reject unknown versions, kinds, IDs or malformed targets before mutation. New game-content definitions use stable string IDs with validated costs, health, timing, faction modifiers and objective parameters. Keep rendering assets in their separate manifest.
- **D3 · Canonical state:** A versioned save contains only authoritative logical state: faction choice, tick, entities with stable IDs and queued work, source/stockpile amounts, district and terminal state, AI schedule/state, command sequence and seeded RNG state. Exclude frame accumulator, UI selection/zoom, invite code, player identity and telemetry outbox. The save wrapper additionally carries match ID and event-completion guard, without copying the outbox.
- **D4 · Deterministic order:** One fixed 0.1-second tick. Apply due commands in sequence, AI orders, ascending entity IDs, damage in ascending target ID, deaths, then victory/district. No rendering FPS or global random source changes outcomes. Seeded RNG is owned by the simulation even though the current rules use no random draws. Preserve the current two-faction costs, movement and both terminal paths.
- **D5 · Persistence and compatibility:** Separate command, simulation-state, save-wrapper and content versions. Read only supported versions; malformed or unknown files return a clear error and stay intact. Write a temporary file, flush and atomically replace the destination where supported. Do not silently reset a match. A resumed match keeps its match ID and must not emit a second start or duplicate completion.
- **D6 · Replay and comparison:** Replay the versioned human command stream at its recorded logical ticks while the deterministic AI derives its own orders. Compare checkpoint hashes and name the first divergent tick. A replay record is diagnostic evidence, not a trusted multiplayer protocol.
- **D7 · Scale and sync evidence:** Benchmark the 20×20/12-unit baseline and at least two larger, crowded cases; record device, build type, duration, commands, tick/route/frame/memory results and budgets before changing routing. Compare macOS and Linux headless hashes when CI is available. Choose lockstep only if declared cross-environment cases agree; otherwise favor an authoritative model or record a missing experiment. This epic does not implement networking.

**Baseline before extraction:** Godot 4.7.2 macOS headless rules, faction and district suites pass; the client suite passes with normal `user://` access. The existing 20×20/12-unit benchmark on this Mac measured 5,000 routes at 0.4553 ms mean and 1,000 ticks at 0.0423 ms mean. Existing tests cover command-post and district terminal paths. This is the comparison baseline, not the later scale target.

**Outcome verified 2026-10-16:** [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md) specifies the implemented simulation, content, save and replay contracts. The [benchmark report](../../../docs/simulation-benchmark-2026-10-16.md) records passing local and Linux route/tick budgets through 48×48/163 entities, identical 700-tick faction hashes and rendered save/crowd probes. [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) records the provisional network direction. All 12 Godot headless suites, Node tests and the game-to-ingest contract pass locally and in Linux CI. An independent Codex review found malformed replay input handling; it was fixed and covered by regression tests. [PR #39](https://github.com/danybgoode/aomx/pull/39) merged as `27661d2`; signed Restricted `preview-27661d2a0900` is ready as itch build `#2143645`. Butler fetched byte-identical files, and the fetched app passed save/quit/reopen/resume. The owner reported that browser download, save/resume, a command-post win and a La Roma hold win all passed on this build. This is a Restricted owner preview, not a public game release.

**Boundary:** this epic does not add the four-resource economy, all ages, production wildlife, network transport or matchmaking. A cross-platform mismatch is evidence for the synchronization decision, not a reason to assert lockstep.

## Deploy order

Land each sprint as a reviewable change on a `feat/harden-rts-simulation` branch, preserving the current Godot scene and test-tagged alpha outbox. Run headless rules and contract checks before the rendered local/preview build; smoke that build before considering the sprint complete. There is no production game deployment rail. A merge to `master` is integration, not shipment.

## Definition of Done (epic)
- [x] All three sprint stories are implemented, reviewed, merged to `master`, and verified in a real Godot build; record commit/PR and smoke evidence in the sprint documents.
- [x] Current Regios and Poblanos matches still finish by command-post and district routes in regression suites; invalid commands/content fail visibly and safely.
- [x] Versioned save/load and replay reproduce declared canonical hashes; incompatible data has a documented, tested rejection path.
- [x] Benchmark evidence names map/unit counts, command load, device/build, duration, tick/frame/memory budgets and results; the synchronization and routing decision records what remains uncertain.
- [x] A second reviewer checks simulation and save migration. The owner completes the downloaded-build save/resume and terminal-match walkthrough; test-tagged telemetry remains excluded from public cohort counts.
- [x] Update [the product poster](../../README.md), [learnings](../../LEARNINGS.md), and [retrospective](RETROSPECTIVE.md) with the observed result. Regenerate the Golden Frijoles board and sync it after status changes.
- [x] Set this README to `status: shipped` only after the epic outcome is verified. Do not describe a merge as a deployed game build.
