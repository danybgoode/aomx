import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { AuditStore } from '../src/funnel/store.mjs';
import { Ingest } from '../src/funnel/ingest.mjs';
import { makeReport, corrections } from '../src/funnel/report.mjs';
import { Outbox } from '../src/funnel/outbox.mjs';
import { publish, publishPlan } from '../src/funnel/publisher.mjs';

const temp = () => fs.mkdtempSync(path.join(os.tmpdir(), 'la-roma-funnel-'));
const at = day => `2026-10-${String(day).padStart(2, '0')}T12:00:00.000Z`;
const base = { schema_version: 1, player_id: 'player_alpha_01', game_version: 'test-1', content_version: 'test-1',
  mode: 'solo', faction: 'neutral', test_account: false, bot: false };
function event(type, id, seq, day, matchId, result) {
  return { ...base, type, event_id: id, claimed_at: at(day), local_sequence: seq,
    ...(matchId ? { match_id: matchId } : {}), ...(result ? { result } : {}) };
}

test('ingest persists stable retries, exclusions, and named rejections', () => {
  const filename = path.join(temp(), 'audit.jsonl');
  const ingest = new Ingest(new AuditStore(filename), { now: () => new Date(at(20)), resolveFlag: () => ({ value: true }) });
  const open = event('game_opened', 'event_open_01', 1, 1);
  const start = event('match_started', 'event_start_01', 2, 1, 'match_one_01');
  const finish = event('match_completed', 'event_finish_01', 3, 1, 'match_one_01', 'win');
  assert.equal(ingest.accept(open).status, 'accepted');
  assert.equal(ingest.accept(start).status, 'accepted');
  const receipt = ingest.accept(finish);
  assert.deepEqual(ingest.accept(finish), receipt);
  assert.equal(ingest.accept({ ...finish, result: 'loss' }).reason, 'event_id_collision');
  assert.equal(ingest.accept({ ...finish, event_id: 'event_finish_02', local_sequence: 4 }).reason, 'duplicate_match_event');
  assert.equal(ingest.accept({ ...finish, event_id: 'event_bad_ver_01', schema_version: 2 }).reason, 'unsupported_version');
  assert.equal(ingest.accept({ ...finish, event_id: 'event_bad_id_01', player_id: '' }).reason, 'invalid_identity');
  assert.equal(ingest.accept({ ...finish, event_id: 'event_unknown_01', email: 'private@example.com' }).reason, 'unknown_field');
  const leaked = ingest.accept({ event_id: 'private@example.com', email: 'private@example.com' });
  assert.equal(leaked.event_id, null);
  assert.equal(ingest.accept({ ...start, event_id: 'event_test_start_01', player_id: 'player_test_01', match_id: 'match_test_01', test_account: true }).reason, 'missing_first_open');
  assert.equal(new AuditStore(filename).rows.length, 10);
  assert.equal(JSON.stringify(new AuditStore(filename).rows).includes('private@example.com'), false);
});

test('cohort dates, abandoned starts, same-day finish, later-day finish and correction', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date(at(20)), resolveFlag: () => ({ value: true }) });
  const rows = [
    event('game_opened', 'event_open_01', 1, 1),
    event('match_started', 'event_start_01', 2, 1, 'match_one_01'),
    event('match_completed', 'event_finish_01', 3, 1, 'match_one_01', 'win'),
    event('match_started', 'event_start_02', 4, 1, 'match_two_01'),
    event('match_completed', 'event_finish_02', 5, 1, 'match_two_01', 'loss'),
    event('game_opened', 'event_open_02', 6, 3),
    event('match_started', 'event_start_03', 7, 3, 'match_three_01'),
    event('match_started', 'event_abandoned_01', 8, 4, 'match_four_01')
  ];
  rows.forEach(e => assert.equal(ingest.accept(e).status, 'accepted'));
  const before = makeReport(ingest.store.rows, at(15));
  assert.equal(before.returning_commanders, 0);
  assert.deepEqual(before.stages[0].counts, [1, 1, 1, 1, 1, 0]);
  assert.equal(before.readings.find(r => r.key === 'match_completion' && r.day === '2026-10-04').value, 0);
  // A delayed result retains its claimed date and changes a mature reading visibly.
  const late = { ...event('match_completed', 'event_finish_03', 9, 4, 'match_four_01', 'win'), claimed_at: '2026-10-04T13:00:00.000Z' };
  assert.equal(ingest.accept(late).status, 'accepted');
  const after = makeReport(ingest.store.rows, at(15));
  assert.equal(after.returning_commanders, 1);
  assert.deepEqual(after.stages[0].counts, [1, 1, 1, 1, 1, 1]);
  assert.ok(corrections(before, after).some(c => c.key === 'return_to_match'));
});

