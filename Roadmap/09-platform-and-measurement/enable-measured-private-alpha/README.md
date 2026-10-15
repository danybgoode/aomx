---
status: in-progress   # AUTHORITATIVE epic status (SSOT) — scaffolded | in-progress | shipped | archived. Set shipped at epic close.
phase: Building       # the executive ladder — Shaping | Locking architecture | Building | Verifying | In review | Shipped.
                     # WRITTEN at each cadence event, never inferred. Shipped = merged AND deployed.
slug: enable-measured-private-alpha
destination: trusted-launch-measurement
title: "Enable a measured private alpha"
area: 09-platform-and-measurement
risk: high
type: feature
sprints_total: 3
stories_total: 7   # the sum of every sprint's stories_total — keep it in step when a story is added
intent_match: null   # copied from the seed by scaffold-epic (intent-match); the reader at the lock may update it
quote_low_usd: 20    # ≈ API $ — copied from the seed's `quote:` by scaffold-epic (finops); null = not quoted, never 0
quote_high_usd: 120
quote_basis: "M, n=0, wide"
hypothesis: "Invited RTS players need an installable solo match whose offline results form a trustworthy cohort. We will know this works when a downloaded match, later-day return, duplicate and rejected path reconcile in Golden Frijoles, with test traffic excluded."   # the result record — copied from the seed by scaffold-epic; null = no target (never an error)
target_metric: null   # no numeric improvement target before the first observed baseline
target_from: null   # from what, a number
target_to: null       # to what, a number
read_date: null       # YYYY-MM-DD; null = 30 days after shipping, derived by the extract and never written back
verdict: null        # proven | disproven | unclear — stamped by `node scripts/epic-read.mjs --epic <slug> --write`
verdict_actual: null
verdict_evidence: null   # https:// link · north-star:<input>@YYYY-MM-DD · ab:<experiment> (unclear: the reason)
verdict_at: null
persona: "An invited classic RTS player installing and finishing a solo match, and the operator checking the first cohort."   # for whom, doing which job — copied from the seed (grounded-bets D1)
grounded: false   # true = traced to a North Star input · false = funded anyway (reason below) · null = Bug/Chore or never asked
grounded_reason: "This enables the agreed North Star inputs, but no eligible cohort or observed baseline exists from which to set an improvement target."   # only with grounded: false
flag_key: telemetry.play_funnel_enabled   # the epic's flag, decided at refine Stage 6b and copied from the seed; null = no flag. The epic page shows its state
target_segment: everyone   # the bet's measurement (one-bet-wired D1), copied from the seed: TARS target segment
adopted_event: match_result_synced
retained_event: later_day_match_completed
retention_days: 7
satisfied_event: null
build_order: 4       # integer position in the ONE global build sequence — the SSOT once the epic
                     # exists (the seed's value is only a fallback). Fill it in at the betting
                     # table; plain integers, no "#2a" suffixes. See 00-ideas/README.md → Ordering.
---

# Epic: Enable a measured private alpha

> **Area:** 09-platform-and-measurement · **Risk:** high · **Class:** Feature · **Scope seed:** [`00-ideas/seeds/enable-measured-private-alpha.md`](../../00-ideas/seeds/enable-measured-private-alpha.md)

## Why

An invited classic RTS player needs a complete game they can install and revisit. This epic makes the existing Godot solo match a small macOS alpha whose offline results can become an auditable first cohort. The first observed later-day completion baseline remains unknown until eligible players finish and their seven-day windows mature.

## Platform-first note

Golden Frijoles remains the flag, roadmap and input-reading destination. The game owns the offline outbox; the aomx service owns accepted-event decisions and durable receipts in a dedicated Postgres container on the existing Oracle VM. Its networks, credentials, storage, backup bucket and resource limits are separate from panfleto. No database credential or Golden Frijoles secret enters a game export.

## Architecture lock — 2026-10-14

