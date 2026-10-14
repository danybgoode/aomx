# Local Godot solo skirmish

The default scene is an original 20×20 isometric solo RTS match on **Godot 4.7.2.stable.official.ed1daf0bf**. A human and authored computer opponent each have a command post, worker and finite resource. Gather, build one recruitment post, produce melee and ranged units, and destroy the opposing command post. Losing your post loses; an unresolved match draws at 15 minutes. The earlier worker prototype remains in `main.tscn`.

Set `GODOT_BIN` to a Godot 4.7.2 executable. On the development Mac it is `/Users/cosmo/Downloads/Godot.app/Contents/MacOS/Godot`. From the repository root:

```sh
"$GODOT_BIN" --headless --path game --import
"$GODOT_BIN" --headless --path game --script res://tests/simulation_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/outbox_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_client_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_benchmark.gd
GODOT_BIN="$GODOT_BIN" npm run skirmish:contract
"$GODOT_BIN" --path game
```

Click a blue unit or building to select it. Right-click a tile to move, the gold resource to gather with a worker, or a red unit or building to attack with a combat unit. Select a worker and press **B**, then click a clear 2×2 area to build the recruitment post. Select the command post and press **1** to queue a worker. Select a completed recruitment post and press **2** or **3** to queue melee or ranged. **R** restarts with a new match ID; **F** retries local event sync. The HUD shows resource, source supply, unit counts, selected health, command-post health, order feedback and result. The computer gathers, builds, recruits a mixed group and starts attacking at 01:20; it replaces lost units while it has resources.

For controlled local result smoke, set `SKIRMISH_SMOKE_SCENARIO=win`, `loss` or `draw` before launching a debug Godot build. These fixtures set up a terminal state immediately or at the 15-minute boundary. They do not appear in release exports.

The client writes test-tagged first-open, later-day open, match-start and match-completed events to `user://funnel-outbox.json` before reporting them saved. It retries pending events in order every five seconds against local loopback ingest at `127.0.0.1:8787`. To exercise sync, run `npm ci && npm run funnel:serve` separately. Start the game with ingest offline, complete a controlled result, reopen the client, then start ingest and press **F**. The HUD distinguishes saved pending, synced test events and events needing attention. An unresolved earlier event holds later uploads. The local audit excludes every game event from public cohorts because `test_account` is true; no Golden Frijoles key is bundled.

Godot flushes a temporary JSON file and renames it into place. Its API does not expose directory fsync, so sudden power loss at that boundary remains unproven. The local ingest has no hosted authentication or release rail. This debug match is a complete local play loop and a contract exercise, not an eligible launch cohort.

## Private alpha export

The source tree is test-tagged and points to loopback. `npm run alpha:export`
copies it to a disposable directory, inserts a pinned HTTPS endpoint and build
channel, runs the Node/Godot contract checks, then writes a versioned macOS ZIP
and SHA-256 manifest in ignored `dist/alpha/`. It requires the matching Godot
4.7.2 macOS export template. For a staging export:

```sh
GODOT_BIN=/path/to/Godot AOMX_BUILD_CHANNEL=preview \
  AOMX_INGEST_URL=https://alpha-api.example.test/v1/events npm run alpha:export
```

Preview builds set `test_account=true`. Production builds set it false, but
the service still excludes events while the Golden Frijoles flag is off.
Alpha builds ask for an individual invite code and save it in the app's
`user://` directory so offline events can sync after restart. An invalid or
missing code leaves events in the outbox. Do not bundle any database, Butler,
OCI, or Golden Frijoles credential into the export.

The export uses Godot's built-in ad hoc code signing. The export command
extracts its own ZIP and verifies the app signature before writing the
manifest. Follow the [downloaded-build QA walkthrough](../docs/alpha-local-qa.md)
for macOS Gatekeeper and gameplay checks. A Developer ID signature and Apple
notarization are not configured for this private preview.

Rules use a fixed 0.1-second tick, integer tile positions, validated commands and stable IDs. Frame delta schedules ticks but does not decide outcomes. The test suite checks costs, production, range, damage, destruction, terminal states and same-command state hashes. On Apple M2 Max with a 20×20 map and 12 units, 5,000 route attempts averaged **0.5440 ms** each and 1,000 ticks averaged **0.0491 ms** each in a headless debug run. A rendered debug window showed roughly **14–28 ms** process-frame values during capture; that is an observation, not a release-build frame benchmark. Units can overlap during movement; crowd routing and larger-scale performance remain future work. Continue with Godot for the next bounded slice.
