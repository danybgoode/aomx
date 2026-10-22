---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Verifying      # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: establish-cdmx-geography-and-maps
title: "Establish CDMX geography and map data"
area: 02-civilizations-and-world
risk: high
type: feature
sprints_total: 3
stories_total: 6   # the sum of every sprint's stories_total
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Classic RTS players can fight in La Roma, but its real places and game geometry lack a checked source and shared map contract. A verified Roma Norte/Cibeles skirmish could make the city easier to recognize without skewing play. We'll know when the owner wins both ways and uncoached players find the place and objective."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: "first_match_completion"   # which number: a North Star input key (grounded) or free text (not grounded)
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "Classic RTS players choosing a CDMX skirmish, including players unfamiliar with Mexican references."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "The first-match-completion input is defined, but no eligible play cohort or controlled map comparison supports a numeric lift target."   # only with grounded: false
flag_key: null   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: null   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: null
retained_event: null
retention_days: null
satisfied_event: null
build_order: 16      # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
destination: fight-for-la-roma
---

# Epic: Establish CDMX geography and map data

> **Area:** 02-civilizations-and-world · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/establish-cdmx-geography-and-maps.md`](../../00-ideas/seeds/establish-cdmx-geography-and-maps.md)
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
Classic RTS players can already fight in La Roma, but the current map does not distinguish verified CDMX places from its fictional playable layout. This epic gives them a recognizable Roma Norte/Cibeles skirmish with fair routes and clear objectives, while giving future maps stable, reviewed place references.

## Platform-first note
Game content owns map geometry and rules. A compact geography registry supplies names, administrative relationships and provenance; it does not define collision or conquest. The existing versioned content loader, map choice and save/replay hashes remain the system of record for play.

## Architecture lock · 2026-10-22

- **D1 · Source boundary:** Read the INEGI AGEM catalog for the 16 CDMX names/codes and the city venue listing for Cibeles. Store those factual references and dated links. Do not import source polygons, coordinates, photos or derived geometry in this wave; record their resource terms as a later decision.
- **D2 · Game versus reference:** The current 28×28 `la_roma` grid is a stylized, authored arena. A versioned sidecar registry and map descriptor provide stable place/territory IDs, labels, source refs and decorative tile roles. The simulation's blocked/cliff tiles remain the authority for passability.
- **D3 · Compatibility:** Preserve `game/content/skirmish.v1.json`, its `la-roma-world-5` content ID and the existing map geometry. The sidecar is presentation/reference data and does not enter deterministic state or content hashes. Existing v5 saves/replays stay compatible; invalid external versions still reject and retain files.
- **D4 · Fairness:** Measure both sides' resource and Cibeles routes on the existing map under matched seeds, then exercise AI, fog, selection and both terminal paths. Any discovered imbalance requiring rule/geometry change is a fresh owner decision with a new version and migration plan.
- **D5 · Player surface:** Keep the native map option list and four independent faction choices. Add concise Roma Norte/Cibeles context, an explicit stylized note and two win routes; reuse the current responsive setup rather than building a new screen.
- **D6 · Release and evidence:** Headless contract and real rendered checks precede a signed Restricted owner build. Owner downloaded full matches and uncoached familiar/unfamiliar comprehension remain separately owed. A merge or signed export alone does not close the epic.

**Sprint contracts:** S1 delivers and validates the source registry/sidecar while all three maps still load. S2 presents the revised choice and proves the unchanged arena's fairness across sides and victory routes. S3 proves v5 save/replay compatibility and records a Restricted build plus outstanding owner/human QA. This lock narrows the seed's possible geometry revision to a metadata and presentation revision because the existing grid can meet the one-map outcome without a cross-system content-version migration.

## What already exists (reuse, don't rebuild)
- `game/rules_content.gd` loads the three known maps and validates the 28×28 La Roma board, spawns, resources and objective.
- `game/skirmish.gd` and `game/skirmish_main.gd` supply pathing, AI, fog, selection, both victory routes and map choice for four factions.
- `game/skirmish_persistence.gd`, `game/skirmish_replay.gd`, `game/participant_replay.gd` and multiplayer replay handling guard content compatibility.
- The [#16 pitch](../../00-ideas/seeds/establish-cdmx-geography-and-maps.md) records official source candidates, rights questions, the proposed UI words and exclusions.

## Scope — stories
| Sprint | Story | Risk |
|---|---|---|
| 1 | S1.1 Verify CDMX source and place registry; S1.2 Validate map metadata | high · high |
| 2 | S2.1 Explain/select La Roma; S2.2 Play the revised fair map | low · high |
| 3 | S3.1 Preserve save/replay compatibility; S3.2 Record owner and reader acceptance | high · low |

## Deploy order
Source/rights review precedes any geographic import. Introduce the registry and validator while the current map remains playable; then expose the reviewed metadata in the skirmish choice after deterministic and rendered checks. Keep the v5 simulation content ID and test old saves/replays before a Restricted owner build. No public invitation is part of this epic. Owner full-match and uncoached reader QA stay open until performed.

## Definition of Done (epic)
- [ ] Six stories satisfy the [pitch's acceptance criteria](../../00-ideas/seeds/establish-cdmx-geography-and-maps.md#acceptance-criteria), with high-risk rights and compatibility decisions reviewed.
- [ ] All three sprint walkthroughs are recorded against a real build; headless contracts, rendered selection, full matches and versioned replay/save behavior pass.
- [ ] The owner completes the downloaded Restricted build playthrough and approves visible place portrayal; invited familiar/unfamiliar readers complete the uncoached task read after separate invitation approval.
- [x] Changes are reviewed and merged to `master`; Restricted build `preview-53fcf2def066` is ready as Butler `#2187758` and its independent fetch passed signature and startup checks.
- [ ] The retrospective, product poster and any durable project learning reflect verified outcomes. Mark `status: shipped` only after owner QA and close-out are complete; regenerate and sync the roadmap then.
