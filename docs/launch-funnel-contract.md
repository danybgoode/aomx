# Launch funnel event contract (v1)

The product boundary is a loopback Node service with a durable JSONL audit log. It accepts fixture events and test-tagged uploads from the Godot prototype's offline outbox. Golden Frijoles holds the enablement flag and four derived daily input readings; the game never receives those credentials. This local service is **not a deployable player backend**: it has no authentication, replay verification, multi-process locking, or hosted storage.

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

`type` is `game_opened`, `match_started`, or `match_completed`. The client persists the stable pseudonymous installation ID, a unique event ID, and a strictly increasing local sequence before acknowledging play. Calling the outbox's ordinary `queue('game_opened')` after restart reuses the first-open event; an intentional later session passes `{ newSession: true }` to record a return open. `match_id` is required for starts and completions and absent for opens. `result` is required for completions (`win`, `loss`, `draw`) and absent otherwise. All times are claimed UTC play times; receipts add independent server `received_at`. `game_version` and `content_version` identify the client rules/content. `mode` is `solo`, `multiplayer`, or `tutorial`. `faction` is a bounded nonempty identifier. `test_account` and `bot` are explicit booleans.

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

`npm run funnel:publish` prints a dry-run plan. `npm run funnel:evaluations` shows how many persisted flag decisions could be reported, using each decision's stored environment. Live `--send` is disabled: the SDK's input push route scopes by bearer key but does not return a project identity that this code can verify. A future publisher must verify the key belongs to aomx before writing, then send only final numeric readings and handle append-only correction conflicts. Never send fixture or synthetic cohort values to the hosted product. Do not place keys in a client export or commit `.env.local`.
