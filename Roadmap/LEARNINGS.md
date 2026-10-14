# Learnings

Only project-specific findings belong here. Add new entries when evidence changes a decision or prevents repeat work.

- **2026-10-13 — Start with a measured funnel.** The game has no playable build, so there is no observed retention baseline. The 15% later-day match completion goal is a hypothesis to revisit after the first mature cohort. See [North Star](00-strategy/north-star.md).
- **2026-10-13 — Aggregate by player before reporting retention.** Golden Frijoles `telemetry_event` inputs count raw event occurrences. The agreed North Star needs distinct players and a later-day condition, so compute those values from identified game events and send the resulting readings through `external_push`.
- **2026-10-13 — Keep products separate.** Golden Frijoles CLI commands act on a selected product. This repo belongs to `aomx`; verify the active product before any future push or key operation.
- **2026-10-13 — The repo is planning only.** No SDK or measurement code can be verified until a game runtime exists. The console correctly reports that it is waiting for its first event.
- **2026-10-13 — Engine decision is provisional until a playable test.** At openage commit `3da21ab`, movement and rendering foundations exist, but gathering and construction are not live game systems; the local build stopped during CMake configuration at missing `toml11`. Use Godot for the first original-content prototype and revisit with measured play and performance evidence. See [ADR 001](../docs/architecture-decisions/001-engine-selection.md).
