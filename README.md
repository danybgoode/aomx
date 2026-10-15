# Battle for La Roma

Battle for La Roma is a real-time strategy game inspired by classic RTS games and set in a fictional, satirical Mexico City. Players build regional civilizations, grow their economies, and compete for control of the city's neighborhoods. La Roma is the ultimate prize.

The project has a planning roadmap and a local launch-funnel instrumentation prototype. There is no game client, deployed backend, or real play cohort yet. Cultural references should enrich the game without being required to understand it.

## Project plan

- [Product roadmap](Roadmap/README.md)
- [Approved strategy](Roadmap/00-strategy/pmf-narrative.md)
- [North Star and launch measurement plan](Roadmap/00-strategy/north-star.md)
- [Golden Frijoles build order](Roadmap/00-ideas/BUILD-ORDER.md) and [first approved build: launch funnel](Roadmap/09-platform-and-measurement/track-launch-play-funnel/README.md)
- [Engine feasibility investigation](docs/technical-feasibility.md) and [engine decision](docs/architecture-decisions/001-engine-selection.md)
- [Next game epic: prove the RTS core](Roadmap/01-core-play/prove-rts-core/README.md)
- [Local launch funnel contract and run commands](docs/launch-funnel-contract.md)

## Golden Frijoles

This repository is connected to the **aomx** product. The project scoped agent skills are in `.agents/skills/`, with their source recorded in `skills-lock.json`. The shared project settings are in `golden-frijoles.config.json`; local credentials and event ingest keys are in the ignored `.env.local`.

The North Star and roadmap are registered in [the aomx console](https://goldenfrijoles.com/app?project=aomx). The console is waiting for the first event. The launch-funnel contract, local ingest, outbox reference and cohort report exist; the Godot client and a real terminal solo match still need to be built before inviting players. `telemetry.play_funnel_enabled` serves off in development, preview and production.

Use `npx -y @golden-frijoles/cli@1.5.1 status` to check the connection. Build the launch funnel's event-contract sprint first, then the RTS core; the later funnel sprints connect to the game as its client and terminal match become available.