The approved bet is still valid, but the live repository disproves parts of the generated builder kickoff: the default branch is `master`, a merge has no deploy effect, and `session-resume.mjs`, `epic-phase.mjs`, `intent-reader.mjs`, and `review-route.mjs` are not installed here. The existing local JSONL service is synchronous, loopback-only and exposes audit/report routes without authentication. These must not be put on a public interface. This lock records the build contracts in their place; any later kit sync must preserve these decisions.

| Decision | Contract and evidence |
| --- | --- |
| D1 · Keep one event policy | Reuse `src/funnel/ingest.mjs` validation and `src/funnel/report.mjs` derivation. The hosted adapter serializes decisions in a Postgres transaction and persists the same rows/receipts. DB constraints enforce event and match uniqueness; no divergent acceptance implementation. |
| D2 · Keep credentials server-side | The game export contains only a versioned HTTPS ingest URL and a public build channel. The hosted service alone holds Postgres and Golden Frijoles credentials. Public HTTP exposes event upload and a non-sensitive health result; operator audit and reports remain private commands. |
| D3 · Release identity and eligibility | Internal/debug builds remain test-tagged. A release build may emit eligible events only after the server flag is enabled for that player. Stable installation identity, event IDs and sequence persist through offline retry. Supported rule/content versions are explicit server configuration. |
| D4 · Recovery precedes invitation | An isolated VM Postgres container, least-privilege role, Oracle capacity check, HTTPS route, independent daily logical backup, disposable restore, disk alerts and second data/security review are gates before any real invitation. The owner changed the database choice on 2026-10-14 after Supabase refused a third active Free project. |
| D5 · Publishing is append-only | Final, covered days are reconciled from the durable audit before a verified aomx-scoped push. A late mismatch stops publication and enters a reviewed correction/backfill record; immature days remain pending. No fixture values enter production. |
| D6 · External release waits | The approved bet explicitly places first invitations after the La Roma objective playtest and owner approval of notice, invitation and production flag. Building the service does not authorize those external changes. |
| D7 · One-Mac alpha QA | On 2026-10-14 the owner waived the separate-Mac install check because no other Mac is available. Verify a freshly downloaded, quarantined app on the owner Mac, including a valid ad hoc signature, Gatekeeper path, gameplay, restart and offline recovery. Record the single-machine coverage limit. |

### Execution log — 2026-10-14

