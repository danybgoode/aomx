# Launch funnel event contract (v1)

The local contract uses a loopback Node service with a durable JSONL audit log. A separate private-alpha adapter now uses isolated Postgres on the Oracle VM, serialized transaction decisions, invite codes and HTTPS through Caddy. Both call the same event validation and report code. Golden Frijoles holds the enablement flag and four derived daily input readings; the game never receives those credentials. Hosted accepted results remain `client_reported` because replay verification is not yet implemented.

## Record

`POST /v1/events` accepts one JSON record:

```json
{
  "schema_version": 1,
  "type": "match_completed",
  "event_id": "example_event_0003",
  "player_id": "example_install_0001",
  "match_id": "example_match_0001",
  "claimed_at": "2026-10-01T12:30:00.000Z",
  "local_sequence": 3,
  "game_version": "prototype-0",
  "content_version": "original-0",
  "mode": "solo",
  "faction": "neutral",
  "test_account": true,
  "bot": false,
  "result": "win"
}
```

`type` is `game_opened`, `match_started`, `match_completed`, or `campaign_mission_completed`. The client persists the stable pseudonymous installation ID, a unique event ID, and a strictly increasing local sequence before acknowledging play. Calling the Node outbox's ordinary `queue('game_opened')` after restart reuses the first-open event; an intentional later session passes `{ newSession: true }` to record a return open. The Godot client calls `queue_open_for_launch()`, which reuses a same-day open and saves a new open on a later UTC day. `match_id` is required for starts, match completions and campaign completions, and absent for opens. `result` is required for match completions (`win`, `loss`, `draw`); campaign completions require `win`. All times are claimed UTC play times; receipts add independent server `received_at`. `game_version` and `content_version` identify the client rules/content. `mode` is `solo`, `multiplayer`, `tutorial`, or `campaign`. `faction` is a bounded nonempty identifier. `test_account` and `bot` are explicit booleans.

Campaign records add `mission_id`: `arrival_copilco`, `foothold_narvarte`, or `battle_la_roma`. The first two guided missions send only a `campaign_mission_completed` adoption event after a verified local win. They cannot send eligible match start or finish events. The final mission sends `match_started`, `match_completed`, then `campaign_mission_completed` on a win; its match events are the only campaign candidates for the North Star. The server requires the current game/content pair, accepted prerequisite completions, an accepted final start and finish, a non-test non-bot actor, and ordinary funnel eligibility checks. All outcomes remain `client_reported`; the server cannot prove a replay from these events. Adoption can be accepted when the separate telemetry funnel flag is off, but the final match cannot enter the North Star unless that flag and its first open/start path are accepted.

An installation ID is a proxy for one person. Reinstalling or using another device can split a person, and a shared installation can merge people. No verified human identity exists yet.

## Receipt and audit policy

The service returns a stable receipt for the same player and event ID. It fsyncs the row before returning it. Each row retains the original event and the receipt with status, reason, receipt time, trust label, and any flag evaluation. A second result for the same player/match/type is rejected. An abandoned match has no completion. Tutorial, bot, test, and flag-off records are stored but excluded. A future claimed time over five minutes ahead of server receipt is quarantined. That threshold is a local anomaly rule, not evidence that older offline play is invalid. Offline results retain claimed and receipt time. Accepted solo outcomes are labelled `client_reported` because no versioned replay exists.

Named rejections include `malformed_event`, `unknown_field`, `unsupported_version`, `unknown_event_type`, `invalid_identity`, `invalid_match_id`, `invalid_claimed_time`, `invalid_sequence`, `invalid_game_version`, `invalid_content_version`, `invalid_context`, `invalid_actor_marker`, `invalid_result`, `unexpected_result`, `unexpected_match_id`, `event_id_collision`, `duplicate_match_event`, `missing_first_open`, `missing_match_start`, `invalid_transition_sequence`, `invalid_transition_time`, `sequence_collision`, `out_of_order_sequence`, and `match_context_mismatch`. Rejected payloads are reduced to safe identifiers in the audit rather than retaining unknown fields. A later local sequence claiming an earlier play time is quarantined as `clock_reversal`. Rejected and quarantined events never enter cohort counts. A quarantined event needs an explicit operator review path before it can be accepted; this prototype preserves it but does not yet implement that review.

## Six stage signals and readings

