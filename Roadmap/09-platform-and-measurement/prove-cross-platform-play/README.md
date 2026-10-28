---
status: in-progress   # authoritative until real-build QA closes
phase: Building
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: prove-cross-platform-play
title: "Prove cross-platform play"
area: 09-platform-and-measurement
risk: high
type: feature
sprints_total: 3
stories_total: 7
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 50    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 300
quote_basis: "L, n=0, wide"
hypothesis: "Classic RTS players currently have only a Restricted macOS build. Playable desktop and browser builds, followed by honest touch-device proof, would let them choose a device without learning different game rules. We'll know when real-device full matches and portable saves pass the declared matrix."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players choosing a desktop or browser for a complete match, then touch-device players testing the same game."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The platform work plausibly improves match completion, but no eligible cohort or platform-specific completion baseline exists to set a numeric target."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 22      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
destination: accessible-cross-platform-release
---

# Epic: Prove cross-platform play

> **Area:** 09-platform-and-measurement · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/prove-cross-platform-play.md`](../../00-ideas/seeds/prove-cross-platform-play.md)
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

Players who choose another computer or browser cannot yet rely on finishing and resuming the same RTS battle. This epic proves the current game on named desktop targets first, then designed touch play on physical phones, and finally Restricted Web multiplayer. Each support claim follows a full match and a recorded device result. The owner approved the plan, option B matrix, proof budget and one orchestrated build on 2026-10-28, including merges and releases. The exact physical device inventory is still being gathered.

The owner can provide one Windows PC, one Android phone and one iPhone alongside the current Mac. No physical Linux PC was named. iOS development signing is unavailable. Native Linux and native iOS therefore remain **unverified** support rows unless those dependencies change; Linux headless checks and iPhone Safari can still run as separate checks. Exact models/OS versions are collected at QA.

## Platform-first note

The Godot simulation owns rules/content/state, the match service owns online results, and the existing ingest owns event eligibility. Platform adapters issue validated commands; they do not fork rules, saves, protocol or reporting. The [scope pitch](../../00-ideas/seeds/prove-cross-platform-play.md) holds the accepted matrix and exclusions.

## What already exists (reuse, don't rebuild)

- `game/skirmish.gd`, `skirmish_persistence.gd`, `skirmish_replay.gd` and `tests/cross_platform_hash_test.gd` provide shared simulation and versioned state.
- `game/skirmish_main.gd`, `ui/battle_hud.gd` and `docs/art/ui-component-spec.md` provide desktop commands and a responsive layout; touch is currently mouse emulation.
- `game/export_presets.cfg`, `game/README.md` and `scripts/alpha-export.mjs` provide a Web compatibility export and signed Restricted macOS route.
- `game/multiplayer_client.gd`, the [multiplayer epic](../../03-multiplayer-and-retention/prove-multiplayer/README.md), and [ADR 004](../../../docs/architecture-decisions/004-synchronization-model.md) provide one server authority and the known failed Web-origin preflight.
- `game/funnel_outbox.gd` and `src/funnel/ingest.mjs` retain the agreed event eligibility and test exclusions.

## Architecture lock

- **D1 · One game:** Native and Web views translate input into the same validated commands and read the same rules/content IDs. No target-specific rule or result branch.
- **D2 · Traceability:** Each proof artifact records source commit, pinned Godot/export-template version, game/content version, target OS/browser and device. CI hashes and actual installed/served builds are different checks.
- **D3 · Persistence:** Same-version canonical solo state crosses native/Web through explicit export/import. Corrupt or old files are rejected without deletion; an exported save contains no invite token, ingest secret or outbox credential. Completion remains deduplicated.
- **D4 · Web:** Start with single-threaded Compatibility export. Browser storage is best effort; clear-site-data and private-window checks are owed. Audio activation and sustained memory are measured in real browsers.
- **D5 · Touch:** A touch adapter owns select/group/order/cancel/pan/zoom. Gesture handling must not dispatch unintended board orders. Phone layout uses the existing HUD contract, not a new game rule.
- **D6 · Online:** The existing server remains authoritative. Only a named Restricted origin gets CORS permission; bad origins/codes stay rejected. `multiplayer.private_match_enabled` controls new admissions and is left off after QA. No public invite or eligibility change is implied by a preview.
- **D7 · Measurement:** Reuse accepted `match_started`/`match_completed`; test traffic stays excluded. The provisional 15% return target and North Star definitions do not change.
- **D8 · Claims:** A row is supported only after a physical-device/browser full match, save/resume and the declared frame/memory check. Missing hardware is unverified. Browser solo and browser multiplayer are separate claims.

**Verified source constraints at lock:** `game/export_presets.cfg` has macOS and single-threaded Web presets only; Windows, Linux, Android and iOS need presets. `game/skirmish_persistence.gd` has a validated schema-5 save but only a local `user://` path; `game/skirmish_main.gd` has replay file selection, not portable solo save dialogs. `game/project.godot` enables touch-to-mouse emulation; the match input handler consumes mouse events and has no gesture adapter. `src/multiplayer/http.mjs` has no OPTIONS or origin policy, consistent with the recorded Web preflight failure. The generated kickoff's `origin/main`, implied deployment on merge, mandatory new flag, and local `session-resume.mjs`/`epic-phase.mjs`/`review-route.mjs` assumptions do not fit this checkout; the branch base is `master`, release is separate, the existing admission flag is reused, and the project runbook plus available pinned kit commands govern verification. The owner approved the entire L run, so the wave review does not require a second appetite decision.

## Scope — stories

| Sprint | Stories | QA gate |
| --- | --- | --- |
| [1 · Desktop and browser solo proof](sprint-1.md) | S1.1 build matrix, S1.2 full matches, S1.3 portable saves | Export/hash specs, browser smoke and named real-device match. |
| [2 · Designed touch and mobile proof](sprint-2.md) | S2.1 touch adapter, S2.2 native/mobile Web target decisions | Input specs, uncoached physical touch tasks and long-match device profile. |
| [3 · Restricted shared play and support decision](sprint-3.md) | S3.1 Web/native online match, S3.2 evidence ledger | Exact-origin/auth tests, replay/receipt check and owner support sign-off. |

## Deploy order

Build and verify locally first. Serve desktop Web on a Restricted preview origin, then enable only its exact origin on the isolated match host. Use scoped, revocable test codes and turn preview admission off after each online smoke. A native/mobile test install and a Restricted upload are releases with source/build identity, not a result of merging to `master`. Keep every new target test-tagged until the owner explicitly opens an eligible cohort.

## Definition of Done (epic)

- [ ] Seven story checks pass, with headless contracts plus real installed/served full matches for each claimed target.
- [ ] Desktop and mobile support statements identify exact passing OS/browser/device/build combinations; unsupported and unverified rows remain explicit.
- [ ] Same-version native/Web saves, audio/input, long-session frame/memory and result parity pass on those claimed targets.
- [ ] Restricted Web/native online match, reconnect, replay, exact-origin denial and excluded receipt pass; independent review covers auth/player data.
- [ ] Each sprint's numbered owner walkthrough records actual build URLs/IDs and results; merge reachability on `origin/master` and real Restricted releases are verified separately.
- [ ] `Roadmap/README.md`, `Roadmap/LEARNINGS.md`, generated board and retrospective reflect actual evidence. Mark `status: shipped` only after the real-build gates pass.
