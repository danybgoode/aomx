---
title: "Create campaigns and scenarios"
slug: create-campaigns-and-scenarios
status: scaffolded
area: "03"
type: feature
appetite: M
underwritten_by: wave-2026-10
risk: high
epic: "03-multiplayer-and-retention/create-campaigns-and-scenarios"
build_order: 24
updated: 2026-10-27
intent_ask: verbatim
hypothesis: "Today classic RTS players face standalone battles with no path into La Roma. A short chapter lets them learn the rules and unlock a final battle on the same maps. We'll know when an uncoached player finishes that battle and the accepted first-match funnel can be read."
persona: "Classic RTS players learning this game's economy, objectives and CDMX setting, including players unfamiliar with Mexican references."
grounded: false
grounded_reason: "First-match completion is agreed, but no real cohort or baseline exists and a campaign-to-skirmish effect has not been tested."
target_metric: first_match_completion
target_from: null
target_to: null
read_date: null
flag_key: campaign.chapter_enabled
target_segment: everyone
adopted_event: campaign_mission_completed
retained_event: campaign_mission_completed
retention_days: 7
satisfied_event: null
intent_match: null
---

# Pitch — Create campaigns and scenarios

Moves: first_match_completion · Tests: value proposition. A chapter may teach the RTS loop; its effect on eligible match completion is unmeasured.

## The ask, as given

> Hi codex Refine seed:
> #20
> create-campaigns-and-scenarios as per golden frijoles methodology, ensure to follow ways of work, team memory etc to ensure a smooth flight

