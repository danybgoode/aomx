# Battle for La Roma

Battle for La Roma is a real-time strategy game inspired by classic RTS games and set in a fictional, satirical Mexico City. Players build regional civilizations, grow their economies, and compete for control of the city's neighborhoods. La Roma is the ultimate prize.

The project is at the planning stage. There is no game client or backend yet. Cultural references should enrich the game without being required to understand it.

## Project plan

- [Product roadmap](Roadmap/README.md)
- [Approved strategy](Roadmap/00-strategy/pmf-narrative.md)
- [North Star and launch measurement plan](Roadmap/00-strategy/north-star.md)
- [First backlog idea: track the launch play funnel](Roadmap/00-ideas/seeds/track-launch-play-funnel.md)

## Golden Frijoles

This repository is connected to the **aomx** product. The project scoped agent skills are in `.agents/skills/`, with their source recorded in `skills-lock.json`. The shared project settings are in `golden-frijoles.config.json`; local credentials and event ingest keys are in the ignored `.env.local`.

The North Star and roadmap are registered in [the aomx console](https://goldenfrijoles.com/app?project=aomx). The console is waiting for the first event. Once a playable build exists, instrument the funnel in the North Star plan and verify a real event arrives before inviting players.

Use `npx -y @golden-frijoles/cli@1.5.1 status` to check the connection. For new product work, follow the local `refine` skill, starting with the launch funnel seed.
