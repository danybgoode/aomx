# Project guidance

Battle for La Roma is a Godot RTS game with one public Web build and one public macOS build from the same source commit. The game includes solo skirmish, campaign, Wonder, solo 2 v 2 and player-created private online rooms. Golden Frijoles planning and funnel prototypes remain; there is no measured real play cohort yet.

- Read `README.md`, `Roadmap/README.md`, `Roadmap/WAYS-OF-WORKING.md`, and the relevant strategy or seed before planning or building.
- Use the project scoped Golden Frijoles skills in `.agents/skills/`. Start with `setup` for connection questions and `refine` for the next product slice. Use the pinned Golden Frijoles CLI and kit for project status and roadmap sync; verify a failed command before claiming network access is unavailable. Do not substitute a browser visit for a CLI or headless check.
- Treat `Roadmap/00-strategy/north-star.md` as the agreed measurement definition. The 15% later-day match completion target is provisional; there is no observed baseline yet.
- Keep cultural humor understandable to players unfamiliar with Mexico. Avoid treating regional stereotypes as gameplay facts.
- Never commit `.env.local`, API keys, tokens, or `.golden-frijoles/` local state. Commit shared config and `skills-lock.json`.
- This repo uses `master` today. A merge is not a game deployment; record the matching Web/macOS artifacts, host image and live verification separately.
- Golden Frijoles recognizes work branches named `feat/<epic-slug>` (also `fix/`, `chore/`, `spike/`, `bug/`, `docs/`), optionally with `-sN`; `codex/` branches do not move the live board to Building. Follow [the roadmap sync runbook](Roadmap/WAYS-OF-WORKING.md#golden-frijoles-roadmap-sync) after changing status or PR state.
