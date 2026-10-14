# Battle for La Roma — product roadmap

> **Mission:** Make a deep, approachable real-time strategy game about regional civilizations competing for control of a fictional Mexico City, with La Roma as the ultimate prize.

This folder is the product source of truth. The [strategy](00-strategy/pmf-narrative.md), [North Star](00-strategy/north-star.md), and [risk validation](00-strategy/risk-validation.md) are agreed starting points. Claims marked as assumptions still need evidence.

## Current state

- **Stage:** A finishable local Godot solo skirmish and launch-funnel prototype are under review; no deployed backend or public game release exists.
- **North Star:** Players completing matches on two different days in a week (`returning_commanders`).
- **Launch goal:** Provisional 15% of first-match completers finish a match on a later day, measured after a sufficiently mature first cohort. The baseline is unknown until real play data arrives.
- **Backlog ideas:** [Solo skirmish](01-core-play/finish-solo-skirmish/README.md) is funded and under review. [La Roma playtest](00-ideas/seeds/prove-la-roma-promise.md) follows a verified local match and funnel reconciliation.
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

No features have shipped. The live provider extract shows the funnel (2/7 locally verified stories), RTS core (4/4) and solo skirmish (3/3) in **Building** on draft PRs; review, merge and a game release are still pending. Later ideas remain raw until `refine` shapes and funds them; the generated board shows their proposed order.

## Working together

[Ways of Working](WAYS-OF-WORKING.md) records this project's current process. [Learnings](LEARNINGS.md) records project-specific discoveries. The `refine` skill turns a backlog seed into an approved, sliced plan.

## License

No license has been selected yet.
