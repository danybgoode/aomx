# Restricted multiplayer remote QA — 2026-10-20

This is builder evidence for the owner-only Restricted preview. It does not close the epic or establish a player cohort. No external participant was invited. The [numbered owner walkthrough](../Roadmap/03-multiplayer-and-retention/prove-multiplayer/sprint-3.md#sprint-3--smoke-walkthrough) remains to be run blind on the downloaded build.

## Reviewed source and deployed services

| Item | Observed evidence |
| --- | --- |
| Game source | `master` `834295f3e0f9`, after reviewed [PR #56](https://github.com/danybgoode/aomx/pull/56), [PR #57](https://github.com/danybgoode/aomx/pull/57), and [PR #58](https://github.com/danybgoode/aomx/pull/58); Project checks and CodeQL passed. |
| Match host | Native Oracle Linux ARM64 image `aomx-match:834295f` on the existing Oracle VM, capped at 768 MiB, 0.75 CPU, read-only root, no added capabilities; container health passed. A 1,000-tick worker hash matched macOS and local Linux: `4d6266cbe25b249d14570136fecc20961863f33338e20a0d7f02021b80844905`. |
| TLS route | `/v1/match/*` at `https://alpha-api.159.54.158.4.sslip.io`; [justread PR #33](https://github.com/danybgoode/justread/pull/33) independently reviewed, merged as `acb88415a86c`, and applied using `/opt/panfleto/deploy/update.sh`. Caddy config validated in its running container. The adjacent panfleto landing/reader and Miyagi site returned HTTP 200 after deployment; match state without a token returned 401. |
| Data | Distinct least-privilege match and retention database roles. Migration 005 adds 30-day live audit/match/invite/tombstone expiry and transaction-locked withdrawal. Postgres 17 suite 31/31 passed. First retention service run deleted zero rows; daily timer active. A disposable backup restore passed before live invitations. |
| Admission | `multiplayer.private_match_enabled` was enabled only in Golden Frijoles preview for bounded internal runs. Afterward preview was set off (served version 5), development and production stayed off (version 1), and the match process was restarted. A version-correct join then returned 403 `match_disabled`. All six internal codes were revoked and their plaintext files deleted. |
| Notice | Restricted participant notice names `miyagi@despachobonsai.com` and 30-day live private-match retention; backups expire after 30 days. |

## Remote sessions

| Run | Setup | Observed result | Limit |
| --- | --- | --- | --- |
| Baseline terminal | Two distinct scoped codes and HTTP clients from macOS through TLS to the ARM64 VM; native macOS Godot clients joined both sides. | One authoritative record, district result `[win, loss]` at tick 1,940, hash `c5fd4674cc292cbd021ce0a2ac2478ced4f40468827f8d8aa3156cb9f16f751a`. Both participant HTTP replays verified all 195 frames with enemy fog redacted; two native Godot replay clients opened their own first frame. | Scripted play and two native clients on one Mac; no full native two-device GUI battle. |
| Cross-OS join and recovery | Native macOS Godot side 0 and official Godot 4.7.2 Linux ARM64 side 1 in a capped VM container. | Both joined. A reconnect restored the same slot and next order index, invalidated the old token, and acknowledged a duplicate order without applying it twice. After the Mac was intentionally idle for 60 seconds, both clients saw `no_result` / `reconnect_expired` at tick 888. Database contained zero match records for that session. | This checks native cross-OS join/recovery, not a terminal battle. |
| Impaired terminal | Two separate logical, invite-bound Node clients inside one disposable Linux ARM64 container; its own network namespace used `tc netem delay 150ms loss 1%`. | District result `[win, loss]` at tick 1,502, hash `cd81915d23e3f32f224d42f3ce9b0d500fc935061632292aba2a21ecbbbe8f49`. Both participant HTTP replays verified all 152 frames with fog. `tc` counted 729 sent packets and 6 drops. | This was 150 ms **egress** delay, approximately 150 ms RTT, not a symmetric RTT profile. Both logical clients shared a Linux container, so it does not satisfy the two-device condition. |

The server created one terminal record for each completed session, with two participant results and a 64-character record hash. No completion record was created for the expired recovery session. These are server records; the existing ingest still treats client reports as `client_reported` and none of this traffic establishes public retention or an eligible cohort.

## Native large-army performance gate

The existing `game/tests/skirmish_scale_benchmark.gd` fixture was rerun on the current reviewed image, with its synthetic 48×48 map, 162 entities, 800 ordered moves and 300 ticks. Godot 4.7.2 produced the **same** final hash on macOS and native VM Linux ARM64: `d908d43b4e32fb873bdb3041e0f4d4c8796fc41a46853e57d6601a5524457ffa`. The declared p95 route/tick budgets are 12/8 ms.

| Environment | Route p95 | Tick p95 | Budget result |
| --- | ---: | ---: | --- |
| Apple M2 Max, macOS, headless debug | 6.424 ms | 7.427 ms | Both pass |
| Oracle ARM64 VM, same image, 768 MiB / **0.75 CPU** live service cap in a disposable container | 37.036 ms | 30.656 ms | Both fail |
| Same VM/image, 768 MiB / **1.5 CPU** diagnostic cap in a disposable container | 12.275 ms | 17.332 ms | Both fail |

At the live 0.75 CPU cap, the 82-entity crowded case also failed its 6/4 ms route/tick budgets (13.656/10.118 ms); the nine-entity baseline passed. The diagnostic 1.5 CPU run did not change the live service. This fixture uses a synthetic map larger than the shipped La Roma map and measures local rules, not network command or render latency. It reveals a **failed declared scale gate**, so no claim of representative large-army reliability or external invitation follows from the successful small-match smokes. A measured optimization or explicitly narrowed Restricted army limit needs a product decision and repeatable evidence.

## Restricted client artifact

The signed macOS export from `834295f3e0f9` is `preview-834295f3e0f9`, archive `dist/alpha/battle-for-la-roma-preview-834295f3e0f9-macos.zip`, SHA-256 `d95ba318d60d90ef256149ebd37448b735f8e98ba0f6edc2e1fc961895fb034a`. Full export QA and strict local code-signature verification passed. It was uploaded to the owner-only itch channel `danybgoode/battle-for-la-roma:mac-private-alpha` as Butler build `#2171274`. The anonymous page returned 404 before upload. At this record's initial writing, Butler was still processing the build; a ready channel, independent fetch, downloaded signature/startup check and owner walkthrough must be recorded separately before accepting it.

## Open acceptance checks

- Resolve the failed native ARM64 large-army p95 gate, then complete the network matrix across macOS, native Linux and Web, including baseline, 100 ms RTT and symmetric 150 ms RTT/1% loss, with pinned command bursts, first divergence, CPU, memory and bandwidth.
- Full native macOS/Linux two-player terminal match, both baseline and impaired, from separate client processes/devices. Repeat an in-window reconnect and a post-terminal retry.
- Download the processed owner build, verify signature and startup independently, then run the numbered visual walkthrough for playback/pause, bad replay handling, no-result wording, excluded in-app outbox receipt and revocation.
- Product owner repeats the walkthrough blind before any second-person invitation. No later-day completion baseline exists.
