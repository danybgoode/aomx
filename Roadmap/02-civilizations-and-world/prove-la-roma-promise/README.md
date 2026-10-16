---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Verifying      # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: prove-la-roma-promise
destination: fight-for-la-roma
title: "Prove the La Roma promise"
area: 02-civilizations-and-world
risk: low
type: feature
sprints_total: 3
stories_total: 4   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Today a classic RTS player can finish a solo skirmish but cannot experience what makes the fight for La Roma distinct. Two contrasting factions and a visible district win path give each match a strategic identity. We'll know when testers in both cultural-context groups can explain the goal and a counterplay choice without coaching."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "A classic RTS player testing whether the game's factions and setting create a fresh strategic choice."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "There is no observed play cohort or first-match completion baseline; this internal prototype will first test comprehension and strategic preference."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 5       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Prove the La Roma promise

> **Area:** 02-civilizations-and-world · **Risk:** low · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/prove-la-roma-promise.md`](../../00-ideas/seeds/prove-la-roma-promise.md)

## Why

A classic RTS player can already finish a solo skirmish, but cannot yet experience a distinct fight for La Roma. This epic adds two counterable faction choices and a visible district hold alongside command-post conquest. It tests whether players familiar and unfamiliar with Mexican references can explain both the goal and a strategic response without coaching. The eight-person playtest is directional; there is no observed retention baseline.

## Platform-first note

Extend the existing fixed-tick Godot skirmish, validated order path, authored AI, HUD, and durable test outbox. Match results remain `win`, `loss`, or `draw`. Bump and coordinate content version if the rules change; keep prototype events test-tagged and excluded by the existing ingest contract. The alpha publisher and server, rather than the game client, decide future cohort eligibility. No new flag or telemetry service is part of this local prototype.

## Rules and architecture decisions · 2026-10-15

- **Factions:** The human chooses Regios or Poblanos before a match; the computer uses the other. Regios deliver five resource per worker trip instead of four and pay one extra resource for each melee or ranged unit. Poblanos use baseline economy and unit cost; their command post and recruitment post start with 20% more health. These are fictional prototype doctrines, not claims about regional people. Show each advantage and weakness in plain language.
- **District:** Mark a central, reachable 3×3 La Roma zone where buildings cannot be placed. Living melee and ranged units alone count. Sole presence progresses a visible hold timer; enemy presence or an empty zone resets it. Sixty continuous seconds of sole presence wins. Show neutral, holding, contested and reset states, plus a warning to the threatened side.
- **Terminal order:** Simultaneous command-post destruction is a draw. Otherwise command-post defeat resolves before a district hold completed on the same tick. The existing 15-minute unresolved draw remains. Freeze commands and emit one terminal result.
- **Opponent and fairness:** The authored computer must be able to enter and contest the district and still defend or threaten a command post. Both starts retain comparable access to resource and center. Test each human faction and both victory routes; any core-rule change or cultural portrayal change goes back to the owner under [Ways of Working](../../WAYS-OF-WORKING.md#escalate-dont-guess).
- **Validation:** The product owner runs a closed, moderated eight-player test only after authorizing invitations and after private alpha delivery checks pass. Four players familiar and four unfamiliar with Mexican references explain both win routes before coaching. The predeclared pass marks are at least three of four in each group explaining both routes, six of eight naming a trade-off and counter, and four of eight voluntarily starting another match. Record raw counts and failures. Do not present this as the 15% later-day target or a North Star baseline.

## Architecture lock · 2026-10-15

- **D1 · Rules stay deterministic:** `game/skirmish.gd` remains the sole fixed-tick rules model. A match owns a human faction and the opposite computer faction; costs, carry limits and building health resolve by side in the model, never from HUD text. Commands for both sides still pass through `issue`. Include faction and district state in snapshots and replay hashes.
- **D2 · Choice precedes the match:** `game/skirmish_main.gd` shows a faction setup on launch and restart. It queues `match_started` only after a selection. `game/funnel_outbox.gd`'s existing event shape stays intact, with `faction` set on the match start and completion; an open before choice remains `neutral`. No event or player identity is fabricated during setup.
- **D3 · Center remains a fair path:** The 3×3 district is centered on the existing map crossing. Open the adjacent center wall tiles so both sides have comparable routes. Building footprints cannot intersect the district; combat units may enter it. The district is game state, not a capturable entity.
- **D4 · Terminal precedence:** Each tick processes movement and simultaneous damage, removes dead units, then checks both posts, one post, district hold, and 15-minute draw in that order. Presence is counted from living combat units after damage. Contest or absence resets progress. Sixty seconds equals 600 fixed ticks. Exactly one result freezes orders.
- **D5 · Opponent uses orders:** The existing authored AI continues gather/build/train through `issue`, then assigns idle combat units to center contest or post attack according to threats. It must not get a separate movement or damage path. Deterministic scenarios cover both faction choices and active counterplay.
- **D6 · Versions and eligibility:** Keep `GAME_VERSION` stable unless the event schema changes; bump `CONTENT_VERSION` for the new rules. The Godot outbox, local contract, alpha export manifest and hosted alpha allowlist must agree before a restricted preview can sync. Preserve old supported content for existing previews. The preview ingest must enforce test exclusion on the server even if a modified client claims `test_account: false`. Any alpha server allowlist or eligibility change gets second review and staging smoke; no production deployment or participant invite follows from the merge.
- **D7 · Visual and QA:** The setup and district HUD use words and shape cues alongside color. Headless rule, outbox and contract checks run at each sprint boundary, followed by a rendered Godot walkthrough. Debug-only smoke fixtures are guarded out of release exports. Record owner QA and the external eight-player test separately; the latter waits for owner-authorized invitations.

**Sprint build contracts:** S1 adds selection, faction parameters and matching event context while preserving command-post conquest. S2 adds district state and countering AI without changing the event schema. S3 adds a versioned test build, receipt/exclusion checks and the approved comprehension protocol; its eight-person result cannot be marked done until the owner-authorized test occurs.

## What already exists (reuse, don't rebuild)

- [`game/skirmish.gd`](../../../game/skirmish.gd): 20×20 fixed-tick match, economy, combat, opponent, terminal rule, command log and state hash.
- [`game/skirmish_main.gd`](../../../game/skirmish_main.gd): input, board rendering, HUD and match lifecycle.
- [`game/funnel_outbox.gd`](../../../game/funnel_outbox.gd) and the [launch event contract](../../../docs/launch-funnel-contract.md): durable, test-tagged start/result events, including faction and content version.
- [Faction design prework](../../../docs/design-prework/civilizations/04-factions.md) and [map and mode notes](../../../docs/design-prework/maps/05-maps-modes.md): candidate identities and center objective, with no previously approved numeric bonuses.
- [Godot run commands](../../../game/README.md) and `game/tests/`: headless rules/client checks plus a rendered solo match. [Private alpha](../../09-platform-and-measurement/enable-measured-private-alpha/README.md) owns delivery and invitation gates.

## Scope — stories
| Sprint | Player-visible result | Risk |
|---|---|---|
| [1](sprint-1.md) | Choose Regios or Poblanos and see a real, counterable rule difference. | low |
| [2](sprint-2.md) | Contest the center or a command post against a computer that can answer either plan. | low |
| [3](sprint-3.md) | Read an uncoached closed playtest across both cultural-context groups. | low |

## Deploy order

The #5 queue position follows the private alpha platform work, not its final cohort invitation. Private alpha Sprints 1–2 and Story 3.1 establish delivery and ingest; this epic's Sprints 1–2 then establish the distinctive objective; private alpha Story 3.2 can invite participants only after its own release gates; this epic's Sprint 3 records their comprehension test. This is the [private alpha plan's named dependency](../../09-platform-and-measurement/enable-measured-private-alpha/README.md#deploy-order), not a requirement to close that whole epic before this one starts.

Build the game changes in one epic run on `feat/prove-la-roma-promise`. Run Godot headless checks and a rendered walkthrough at each sprint boundary. Merge to `master` only after review; this is not a deployment or an invitation. Any preview export and participant access follow the separate private alpha runbook and explicit owner authorization.

## Definition of Done (epic)
- [ ] Both factions change decisions, can win by either route, and have visible counterplay; owner reviews the portrayal and plays one match as each.
- [ ] Headless checks cover costs, health, district entry/contest/reset/hold, terminal precedence, AI paths, and deterministic replay. The event contract still emits one test-tagged terminal result and no public cohort event.
- [ ] Each sprint's numbered local Godot smoke walkthrough is performed and its outcome recorded; the owner verifies objective text and a complete match.
- [ ] After owner-approved invitations and private alpha delivery checks, the closed eight-player test records each group's uncoached answers, exact counts, second-match starts, failures and a verdict against the predeclared marks. A failure leads to a re-scope, not a retroactive target change.
- [ ] Review and merge reach `master`; update the product poster, retrospective and durable learnings. Mark this README `status: shipped` only after the behavior and playtest outcome are checked. A merge is not a game deployment.
