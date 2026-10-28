import test from 'node:test';
import assert from 'node:assert/strict';
import { Ingest, validate } from '../src/funnel/ingest.mjs';
import { wonderDecision, WONDER_FLAG } from '../src/alpha/wonder-flags.mjs';
import { gameVersion, currentContentVersion, supportedVersions } from '../src/alpha/versions.mjs';
import { wonderAdoptionPlan, publishWonderAdoptions } from '../src/alpha/wonder-adoption.mjs';
import { serve } from '../src/funnel/http.mjs';

const at = '2026-10-20T12:00:00.000Z';
const base = { schema_version: 1, player_id: 'player_wonder_01', game_version: gameVersion,
  content_version: 'la-roma-wonder-1', faction: 'regios', test_account: false, bot: false,
  mode: 'solo', objective_id: 'wonder', wonder_flag_version: 3, claimed_at: at };
const event = (type, id, sequence, result) => ({ ...base, type, event_id: id,
  match_id: 'match_wonder_01', local_sequence: sequence, ...(result ? { result } : {}) });
function harness(enabled = true) {
  const store = { rows: [], append(row) { this.rows.push(row); } };
  const ingest = new Ingest(store, { now: () => new Date(at), supportedVersions,
    resolveFlag: () => ({ value: true }), resolveWonderFlag: () => ({ value: enabled, flagVersion: 3 }) });
  return { store, ingest };
}

test('served Wonder decision targets and tracks the same pseudonymous user', async () => {
  let targeted, exposure;
  const provider = { resolveBooleanEvaluation(key, fallback, context) {
    assert.equal(key, WONDER_FLAG);
    assert.equal(fallback, false);
    targeted = context.targetingKey;
    return { value: true, flagVersion: 3, variant: 'on', reason: 'TARGETING_MATCH' };
  }, getStatus: () => ({ snapshotVersion: 5 }) };
  const growth = { async trackFlagEvaluation(input) { exposure = input; return { ok: true }; } };
  const decision = await wonderDecision({ provider, growthForPlayer: () => growth, environment: 'preview' })('player_wonder_01');
  assert.deepEqual(decision, { enabled: true, flag_version: 3, snapshot_version: 5, environment: 'preview' });
  assert.equal(targeted, exposure.subject.id);
  assert.equal(exposure.subject.type, 'user');
  assert.equal(exposure.flagKey, WONDER_FLAG);
  assert.equal((await wonderDecision({ provider, environment: 'preview' })('player_wonder_01')).enabled, false);
});

test('Wonder flag route authenticates a bound invite before evaluating', async () => {
  let evaluations = 0;
  const ingest = { async authorizeCampaign(playerId, token) {
    if (playerId !== 'player_wonder_01' || token !== 'valid_invite_code_1234567890') {
      throw Object.assign(new Error('invite_invalid'), { statusCode: 401 });
    }
  } };
  const server = serve(ingest, { port: 0, publicMode: true,
    wonderDecision: async () => { evaluations++; return { enabled: false, flag_version: 1, snapshot_version: 5, environment: 'preview' }; } });
  try {
    await new Promise(resolve => server.once('listening', resolve));
    const url = `http://127.0.0.1:${server.address().port}/v1/modes/flag`;
    const send = (playerId, token) => fetch(url, { method: 'POST',
      headers: { 'content-type': 'application/json', 'x-aomx-invite-code': token },
      body: JSON.stringify({ player_id: playerId }) });
    assert.equal((await send('player_other', 'valid_invite_code_1234567890')).status, 401);
    assert.equal(evaluations, 0);
    const response = await send('player_wonder_01', 'valid_invite_code_1234567890');
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { enabled: false, flag_version: 1, snapshot_version: 5, environment: 'preview' });
    assert.equal(evaluations, 1);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});

