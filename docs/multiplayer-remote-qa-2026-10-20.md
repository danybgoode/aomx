# Restricted multiplayer remote QA — 2026-10-20

This is builder evidence for the owner-only Restricted preview. It does not close the epic or establish a player cohort. No external participant was invited. The [numbered owner walkthrough](../Roadmap/03-multiplayer-and-retention/prove-multiplayer/sprint-3.md#sprint-3--smoke-walkthrough) remains to be run blind on the downloaded build.

## Reviewed source and deployed services

| Item | Observed evidence |
| --- | --- |
| Game source | `master` `2ad3d65a3d80`, including [PR #56](https://github.com/danybgoode/aomx/pull/56), [PR #57](https://github.com/danybgoode/aomx/pull/57), [PR #58](https://github.com/danybgoode/aomx/pull/58) and [PR #59](https://github.com/danybgoode/aomx/pull/59); Project checks and CodeQL passed. |
| Match host | Native Oracle Linux ARM64 image `aomx-match:2ad3d65` from a SHA-256-checked `git archive` of merged master on the existing Oracle VM, capped at 768 MiB, **1.0 CPU**, read-only root, no added capabilities; container health passed. The previous `aomx-match:834295f` image and release directory remain for rollback. The original image's 1,000-tick worker hash matched macOS and local Linux: `4d6266cbe25b249d14570136fecc20961863f33338e20a0d7f02021b80844905`. |
| TLS route | `/v1/match/*` at `https://alpha-api.159.54.158.4.sslip.io`; [justread PR #33](https://github.com/danybgoode/justread/pull/33) independently reviewed, merged as `acb88415a86c`, and applied using `/opt/panfleto/deploy/update.sh`. Caddy config validated in its running container. The adjacent panfleto landing/reader and Miyagi site returned HTTP 200 after deployment; match state without a token returned 401. |
| Data | Distinct least-privilege match and retention database roles. Migration 005 adds 30-day live audit/match/invite/tombstone expiry and transaction-locked withdrawal. Postgres 17 suite 31/31 passed. First retention service run deleted zero rows; daily timer active. A disposable backup restore passed before live invitations. |
| Admission | `multiplayer.private_match_enabled` was enabled only in Golden Frijoles preview for bounded internal runs. After the post-deploy regression, preview was set off (served version 9), development and production stayed off (version 1), and the match process was restarted. A current-version join returned 403 `match_disabled`. All twelve internal codes were revoked and their plaintext files deleted. |
| Notice | Restricted participant notice names `miyagi@despachobonsai.com` and 30-day live private-match retention; backups expire after 30 days. |

## Remote sessions

| Run | Setup | Observed result | Limit |
| --- | --- | --- | --- |
| Baseline terminal | Two distinct scoped codes and HTTP clients from macOS through TLS to the ARM64 VM; native macOS Godot clients joined both sides. | One authoritative record, district result `[win, loss]` at tick 1,940, hash `c5fd4674cc292cbd021ce0a2ac2478ced4f40468827f8d8aa3156cb9f16f751a`. Both participant HTTP replays verified all 195 frames with enemy fog redacted; two native Godot replay clients opened their own first frame. | Scripted play and two native clients on one Mac; no full native two-device GUI battle. |
| Cross-OS join and recovery | Native macOS Godot side 0 and official Godot 4.7.2 Linux ARM64 side 1 in a capped VM container. | Both joined. A reconnect restored the same slot and next order index, invalidated the old token, and acknowledged a duplicate order without applying it twice. After the Mac was intentionally idle for 60 seconds, both clients saw `no_result` / `reconnect_expired` at tick 888. Database contained zero match records for that session. | This checks native cross-OS join/recovery, not a terminal battle. |
| Cross-OS terminal | A macOS Godot client and a separate Linux ARM64 Godot client in the capped VM container used two distinct invite codes over Restricted TLS. Scripted orders gathered, built, trained and moved fighters. | Both clients reported tick 1,025, the identical terminal hash `ba6430fdf16e39d41b8d44f93d49b73b371a82fdeba3bc4b4a1331a8ffea0ef1`, and `[win, loss]`. Each participant's HTTP replay verified all 104 frames with fog redacted. | Headless scripted clients; the downloaded native GUI owner walkthrough and impaired cross-OS terminal run remain open. |
| Optimized post-deploy cross-OS terminal | macOS and Linux ARM64 Godot clients used fresh separate codes over Restricted TLS against `aomx-match:2ad3d65` at 1.0 CPU. | Both reported tick 1,028, identical hash `b3b5e32546f1abbe69de9884bc1a6b5ade49755eb90b3d350128806c5ac65872`, and `[win, loss]`. Each participant replay verified all 104 frames with fog redacted. The database stored one two-participant record; the first failed join attempt ended `reconnect_expired` with no terminal record. The observed live container was healthy at 91.4 MiB and 6.37% CPU in a sample, with 545 kB received / 2.22 MB sent. | Headless scripted clients; one Linux code file initially lacked read permission under the container UID, then fresh unclaimed codes and a service reset completed the run. The impaired cross-OS terminal run and downloaded GUI owner walkthrough remain open. |
| Impaired terminal | Two separate logical, invite-bound Node clients inside one disposable Linux ARM64 container; its own network namespace used `tc netem delay 150ms loss 1%`. | District result `[win, loss]` at tick 1,502, hash `cd81915d23e3f32f224d42f3ce9b0d500fc935061632292aba2a21ecbbbe8f49`. Both participant HTTP replays verified all 152 frames with fog. `tc` counted 729 sent packets and 6 drops. | This was 150 ms **egress** delay, approximately 150 ms RTT, not a symmetric RTT profile. Both logical clients shared a Linux container, so it does not satisfy the two-device condition. |

The server created one terminal record for each completed session, with two participant results and a 64-character record hash. No completion record was created for the expired recovery session. These are server records; the existing ingest still treats client reports as `client_reported` and none of this traffic establishes public retention or an eligible cohort.

## Native large-army performance gate

The existing `game/tests/skirmish_scale_benchmark.gd` fixture was rerun on the current reviewed image, with its synthetic 48×48 map, 162 entities, 800 ordered moves and 300 ticks. Godot 4.7.2 produced the **same** final hash on macOS and native VM Linux ARM64: `d908d43b4e32fb873bdb3041e0f4d4c8796fc41a46853e57d6601a5524457ffa`. The declared p95 route/tick budgets are 12/8 ms.

| Environment | Route p95 | Tick p95 | Budget result |
| --- | ---: | ---: | --- |
| Apple M2 Max, macOS, headless debug | 6.424 ms | 7.427 ms | Both pass |
| Oracle ARM64 VM, same image, 768 MiB / **0.75 CPU** live service cap in a disposable container | 37.036 ms | 30.656 ms | Both fail |
| Same VM/image, 768 MiB / **1.5 CPU** diagnostic cap in a disposable container | 12.275 ms | 17.332 ms | Both fail |

At the live 0.75 CPU cap, the 82-entity crowded case also failed its 6/4 ms route/tick budgets (13.656/10.118 ms); the nine-entity baseline passed. The diagnostic 1.5 CPU run did not change the live service. The 48×48 fixture is larger than playable La Roma and runs all ticks back to back, so this is a **synthetic stress failure**. It does not by itself describe the playable population ceiling or a real 10 Hz match.

The follow-up optimization keeps all 162 entities, 800 orders, 300 back-to-back ticks, fixture budgets and final hash unchanged. It caches same-tick move routes until navigation changes, indexes live occupancy during movement, avoids redundant breadth-first visits, and skips sight-mask rebuilding when observer positions are unchanged. A new skirmish check covers building placement invalidating a cached route. The native ARM64 results from disposable containers were:

| Source and CPU cap | Route p95 / 12 ms | Tick p95 / 8 ms | Result |
| --- | ---: | ---: | --- |
| Reviewed `834295f`, 0.75 CPU | 37.036 ms | 30.656 ms | Fail |
| Optimized candidate, 0.75 CPU | 5.237 ms | 14.017 ms | Tick fails |
| Optimized candidate, **1.0 CPU** | **5.229 ms** | **4.170 ms** | Both pass |

The unchanged 82-entity 6/4 ms case also passed at 1.0 CPU (2.221/2.239 ms). The optimized macOS run retained the 162-entity final hash and passed at 2.700/1.849 ms. The 1.0 CPU cap leaves one of the VM's two cores available to other services at quota. The initial candidate source and fixture were copied to the VM and bind-mounted read-only over the prior image in isolated containers. [Machine-readable run provenance](fixtures/multiplayer-large-army-2026-10-20.json) records their SHA-256 values. After review and merge, the unchanged suite ran **directly inside final image `aomx-match:2ad3d65`**, without mounts, at the deployed 1.0 CPU cap: 162-entity route/tick p95 **5.200/4.124 ms**, same final hash. The live container then became healthy with admissions off before the bounded cross-OS run.

The current La Roma content has a 28×28 map and a 24-population cap per side. A second profile used 46 fighters plus the two starting workers and two command posts (50 entities), 500 accepted orders and 300 ticks. macOS and native ARM64 matched hash `ab970c0fcdcd8f5b5f735ba3ca04d01c7d52300118d22c08e7613068f8ac6578`. With tick starts paced at the actual 100 ms interval, the **live 0.75 CPU cap passed** the same 12/8 ms route/tick p95 budgets (3.738/4.800 ms). A back-to-back 300-tick burst exceeded the tick budget in all three capped VM repeats (p95 23.779–27.664 ms), consistent with CPU-quota throttling; a disposable 1.5 CPU run passed (4.353 ms). See [machine-readable runs](fixtures/multiplayer-capacity-2026-10-20.json). This profile measures the unit population cap, not an upper bound on buildings, network bandwidth or two-device latency.

Reproduction uses game/image source `834295f` and the newer opt-in benchmark fixture from `c7c7cfc` (SHA-256 in the JSON). The fixture was copied from this checkout to the VM at `/tmp/aomx-capacity-benchmark-20261020.gd` and **bind-mounted read-only** over the older image's fixture; the game and Godot binary in the image were not replaced. On macOS, run `AOMX_BENCH_PROFILE=live_capacity_paced "$GODOT_BIN" --headless --path game --script res://tests/skirmish_scale_benchmark.gd`. On the VM, run:

```sh
docker run --rm --network none --read-only --tmpfs /tmp:size=64m \
  --memory 768m --cpus 0.75 --pids-limit 64 --cap-drop ALL \
  --mount type=bind,src=/tmp/aomx-capacity-benchmark-20261020.gd,dst=/app/game/tests/skirmish_scale_benchmark.gd,readonly \
  --entrypoint /usr/local/bin/godot -e AOMX_BENCH_PROFILE=live_capacity_paced \
  aomx-match:834295f --headless --path /app/game \
  --script res://tests/skirmish_scale_benchmark.gd
```

## Restricted client artifact

The signed macOS export from `834295f3e0f9` is `preview-834295f3e0f9`, archive `dist/alpha/battle-for-la-roma-preview-834295f3e0f9-macos.zip`, SHA-256 `d95ba318d60d90ef256149ebd37448b735f8e98ba0f6edc2e1fc961895fb034a`. Full export QA and strict local code-signature verification passed. It was uploaded to the owner-only itch channel `danybgoode/battle-for-la-roma:mac-private-alpha` as Butler build `#2171274`; Butler later marked it ready. An authenticated independent `butler fetch` extracted the app; its files matched a fresh extraction of the source ZIP, strict `codesign --verify --deep` passed, and the downloaded executable exited cleanly after a headless startup. The anonymous page returned 404 before upload. This build predates the 162-entity optimization and must be superseded by a matching host/client release. The downloaded visual owner walkthrough remains open.

The matching merged-source export is `preview-2ad3d65a3d80`, archive `dist/alpha/battle-for-la-roma-preview-2ad3d65a3d80-macos.zip`, SHA-256 `a2c183dc8cc97e208dbb98feaed0f7d81cefc1c3f8605a49e58c6e7f23de8b60`. Its manifest pins both HTTPS endpoints and game/content versions, and the export pipeline passed its Godot, Node, multiplayer integration, replay, contract, benchmark and strict local signature checks. A GUI launch of an extraction of this source archive rendered the setup, faction selection, live match HUD, the exact build ID in its menu, and the private-match invite field and join button. Butler accepted it on the owner-only `mac-private-alpha` channel as build `#2173082`. At this update it was still processing; independent fetch, signature/startup and rendered walkthrough on the downloaded copy are open. The itch page still returned HTTP 404 anonymously after upload.

## Web feasibility finding

A browser preflight from `http://localhost:8000` to the match join route returned HTTP 404 without `Access-Control-Allow-Origin` on the current Caddy/host deployment. A locally served Web export therefore cannot join the Restricted host from that origin. Web export creation alone is not browser-play evidence. A deliberate hosted origin and reviewed CORS policy are needed if Web play is included in this Restricted slice.

## Open acceptance checks

- Complete the representative population-cap network matrix across macOS and native Linux, including baseline, 100 ms RTT and symmetric 150 ms RTT/1% loss, with pinned command bursts, first divergence, CPU, memory and bandwidth. Resolve the Web-origin/CORS feasibility finding if Web play is included. Measure additional buildings.
- Full native macOS/Linux impaired terminal match from separate client processes/devices; repeat an in-window reconnect and a post-terminal retry on the deployed optimized image.
- Download the processed owner build, verify signature and startup independently, then run the numbered visual walkthrough for playback/pause, bad replay handling, no-result wording, excluded in-app outbox receipt and revocation.
- Product owner repeats the walkthrough blind before any second-person invitation. No later-day completion baseline exists.
