# Battle for La Roma — proposed delivery roadmap

**Status:** Proposed for product-owner review · **Date:** 2026-10-13

This plan sequences playable outcomes. It does not reduce the [full game vision](../docs/design-prework/design/00-master-gdd.md) or approve the proposed factions, economy numbers, or modes in the design bible. The [Godot decision](../docs/architecture-decisions/001-engine-selection.md) is a prototype choice with explicit revisit triggers. Each increment below should end with a build someone can operate and evidence that the stated outcome works.

## Product goal and evidence

A classic RTS player can build an economy, command an army, understand the win condition, finish a battle for a fictional Mexico City neighborhood, and want another match. The game must remain legible to someone who misses the cultural references.

- **First technical proof:** A worker can move, gather, and construct in a fresh original-content Godot build. This is not a match and produces no eligible match completion.
- **First finishable match:** A human can beat or lose to a rule-based computer opponent under explicit rules, then restart. It may use a subset of the full ages and resources. Development matches are excluded from launch cohorts.
- **First value-proposition test:** Two factions play differently, a district objective changes decisions, and both culturally familiar and unfamiliar RTS testers can explain how to win.
- **First measured cohort:** Before invitations, the app can record a complete solo match while offline, sync it later, and reconcile accepted results with the Golden Frijoles funnel. The provisional later-day return goal is 15%, with no baseline until mature cohorts exist.

The first match is the traditional **play against the computer** experience. Its opponent follows authored economic and tactical rules through the same simulation commands a human uses; no generative model or LLM is in scope. Bot identities never enter player counts; a human playing an eligible solo match can enter the cohort. The owner chose a **reduced first-match ruleset** while preserving the four-resource, four-age full vision. The first-playable effort has **L appetite**, several waves with a decision at each exit.

## Ordered increments

| Order | Player or team outcome | Smallest integrated demo | Exit evidence | Main deferrals |
| --- | --- | --- | --- | --- |
| 0 · Engine proof | A builder can change and test original RTS rules without relying on proprietary assets. | Isometric map, one worker, one resource, one building, selection, pathing, gathering, placement and construction. | Fresh-checkout boot, deterministic command replay, headless rule checks, rendered input smoke. | Enemy, combat, match results, retention claims. |
| 1 · Finishable internal skirmish | A human can make economy and combat choices against a rule-based computer opponent and reach victory or defeat. | One symmetric map, one mirrored faction, a small resource subset, workers, production, at least two counterable combat roles, literal building destruction, authored opponent rules, explicit conquest end. | Both win and loss paths complete; restart works; no stuck unit or duplicate result in scripted runs. | Full roster, four ages, public cohort metrics. |
| 2 · Distinctive closed playtest | A player can test the actual Battle for La Roma promise, not only generic RTS mechanics. | Two meaningfully different faction prototypes, a contested district objective, readable themed presentation and short onboarding. | Culturally familiar and unfamiliar RTS players explain the objective and next choice unaided; record whether they choose another match. | Final faction roster, polished art, campaign. |
| 3 · Measured first cohort | An offline solo match is saved safely and counted after sync, with its trust level visible. | Stable pseudonymous human ID, durable local event log, resumable sync, result verification or an explicitly accepted self-report policy, test/bot exclusion, deduplication, mature cohort calculations and Golden Frijoles readings. | Reconcile offline first finish, later-day finish, delayed upload, abandonment, duplicate upload and device-clock change before invitations. | Treating a tiny cohort's 15% rate as proof of retention. |
| 4 · Strategic depth | Repeated matches support economy, scouting, composition and timing decisions across the full classic RTS arc. | Add remaining resources and age transitions, queues and population, research, fog, counter roles, siege and defenses in playable increments. | Each added rule changes a decision and has a counterexample playtest; the computer opponent can use it. | Unmeasured breadth and decorative content. |
| 5 · Identity and scale | The game supports several viable strategies and recognizable CDMX match stories. | Expand approved factions, maps, original art/audio, balance scenarios, onboarding and accessibility. | Faction matchup and map-spawn evidence, performance budgets, comprehension checks. | Locking proposed four-faction roster without cultural and balance review. |
| 6 · More ways to play | Players can choose the modes that earned demand. | Improve the Battle for La Roma mode; consider Wonder, teams and multiplayer after their own technical and product gates. | Measured interest, rule clarity, state-repeatability and network-session tests where applicable. | Campaign, scenario editor and modding until the core game is stable. |
| 7 · Release candidate | Players can install, learn, play, return and report problems reliably. | Distribution build, settings, localization, accessibility pass, performance and crash work, support and community loop. | Release checklist, test matrix, observed funnel baseline and a decision on the provisional 15% goal. | Release date until the evidence and distribution rail exist. |

