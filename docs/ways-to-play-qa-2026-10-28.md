# Ways to play · Restricted pilot QA

**State · 2026-10-28:** The reviewed solo-mode code is on `master`, the signed owner-only pilot is downloadable, and a compatible ingest image is healthy. The epic remains in progress: the owner has not yet finished the three objectives or a cold Wonder save/quit/resume on this downloaded build. There is no public release or eligible play cohort.

## Exact release

| Item | Verified value |
| --- | --- |
| Source | `master` merge `f49a1ce1b62cca0c0375c57e17b5fe3f5b466a59`; S1 [#95](https://github.com/danybgoode/aomx/pull/95), S2 [#96](https://github.com/danybgoode/aomx/pull/96), S3 [#97](https://github.com/danybgoode/aomx/pull/97). |
| Build | `preview-f49a1ce1b62c`, Godot 4.7.2, game `godot-4.7.2-skirmish-7`, base content `la-roma-world-5`, Wonder content `la-roma-wonder-1`. |
| Restricted channel | `danybgoode/battle-for-la-roma:mac-ways-to-play-pilot`, Butler build **#2234135**, upload **#20099282**. Existing channels were not replaced. |
| Isolated local profile | `BattleForLaRomaWaysPilot` for save, outbox and invite state. |
| Source ZIP SHA-256 | `0ac08f247dc0f88f5bbad22ecc25e2bb9da7de09a16c8698d381f12ceb0ede3a`. |

The full `npm run alpha:export` gate passed from merged `master`: Node tests, Godot headless suite, simulation contracts, multiplayer integration and replay, performance probes, macOS export and strict signature verification. Linux CI `verify` and CodeQL passed on all three PRs. The four-faction normal-match matrix covers La Roma and Conquest in Sprint 3 and Wonder in the existing cross-platform hash fixture. La Roma ended by center hold at ticks 1673–1772. Conquest ended once by command-post loss and three times by the 9000-tick draw; this is a valid terminal check, with AI pacing still an open play-quality question. Wonder's four-faction full-match hash/replay fixture passed on macOS and Linux. The Wonder client test passed legal construction, a 120-tick hold, save, served-off decision, state-hash/match-ID preserving resume, and one completion/adoption pair. That test resumes in one process; a real quit/reopen remains owed.

The authenticated fresh `butler fetch` extracted **163.85 MiB** from build #2234135. `diff -qr` found no differences between the fetched app and a separate extraction of the source ZIP. `codesign --verify --deep --strict` passed on the fetched app, and its executable exited cleanly after a bounded headless startup. The anonymous itch page returned HTTP **404** before and after upload.

## Ingest and rollout boundary

The alpha VM had 23 GiB free on root and 45 GiB on data before the update. A fresh database backup was restored to the distinct disposable `aomx_restore_test` database with matching counts (121 audit events, 18 report rows, zero observed/publication rows); the live database was not cleared. Source from `f49a1ce` was installed with locked production dependencies and built as `aomx-ingest:f49a1ce`. The ingest container is healthy, and HTTPS `/healthz` returned **200**. An unauthorized POST to `/v1/modes/flag` returned **401 `invite_required`**. The database stayed on `postgres:17-alpine`; the private-match host stayed on `aomx-match:0d29ed3`. The pilot has an explicit version-mismatch message for that older host. The VM's backup, health, report and retention timers remain active.

Golden Frijoles `modes.wonder_enabled` is served **off, version 1**, in development, preview and production. New Wonder starts on the downloaded app are unavailable until an owner-scoped preview evaluation is arranged. No accepted Wonder event, eligible public completion, later-day retention result, or same-build private match is claimed. The old Restricted `mac-private-alpha` channel remains the intended private-match regression path; its behavior still needs the owner check below.

Sprint 2's final-head Linux verify, CodeQL, independent verifier and different-family general review passed. An earlier-head different-family security lens had no findings. Its final-head rerun stalled; automatic approval review rejected a focused retry because it would send private source to the external reviewer, so that advisory check remains pending. Sprint 3 had a fresh independent high-risk verifier with no merge blocker; its external review was not repeated under that rejection.

## Owner downloaded-build walkthrough · open

Use the owner account's Restricted page and confirm Butler **#2234135**, build ID `preview-f49a1ce1b62c`, and strict app signature. Record window size, faction, result reason, match ID where shown, and what was hard to understand. Do not use an old channel or a local editor build as acceptance evidence.

1. At **1024×700** and **1280×800**, inspect setup for Conquest and La Roma with Wonder off. Confirm each rule is readable and only Wonder is disabled.
2. Start Conquest as two different factions. Hold the center without winning, then destroy the opposing command post in one match. Record any stalled attack or draw.
3. Start La Roma as two different factions. Complete the center hold in one match and a command-post route in another. Confirm each result names the actual route.
4. After a served **owner-only preview** Wonder evaluation and a fresh scoped internal QA invite are available, start Wonder on 28×28 La Roma. Reach `godin`, pay 16 comida/20 materiales/20 varos/12 terrenos, complete 180 construction ticks, then protect the Wonder for 900 hold ticks. Read the public timer without using enemy fogged unit information. Record the result and the excluded test receipt.
5. Start another Wonder match, save after progress, quit the app fully, reopen the **fetched** app and resume. Confirm objective, match ID, timer and balances. Destroy a Wonder, then verify its timer resets if rebuilt. One finish should create one completion and adoption pair; replay/retry must not add another.
6. Check the campaign chapter and the **old** Restricted private-match channel for their previous behavior. On the new pilot, attempt private entry and record its explicit host-version message. Refresh Wonder after a served-off decision and confirm new Wonder starts are blocked while Conquest and La Roma remain available.
7. Record exact observations, any rules/copy confusion and the provider evaluation plus excluded receipt. Keep the flag off outside the bounded owner check. An uncoached comprehension read and any public rollout decision remain separate.
