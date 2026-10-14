# Project guidance

Battle for La Roma is a new RTS game project. This repository currently contains planning documents and Golden Frijoles setup, with no game implementation yet.

- Read `README.md`, `Roadmap/README.md`, `Roadmap/WAYS-OF-WORKING.md`, and the relevant strategy or seed before planning or building.
- Use the project scoped Golden Frijoles skills in `.agents/skills/`. Start with `setup` for connection questions and `refine` for the next product slice.
- Treat `Roadmap/00-strategy/north-star.md` as the agreed measurement definition. The 15% later-day match completion target is provisional; there is no observed baseline yet.
- Keep cultural humor understandable to players unfamiliar with Mexico. Avoid treating regional stereotypes as gameplay facts.
- Never commit `.env.local`, API keys, tokens, or `.golden-frijoles/` local state. Commit shared config and `skills-lock.json`.
- This repo uses `master` today. Do not describe a merge as a deployment until a game build and deploy process actually exist.
