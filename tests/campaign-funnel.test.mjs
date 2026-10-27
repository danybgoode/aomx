import test from 'node:test';
import assert from 'node:assert/strict';
import { Ingest } from '../src/funnel/ingest.mjs';
import { makeReport } from '../src/funnel/report.mjs';
import { adoptionPlan, publishAdoptions } from '../src/alpha/campaign-adoption.mjs';

const at = n => `2026-10-${String(n).padStart(2, '0')}T12:00:00.000Z`;
const base = { schema_version: 1, player_id: 'player_alpha_01', game_version: 'test-1',
  content_version: 'test-1', faction: 'regios', test_account: false, bot: false };
function event(type, id, sequence, day, matchId, missionId, result) {
  return { ...base, type, event_id: id, local_sequence: sequence, claimed_at: at(day),
    mode: missionId ? 'campaign' : 'solo', ...(matchId ? { match_id: matchId } : {}),
    ...(missionId ? { mission_id: missionId } : {}), ...(result ? { result } : {}) };
}
function harness(campaignOn = true) {
  const store = { rows: [], append(row) { this.rows.push(row); } };
  const ingest = new Ingest(store, { now: () => new Date(at(20)),
    resolveFlag: () => ({ value: true }), resolveCampaignFlag: () => ({ value: campaignOn }),
    supportedVersions: [{ game: 'test-1', content: 'test-1' }] });
  return { store, ingest };
}

test('guided wins adopt once while only the final full battle enters the match funnel', () => {
  const { store, ingest } = harness();
  const open = event('game_opened', 'event_open_01', 1, 1);
  const arrival = event('campaign_mission_completed', 'event_arrival_01', 2, 1, 'mission_arrival_01', 'arrival_copilco', 'win');
  const foothold = event('campaign_mission_completed', 'event_foothold_01', 3, 1, 'mission_foothold_01', 'foothold_narvarte', 'win');
  const start = event('match_started', 'event_start_01', 4, 1, 'match_final_01', 'battle_la_roma');
  const finish = event('match_completed', 'event_finish_01', 5, 1, 'match_final_01', 'battle_la_roma', 'win');
  const finale = event('campaign_mission_completed', 'event_finale_01', 6, 1, 'match_final_01', 'battle_la_roma', 'win');
  for (const item of [open, arrival, foothold, start, finish, finale]) assert.equal(ingest.accept(item).status, 'accepted');
  assert.equal(ingest.accept(arrival).receipt_id, store.rows[1].receipt.receipt_id);
  assert.equal(ingest.accept({ ...arrival, event_id: 'event_arrival_02', local_sequence: 7 }).reason, 'duplicate_match_event');
  assert.equal(adoptionPlan(store.rows).length, 3);
  const report = makeReport(store.rows, at(20));
  assert.deepEqual(report.stages[0].counts.slice(0, 3), [1, 1, 1]);
  assert.equal(report.readings.find(r => r.key === 'match_completion').numerator, 1);
});

test('tutorial matches, skipped unlocks, losses, test accounts and flag-off starts stay out', () => {
  const { ingest } = harness();
  assert.equal(ingest.accept(event('game_opened', 'event_open_01', 1, 1)).status, 'accepted');
  const tutorialStart = event('match_started', 'event_tutorial_01', 2, 1, 'match_tutorial_01', 'arrival_copilco');
  assert.equal(ingest.accept(tutorialStart).reason, 'tutorial_match_ineligible');
  const finalStart = event('match_started', 'event_start_01', 2, 1, 'match_final_01', 'battle_la_roma');
  assert.equal(ingest.accept(finalStart).reason, 'missing_mission_prerequisite');
  const loss = event('campaign_mission_completed', 'event_loss_01', 2, 1, 'mission_arrival_01', 'arrival_copilco', 'loss');
  assert.equal(ingest.accept(loss).reason, 'invalid_result');
  const invalid = event('campaign_mission_completed', 'event_unknown_01', 2, 1, 'mission_arrival_01', 'unknown', 'win');
  assert.equal(ingest.accept(invalid).reason, 'invalid_campaign_context');
  const testWin = { ...event('campaign_mission_completed', 'event_test_01', 2, 1, 'mission_arrival_01', 'arrival_copilco', 'win'), test_account: true };
  assert.equal(ingest.accept(testWin).status, 'excluded');
  assert.equal(ingest.accept(testWin).reason, 'test_account');
  const off = harness(false);
  off.ingest.accept(event('game_opened', 'event_open_02', 1, 1));
  assert.equal(off.ingest.accept(event('campaign_mission_completed', 'event_arrival_01', 2, 1, 'mission_arrival_01', 'arrival_copilco', 'win')).reason, 'campaign_flag_off');
});

test('adoption publishing uses the event ID for retry safe identity', async () => {
  const { store, ingest } = harness();
  ingest.accept(event('game_opened', 'event_open_01', 1, 1));
  ingest.accept(event('campaign_mission_completed', 'event_arrival_01', 2, 1, 'mission_arrival_01', 'arrival_copilco', 'win'));
  let usedId;
  let sent;
  const growthForPlayer = id => { usedId = id; return { track: async (name, props) => { sent = { name, props }; return { ok: true }; } }; };
  assert.equal(await publishAdoptions(adoptionPlan(store.rows), growthForPlayer), 1);
  assert.equal(usedId, 'player_alpha_01');
  assert.equal(sent.name, 'campaign_mission_completed');
  assert.equal(sent.props.context.subject.id, usedId);
  assert.equal(sent.props.context.idempotencyKey, 'campaign_mission:event_arrival_01');
});