test('Wonder adoption requires an accepted full match and survives a later flag-off', () => {
  const { ingest } = harness();
  const opened = { ...base, type: 'game_opened', event_id: 'event_open_wonder_01',
    content_version: currentContentVersion, local_sequence: 1 };
  delete opened.match_id; delete opened.objective_id; delete opened.wonder_flag_version;
  assert.equal(ingest.accept(opened).status, 'accepted');
  const start = event('match_started', 'event_start_wonder_01', 2);
  const finish = event('match_completed', 'event_finish_wonder_01', 3, 'win');
  const adoption = event('wonder_match_completed', 'event_adopt_wonder_01', 4, 'win');
  assert.equal(ingest.accept({ ...adoption, event_id: 'event_early_wonder_01' }).reason, 'missing_wonder_finish');
  assert.equal(ingest.accept(start).status, 'accepted');
  ingest.resolveWonderFlag = () => ({ value: false, flagVersion: 4 });
  assert.equal(ingest.accept(finish).status, 'accepted');
  assert.equal(ingest.accept(adoption).status, 'accepted');
  assert.equal(ingest.accept(adoption).status, 'accepted');
  assert.equal(ingest.accept({ ...adoption, event_id: 'event_adopt_wonder_02', local_sequence: 5 }).reason, 'duplicate_match_event');
  assert.deepEqual(wonderAdoptionPlan(ingest.store.rows).map(item => item.event_id), ['event_adopt_wonder_01']);
});

test('accepted Wonder adoption publishes once with stable user and idempotency key', async () => {
  const adoption = event('wonder_match_completed', 'event_adopt_wonder_03', 4, 'loss');
  const rows = [{ receipt: { status: 'accepted' }, event: adoption },
    { receipt: { status: 'accepted' }, event: adoption },
    { receipt: { status: 'excluded' }, event: { ...adoption, match_id: 'match_wonder_02' } }];
  const events = wonderAdoptionPlan(rows);
  assert.equal(events.length, 1);
  let tracked;
  assert.equal(await publishWonderAdoptions(events, playerId => {
    assert.equal(playerId, 'player_wonder_01');
    return { async track(name, payload) { tracked = { name, payload }; return { ok: true }; } };
  }), 1);
  assert.equal(tracked.name, 'wonder_match_completed');
  assert.equal(tracked.payload.context.subject.id, 'player_wonder_01');
  assert.equal(tracked.payload.context.idempotencyKey, 'wonder_match:event_adopt_wonder_03');
});

test('Wonder rejects off starts, malformed context and test traffic', () => {
  const { ingest } = harness(false);
  const opened = { ...base, type: 'game_opened', event_id: 'event_open_wonder_02',
    content_version: currentContentVersion, local_sequence: 1 };
  delete opened.match_id; delete opened.objective_id; delete opened.wonder_flag_version;
  ingest.accept(opened);
  assert.equal(ingest.accept(event('match_started', 'event_start_wonder_02', 2)).reason, 'wonder_flag_off');
  assert.equal(ingest.accept(event('match_completed', 'event_finish_wonder_02', 3, 'win')).reason, 'prior_event_excluded');
  assert.equal(ingest.accept(event('wonder_match_completed', 'event_adopt_wonder_02', 4, 'win')).reason, 'prior_event_excluded');
  assert.equal(validate({ ...event('match_started', 'event_bad_wonder_01', 2), content_version: currentContentVersion }), 'invalid_wonder_context');
  assert.equal(validate({ ...event('match_started', 'event_bad_wonder_02', 2), wonder_flag_version: undefined }), 'invalid_wonder_context');
  const testTraffic = harness();
  const testOpen = { ...opened, test_account: true, event_id: 'event_test_open_wonder_01' };
  assert.equal(testTraffic.ingest.accept(testOpen).status, 'excluded');
  assert.equal(testTraffic.ingest.accept({ ...event('match_started', 'event_test_start_wonder_01', 2), test_account: true }).status, 'excluded');
});
