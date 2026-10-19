# Local Godot solo skirmish

The default scene is an original 28×28 isometric solo RTS match on **Godot 4.7.2.stable.official.ed1daf0bf**. Choose Regios, Poblanos, Oaxaqueños or Veracruzanos, then La Roma, Narvarte or Copilco and a computer opponent. The faction bonuses are fictional play doctrines, not claims about regional people. Regios workers carry five at a fighter surcharge; Poblanos have stronger buildings. Oaxaqueños gather faster and can research construction support, but have lighter buildings. Veracruzanos move faster and can research trade income, but have lighter buildings and a fighter surcharge. Scout the fog and recruit melee, ranged, armored and siege units. Destroy the opposing command post or hold the marked central 4×4 district uncontested for 75 seconds. Any living fighter can hold or contest; an enemy fighter or empty district resets the timer. Command-post loss takes priority over a simultaneous district hold. An unresolved match draws at 15 minutes. The earlier worker prototype remains in `main.tscn`.

Choose **Learner**, **Standard**, or **Challenger** before choosing a faction. Learner reacts every 40 ticks, scouts later, and caps its army at four. Standard reacts every 20 ticks, scouts earlier, counters visible roles, and caps at six. Challenger reacts every 10 ticks, presses objectives earlier, remembers sightings longer, and caps at eight. All three use the same costs, damage, sight, population, resources and win rules. Faction, opponent, map and difficulty stay fixed in schema-5 saves and replays; older saves return an explicit version error and remain on disk. The [world QA record](../docs/world-expansion-qa-2026-10-19.md) covers this wave.

Set `GODOT_BIN` to a Godot 4.7.2 executable. On the development Mac it is `/Users/cosmo/Downloads/Godot.app/Contents/MacOS/Godot`. From the repository root:

```sh
"$GODOT_BIN" --headless --path game --import
"$GODOT_BIN" --headless --path game --script res://tests/simulation_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/outbox_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/faction_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/district_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_client_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/rules_content_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_persistence_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_replay_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/world_expansion_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/cross_platform_hash_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_save_client_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_scale_benchmark.gd
"$GODOT_BIN" --headless --path game --script res://tests/skirmish_benchmark.gd
"$GODOT_BIN" --headless --path game --script res://tests/warfare_test.gd
"$GODOT_BIN" --headless --path game --script res://tests/strategic_opponent_test.gd
OPPONENT_REPORT_PATH=/absolute/path/opponent-report.json "$GODOT_BIN" --headless --path game --script res://tests/opponent_scenario_report.gd
"$GODOT_BIN" --headless --path game --script res://warfare_performance_probe.gd
GODOT_BIN="$GODOT_BIN" npm run skirmish:contract
"$GODOT_BIN" --path game
```

Hover a friendly unit or building for a gold outline and selection hint, then click its sprite or ground tile. Shift-click or drag selects a group; click a group portrait to focus one member. The selected unit has a cyan outline, ground ring, and a four-direction heading marker when it moves. Existing project-original unit sprites use a small view-only stride and idle animation. The compact top HUD shows stockpiles, faction and clock. The bottom HUD shows selection, health, activity and contextual commands. The collapsible objective widget, event notices and minimap show strategic state. Pause, **Reset** and **Menu** sit at the top right. Reset keeps faction, map and opponent; Menu has save, resume, audio mute/volume, invite, sync and support controls. The two sides use blue and red art, with text labels and outlines alongside color.

Choose Move, Gather, Build or Attack, then click a board target; **Esc** or Cancel leaves targeting. Unavailable orders show their blocking reason. Right-click issues a direct order. Select a worker and press **B**, then click a clear 2×2 site outside the central district to build a recruitment post. Select the command post and press **1** to queue a worker. Select a completed recruitment post and press **2** or **3** to queue melee or ranged, or use cards for armored and siege after the required age. **+**/**-** or the mouse wheel changes zoom; **0** fits the window. **G** toggles fullscreen, **R** returns to setup and **F** retries local event sync. The computer gathers, builds, scouts with current sight and remembered positions, recruits, contests the center and attacks the post. Desktop, mobile landscape and portrait layouts expose the same commands; touch uses Godot mouse emulation.

Open **Menu → Save current match** during play. On the faction screen or in Menu, **Resume saved match** restores the same match ID and logical state. One local slot lives at `user://solo-skirmish-save.v1.json`; saving again replaces it. An unsupported or damaged save stays on disk and displays a reason, without silently resetting the match. A completed match ID cannot be resumed into a second result. The save is local to the current Godot profile, so moving between machines requires copying that file and a compatible build/content version. The [simulation contract](../docs/architecture-decisions/003-simulation-contract.md) defines format and replay semantics.

The [HUD implementation notes](../docs/art/ui-component-spec.md) and [four screenshots](../docs/screenshots/readable-hud/README.md) compare the playable interface with the approved concept. To build a local Web export, install the Godot 4.7.2 Web template and run `"$GODOT_BIN" --headless --path game --export-release Web /absolute/path/game.html`; serve the generated HTML, JavaScript, WASM and PCK from one directory. The Web export is a compatibility check, separate from the signed macOS Restricted preview.

For the owned-art pipeline and actual-scale comparison, see [the production notes](../docs/art/owned-art-pipeline.md). Run `scripts/export-owned-art.sh`, `node scripts/validate-art-manifest.mjs`, then `"$GODOT_BIN" --path game res://art_pilot.tscn`. The boar and raised tiles are pilot candidates; the selected flower tile is decorative in the match.

For controlled local smoke, set `SKIRMISH_SMOKE_SCENARIO=win`, `loss`, `draw`, `district_hold`, or `district_contest` before launching a debug Godot build. The first three set a terminal state immediately or at the 15-minute boundary. `district_hold` places a friendly fighter at center; `district_contest` places both sides at center with a low-health defender so you can attack it and watch the timer restart. The AI is disabled only in these two debug fixtures. The environment hook does not run in release exports.

The client writes test-tagged first-open, later-day open, match-start and match-completed events to `user://funnel-outbox.json` before reporting them saved. Match events include the selected faction and `la-roma-world-5` content version; an open before choice uses neutral. The ingest allowlist accepts this version alongside earlier supported versions. Pending events retry in order every five seconds against local loopback ingest at `127.0.0.1:8787` in development. Run `npm ci && npm run funnel:serve` separately to exercise sync. The local audit excludes every game event from public cohorts because `test_account` is true; no Golden Frijoles key is bundled.

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

Rules use a fixed 0.1-second tick, integer tile positions, validated versioned commands/content, stable IDs and a versioned canonical save. Frame delta schedules ticks but does not decide outcomes. The test suite checks costs, production, range, damage, destruction, terminal states, save/resume and replay hashes. The [foundation benchmark](../docs/simulation-benchmark-2026-10-16.md) records 20×20, 32×32 and 48×48 debug cases with 15–163 entities; each met its declared route and tick p95 budget on the Apple M2 Max. Dense fighters can still overlap, and release-build/minimum-device performance remains unmeasured. Continue with Godot for the next bounded slice.
