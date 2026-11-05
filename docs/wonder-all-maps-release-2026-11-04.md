# Wonder on all maps · Restricted release QA

**State, 2026-11-04:** The approved landing and game home UI are on `master`, the public promotional page is live, and Wonder on all four solo maps is available in a new Restricted macOS preview. Campaign Chapter and Wonder were served on for a bound preview identity. No public game build or eligible play cohort is claimed.

## Exact release

| Item | Verified result |
| --- | --- |
| Source | PR [#108](https://github.com/danybgoode/aomx/pull/108), merged as `5baa01b4b3f9f412a4f7abe707d68d8f7afb9a7a`; the signed export was built from PR head `9892eed7ab8a`. The merge changed no game, ingest, script, or landing files from that head. |
| Landing | Cloudflare Pages Direct Upload, <https://battle-for-la-roma.pages.dev/>, production deployment `1748b1ee.battle-for-la-roma.pages.dev`, linked to merged commit `5baa01b`. The canonical HTML and hero image returned 200; desktop and 390-pixel Chromium captures were reviewed. |
| Ingest | CI image `ghcr.io/danybgoode/aomx-ingest:5baa01b` healthy on the alpha VM. The private-match host stayed on `ghcr.io/danybgoode/aomx-match:2a6c071` and healthy. Source release `/opt/aomx/releases/5baa01b-wonder-all-maps` has locked production dependencies. A fresh backup and disposable restore drill succeeded before rollout and again after the source switch. |
| Download | Restricted itch.io channel `danybgoode/battle-for-la-roma:mac-wonder-all-maps`, upload **#20290779**, Butler build **#2301808**, version `preview-9892eed7ab8a`. The anonymous itch page returned 404 from an independent address. |
| Artifact | `dist/alpha/battle-for-la-roma-preview-9892eed7ab8a-macos.zip`, SHA-256 `ced5566804c94f3c539aef54f514a39823d1e26d0e0ba9327c46260d63a4c4c2`. An authenticated fresh Butler fetch extracted 166.29 MiB. It matched the source ZIP by `diff -qr`; strict code-signature verification and a bounded headless app launch passed. |

## Checks

- `npm test`: 52 passed and three database integration cases skipped. PR `verify` and CodeQL passed. The signed export gate also passed Godot headless, simulation contracts, multiplayer integration and replay, performance probes, and strict macOS signature verification.
- Normal Wonder AI matches on La Roma, Narvarte, Copilco and La Roma Large each built a Wonder and reached a terminal result. Copilco's early scout no longer blocks the Terrenos route before Godín. The four original La Roma Wonder full-match hashes stayed unchanged.
- Map-specific Wonder content IDs passed save/replay checks and live ingest validation. With a bound preview invite and signed exposure proof, all four start events returned 200 and were excluded as `preview_environment`. The existing v12 pilot open still returned 200 and was excluded as test traffic. These QA events did not enter public measurement.
- Bound preview flag responses served `campaign.chapter_enabled=true` and `modes.wonder_enabled=true`, both version 2; the Wonder response included its exposure proof. The freshly fetched app displayed Campaign Chapter as selectable, opened `Llegada a Copilco`, kept Wonder selected after changing to Narvarte, and launched a Copilco Wonder match. The scoped QA invite was revoked and removed from the isolated `BattleForLaRomaWonderAllMaps` profile after the check.
- The pinned Golden Frijoles CLI listed all four configured flags as `on`, `serving: true`, and `reach: everyone` in development, preview, and production. `multiplayer.private_match_enabled` is version 24 and `telemetry.play_funnel_enabled` is version 2; those served configurations do not establish a compatible private match in the v7 solo preview.

## Remaining acceptance

The owner still needs to finish a Wonder match and a cold quit/reopen save-resume in the fetched build. The current v7 solo preview is deliberately isolated from the v12 private-match host; the existing v12 private channels remain available. The in-match HUD and alpha support panel still contain English copy, outside this landing/home interface slice. The repository has no configured `smoke` skill Playwright harness; the live landing was checked with direct HTTP and headless Chromium captures. Keep the Wonder epic `in-progress` until its broader acceptance checks and measured rollout evidence are complete.
