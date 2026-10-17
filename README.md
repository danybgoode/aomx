# Battle for La Roma

Battle for La Roma is a real-time strategy game inspired by classic RTS games and set in a fictional, satirical Mexico City. Players build regional civilizations, grow their economies, and compete for control of the city's neighborhoods. La Roma is the ultimate prize.

The project has a local launch-funnel instrumentation prototype and a finishable Godot solo skirmish. An isolated alpha ingest is staged on the Oracle VM, and a Restricted macOS preview exists on itch.io. There is no public game release or real play cohort yet. Cultural references should enrich the game without being required to understand it.

## Project plan

- [Global game design document v0.3](docs/design/GDD.md), [architecture and capability review](docs/architecture-review-2026-10-16.md), and [full-game build path](Roadmap/full-game-build-path.md)
- [Local artwork inventory and integration rules](docs/art/reference-inventory.md)
- [Product roadmap](Roadmap/README.md)
- [Approved strategy](Roadmap/00-strategy/pmf-narrative.md)
- [North Star and launch measurement plan](Roadmap/00-strategy/north-star.md)
- [Golden Frijoles build order](Roadmap/00-ideas/BUILD-ORDER.md) and [first approved build: launch funnel](Roadmap/09-platform-and-measurement/track-launch-play-funnel/README.md)
- [Engine feasibility investigation](docs/technical-feasibility.md) and [engine decision](docs/architecture-decisions/001-engine-selection.md)
- [Local Godot solo skirmish](game/README.md), [funded solo-skirmish epic](Roadmap/01-core-play/finish-solo-skirmish/README.md) and [RTS core epic](Roadmap/01-core-play/prove-rts-core/README.md)
- [Local launch funnel contract and run commands](docs/launch-funnel-contract.md)

The GDD sets the full standalone game's design direction. The roadmap and funded epics determine approved build scope; source and tests establish what works today. Age of Empires II: Definitive Edition is the fidelity reference; a specific build/patch and exception policy must be recorded before numerical parity claims. `references/` is ignored local source material, while the canonical GDD and selected production assets live in tracked project paths.

## Golden Frijoles

This repository is connected to the **aomx** product. The project scoped agent skills are in `.agents/skills/`, with their source recorded in `skills-lock.json`. The shared project settings are in `golden-frijoles.config.json`; local credentials and event ingest keys are in the ignored `.env.local`.

The North Star and roadmap are registered in [the aomx console](https://goldenfrijoles.com/app?project=aomx). The console is waiting for the first eligible event. The launch-funnel contract, local ingest, outbox and cohort report exist; the Godot solo skirmish saves test-tagged terminal results locally. On 2026-10-15, the owner enabled `telemetry.play_funnel_enabled` in development, preview and production. The staged VM ingest uses preview, and the available macOS preview emits test-tagged traffic. The switch alone does not create an eligible cohort.

Use `npx -y @golden-frijoles/cli@1.5.1 status` to check the connection. The isolated authenticated ingest is staged on the VM; the next funnel work is owner sync QA, a released eligible client and mature cohort reconciliation. A local match does not create public readings.
