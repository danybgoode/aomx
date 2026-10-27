import test from 'node:test';
import assert from 'node:assert/strict';
import { campaignDecision, CAMPAIGN_FLAG } from '../src/alpha/campaign-flags.mjs';
import { serve } from '../src/funnel/http.mjs';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';

test('campaign decision uses one user ID for targeting and exposure, with no client key', async () => {
  let targeted;
  let exposure;
  const provider = {
    resolveBooleanEvaluation(key, fallback, context) {
      assert.equal(key, CAMPAIGN_FLAG);
      assert.equal(fallback, false);
      targeted = context.targetingKey;
      return { value: true, flagVersion: 'v2', variant: 'on', reason: 'TARGETING_MATCH' };
    },
    getStatus: () => ({ snapshotVersion: 's2' })
  };
  const growth = { async trackFlagEvaluation(input) { exposure = input; return { ok: true }; } };
  const decision = await campaignDecision({ provider, growthForPlayer: id => { assert.equal(id, 'player_0001'); return growth; }, environment: 'preview' })('player_0001');
  assert.deepEqual(decision, { enabled: true, flag_version: 'v2', snapshot_version: 's2', environment: 'preview' });
  assert.equal(targeted, exposure.subject.id);
  assert.equal(exposure.subject.type, 'user');
  assert.equal(exposure.flagKey, CAMPAIGN_FLAG);
  assert.equal(JSON.stringify(decision).includes('key'), false);
});

test('campaign decision fails off without a served version or recorded exposure', async () => {
  const provider = { resolveBooleanEvaluation: () => ({ value: true, flagVersion: 'v2', variant: 'on' }),
    getStatus: () => ({ snapshotVersion: 's2' }) };
  assert.equal((await campaignDecision({ provider, environment: 'preview' })('player_0001')).enabled, false);
  const growth = { trackFlagEvaluation: async () => ({ ok: false }) };
  assert.equal((await campaignDecision({ provider, growthForPlayer: () => growth, environment: 'preview' })('player_0001')).enabled, false);
  assert.equal((await campaignDecision({ growthForPlayer: () => growth, environment: 'preview' })('player_0001')).enabled, false);
});

test('campaign flag route authenticates a bound invite before evaluating', async () => {
  let evaluations = 0;
  const ingest = { async authorizeCampaign(playerId, token) {
    if (playerId !== 'player_0001' || token !== 'valid_invite_code_1234567890') {
      throw Object.assign(new Error('invite_invalid'), { statusCode: 401 });
    }
  } };
  const server = serve(ingest, { port: 0, publicMode: true,
    campaignDecision: async () => { evaluations++; return { enabled: true, flag_version: 'v2', snapshot_version: 's2', environment: 'preview' }; } });
  try {
    await new Promise(resolve => server.once('listening', resolve));
    const url = `http://127.0.0.1:${server.address().port}/v1/campaign/flag`;
    const send = (playerId, token) => fetch(url, { method: 'POST',
      headers: { 'content-type': 'application/json', 'x-aomx-invite-code': token },
      body: JSON.stringify({ player_id: playerId }) });
    assert.equal((await send('player_other', 'valid_invite_code_1234567890')).status, 401);
    assert.equal(evaluations, 0);
    const response = await send('player_0001', 'valid_invite_code_1234567890');
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { enabled: true, flag_version: 'v2', snapshot_version: 's2', environment: 'preview' });
    assert.equal(evaluations, 1);
  } finally {
    await new Promise(resolve => server.close(resolve));
  }
});

test('campaign flag authorization rejects unclaimed, revoked and deleted invite identities', async () => {
  let record = { player_id: 'player_0001', revoked: false, deleted: false };
  const pool = { async query(_sql, params) {
    assert.equal(params.length, 2);
    return { rows: record ? [record] : [] };
  } };
  const funnel = new PostgresFunnel(null, { pool });
  const token = 'valid_invite_code_1234567890';
  await funnel.authorizeCampaign('player_0001', token);
  for (record of [null, { player_id: null, revoked: false, deleted: false },
    { player_id: 'player_other', revoked: false, deleted: false },
    { player_id: 'player_0001', revoked: true, deleted: false },
    { player_id: 'player_0001', revoked: false, deleted: true }]) {
    await assert.rejects(funnel.authorizeCampaign('player_0001', token), { statusCode: 401 });
  }
  await assert.rejects(funnel.authorizeCampaign('player_0001', 'short'), { statusCode: 401 });
});