- Supabase refused a third active Free project. The owner chose isolated VM Postgres; an aomx-specific private OCI backup bucket was provisioned. No Supabase project or paid upgrade was made.
- The existing Oracle VM had about 10 GB available memory and 45 GB free `/data` space before aomx services. Panfleto occupies its own compose project. The aomx service is being staged as a separate project and network.
- The official Godot 4.7.2 export template SHA-256 matched the release digest `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`. Headless game and Node tests passed locally, including a disposable Postgres invite/receipt test. A preview ZIP was produced; fresh-install and second-Mac verification are still owed.
- Butler 15.32.0 runs on macOS. The `danybgoode/battle-for-la-roma` itch.io project was created as **Draft** with a development status and AI-code disclosure. No player access key, invitation or production flag change was issued.
- Commit `12be123fe3ec` passed the [Private alpha contract CI](https://github.com/danybgoode/aomx/actions/runs/38625290617). The preview ZIP SHA-256 is `c99fd9ffbc27c3742b2cc416514ce8530bea2417d095cd9d0b3875517cb8451c`; its freshly extracted app launched headlessly on the builder Mac. The ZIP is uploaded to itch.io's `mac-private-alpha` Butler channel. The Draft page now has a cover, install text and graphics/code AI disclosures. A second-Mac downloaded play/restart test is still owed.
- VM staging uses a separate `aomx` Compose project, Postgres 17 container, private OCI bucket `aomx-backups`, three enabled systemd timers, and HTTPS `https://alpha-api.159.54.158.4.sslip.io` allowlisted to the current operator workstation. The preview flag remains off. Internal HTTPS smoke showed a missing invite rejected, a stable duplicate receipt, three excluded flag-off events, and an unsupported version rejected; no public event was accepted. The internal smoke invite was revoked and a later request returned 401.
- An OCI dump after that smoke restored into `aomx_restore_test` with matching counts: 4 audit events, 0 observed days, 3 report snapshots, 0 publications. Object `aomx/db/aomx-2026-10-14T22-46-36.901Z.dump`, SHA-256 `09a4e118b5602eacd63ca583b3c9bbac7132e402953fe595729d34821f15542b`. Health, backup and report services each ran once successfully. An owner-controlled external alert sink and a game outage/recovery rehearsal remain open.
- Panfleto's next `update.sh` resets its tracked Caddyfile. The running aomx route is therefore temporary until [sibling deployment PR #29](https://github.com/danybgoode/justread/pull/29) is independently reviewed, merged and deployed. The PR preserves panfleto's default network and adds only `aomx_proxy` to Caddy. No external invitation or flag change is authorized by the staging checks.
- Independent review found that rejected events blocked later outbox sync, unsupported/quarantined opens could claim an invite, restore testing used the local dump, rate limits grouped all proxy users, and publication compared only rounded values. The branch now continues past retained rejected events, claims only accepted/excluded opens, downloads and hashes the OCI object before restore, limits by invite with a separate global cap, and compares raw reading counts under the ingest/coverage publication lock. The additive publication migration ran on VM staging. These fixes require final CI and reviewer recheck before merge.
- A fresh off-project download and restore passed for `aomx/db/aomx-2026-10-14T22-52-11.594Z.dump` (SHA-256 `f2326e0439b46366a280e56990fa7056746fbcea35bb06641fcb2bf840b2af60`): source and restored counts both had 4 audit events, 0 observed days, 3 report snapshots, 0 publications. The page was still Draft at that point. No download keys were created.
- Reviewer recheck found two more release paths: a quarantined open needed a fresh event after correcting the device clock, and a stalled remote publication could hold the ingest lock. A same-day restart now queues a new open after an attention receipt; the publisher passes one 20-second abort signal through the SDK fetch implementation for the entire locked batch. The Godot outbox recovery check passed. Neither a production reading nor real invite has been sent.
- The final candidate from commit `623713e89326` is Butler build `#2128881` on the `mac-private-alpha` channel. ZIP SHA-256 `8d64e67d931a3499058312ea1909d1002ec2956e94700e26e98b36c639f400c8`; a fresh extraction launched headlessly on the builder Mac. [CI](https://github.com/danybgoode/aomx/actions/runs/38650773406) and the independent recheck passed. [Draft PR #11](https://github.com/danybgoode/aomx/pull/11) targets the preceding skirmish branch; Golden Frijoles roadmap version 8 records this epic as **In progress / Building**, 0/7 stories complete.
- An isolated ingest outage rehearsal stopped only `aomx-ingest`, queued three test-tagged events offline, restarted the container, and synced three excluded receipts. A duplicate kept its receipt. The temporary invite was revoked. The final OCI object `aomx/db/aomx-2026-10-14T22-59-58.604Z.dump` (SHA-256 `2a06385065513b85ad89b64f20e3e2cac3338ddd288a2d9984b314ae7b5790e0`) was downloaded and restored into a disposable database: source and restored counts matched at 7 audit events, 0 observed days, 4 reports and 0 publications. The dry-run publisher found no mature days or pending numeric pushes.
- After the owner explicitly approved Restricted visibility, the itch.io page at `https://danybgoode.itch.io/battle-for-la-roma` was saved as **Restricted**. Anonymous access returned 404. The owner downloaded Butler build `#2128881`; its extracted executable and PCK hashes matched the fresh local export. No second-account key or invitation exists. `security find-identity -v -p codesigning` found zero valid identities on the builder Mac, so signing remains a release decision. A second-Mac install/play/restart, named alert destination, participant notice, La Roma objective and live publisher-key verification remain release gates. The preview flag is off; no numeric production metric was pushed.
- The owner reported that the downloaded app was labeled damaged by macOS. `codesign --verify --deep --strict` proved both the downloaded and local archive had an invalid signature: the export preset disabled code signing. The preset now uses Godot's built-in ad hoc signing, and `alpha:export` checks the extracted ZIP's signature. The owner waived the separate-Mac check; a newly downloaded build must pass the [local QA walkthrough](../../../docs/alpha-local-qa.md). The owner named `daniel@despachobonsai.com` for failure alerts and tester support; the alert subscription still needs provisioning and confirmation.
- Signed preview `preview-1cf1e6843e3b` was uploaded as Butler build `#2129045` on the Restricted `mac-private-alpha` channel. Its ZIP SHA-256 is `02c2f976f52c2342c70a53bbd1d2afdd56ed95657a667ae6e9eb4c8d905ad46c`. The owner downloaded it through itch.io; `codesign --verify --deep --strict` passed on the quarantined app and its executable/PCK matched the fresh export. After adjusting macOS privacy settings, the owner opened the app and observed the opponent playing. Gameplay result, restart and offline sync remain to be recorded. The first play report exposed unclear economy instructions: Resource starts at 0, a worker must right-click the gold source, and a recruitment post costs 6. The [QA walkthrough](../../../docs/alpha-local-qa.md) now gives those steps.
- An OCI Notifications topic was created in a dedicated `aomx-alpha-alerts` compartment. An EMAIL subscription for `daniel@despachobonsai.com` is **pending owner confirmation**. The Oracle VM published a test message to the topic through an instance-principal grant scoped to that compartment. The new health alert code still needs deployment and an end-to-end delivered-email check after confirmation.
- The owner confirmed the OCI email subscription; OCI now reports it **ACTIVE**. VM alert code and the topic/state configuration were installed in the aomx health service. Its manual run passed with `issues: []`; an additional VM publish to the active subscription returned message ID `63467fc4-743a-5cd6-6cd0-0daea1a3bb9e`, and the owner confirmed the test email arrived. The owner approved one internal, test-only invite labeled `owner_qa_20261014`; its code is stored privately on the VM, never in the repository, and must be revoked after owner sync QA. The production flag remains off.
- First-play feedback led to clearer build guidance in the game: pressing B below the 6-resource cost now instructs the player to gather gold, and the HUD labels distinguish stockpile from remaining gold. Updated preview `preview-9692d809fd9b` passed all 14 Node tests, four Godot suites, Godot-to-Node contract and extracted-app signature verification. ZIP SHA-256 `a7e2f4b05444bd479958bfb185365d65027844ceabacda453aead6524820fea0`; Butler build `#2130146` is processed on the Restricted channel. An owner download and playthrough of this new version are still owed.

### Sprint build contracts

1. **S1:** Pin Godot 4.7.2 and templates; export a versioned macOS ZIP with manifest/checksum and no credentials; run headless, signature and fresh-export checks. Prepare installation/support and restricted distribution instructions. A fresh download and gameplay on the owner Mac, plus keyed access independent of the creator session, still require verification.
2. **S2:** Add transactional Postgres persistence, safe public HTTP, isolated Docker/Caddy deployment assets, environment-specific client endpoint and backup/restore/monitoring commands. Exercise deterministic and disposable-DB checks locally; verify live capacity and staging before deployment.
3. **S3:** Reconcile mature covered cohorts and verify aomx project identity before any numeric push. Provide operator commands and a correction stop path. Real cohort and external invitation remain gated by the approved product sequence and live review.

## What already exists (reuse, don't rebuild)

- [`game/skirmish_main.gd`](../../../game/skirmish_main.gd) and [`game/funnel_outbox.gd`](../../../game/funnel_outbox.gd) provide a finishable local match and ordered offline events.
- [`src/funnel/ingest.mjs`](../../../src/funnel/ingest.mjs), [`src/funnel/http.mjs`](../../../src/funnel/http.mjs) and [`scripts/funnel-report.mjs`](../../../scripts/funnel-report.mjs) provide validation, local receipts and cohort logic.
- The [funnel contract](../../../docs/launch-funnel-contract.md) and [North Star](../../00-strategy/north-star.md) define event eligibility, deduplication and mature readings.
- `telemetry.play_funnel_enabled` already exists in Golden Frijoles `aomx`, serving off in all environments.
- The owner's sibling `fluxonline/deploy/` demonstrates Oracle VM, Docker, Caddy and OCI object backup operations. This epic creates isolated aomx resources on that VM.

## Approved boundaries

- **Audience and order:** Start with invited macOS classic RTS players. Build this after the current funnel/core/skirmish draft stack, before the distinctive La Roma playtest; invite testers only when the game objective and measurement walkthrough are ready.
- **Database:** Use dedicated VM Postgres with a private aomx network and loopback-only operator port. Monitor the agreed 500 MB alpha planning quota and VM disk. Keep the outbox retryable through outages.
- **Recovery:** Before real invitation, prove daily logical export to OCI Object Storage and a restore into a disposable database. A missed backup, pause warning, sustained ingest failure or 80% quota use stops new invitations until an operator resolves it. Alert at 50% quota use.
- **Spend:** No paid database upgrade is authorized by this bet. Revisit the plan if capacity, pause or recovery burden affects the cohort.
- **Trust:** The server validates version, identity, sequence, match transition, time confidence and available integrity evidence. Until replay validation exists, accepted results are labeled `client_reported`; test, bot, tutorial, quarantined and rejected traffic stays out of public cohorts.
- **Release:** A restricted distribution page and a repeatable game export are required. The owner waived a separate-Mac check; test the quarantined download and Gatekeeper behavior on the owner Mac before invitation. Do not claim a merge to `master` is a release.

## Scope — stories

| Sprint | Player or operator result | Stories | Risk |
| --- | --- | --- | --- |
| [1 · Package the first desktop build](sprint-1.md) | A known macOS build installs and completes a solo match; the restricted page is ready. | S1.1–S1.2 | Low export; high distribution |
| [2 · Host accepted ingest and durable audit](sprint-2.md) | Offline uploads reach a recoverable aomx audit through HTTPS on isolated services. | S2.1–S2.3 | High |
| [3 · Reconcile and invite a small cohort](sprint-3.md) | Accepted results produce reviewed Golden Frijoles readings and a limited invited release. | S3.1–S3.2 | High |

## Deploy order

Keep `telemetry.play_funnel_enabled` off while building and rehearsing. First make and inspect a reproducible macOS export, without inviting players. Then migrate the audit to isolated VM Postgres, establish backups/restore and start the isolated service behind HTTPS. Point a test-tagged build at staging and prove offline retry and exclusions. Sprints 1–2 and Story 3.1 can finish before the [La Roma playtest](../../00-ideas/seeds/prove-la-roma-promise.md); Story 3.2's invitation waits for that distinctive objective. This is the per-sprint dependency exception to epic-mode execution. Only after a second data/security review, approved participant notice, aomx key verification and release smoke should the owner authorize invitations and the production flag switch. The cohort read follows its real seven-day maturity; pending is not zero.

## Definition of Done (epic)

- [ ] All seven stories pass their acceptance checks, CI/headless checks and sprint smoke walkthroughs, with commit refs recorded in each sprint.
- [ ] A downloaded macOS build installs, completes and restarts a solo match; its offline events survive restart and sync with stable receipts. No project secret is bundled.
- [ ] The separate aomx service and VM Postgres audit survive restart; a daily off-project backup and disposable restore pass. Capacity, quota, write failure and backup alerts have a named operator response.
- [ ] Duplicates, test accounts, bots, unsupported versions, incomplete matches and clock anomalies are excluded or quarantined according to the agreed contract; only accepted paths count.
- [ ] The aomx publisher key is verified, a second reviewer checks player data and reporting integrity, and four mature readings reconcile with raw events. Immature cohorts remain pending; the first observed baseline is reported only when real windows mature.
- [ ] The served Golden Frijoles flag state is checked in every environment; production eligibility changes only after the approved walkthrough. The owner approves the participant notice and external invitation.
- [ ] The deployed build is smoke-tested at the actual distribution and ingest endpoints. The sprint docs, product poster, learnings and retrospective reflect the outcome; mark `status: shipped` only after review, merge, release and verification.
