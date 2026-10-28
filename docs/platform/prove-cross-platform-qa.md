# Cross-platform proof #22 — QA ledger

This ledger belongs to the funded [epic](../../Roadmap/09-platform-and-measurement/prove-cross-platform-play/README.md). A support row passes only after an installed or served **full** 28×28 La Roma Standard match at up to 24 population per side, with deliberate commands, save/resume, audio, frame p95 ≤33.3 ms and a device-specific peak-memory budget recorded before the run. Browser solo and browser online are separate rows. All platform pilot builds use the `preview` channel, `test_account=true`, and an isolated `BattleForLaRomaPlatformPilot` user directory. No public cohort or support claim exists yet.

## Local component evidence

| Check | Result | Limit |
| --- | --- | --- |
| Node suite | 51 passed, 3 existing Postgres tests skipped | Not a deployed service or device match. |
| Godot 4.7.2 portable save test | Passed native roundtrip, deterministic continuation, corrupt/old rejection without replacing good save | Browser file picker and clear-site-data still need a served build check. |
| Godot 4.7.2 touch test | Passed tap selection, group add, pan/pinch without order, cancel, HUD hit and emulated-mouse filtering | Synthetic input does not prove phone GUI delivery. |
| Authoritative match integration | Two native headless clients joined, issued an order and compared redacted state | No Web client or terminal match in this check. |
| Exact-origin match HTTP contract | Allowed preflight and native health passed; wrong origin/method/header rejected | Restricted TLS route and two-player Web/native match still need a hosted check. |
| Desktop Web smoke | Headless Chrome rendered [setup](../screenshots/platform/web-setup-521f7d8.png) and [running solo match](../screenshots/platform/web-match-521f7d8.png) from preliminary commit `521f7d8` | The game was not played to terminal; loopback ingest was offline, so the visible sync warning is expected. The later touch safeguard is not in these captures. |

The generic project `smoke` skill cannot run because this Godot checkout has no `scripts/live-smoke.mjs` or `live-smoke.config.json`. Its instructions require stopping rather than inventing that template harness. The Web smoke above used the exported files served locally and headless Chrome's debugging protocol. The Chrome command used `--enable-unsafe-swiftshader`, so its rendering and frame behavior are not a GPU support result.

## Artifact matrix

Build identity and SHA-256 values will be stamped from the final clean platform pilot manifests after review fixes. The current export generator is `node scripts/platform-export.mjs <web|macos|windows|linux|android>`; each run writes a file list and hash under ignored `dist/platform/<build-id>/<target>/manifest.json`. The pinned Godot engine and official template are `4.7.2.stable.official.ed1daf0bf`. Game/content IDs are `godot-4.7.2-skirmish-7` / `la-roma-world-5`. The downloaded official export-template TPZ matched SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` before selected templates were installed.

| Target | Artifact build | Real-device result | Support status |
| --- | --- | --- | --- |
| Native macOS, owner Mac | Export succeeded; fresh install and full match owed | Model/OS, frame, memory and owner walkthrough owed | Unverified |
| Native Windows, one owner PC | Export succeeded; physical PC model/OS and install owed | Full match and save transfer owed | Unverified |
| Native Linux | Export succeeded; no physical Linux PC named | No installed-device match | Unverified |
| Desktop Web, Mac Safari | Compatibility export succeeded | Full match, audio and storage matrix owed | Unverified |
| Desktop Web, Windows Chrome/Firefox | Compatibility export succeeded | Physical Windows/browser versions and full matches owed | Unverified |
| Native Android | Godot Android template installed; export needs Google Android SDK, platform-tools and build-tools | APK and Android phone model/OS/full match owed | Unverified |
| Android Chrome Web | Web export exists | Phone model/OS/browser, touch and full match owed | Unverified |
| iPhone Safari Web | Web export exists | Phone model/iOS/Safari, touch and full match owed | Unverified |
| Native iOS | No Apple development signing setup | Cannot install a native test build | Unverified |
| Desktop Web online with native peer | Exact-origin local contract passed | Restricted TLS host, two scoped codes, real Web/native terminal/reconnect/replay and excluded receipt owed | Unverified |

## Physical-device walkthrough owed

Record date, exact model, OS, browser version, build ID and SHA-256, install or served URL, graphics backend, RAM, orientation and whether the test account build is isolated. Do not put invite codes, tokens, private host credentials, or player save contents in this ledger.

1. Fresh install or open the served build. Confirm the game/content version and setup choices; capture a screenshot and load time. On browser, confirm audio starts after a gesture.
2. Play the declared match: select and group units, gather, build, attack, pan/zoom, cancel a target, use the minimap, then reach a terminal result. Record the visible reason, command acknowledgements, frame p95 over sustained play and peak memory. Record failure and last safe action if it cannot finish.
3. Save during play. Export the solo save, import it on a different same-version target, confirm match ID/state, finish once, and check one test-tagged completion. Try corrupt and older-version files and confirm the good save remains. On browser, clear site data and reimport; record private-window behavior separately.
4. On phones, repeat command, scroll, orientation and interruption/resume checks near screen edges. Verify GUI buttons and file pickers receive touch input and do not order the board behind the HUD.
5. For online Web, first verify allowed and denied OPTIONS on the actual Restricted TLS route. With two distinct scoped codes and preview admission on, pair Web with native, complete, reconnect and replay. Inspect the authoritative terminal record and excluded ingest receipt, then revoke codes, turn admission off, restart the match service and verify a new join is denied.

The source of truth for platform support remains the completed rows above. #23 release candidate stays behind these evidence gates.
