# Cross-platform proof #22 — QA ledger

This ledger belongs to the funded [epic](../../Roadmap/09-platform-and-measurement/prove-cross-platform-play/README.md). A support row passes only after an installed or served **full** 28×28 La Roma Standard match at up to 24 population per side, with deliberate commands, save/resume, audio, frame p95 ≤33.3 ms and a device-specific peak-memory budget recorded before the run. Browser solo and browser online are separate rows. All platform pilot builds use the `preview` channel, `test_account=true`, and an isolated `BattleForLaRomaPlatformPilot` user directory. No public cohort or support claim exists yet.

The owner prioritizes easy Web distribution. The first release decision is for desktop Web solo on exact passing browser/OS combinations; mobile Web and online Web have separate claims. Native exports are follow-on candidates and do not hold a passing Web-only decision.

## Owner QA source follow-up — 2026-11-03

Later draft source branches add worker-planted food fields (game version 9, [PR #102](https://github.com/danybgoode/aomx/pull/102)) and selectable Medium/Large maps with seeded neutral sites (game version 10, [map QA](../world/explorable-map-sizes.md)). The version 7 artifact hashes below remain receipts for their exact source commit. Those rule versions are superseded by the version 12 source and local export recorded next; the hosted channels still serve the older pilot.

The branch subsequently added a simulation-side occupied-destination and congestion fix, versioned as `godot-4.7.2-skirmish-8`. The table below remains an exact receipt for the prior version 7 commit; it does not represent the new rule version. Godot warfare/client checks, cross-platform and Wonder deterministic hash fixtures, and the Node suite (51 passed, 3 database skips) passed for version 8. Version 8 is superseded by the later version 12 export below.

The source fixes and art in [PR #99](https://github.com/danybgoode/aomx/pull/99) produced clean local QA export `platform-78b89fd9bd4d` from commit `78b89fd9bd4dc4b281a0f843544a1017775b5318`, Godot 4.7.2, game/content `godot-4.7.2-skirmish-7` / `la-roma-world-5`. All four desktop export commands succeeded from the same commit with `test_account=true` and the current Restricted `sslip.io` endpoint. The macOS ZIP passed strict signature verification. Native Godot desktop and narrow renders show the new setup, resource art and selected actor state; targeted client, movement and art checks passed. A local Chrome run exposed a high-DPI Web size issue; Godot window content scaling corrected both setup and battlefield UI, and the browser visibly started a solo match and returned home through **MENU** on the code-equivalent temporary probe. The [owner QA record](../qa/2026-11-03-owner-review.md) names remaining gameplay. **No hosted Web or macOS tester channel has been replaced with this build**, and no physical full-match or support claim follows from these exports.

The stacked draft branches now reach game version `godot-4.7.2-skirmish-12`, world content `la-roma-world-6`, and state schema 8. Clean local Web, macOS, Windows and Linux QA exports were made from commit `5c03ab34bdcf50ece8bfa8d9d16e75a181f212b5` (`dirty:false`) with Godot 4.7.2, `test_account=true`, preview channel and the current Restricted `sslip.io` endpoint. This is source and packaging evidence, not a served/installed full-match acceptance. The hosted pilots still serve the older build described below. Online play needs a matching version 12 private-match host before testers receive this client.

| QA target | New local artifact and SHA-256 |
| --- | --- |
| Web | `dist/platform/platform-78b89fd9bd4d/web/index.pck` — `33ad8aaae08a6eb945fdf6523434b93150f01e949e2dcdb920d4c6c59cb02303`; `index.wasm` — `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0` |
| macOS | `dist/platform/platform-78b89fd9bd4d/macos/battle-for-la-roma-macos.zip` — `da406458d3b84003dd482a76faca1cfbccfb396a24dd25d41b47ef1ba6df60d8` |
| Windows | `dist/platform/platform-78b89fd9bd4d/windows/battle-for-la-roma.exe` — `320efea23961495769786349ab6d97d5151a42273f3de8fc27e8f7ad0a1fcdb9`; `.pck` — `d6f06e8db831c5b8072f9fda48c5bedeb6ae09c67f938ae9344f0fb5a919effd` |
| Linux | `dist/platform/platform-78b89fd9bd4d/linux/battle-for-la-roma.x86_64` — `d9f79ab89b5ae369aeed11c6052d402e8218cd503bf85b4a235f9c30c46a7c63`; `.pck` — `ae3170ff64dcf39c4a74cf00505cf951a571f02fa47932f06ebb48849a6da923` |

### Version 12 local QA package receipts

| Target | Artifact | SHA-256 / result |
| --- | --- | --- |
| Web | `dist/platform/platform-5c03ab34bdcf/battle-for-la-roma-web-platform-5c03ab.zip` | `09ab84e0221ab342eecdb574d3edcdc1b368ee6f73e94bdbc667ffb70c35daeb`; nine root files with `index.html` at root |
| macOS | `dist/platform/platform-5c03ab34bdcf/macos/battle-for-la-roma-macos.zip` | `75fd538a94f508a9e408eea8bce373d64c93d0bffe188016cb019f8d4f68ef56`; extracted app passed `codesign --verify --deep --strict` |
| Windows | `dist/platform/platform-5c03ab34bdcf/windows/battle-for-la-roma.exe` and `.pck` | Export succeeded; no physical Windows QA |
| Linux | `dist/platform/platform-5c03ab34bdcf/linux/battle-for-la-roma.x86_64` and `.pck` | Export succeeded; no physical Linux QA |

The newly built [owner-private entry page](https://battle-for-la-roma-private-pilot.jokeyquail1.chatgpt.site) links to the existing Restricted itch.io Web and macOS pilots. It is a separate static Site, version 2, with owner-only access and no external viewers or groups. It is not the requested public `battleforlaroma.com` domain or a game-build deployment.

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
| Web save download and storage recovery | The in-game Export control downloaded a 5,829-byte validated JSON save (SHA-256 `926338fe7a09ee6ea9122a26a1812b2af92976fb3b14d9b7242b3984bad793be`). After clearing all data for the test origin and reloading, Chrome's file picker [reimported that file](../screenshots/platform/web-clear-import-99bed69.png) at its saved `00:20` match clock | Same-version recovery passed on this local Chrome profile; transfer to another device and private-window behavior remain owed. The save file itself is kept out of the repo. |
| Web terminal from imported state | The first imported save continued unattended to a [defeat at 02:47](../screenshots/platform/web-terminal-99bed69.png) with a visible terminal reason | This proves the served browser can reach a terminal from restored state; it does not satisfy the deliberate-command/full-match performance acceptance path. |
| Restricted itch.io Web pilot | [Owner-only pilot](https://danybgoode.itch.io/battle-for-la-roma-web-pilot) is an HTML project with `web-platform-pilot` marked browser-playable and click-to-launch fullscreen. The signed-in owner launched the hosted `html-classic.itch.zone/html/20111028-2238260/` build in Firefox on macOS, reached setup, selected Regios and entered a solo match. An anonymous GET to the page returned HTTP 404 after upload. | This proves a private HTTPS launch and match entry in that owner browser, not a full match, browser/OS support, audio, performance, or phone touch. The sync warning is expected because the build's default ingest endpoint is loopback. Mobile-friendly remains off pending physical device proof. |
| Mobile-sized Web rendering | Chrome device emulation at 844×390 [selected a worker by touch](../screenshots/platform/web-landscape-touch-80c56b3.png); 390×844 [kept the board and HUD visible](../screenshots/platform/web-portrait-80c56b3.png) | Emulation is not a physical Android/iPhone browser, frame result, or full match. |
| Native macOS package | Freshly extracted the clean macOS zip, verified its code signature with `codesign --verify --deep --strict`, and launched the binary headlessly | This is a launch check, not an installed full match or owner walkthrough. |
| Review and CI | PR #99 general and security advisory passes were answered or clean; the final code-only general pass was clean at `56e8014`; `verify` and CodeQL passed at `56e8014`; local Node and Godot regression suites passed after the camera fix | Successful independent passes used Mistral Vibe after Antigravity version mismatch and Claude CLI error. The final code-only pass withheld docs and one code file for budget; advisory review is not exhaustive. |

The generic project `smoke` skill cannot run because this Godot checkout has no `scripts/live-smoke.mjs` or `live-smoke.config.json`. Its instructions require stopping rather than inventing that template harness. The Web smoke above used the exported files served locally and headless Chrome's debugging protocol. The Chrome command used `--enable-unsafe-swiftshader`, so its rendering and frame behavior are not a GPU support result.

## Artifact matrix

The previously hosted pilot build `platform-99bed69ff59e` comes from commit `99bed69ff59ea0ec183d1f79f2fbc4f1e0be8e69` (`dirty:false`); the earlier UI captures came from clean build `platform-80c56b35971b`. The current QA export is recorded above. The export generator is `node scripts/platform-export.mjs <web|macos|windows|linux|android>`; each run writes a file list and hashes under ignored `dist/platform/<build-id>/<target>/manifest.json`. The pinned Godot engine and official template are `4.7.2.stable.official.ed1daf0bf`. Game/content IDs are `godot-4.7.2-skirmish-7` / `la-roma-world-5`. The downloaded official export-template TPZ matched SHA-256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` before selected templates were installed.

The nine-file Web pilot ZIP is `dist/platform/platform-99bed69ff59e/battle-for-la-roma-web-platform-99bed69.zip`, SHA-256 `e5dbceef17b4aa10fa700036079ae10c7fc4c292885e180bdd5c959b565fee8c`. It has `index.html` at its root. It was uploaded to a **separate Restricted HTML itch.io project**, [Battle for La Roma — Web Pilot](https://danybgoode.itch.io/battle-for-la-roma-web-pilot), as Butler channel `web-platform-pilot`, upload `#20111028`, build `#2238260`, version `platform-99bed69ff59e`. The three native macOS download channels remain on the original Restricted project. The Web page has no payments or password access; only the owner and people explicitly authorized through itch.io can open it. The page says this pilot is solo only, warns that browser data may be cleared, and asks testers to record their device/browser. No public release or support claim follows from this upload.

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
| Desktop Web, owner Mac Firefox | MacBook Pro `Mac14,5` (Apple M2 Max, 64 GB), macOS 27.2 (26B123), Firefox 159.0; Restricted HTTPS build `platform-99bed69ff59e` served by itch.io; setup and solo match entry observed | Deliberate full match, audio, frame and memory profile owed | Unverified |
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