test('outbox survives restart and outage, retries in order, and retains rejected event', async () => {
  const filename = path.join(temp(), 'outbox.json');
  const outbox = new Outbox(filename, { now: () => new Date(at(1)) });
  const open = outbox.queue('game_opened');
  const match = outbox.queue('match_started', { matchId: 'match_one_01' });
  const result = outbox.queue('match_completed', { matchId: 'match_one_01', result: 'win' });
  assert.equal(outbox.queue('match_completed', { matchId: 'match_one_01', result: 'loss' }).event_id, result.event_id);
  const restarted = new Outbox(filename);
  assert.equal(restarted.state.player_id, open.player_id);
  assert.equal(restarted.queue('game_opened').event_id, open.event_id);
  assert.deepEqual(restarted.state.events.map(x => x.event.event_id), [open.event_id, match.event_id, result.event_id]);
  await restarted.sync(async () => { throw new Error('offline'); });
  assert.ok(restarted.status.every(x => x.status === 'pending'));
  const seen = [];
  await restarted.sync(async e => { seen.push(e.type); return { event_id: e.event_id, status: e.type === 'match_completed' ? 'quarantined' : 'accepted', reason: 'clock_ahead' }; });
  assert.deepEqual(seen, ['game_opened', 'match_started', 'match_completed']);
  assert.deepEqual(restarted.status.map(x => x.status), ['accepted', 'accepted', 'needs_attention']);
  assert.equal(new Outbox(filename).state.events[2].event.event_id, result.event_id);
});

test('clock anomaly and test traffic stay outside readings', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date(at(1)) });
  assert.equal(ingest.accept({ ...event('game_opened', 'event_future_01', 1, 10) }).reason, 'clock_ahead');
  assert.equal(ingest.accept({ ...event('game_opened', 'event_test_01', 1, 1), player_id: 'player_test_01', test_account: true }).status, 'excluded');
  assert.equal(makeReport(ingest.store.rows, at(15)).accepted_events, 0);
});

test('preview ingest excludes client claims even when its flag is on', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), {
    now: () => new Date(at(20)), resolveFlag: () => ({ value: true, environment: 'preview' }),
    forceExcludeReason: 'preview_environment' });
  const rows = [
    event('game_opened', 'event_preview_open_01', 1, 1),
    event('match_started', 'event_preview_start_01', 2, 1, 'match_preview_01'),
    event('match_completed', 'event_preview_finish_01', 3, 1, 'match_preview_01', 'win')
  ];
  const receipts = rows.map(row => ingest.accept(row));
  assert.ok(receipts.every(receipt => receipt.status === 'excluded' && receipt.reason === 'preview_environment'));
  assert.deepEqual(ingest.accept(rows[2]), receipts[2]);
  assert.equal(makeReport(ingest.store.rows, at(20)).accepted_events, 0);
});

test('unverified multiplayer claims cannot enter production readings', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), {
    now: () => new Date(at(20)), resolveFlag: () => ({ value: true, environment: 'production' }),
    supportedVersions: [{ game: 'test-1', content: 'test-1' }] });
  const rows = [
    { ...event('game_opened', 'event_online_open_01', 1, 1), mode: 'multiplayer' },
    { ...event('match_started', 'event_online_start_01', 2, 1, 'online_match_01'), mode: 'multiplayer' },
    { ...event('match_completed', 'event_online_finish_01', 3, 1, 'online_match_01', 'win'), mode: 'multiplayer' }
  ];
  for (const row of rows) {
    const receipt = ingest.accept(row);
    assert.equal(receipt.status, 'excluded');
    assert.equal(receipt.reason, 'multiplayer_unverified');
    assert.equal(receipt.trust, 'client_reported');
  }
  assert.equal(ingest.accept({ ...rows[2], event_id: 'event_online_forged_01',
    local_sequence: 4, result: 'loss' }).reason, 'duplicate_match_event');
  assert.equal(ingest.accept({ ...rows[2], event_id: 'event_online_old_01',
    game_version: 'wrong' }).reason, 'unsupported_game_version');
  assert.equal(makeReport(ingest.store.rows, at(20)).accepted_events, 0);
});

test('clock reversal is quarantined even when sequence increases', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date(at(20)), resolveFlag: () => ({ value: true }) });
  assert.equal(ingest.accept(event('game_opened', 'event_open_01', 1, 3)).status, 'accepted');
  assert.equal(ingest.accept(event('game_opened', 'event_open_02', 2, 2)).reason, 'clock_reversal');
  assert.equal(makeReport(ingest.store.rows, at(20)).accepted_events, 1);
});

