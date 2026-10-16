# Battle for La Roma — product roadmap

> **Mission:** Make a deep, approachable real-time strategy game about regional civilizations competing for control of a fictional Mexico City, with La Roma as the ultimate prize.

This folder is the product source of truth. The [strategy](00-strategy/pmf-narrative.md), [North Star](00-strategy/north-star.md), and [risk validation](00-strategy/risk-validation.md) are agreed starting points. Claims marked as assumptions still need evidence.

The [Horizon](horizon.md) names the end states each epic advances. Epic `destination:` fields link to those declarations for the Golden Frijoles Horizon view.

## Current state

- **Stage:** The Godot solo skirmish now has two faction prototypes and an optional La Roma district win route, with a signed local preview candidate. Isolated alpha ingest is staged on the Oracle VM; no public game release exists.
- **North Star:** Players completing matches on two different days in a week (`returning_commanders`).
- **Launch goal:** Provisional 15% of first-match completers finish a match on a later day, measured after a sufficiently mature first cohort. The baseline is unknown until real play data arrives.
- **Funded work:** [Solo skirmish](01-core-play/finish-solo-skirmish/README.md) is implemented. [Measured private alpha](09-platform-and-measurement/enable-measured-private-alpha/README.md) has isolated Oracle VM Postgres staging, off-project restore evidence and a Restricted macOS download for the owner; its external invitation gates remain open. [Prove the La Roma promise](02-civilizations-and-world/prove-la-roma-promise/README.md) has builder-verified faction and district stories; its closed eight-player comprehension test remains open.
- **Build order:** [Generated board](00-ideas/BUILD-ORDER.md) records the docs-only order. The Golden Frijoles Hub board also reads live branches and PRs; see the [sync runbook](WAYS-OF-WORKING.md#golden-frijoles-roadmap-sync). Update source seed or epic status and regenerate the file; do not edit it by hand.
- **First build:** [Track the launch play funnel](09-platform-and-measurement/track-launch-play-funnel/README.md) has a local event contract, fixture ingest, Godot outbox and cohort report. [Prove the RTS core](01-core-play/prove-rts-core/README.md) and [finish a solo skirmish](01-core-play/finish-solo-skirmish/README.md) now provide a local client with a terminal result. The public funnel still needs hosted ingest and a first mature real cohort.

## Product areas

The areas below are provisional until the first epics are shaped.

| Area | Scope |
| --- | --- |
| 01 · Core play | Gathering, settlements, economy, ages, units, and battles. |
| 02 · Civilizations and world | Regional factions, Mexico City neighborhoods, art, writing, and accessibility of cultural references. |
| 03 · Multiplayer and retention | Matchmaking, completed matches, return play, and social play. |
| 09 · Platform and measurement | Build tooling, delivery, telemetry, and the launch funnel. |

## Feature map

No game feature has been publicly released. The funnel has 2/7 locally verified stories; RTS core and solo skirmish each have 4/4. La Roma has 3/4 builder-verified stories and a signed local preview candidate; its eight-player test is unrun. The measured private alpha is funded at #4, with its owner QA and invitation gates still open. The live board may show merged PRs as complete even when a game build has not been released. Later ideas remain raw until `refine` shapes and funds them; the generated board shows their proposed order.

## Suggested next work · 2026-10-15

This is the practical sequence across the existing epics and raw seeds. The [generated build order](00-ideas/BUILD-ORDER.md) keeps initiative priority, while the live board also reflects GitHub PR state; neither automatically orders the unfinished steps inside an epic.

1. **Finish internal play QA and readability.** Close the recorded checks in [RTS core](01-core-play/prove-rts-core/README.md) and [solo skirmish](01-core-play/finish-solo-skirmish/README.md), and the owner's downloaded-build walkthrough in [private alpha](09-platform-and-measurement/enable-measured-private-alpha/README.md). Fix the small board/instructions and provide usable zoom or display scaling; then verify restart, offline persistence and one test-tagged sync receipt. Do not mark an epic shipped from a PR merge alone.
2. **Finish the pre-invitation measurement path.** Continue [launch funnel](09-platform-and-measurement/track-launch-play-funnel/README.md) and [private alpha](09-platform-and-measurement/enable-measured-private-alpha/README.md): make the restricted route durable and reachable from the owner Mac, verify independent keyed download, test exclusions and stable receipts, then verify the aomx-scoped publisher identity. Keep real invitations closed.
3. **Review the [La Roma implementation](02-civilizations-and-world/prove-la-roma-promise/README.md) and signed local preview.** The faction and district slices have passed builder QA. Review the version allowlist and test-event exclusion, then merge the code; this does not distribute a build.
4. **Finish private alpha delivery checks before a La Roma playtest.** Stage the new allowlist, verify an invited HTTPS test receipt and restricted download of the exact build, then obtain owner authorization for eight external invitations. Record uncoached comprehension and second-match choices against the predeclared marks.
5. **Invite a small private alpha cohort, then read the mature funnel.** Finish [private alpha](09-platform-and-measurement/enable-measured-private-alpha/README.md) and [launch funnel](09-platform-and-measurement/track-launch-play-funnel/README.md) with approved participant notice, release checks, accepted events and reconciled readings after the seven-day windows close. Report the observed baseline; the 15% target remains provisional.
6. **Refine, fund and build [Prepare a release candidate](00-ideas/seeds/prepare-release-candidate.md).** That raw seed covers distribution quality, onboarding, settings, accessibility, performance, support and a wider release decision informed by alpha evidence.
7. Revisit the later raw seeds after playtest evidence: [Deepen strategic play](00-ideas/seeds/deepen-strategic-play.md), [Expand civilizations and world](00-ideas/seeds/expand-civilizations-and-world.md), then [Add more ways to play](00-ideas/seeds/add-more-ways-to-play.md). Each needs its own refinement and approval before building.

## Working together

[Ways of Working](WAYS-OF-WORKING.md) records this project's current process. [Learnings](LEARNINGS.md) records project-specific discoveries. The `refine` skill turns a backlog seed into an approved, sliced plan.

## License

No license has been selected yet.
