# ADR 003: One versioned solo simulation contract

**Date:** 2026-10-16
**Status:** Accepted for the current solo skirmish

## Decision

`game/skirmish.gd` remains the sole rules authority. The Godot scene converts input into commands and renders snapshots; it does not decide costs, path blocking, damage or victory. `game/content/skirmish.v1.json` defines the currently playable rules using stable unit, building and faction IDs. `game/rules_content.gd` validates the schema and map before a match starts. The art manifest remains a separate view contract.

A semantic command has `schema_version`, `issued_tick`, `sequence`, `side`, `kind`, `actor_id` and a typed target. The simulation accepts it only at the current logical tick and next sequence. The older `issue()` call remains an adapter for current input and tests. A canonical state snapshot has its own schema version, content ID and SHA-256 of the source definition. It includes entities, IDs, paths, queues, resources, faction, AI state, district state, terminal state, clock and seed/RNG state. It excludes view state, frame time, invite code and funnel outbox. The simulation runs at a fixed 100 ms tick. AI orders and entity updates have explicit ordering; damage is applied in ascending target ID. The local seeded integer RNG is available for future rules, but no current rule draws from it.

`game/skirmish_persistence.gd` writes a v1 JSON wrapper through a flushed temporary file and rename. The wrapper holds the canonical state, match ID, event completion guard, accepted command history and hash checkpoints. It is capped at 16 MiB. Loading checks format, versions, content hash, structure, history and canonical hash before replacing the active match. Unsupported or corrupt files remain in place and return a readable error. There is no migration from a prior save format because the prototype had no match save. Any later change to logical rules must either preserve the declared versions and replay hashes or introduce a tested format migration. An unkeyed hash detects accidental damage and divergence; it is not anti-cheat or authenticity proof. Godot does not expose directory fsync, so sudden power loss during rename has not been proven safe on every filesystem.

`game/skirmish_replay.gd` records the human command stream, initial seed, content/game versions, checkpoints and final hashes. The deterministic AI generates its own orders during replay. Verification reports the first divergent logical tick at a checkpoint or the final tick. Replays are diagnostic artifacts, not a multiplayer transport or a player-facing replay browser. A resumed match keeps its match ID; the client never enqueues a second start and refuses to resume an already completed match ID from the outbox.

## Migration from the prototype

The current match values were copied into validated definitions without changing the live faction effects, one-resource economy, routes, combat values, district hold or command-post terminal path. Existing Regios/Poblanos tests and rendered probes protect those behaviors. Future four-resource economy, ages, prerequisites and tech effects belong in new versioned content and simulation migrations; v1 only validates definitions it uses. Current `Skirmish` constants remain compatibility names for UI and existing tests, while rule evaluation reads content definitions. Do not extend the compatibility constants as a second rules source.

## Evidence and limits

Godot 4.7.2 macOS headless suites cover current rules, malformed commands/content, save round-trip, continuation, corrupt/unsupported saves, replay divergence and event deduplication. The same 700-tick fixtures are pinned for Linux CI. Rendered desktop probes cover save/resume and an 82-entity crowd. See [the benchmark report](../simulation-benchmark-2026-10-16.md) and [sync decision](004-synchronization-model.md). A downloaded preview walkthrough remains an owner QA gate.