test('calendar-impossible timestamps are rejected', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date(at(20)) });
  assert.equal(ingest.accept({ ...event('game_opened', 'event_bad_date_01', 1, 1), claimed_at: '2026-02-30T12:00:00.000Z' }).reason, 'invalid_claimed_time');
});

test('return rate includes a first finish after the first-open funnel window', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date('2026-11-01T12:00:00.000Z'), resolveFlag: () => ({ value: true }) });
  [
    event('game_opened', 'event_open_01', 1, 1),
    event('match_started', 'event_start_01', 2, 10, 'match_one_01'),
    event('match_completed', 'event_finish_01', 3, 10, 'match_one_01', 'win'),
    event('match_started', 'event_start_02', 4, 11, 'match_two_01'),
    event('match_completed', 'event_finish_02', 5, 11, 'match_two_01', 'loss')
  ].forEach(e => assert.equal(ingest.accept(e).status, 'accepted'));
  const report = makeReport(ingest.store.rows, '2026-10-20T12:00:00.000Z');
  assert.equal(report.stages[0].counts[2], 0);
  assert.equal(report.returning_commanders, 1);
  assert.equal(report.readings.find(r => r.key === 'return_to_match').value, 100);
});

test('an attested zero day has a numeric zero new-player reading, not a missing day', () => {
  const report = makeReport([], '2026-10-12T12:00:00.000Z', { observedDays: ['2026-10-02'] });
  const count = report.readings.find(r => r.key === 'new_players' && r.day === '2026-10-02');
  assert.equal(count.status, 'final');
  assert.equal(count.value, 0);
  assert.equal(report.stages[0].status, 'no_data');
  assert.equal(report.readings.find(r => r.key === 'first_match_completion').status, 'no_data');
});

test('the server defaults off and records the flag decision without creating a cohort', () => {
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), { now: () => new Date(at(20)) });
  const receipt = ingest.accept(event('game_opened', 'event_open_01', 1, 1));
  assert.equal(receipt.status, 'excluded');
  assert.equal(receipt.reason, 'flag_off');
  assert.equal(receipt.flag.value, false);
  assert.equal(makeReport(ingest.store.rows, at(20)).status, 'no_data');
});

test('a flag-off start cannot turn into a public completion when the flag turns on', () => {
  let on = true;
  const ingest = new Ingest(new AuditStore(path.join(temp(), 'audit.jsonl')), {
    now: () => new Date(at(20)), resolveFlag: () => ({ value: on, environment: 'development' })
  });
  assert.equal(ingest.accept(event('game_opened', 'event_open_01', 1, 1)).status, 'accepted');
  on = false;
  assert.equal(ingest.accept(event('match_started', 'event_start_01', 2, 1, 'match_one_01')).reason, 'flag_off');
  on = true;
  assert.equal(ingest.accept(event('match_completed', 'event_finish_01', 3, 1, 'match_one_01', 'win')).reason, 'prior_event_excluded');
  const report = makeReport(ingest.store.rows, at(20));
  assert.deepEqual(report.stages[0].counts.slice(0, 3), [1, 0, 0]);
});

test('publisher sends only mature numeric readings to aomx and surfaces backfill conflicts', async () => {
  const report = { readings: [
    { key: 'new_players', day: '2026-10-01', status: 'final', value: 1 },
    { key: 'return_to_match', day: '2026-10-01', status: 'pending', value: null }
  ] };
  assert.deepEqual(publishPlan(report).find(x => x.key === 'new_players').values, [{ occurredOn: '2026-10-01', value: 1 }]);
  assert.deepEqual(publishPlan({ ...report, observed_days: [] }, { requireCoverage: true })
    .find(x => x.key === 'new_players').values, []);
  assert.deepEqual(publishPlan({ ...report, observed_days: ['2026-10-01'] }, { requireCoverage: true })
    .find(x => x.key === 'new_players').values, [{ occurredOn: '2026-10-01', value: 1 }]);
  const called = [];
  const client = { pushInputValues: async (key, values) => { called.push([key, values]); return { ok: true, mismatchedDuplicates: [] }; } };
  await assert.rejects(() => publish(report, client, 'wrong'), /wrong_project/);
  assert.equal(called.length, 0);
  await publish(report, client, 'aomx');
  assert.equal(called.length, 1);
  await assert.rejects(() => publish(report, { pushInputValues: async () => ({ ok: true, mismatchedDuplicates: ['2026-10-01'] }) }, 'aomx'), /needs_backfill/);
});