Order 2 and 3 should converge before inviting a cohort. Telemetry contract work starts in increment 0, but an internal prototype must never be counted as an eligible match. A measured launch requires both a product-specific play experience and a trustworthy event path.

## Proposed epic boundaries

The L-sized first-playable goal spans several reviewable epics. Scaffold only the next approved epic; keep the others as candidate outcomes until its demo changes or confirms the plan. The [E1 pitch](00-ideas/seeds/prove-rts-core.md) narrows the first bet to the engine and economy proof; E2 remains a candidate until that demo is reviewed.

| Epic candidate | Iterations | Exit review | Depends on |
| --- | --- | --- | --- |
| E1 · Prove the RTS core | A1–A3: command/move, gather/deliver, build/replay | Fresh-checkout Godot demo; visible command feedback; repeatable local command replay; decide whether Godot remains the prototype engine. | Original-content project and a pinned engine build. |
| E2 · Finish a solo skirmish | B1–B3: produce an army, resolve combat, beat or lose to a rule-based opponent | A human completes win and loss paths and restarts; one terminal result per match; scripted opponent uses the same command rules. | E1's command/state loop and engine decision. |
| E3 · Prove the La Roma promise | C1a–C1b: differentiate two faction prototypes; add the contested district and teach its rule | Familiar and unfamiliar RTS testers understand the objective and make different strategic choices; revise or drop weak faction distinctions. | E2's finishable match. |
| E4 · Measure an offline playtest | C2a–C3: durable offline result and sync; acceptance and Golden Frijoles reconciliation; small closed cohort | First match, later-day match, abandonment, duplicate upload and clock change reconcile from client to accepted event to dashboard; the first mature cohort gives a baseline. | E2's terminal result, E3's product-specific playtest, and an explicit offline date/trust policy. |

E1 and E2 cover the first finishable-match goal; E3 and E4 are both required before inviting a measured cohort. Later strategic-depth, content, modes, multiplayer and release work stays at the increment level until playtest evidence supports a smaller epic. The iterations are outcome checkpoints, not dates or a commitment to build all four epics without review.
The event schema and local test log begin in E1/E2. E4's sync and reconciliation work can start alongside E3 once E2 provides a terminal result; only the cohort invitation waits for both epics to pass review.

## Initial sprint candidates

These are sprint goals, not calendar promises or funded epics. Each should produce a runnable demo and a short walkthrough. Reorder or cut them at the preceding exit review.

| Sprint | Goal | Reviewable result |
| --- | --- | --- |
| A1 | Command a worker on an original map. | Select, move, reject an unreachable move, inspect simulation state. |
| A2 | Turn a resource into visible stockpile. | Gather, carry or deliver, deplete, interrupt and resume. |
| A3 | Spend that stockpile on a real structure. | Preview, place, construct, obstruct and reroute; replay the same commands to the same state. |
| B1 | Create an army through the economy. | Produce workers/combat units, spend resources once, respect capacity and queues. |
| B2 | Resolve a legible battle. | Two roles with counterplay attack units and structures; show damage, defeat and destruction. |
| B3 | Finish a human-versus-computer skirmish. | The opponent gathers, builds and fights through authored rules and ordinary commands; human win, loss and restart have one terminal result. |
| C1a | Make factions change a strategic choice. | Two faction prototypes with distinct, counterable strengths; testers can name the choice each creates. |
| C1b | Make the setting change the match objective. | A contestable district with clear rules, feedback and a short explanation players can use without knowing the cultural references. |
| C2a | Preserve an offline match result. | A durable result and command/event log survives restart and syncs once when connectivity returns. |
| C2b | Reconcile the launch funnel. | Declare replay or self-report acceptance and date policy; exclude test traffic, deduplicate results and compare cohort calculations with Golden Frijoles readings. |
| C3 | Invite a small closed cohort. | Event reconciliation, comprehension/playtest notes and first baseline after the return window matures. |

