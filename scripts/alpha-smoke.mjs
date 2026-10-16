import fs from 'node:fs';
import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';
import { gameVersion, currentContentVersion } from '../src/alpha/versions.mjs';

const endpoint = process.env.AOMX_INGEST_URL;
const inviteFile = process.env.AOMX_INVITE_FILE;
if (!endpoint?.startsWith('https://') || !inviteFile) {
  throw new Error('AOMX_INGEST_URL (HTTPS /v1/events) and AOMX_INVITE_FILE are required');
}
const token = JSON.parse(fs.readFileSync(inviteFile, 'utf8')).token;
const id = prefix => `${prefix}_${randomBytes(8).toString('hex')}`;
const player = id('internal_smoke');
const match = id('match');
const now = new Date().toISOString();
const base = { schema_version: 1, player_id: player, claimed_at: now,
  game_version: gameVersion, content_version: currentContentVersion,
  mode: 'solo', faction: 'neutral', test_account: true, bot: false };
const open = { ...base, type: 'game_opened', event_id: id('event'), local_sequence: 1 };
const start = { ...base, faction: 'regios', type: 'match_started', event_id: id('event'), match_id: match, local_sequence: 2 };
const finish = { ...base, faction: 'regios', type: 'match_completed', event_id: id('event'), match_id: match,
  local_sequence: 3, result: 'win' };
async function post(event, invite = token) {
  const response = await fetch(endpoint, { method: 'POST', headers: {
    'content-type': 'application/json', ...(invite ? { 'x-aomx-invite-code': invite } : {}) },
    body: JSON.stringify(event), signal: AbortSignal.timeout(8000) });
  return { code: response.status, body: await response.json() };
}
assert.equal((await post(open, null)).code, 401);
const first = await post(open);
assert.equal(first.code, 200);
assert.equal(first.body.status, 'excluded');
assert.equal(first.body.reason, 'test_account');
assert.deepEqual((await post(open)).body, first.body);
for (const event of [start, finish]) {
  const receipt = await post(event);
  assert.equal(receipt.code, 200);
  assert.equal(receipt.body.status, 'excluded');
  assert.equal(receipt.body.reason, 'test_account');
}
const forged = await post({ ...open, event_id: id('event'), local_sequence: 4, test_account: false });
assert.equal(forged.code, 200);
assert.equal(forged.body.status, 'excluded');
assert.equal(forged.body.reason, 'preview_environment');
const invalid = await post({ ...finish, event_id: id('event'), local_sequence: 5,
  game_version: 'unknown' });
assert.equal(invalid.code, 422);
assert.equal(invalid.body.reason, 'unsupported_game_version');
process.stdout.write(JSON.stringify({ ok: true, endpoint, player_id: player,
  first_receipt: first.body.receipt_id, exclusion: 'test_account', forged_exclusion: forged.body.reason,
  accepted_public_events: 0 }) + '\n');
