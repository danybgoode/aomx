# Local Godot solo skirmish

The default scene is an original 20×20 isometric solo RTS match on **Godot 4.7.2.stable.official.ed1daf0bf**. Choose Regios or Poblanos before each match; the computer plays the other faction. Regios workers deliver five gold per trip but combat units cost one more gold. Poblanos have stronger command and recruitment posts with standard economy and unit costs. Build an army and either destroy the opposing command post or hold the marked central 3×3 La Roma district uncontested for 60 seconds. Only living melee and ranged units count; an enemy fighter or empty district resets the timer. Losing your post or the district loses; an unresolved match draws at 15 minutes. The earlier worker prototype remains in `main.tscn`.

Set `GODOT_BIN` to a Godot 4.7.2 executable. On the development Mac it is `/Users/cosmo/Downloads/Godot.app/Contents/MacOS/Godot`. From the repository root:

```sh
"$GODOT_BIN" --headless --path game --import
"$GODOT_BIN" --headless --path game --script res://tests/simulation_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/outbox_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/faction_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/district_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_client_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_benchmark.gd
GODOT_BIN="$GODOT_BIN" npm run skirmish:contract
"$GODOT_BIN" --path game
```

Click one of your units or buildings to select it. Poblanos use blue art and Regios use red art, whichever faction you choose. Right-click a tile to move, the gold cart to gather with a worker, or an opposing unit or building to attack with a combat unit. The stockpile starts at 0; Regios workers deliver five gold per trip and Poblanos workers deliver four. At 6 or more stockpile, select a worker and press **B**, then click a clear 2×2 area outside La Roma to build the recruitment post. The game gives a gather hint if B is pressed too early. Select the command post and press **1** to queue a worker. Select a completed recruitment post and press **2** or **3** to queue melee or ranged. **+**/**-** or the mouse wheel zooms the board, **0** resets zoom, and **G** toggles fullscreen. **R** returns to faction choice with a new match ID after selection; **F** retries local event sync. The HUD shows district hold and threat state, stockpile, gold left, unit counts, selected health, command-post health, and the last order. A short colored marker confirms or rejects orders on the board. The computer gathers, builds, recruits a mixed group, contests the district, and can attack your command post.

For controlled local smoke, set `SKIRMISH_SMOKE_SCENARIO=win`, `loss`, `draw`, `district_hold`, or `district_contest` before launching a debug Godot build. The first three set a terminal state immediately or at the 15-minute boundary. `district_hold` places a friendly fighter at center; `district_contest` places both sides at center with a low-health defender so you can attack it and watch the timer restart. The AI is disabled only in these two debug fixtures. The environment hook does not run in release exports.

The client writes test-tagged first-open, later-day open, match-start and match-completed events to `user://funnel-outbox.json` before reporting them saved. Match events include the selected faction and `la-roma-prototype-1` content version; an open before choice uses neutral. It retries pending events in order every five seconds against local loopback ingest at `127.0.0.1:8787`. To exercise sync, run `npm ci && npm run funnel:serve` separately. Start the game with ingest offline, complete a controlled result, reopen the client, then start ingest and press **F**. The HUD distinguishes saved pending, synced test events and events needing attention. An unresolved earlier event holds later uploads. The local audit excludes every game event from public cohorts because `test_account` is true; no Golden Frijoles key is bundled.

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

Preview builds set `test_account=true`. Production builds set it false; release
eligibility still depends on the served Golden Frijoles flag and server policy.
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
