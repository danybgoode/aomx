# Battle for La Roma repository guidance

- Read `AGENTS.md`, `Roadmap/WAYS-OF-WORKING.md`, and the relevant epic or seed before changing code. `master` is the default branch.
- Preserve the agreed definitions in `Roadmap/00-strategy/north-star.md`. Do not count test accounts, bots, rejected events, or immature cohorts as real readings.
- Keep `.env.local`, credentials, invite codes, and `.golden-frijoles/` state out of commits and game exports.
- Run `npm test` with the disposable Postgres test database and the Godot checks in `.github/workflows/alpha-ci.yml` for changes to game, ingest, or measurement code.
- A merge to `master` does not publish a game build or authorize an external alpha invitation. Treat the Restricted itch.io preview and Oracle VM as separate release steps.
