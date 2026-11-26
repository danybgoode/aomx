---
epic: pocket-shell
sprint: 2
title: "Pocket services"
stories_total: 2
---

# La Roma Pocket: the shell and its services · Sprint 2: Pocket services

**Status:** ⬜ Planned

## Stories

### S2.1 Ghost boards, daily seeds and leaderboards

As a pocket player, I face real neighbours without waiting for them. `src/pocket/` on the existing match host and migration `db/007_pocket.sql` store run snapshots, match ghosts by mode, round and strength, publish one daily seed per mode, and keep leaderboards per colonia chosen from a preset list (D4). Each mode is gated by a `pocket.<mode>_enabled` flag through the Golden Frijoles SDK.

### S2.2 Verified results

As a competitor, I trust the leaderboard. The headless Godot worker re-simulates each submitted run from its seed and inputs before the run can rank or become a ghost. Mismatches are quarantined and never rank. Done when an integration test like `multiplayer:integration` passes, including a tampered submission.