The six stages follow [the agreed North Star](../Roadmap/00-strategy/north-star.md): first `game_opened`, first eligible `match_started`, first `match_completed` / `first_match_completed`, later-day `game_opened`, later-day `match_started`, and later-day `match_completed` / `later_day_match_completed`. The derived names are report stage labels, not extra client event types. All dates are UTC. The cohort report counts distinct installation IDs, gives each stage's numerator and first-open denominator, marks immature seven-day windows `pending`, and keeps `no_data` distinct from a final zero. It also counts Returning commanders from two completions on distinct UTC dates inside seven days. Its mature first-completion cohort supplies the observed `return_to_match` baseline; the 15% goal remains provisional.

`new_players`, `first_match_completion`, `return_to_match`, and `match_completion` are derived daily from accepted records. The three rates use percentage points 0–100. `return_to_match` includes every first-match completer, even if that first finish occurred outside the first-open funnel's seven-day window. `match_completion` closes after the full 24-hour result window for a start day. A day with zero new players is emitted as numeric `0` only when an operator attests full ingest coverage for that closed UTC day with `npm run funnel:observe-day -- --day YYYY-MM-DD --complete`; an unobserved gap remains missing rather than inventing a zero. Report revisions are appended to a local history file; a late accepted upload can produce a correction with old and new readings. The SDK's `pushInputValues` is append-only and reports mismatched re-pushes; it does not overwrite a published day. A production correction therefore needs a reviewed backfill path that is not yet in this repository.

## Local walkthrough

Requires Node 24. From a fresh checkout:

```sh
npm ci
npm test
npm run funnel:fixtures
npm run funnel:report
npm run funnel:publish
npm run funnel:evaluations
npm run funnel:serve
```

Fixtures write `.funnel-local/fixture-audit.jsonl` and show four test-tagged accepted-for-audit events (`excluded` for public reporting), a stable retry receipt, a rejected second finish, and an unsupported-version rejection. Running the fixture command again preserves the first receipts. The default report uses `.funnel-local/audit.jsonl`; set `FUNNEL_AUDIT_PATH=.funnel-local/fixture-audit.jsonl` to inspect the fixture log. The loopback service exposes `GET /v1/audit` and `GET /v1/report`. It fails closed for real traffic if the Golden Frijoles flag provider is not configured. A server-only `GOLDEN_FRIJOLES_FLAG_READ_KEY` and `GOLDEN_FRIJOLES_ENVIRONMENT` configure it; the SDK evaluates `telemetry.play_funnel_enabled` with the same `player_id` as targeting key.

`npm run funnel:publish` prints a local dry-run plan. `npm run funnel:evaluations` shows how many persisted flag decisions could be reported, using each decision's stored environment. The local prototype's live `--send` stays disabled. The hosted publisher is a separate operator command with a project-key verification gate; the SDK's input push route alone does not identify a project. Never send fixture or synthetic cohort values to the hosted product. Do not place keys in a client export or commit `.env.local`.

## Private-alpha adapter

`scripts/alpha-server.mjs` accepts `POST /v1/events`, `POST /v1/campaign/flag`, and `GET /healthz` on the hosted route. Every event needs an `X-Aomx-Invite-Code` header. A valid code binds to one installation ID on its first well-formed `game_opened`; later uploads from another installation are refused. The campaign flag route requires that same already-bound code and player ID before evaluating. It returns only the enabled decision and numeric flag/snapshot versions, and reports a user-level Golden Frijoles evaluation with the same pseudonymous ID. Missing provider, unverified project key or failed exposure tracking serves off. The server enforces a 16 KB event payload limit, 1 KB flag request limit, and the same rate limit for both routes. Audit and report routes are unavailable publicly; the operator uses private database commands. The `alpha_private` schema separates durable receipts, coverage attestations, report history, published days and hashed invite codes.

`npm run alpha:campaign-publish` previews a bounded batch of at most 100 audit rows. `--send` uses a separately verified aomx key and an operator-only absolute cursor file. It sends only accepted, non-test mission wins to Golden Frijoles with the event ID as an idempotency key, then advances the audit-ID cursor after all sends succeed. It runs outside the ingest advisory lock; repeat batches until `more_may_remain` is false. The project uses a distinct scrypt attestation for this campaign key. The existing daily input publisher keeps its own verified-key gate and reporting path.

The alpha export sets its endpoint, test marker, channel and build ID in an isolated copy. Preview builds always carry `test_account=true`. Production builds carry `false`, but a flag-off event is still excluded. Only the operator can run `alpha:observe-day -- --complete`, `alpha:report -- --record`, or `alpha:publish`; the latter requires a separately verified aomx project key fingerprint before `--send`. These commands must use non-client secrets. [The alpha runbook](../deploy/alpha/README.md) describes deployment, backup, restricted itch.io distribution and invitation gates.