## Measurement through the slices

The [North Star](00-strategy/north-star.md) is the agreed measurement starting point; the [launch-funnel seed](00-ideas/seeds/track-launch-play-funnel.md) remains the detailed implementation idea. The owner's offline requirement reveals one necessary amendment: the current text says a product backend emits authoritative starts/results, but an offline solo match finishes before the backend can see it. Keep an event ID, claimed UTC time, monotonic local sequence, stable pseudonymous human ID, match ID, game/content version, mode and test flag. Save the event/command log durably, then sync idempotently. Prefer server replay of the versioned command log to validate a completed match; prove that replay works before promising it. If it does not, explicitly label accepted outcomes as client reported rather than claiming backend authority. A local device date can be wrong or manipulated, so flag implausible clocks and disclose the limitation on later-day rates. Count an offline match only after successful sync and acceptance; show pending locally until then. Bot participants, tutorials, abandoned matches and test accounts do not count. Compute distinct-player counts and rates outside raw event occurrence counts, then send daily `external_push` readings.

Before the first invitation, walk an offline first match, a later-day finish, a delayed upload, an abandonment, a duplicate upload and a device-clock change through local state, sync, raw events and the dashboard. Show counts and conversion at each stage; hold seven-day readings as pending until cohorts mature under a declared late-sync grace and backfill policy. Never-synced matches cannot appear in the console; the client must show that they are pending. Review the 15% goal only after the first eligible cohort matures, ideally with at least 100 first-match completers, as the approved strategy specifies. Write the exact offline amendment into the North Star before sending the first real cohort.

## Decision gates and risks

| When | Decision to make | Evidence required |
| --- | --- | --- |
| Before A1 | Pin an exact supported Godot version, original asset format and initial content-data format. | Editor and headless fresh-checkout boot; version and build command recorded. |
| After A3 | Continue with Godot or revisit the engine decision. | Real rendered prototype, deterministic replay, pathing and frame-time measurements at the prototype scale. |
| Before B3 | Define conquest defeat and rule-based opponent behavior. | Human-readable win/loss rules plus deterministic acceptance scenarios. |
| Before C2 | Decide how offline results are accepted, dated and corrected after sync. | Replay feasibility across target builds; threat model for duplicate, forged, aborted and clock-shifted results; operational cost; one end-to-end offline event trial. |
| Before C3 | Set the first qualitative playtest threshold and sample plan. | Objectives understandable in both cultural-familiarity groups; clear consent and exclusion of internal testers. |
| Before multiplayer | Choose synchronization architecture. | Representative unit-count benchmarks, repeatable state hashes and a real server/client test. Godot's network APIs alone are not that evidence. |

The largest risks are scope expansion, weak RTS decisions beneath the satire, crowd pathing, a match result that cannot be trusted, and faction humor that obscures rules or flattens people. Use original art/audio and culturally reviewed writing. Do not import Age of Empires assets or treat proposed balance numbers as approved.

## Source decisions to reconcile

- The design-bible overview calls Godot selected for MVP, while ADR 001 labels it a proposed recommendation. Treat Godot as the working prototype choice and use the A3 evidence gate before making a stronger commitment.
- The master GDD lays out four named ages and four named resources, while the decision register labels these proposals. Keep the four-function ambition visible; approve names, fiction and detailed rules through play and design review rather than silently treating them as final balance.
- The approved North Star describes backend-authoritative match events, while the owner requires offline solo matches to count. The precise sync, result-confidence and date policy needs an explicit North Star amendment before inviting players.
- “Bots excluded” in the funnel should mean bot *participants* are excluded from player counts. A human playing against the rule-based computer opponent remains eligible once the match passes the offline acceptance checks.

## Backlog policy

Fund only the next outcome after reviewing the prior demo. Keep later increments visible as product goals, not detailed sprint contracts. Each epic should have a player-facing Why, acceptance scenarios, and a smoke walkthrough. If a system cannot be shown in a match or prototype, narrow it before building. Record decisions in the design bible or an ADR and update this roadmap when evidence changes the order.

**First planning move:** Build E1 as the first approved epic, then re-evaluate after its engine-proof demo and shape E2 from that evidence. Keep the overall first-playable goal at L appetite and preserve the existing funnel idea as E4's measurable-cohort gate.
