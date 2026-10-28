# Cross-platform proof #22 — QA ledger

This ledger belongs to the funded [epic](../../Roadmap/09-platform-and-measurement/prove-cross-platform-play/README.md). A support row passes only after an installed or served **full** 28×28 La Roma Standard match at up to 24 population per side, with deliberate commands, save/resume, audio, frame p95 ≤33.3 ms and a device-specific peak-memory budget recorded before the run. Browser solo and browser online are separate rows. All platform pilot builds use the `preview` channel, `test_account=true`, and an isolated `BattleForLaRomaPlatformPilot` user directory. No public cohort or support claim exists yet.

The owner prioritizes easy Web distribution. The first release decision is for desktop Web solo on exact passing browser/OS combinations; mobile Web and online Web have separate claims. Native exports are follow-on candidates and do not hold a passing Web-only decision.

## Local component evidence

| Check | Result | Limit |
| --- | --- | --- |
| Node suite | 51 passed, 3 existing Postgres tests skipped | Not a deployed service or device match. |
| Godot 4.7.2 portable save test | Passed native roundtrip, deterministic continuation, corrupt/old rejection without replacing good save | Browser file picker and clear-site-data still need a served build check. |
| Godot 4.7.2 touch test | Passed tap selection, group add, pan/pinch without order, cancel, HUD hit and emulated-mouse filtering | Synthetic input does not prove phone GUI delivery. |
| Authoritative match integration | Two native headless clients joined, issued an order and compared redacted state | No Web client or terminal match in this check. |
| Exact-origin match HTTP contract | Allowed preflight and native health passed; wrong origin/method/header rejected | Restricted TLS route and two-player Web/native match still need a hosted check. |
| Desktop Web smoke | Headless Chrome rendered [setup](../screenshots/platform/web-setup-80c56b3.png) and [running solo match](../screenshots/platform/web-match-80c56b3.png) from clean build `platform-80c56b35971b` | The game was not played to terminal; loopback ingest was offline, so the visible sync warning is expected. |
| Web save import | Chrome's actual file picker loaded a generated same-version solo save in final clean build `platform-99bed69ff59e`; the [resumed match](../screenshots/platform/web-import-99bed69.png) has the home board in view | Cross-device transfer, corrupt-file picker behavior and full-match completion remain owed. The first browser run exposed an off-screen resume camera, fixed at `830ac71` and checked again here. |
| Mobile-sized Web rendering | Chrome device emulation at 844×390 [selected a worker by touch](../screenshots/platform/web-landscape-touch-80c56b3.png); 390×844 [kept the board and HUD visible](../screenshots/platform/web-portrait-80c56b3.png) | Emulation is not a physical Android/iPhone browser, frame result, or full match. |
| Native macOS package | Freshly extracted the clean macOS zip, verified its code signature with `codesign --verify --deep --strict`, and launched the binary headlessly | This is a launch check, not an installed full match or owner walkthrough. |
| Review and CI | PR #99 general and security advisory passes were answered or clean; `verify` and CodeQL passed at `80c56b3`; local Node and Godot regression suites passed after the camera fix | Both successful reviews used Mistral Vibe after Antigravity version mismatch and Claude CLI error; a second external reviewer family has not checked the final diff. |

The generic project `smoke` skill cannot run because this Godot checkout has no `scripts/live-smoke.mjs` or `live-smoke.config.json`. Its instructions require stopping rather than inventing that template harness. The Web smoke above used the exported files served locally and headless Chrome's debugging protocol. The Chrome command used `--enable-unsafe-swiftshader`, so its rendering and frame behavior are not a GPU support result.

## Artifact matrix

Latest clean build `platform-99bed69ff59e` comes from commit `99bed69ff59ea0ec183d1f79f2fbc4f1e0be8e69` (`dirty:false`); the earlier UI captures came from clean build `platform-80c56b35971b`. The export generator is `node scripts/platform-export.mjs <web|macos|windows|linux|android>`; each run writes a file list and hashes under ignored `dist/platform/<build-id>/<target>/manifest.json`. The pinned Godot engine and official template are `4.7.2.stable.official.ed1daf0bf`. Game/content IDs are `godot-4.7.2-skirmish-7` / `la-roma-world-5`. The downloaded official export-template TPZ matched SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` before selected templates were installed.

| Target | File | SHA-256 |
| --- | --- | --- |
| Web | `index.wasm` | `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| Web | `index.pck` | `729baf82dae89f9761f37d5738551c50b4e966c2fb7a05c689d4eb9edfc69b13` |
| macOS | `battle-for-la-roma-macos.zip` | `013405007f0b39c687fbcf9d176a932a78eeab2608fad7982c90a9b2d849de0c` |
| Windows | `battle-for-la-roma.exe` / `battle-for-la-roma.pck` | `320efea23961495769786349ab6d97d5151a42273f3de8fc27e8f7ad0a1fcdb9` / `65809ae05ac72c9aabb1555570152277d23f5f8c490030dc7467cbb5b0c6b17a` |
| Linux | `battle-for-la-roma.x86_64` / `battle-for-la-roma.pck` | `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63` / `fee27ab2bd4993f4c3c524cfe06911d7a3ac08adb6596576434588230f0d19f3` |

| Target | Artifact build | Real-device result | Support status |
| --- | --- | --- | --- |
| Native macOS, owner Mac | Export succeeded; fresh install and full match owed | Model/OS, frame, memory and owner walkthrough owed | Unverified |
| Native Windows, one remote PC | Export succeeded; physical PC model/OS and install owed | Full match and save transfer owed | Unverified |
| Native Linux | Export succeeded; no physical Linux PC named | No installed-device match | Unverified |
| Desktop Web, Mac Safari | Compatibility export succeeded | Full match, audio and storage matrix owed | Unverified |
| Desktop Web, Windows Chrome/Firefox | Compatibility export succeeded | Remote PC/browser versions and full matches owed | Unverified |
| Native Android | Godot Android template installed; export needs Google Android SDK, platform-tools and build-tools | APK and remote Android phone model/OS/full match owed | Unverified |
| Android Chrome Web | Web export exists | Remote phone model/OS/browser, touch and full match owed | Unverified |
| iPhone 15 Pro Safari Web | Web export exists | iOS/Safari versions, touch and full match owed | Unverified |
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