The original raw idea is preserved in [the source revision](https://github.com/danybgoode/aomx/blob/b3bc54b6219772d669efed1102040513de5398e4/Roadmap/00-ideas/seeds/create-campaigns-and-scenarios.md) and the [full-game path](../../full-game-build-path.md). It called for an arrival-to-La-Roma sequence, versioned missions, saves/replays, an atlas and creator scenarios. The owner narrowed this first bet on 2026-10-27.

### Claims

1. Refine backlog idea #20 using Golden Frijoles, Ways of Working and project learnings.
2. Shape an authored path from arrival to a La Roma battle on the existing simulation.
3. Decide campaign progression and creator scope before funding.

**Teach-back:** Partly — the owner chose chapter progression with mission unlocks, an M appetite, authored campaign first, measurement by first-mission completion, and final-battle-only eligibility; the full pitch remains for review.

## Problem

Copilco, Narvarte and La Roma are playable solo maps, but there is no authored path that teaches economy, expansion and the La Roma objective in sequence. A full campaign/editor pair mixes a player learning problem with a creator tooling problem before either is validated. No real cohort shows that missions improve completion or return play.

## Appetite

**M — several connected slices needing an architecture and save review.** The owner chose this on 2026-10-27. It buys one three-mission chapter on existing maps and rules, local chapter unlocks, a bounded objective format, one server-served campaign flag and actual-build comprehension checks. It does not buy persistent conquest, a scenario editor, arbitrary scripts, new maps or a broad narrative campaign. Re-evaluate creator tools after the chapter is tested.

quote: $20–120 (M, n=0, wide)

## Outcome & signal

A player starts in Copilco, completes a middle Narvarte mission and reaches a full La Roma battle. Goals and locks are readable, progress survives restart, and all skirmish maps/factions remain independently selectable. The owner finishes the sequence on a signed Restricted download; uncoached players familiar and unfamiliar with Mexican references can state the next action and how to win. After an eligible cohort exists, read first-match completion for exposed and unexposed players with counts and uncertainty. Only the final full battle may qualify, after explicit checks. No lift target is invented.

## Stage-2.5 bucket

**Genuinely new campaign progression; existing match play is reusable.** The maps, economy, AI, two terminal routes, setup, saves and replays already work. Connecting plain skirmishes is a lighter option, but it would not teach mission goals or prove objective, unlock and replay behavior. Deferring creator tools keeps the first bet within M.

## Bill of materials (What / Why)

| What | Why |
|---|---|
| Versioned mission definitions and validator | Author a chapter without unchecked scripts or a second rules engine. |
| Deterministic objective adapter | Show progress and finish missions from canonical match state. |
| Three-mission chapter and local unlock ledger | Give arrival, expansion and La Roma an understandable sequence. |
| Selection, goal and result copy | Show what is available, what is locked and what to do next. |
| Server-served campaign flag and adoption event | Measure first-mission completion per player without exposing a provider key. |
| Save, replay and funnel boundary checks | Preserve progress and the agreed match definition. |
| Restricted owner and uncoached play | Check finishability and clarity before widening scope. |

The owner may edit the Why column at the Plan gate.

## Scope

**In v1:** Three authored missions on existing Copilco, Narvarte and La Roma Large map IDs. The final map depends on #24's owner acceptance; if that proof fails, return to the owner before changing the finale. The player can choose any existing faction; a mission cannot imply one regional faction belongs to a neighborhood. Use a versioned, bounded data format for mission ID, map ID, objective IDs, copy, prerequisites and completion conditions. Reject unknown IDs, prerequisite cycles, unsupported actions and duplicate unlocks before play. The fixed-tick simulation owns objective transitions and the terminal result. Mission state and definitions enter save/replay compatibility checks. A versioned local ledger records each verified completion once, separate from the match save and funnel outbox. Show chapter choice, lock reason, in-match goal/progress, result and next mission. Keep standard skirmish open. Serve a Golden Frijoles enablement flag from the existing alpha backend using the stable pseudonymous player ID, with an offline last-served decision and an off default before first evaluation; report user-level evaluation and first-mission completion without a provider credential in the client.

**Out of v1 (no-gos):** Persistent conquest, branching chapters, currency or rewards that change skirmish rules, new victory modes, map geometry, full illustrated atlas navigation, arbitrary script execution, in-game editor, user-supplied scenario loading/sharing, multiplayer missions, cloud progression, public invitations and a release claim. Creator authoring/sharing gets a separate later bet after this contract is tested.

## Rabbit holes

- **Match eligibility:** The owner chose only the final full battle as potentially eligible. It must meet the existing real-match checks: human, full playable start-to-terminal match, no scripted advantage, accepted start and finish, supported version and unflagged test identity. The first two guided missions remain excluded tutorials. Client and ingest must agree; replay cannot inflate the funnel.
- **One rules authority:** Evaluate bounded conditions on fixed ticks from canonical state. Any orders use the validated command path. The scene displays goals but never decides a win; AI gets no hidden information.
- **Save/replay:** Include mission ID, definition/content hash and objective state. Resume retains match ID; replay and duplicate terminal events cannot grant progress twice. Preserve malformed/unsupported files with readable errors and retain old skirmish compatibility.
- **Local progress:** Use atomic, idempotent writes and a clear corruption/recovery path. The ledger contains no invite credential or telemetry outbox contents.
- **Offline flag:** The backend resolves campaign.chapter_enabled and records an evaluation for the same pseudonymous user ID used by gameplay events, then returns only the decision/version. The native client caches the last served choice for an offline session; a remote off applies at the next successful check, not instantly during disconnection. First use with no served choice stays off. A Restricted build can be withdrawn separately. No flag read key goes into the client.
- **Content/portrayal:** The GDD's larger CU-to-Roma arc is proposed, not approved chronology. This cut uses three playable maps and skips Condesa. Teach tasks in plain language without relying on local jokes.
- **Appetite stop:** If the chapter needs new general combat rules or a second simulation, return that change to the owner instead of growing M.

## What already exists (reuse, don't rebuild)

- game/rules_content.gd, game/content/skirmish.v1.json and game/content/maps/{copilco,narvarte}.json validate current rules and map choices; game/map_geography.gd separates place labels from game geometry.
- game/skirmish.gd owns commands, fixed ticks, snapshots, AI, objectives and terminal results. game/skirmish_main.gd owns the native setup, HUD and result presentation.
- game/skirmish_persistence.gd and game/skirmish_replay.gd preserve hashes, match identity and deterministic playback. [ADR 003](../../../docs/architecture-decisions/003-simulation-contract.md) is the contract to extend.
- game/funnel_outbox.gd and src/funnel/ingest.mjs define match events. The ingest excludes tutorial mode, but the native outbox currently queues only solo/multiplayer, so campaign classification needs real contract work.
- [#16 maps](../../02-civilizations-and-world/establish-cdmx-geography-and-maps/README.md), [#18 interfaces](../../02-civilizations-and-world/complete-game-interfaces/README.md), the [GDD](../../../docs/design/GDD.md) and [coverage review](../art-world-coverage-2026-10-21.md) bound map, UI and cultural decisions.

## Visuals

~~~mermaid
flowchart LR
  P[Player] --> C[Campaign selection]
  C --> D[(Versioned mission definitions)]
  D --> V[Validator]
  V --> S[Existing fixed-tick simulation]
  S --> R[Mission result]
  R --> L[(Local chapter progress)]
  L --> C
  S --> Q[Save and replay]
  R --> F[Existing funnel outbox and ingest]
  C -->|player ID, no provider key| B[Alpha backend flag resolver]
  B -->|served decision and version| C
  B --> GF[Golden Frijoles]
~~~

~~~mermaid
flowchart LR
  A[Choose available mission] --> B[Read goal and begin]
  B --> C[Play existing commands]
  C --> D{Terminal result}
  D -->|win| E[Record completion once]
  D -->|loss or exit| G[Retry or resume]
  E --> H[Unlock next mission]
~~~

~~~mermaid
stateDiagram-v2
  [*] --> locked
  locked --> available: prerequisite won
  available --> active: start
  active --> available: loss or abandon
  active --> completed: verified win
  completed --> completed: replay or duplicate result
~~~

| Mission ID | Existing map | Visible goal | Unlock |
|---|---|---|---|
| arrival_copilco | copilco | Learn gathering, construction and recruitment; finish the encounter. | Available first. |
| foothold_narvarte | narvarte | Expand, defend and win the contest. | Win arrival_copilco. |
| battle_la_roma | la_roma_large | Finish a full battle by a declared existing terminal route. | Win foothold_narvarte; #24 owner QA accepted. |

~~~surface
state: campaign-selection-idle
route: /campaign
- head "Campaign" action "Start available mission"
- steps "Arrival · Foothold · Battle for La Roma" count 3
- card "Arrival in Copilco · available"
- card "Foothold in Narvarte · locked: finish Arrival first"
- card "Battle for La Roma · locked: finish Foothold first"
- note "Skirmish maps remain available separately."
~~~

~~~surface
state: campaign-selection-error
route: /campaign
- head "Campaign"
- note "Chapter progress could not be read. Your saved match was not changed."
- card "Retry reading progress"
~~~

~~~surface
state: campaign-mission-idle
route: /campaign/mission
- head "Current mission"
- summary "Goal and current progress"
- note "Finish the visible objective to unlock the next mission."
~~~

~~~surface
state: campaign-result-success
route: /campaign/result
- head "Mission complete" action "Continue to next mission"
- summary "What you achieved"
- note "Progress saved. You can replay this mission or choose any skirmish map."
~~~

Review the [grey campaign sketch](../create-campaigns-and-scenarios-sketch.html).

## UX heuristics & rails check

- **CI guards:** existing Godot content, simulation, persistence, replay and client suites plus npm run skirmish:contract; extend them for mission state, progress idempotence and funnel classification.
- **Audits lens:** the [owner interface/movement/map audit](../audits/2026-10-23-owner-interface-movement-map.md) requires readable default scale and reachable commands. Do not count #24's open owner QA as campaign proof.
- **Design-language debt:** #18 owns broad menu/HUD layout. Reuse current native controls and scaling. The full illustrated atlas is unbuilt.

## Measurement and runtime gate

**Measure — yes, owner chosen:** campaign.chapter_enabled is an enablement flag, off in every Golden Frijoles environment until explicitly rolled out. The alpha backend resolves it for the same stable pseudonymous user ID as the outbox and reports each user-level evaluation; the client gets only the served decision/version. The adoption event is campaign_mission_completed, emitted once on the first Copilco mission win and again for later mission wins; retention is another such completion within seven days. Record mission ID and match ID in a reviewed, versioned event contract. Test accounts are excluded. The agreed first_match_completion input remains the outcome read, with no numeric target until a real cohort exists.

**Safety — same flag:** Disable campaign.chapter_enabled to stop new online campaign starts at the next check. Offline cached access cannot be remotely revoked until reconnection; the owner reviews this limitation at the Plan gate. Keep saved progress safe and standard skirmish available. Verify a served off version in every environment before calling the gate ready.

## Proposed slices, risk and QA

| Sprint / story | Player or operator result | Risk | QA stage and owner smoke |
|---|---|---|---|
| 1 · Mission contract · S1.1 | An author validates bounded mission definitions on existing maps. | high · shared content | Headless valid/invalid fixtures and unchanged skirmish hash. |
| 1 · Mission contract · S1.2 | A player's mission objective advances through the existing rules. | high · simulation/save | Fixed-tick ordering, fair AI, hashes and rendered goal/terminal check. |
| 2 · Chapter path · S2.1 | A player selects an available mission and understands a locked one. | low · native UI | Client and 1024×700/1280×800 captures; owner starts mission. |
| 2 · Chapter path · S2.2 | A win unlocks exactly the next mission after restart. | high · local player data | Atomic ledger, corruption, duplicate/replay, resume and rollback fixtures; owner restart. |
| 3 · Play and measure · S3.1 | A player finishes arrival, foothold and La Roma on the same simulation. | high · integration | Full chapter, save/replay, all-map regression, performance and downloaded-build smoke. |
| 3 · Play and measure · S3.2 | An enabled player is counted once for first-mission adoption, while only a checked final battle can enter the eligible funnel. | high · flag, identity and North Star integrity | Server flag/evaluation, client/outbox/ingest receipts for tutorial, final battle, duplicate, abandoned, replay and test account; served off in every environment. |
| 3 · Play and measure · S3.3 | Familiar and unfamiliar players understand goals without coaching. | low · research | Owner-authorized reader sessions; leave story open if unrun. |

Each sprint gets a numbered actual-build walkthrough. Shared simulation, progress data and funnel stories need independent review under Ways of Working. Core-rule, portrayal or North Star changes return to the owner.

## Acceptance criteria

1. Three versioned missions load on Copilco, Narvarte and the accepted La Roma Large pilot. Bad IDs, cycles and unsupported actions fail before play. Standalone maps and all four faction choices remain available.
2. The fixed-tick simulation owns objective transitions and terminal result. Conditions are bounded and deterministic; the scene only displays them. AI uses fair information and legal commands.
3. A player can see each goal, finish the first mission, unlock the next and complete a full La Roma battle. Loss or exit never unlocks. Replay cannot grant duplicate progress.
4. Mission state survives save/quit/resume and deterministic replay. Old skirmish saves/replays retain their declared compatibility or fail clearly without deletion. Corrupt progress does not erase a good match save.
5. The backend serves the campaign enablement decision per pseudonymous player, reports user-level flag evaluations and never sends its provider key to the client. A first mission win emits one campaign_mission_completed adoption event; a later mission completion is a repeat. An off flag blocks new online starts, a never-served offline client defaults off, and cached offline behavior is documented and tested.
6. Only the final full campaign battle can enter the North Star funnel, after the accepted eligibility checks. The first two missions, test accounts, replays and abandoned matches cannot increase eligible completion; accepted starts and finishes reconcile once.
7. A signed Restricted download supports a complete owner chapter and a separate unchanged skirmish at readable default scale. Record build/content IDs, outcomes and failed steps; merge alone proves neither release nor completion.
8. After separate invitation approval, at least one RTS player familiar and one unfamiliar with Mexican references try the chapter uncoached. Record objective understanding and confusion without inferring retention.

## Open risks / research and Plan gate

- **Owner choices recorded 2026-10-27:** chapter progression with mission unlocks; M appetite; authored campaign first, creator workflow later; a Golden Frijoles Measure flag; first-mission completion as adoption; only the final full battle may become North Star eligible after explicit checks. The three-mission content and Why column remain proposed.
- **Plan-gate trade-off:** a server-served per-player flag adds backend and event-contract work to M. Offline cached campaign access cannot be shut off immediately; the flag governs the next successful check. The owner can narrow rollout to the Restricted channel at the Plan gate.
- **Dependency:** #16's place labels and #24's large-map pilot inform this chapter. #24's full owner match remains open; use stable existing map IDs until its QA closes.
- **Opportunity cost:** propose building after #24's owner proof. Alternate modes #21, cross-platform proof #22 and release candidate #23 stay waiting; existing alpha and owner QA continue.
- **Research:** no external fact is needed for this cut. The GDD's chronology is a proposal. Any new factual place claim or cultural portrayal needs source and owner review.

## Intent match

The pinned kit attempted the advisory 20-question check on 2026-10-27 but could not look from the sandbox: Jev's network fetch failed. Automatic approval review rejected a network retry because it would send the internal seed claims and roadmap context to an external Jev service without separate authorization. No score or gap verdict is claimed. Review the ask, owner choices, sketch and eight acceptance checks directly at the Plan gate.
