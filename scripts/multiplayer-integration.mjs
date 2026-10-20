import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { once } from 'node:events';
import { spawn } from 'node:child_process';
import { MemoryMatchStore } from '../src/multiplayer/store.mjs';
import { MatchSession } from '../src/multiplayer/session.mjs';
import { GodotMatchWorker } from '../src/multiplayer/worker.mjs';
import { serveMatch } from '../src/multiplayer/http.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';

const godotBin = process.env.GODOT_BIN;
if (!godotBin) throw new Error('GODOT_BIN is required');
const store = new MemoryMatchStore();
const codes = ['a'.repeat(32), 'b'.repeat(32)];
codes.forEach(code => store.addInvite(code));
const session = new MatchSession({ store, evaluateAdmission: () => true, tickMs: 1000,
  workerFactory: () => new GodotMatchWorker({ godotBin, gamePath: resolve('game') }).start()
    .catch(error => { process.stderr.write(`worker start: ${error.message}\n`); throw error; }) });
const server = serveMatch(session, { port: 0 });
await once(server, 'listening');
const origin = `http://127.0.0.1:${server.address().port}`;
const post = async (path, data, token = '') => {
  const response = await fetch(origin + path, { method: 'POST', headers: {
    'content-type': 'application/json', ...(token ? { 'x-aomx-match-token': token } : {}) },
  body: JSON.stringify(data) });
  return response.json();
};
const state = async token => (await fetch(origin + '/v1/match/state', {
  headers: { 'x-aomx-match-token': token } })).json();
try {
  const joins = await Promise.all(codes.map((invite_code, side) => post('/v1/match/join', {
    invite_code, player_id: `player000${side + 1}`, ...SkirmishVersions.public() })));
  if (!joins.every(join => join.ok)) throw new Error(`joins_failed:${JSON.stringify(joins)}`);
  assert.deepEqual(joins.map(join => join.side), [0, 1]);
  assert(joins.every(join => join.ok));
  const [left, right] = await Promise.all(joins.map(join => state(join.token)));
  assert(left.ok && right.ok);
  assert.equal(left.hash, right.hash);
  assert.equal(left.state.balances[1].varos, 0);
  assert.equal(right.state.balances[0].varos, 0);
  assert.equal(left.state.explored[1].length, 0);
  assert.equal(right.state.explored[0].length, 0);
  const ownedActor = left.state.entities.find(entity => entity.side === 0 && entity.kind === 'worker');
  const envelope = { match_id: joins[0].match_id, expected_tick: left.tick };
  const foreign = await post('/v1/match/order', { ...envelope, side: 1, sequence: 1, kind: 'stop',
    actor_id: ownedActor.id, target: '' }, joins[1].token);
  assert.equal(foreign.ok, false);
  const accepted = await post('/v1/match/order', { ...envelope, side: 0, sequence: 1, kind: 'stop',
    actor_id: ownedActor.id, target: '' }, joins[0].token);
  if (!accepted.ok) throw new Error(`order_failed:${JSON.stringify(accepted)}`);
  assert(accepted.ok);
  const duplicate = await post('/v1/match/order', { ...envelope, side: 0, sequence: 1, kind: 'stop',
    actor_id: ownedActor.id, target: '' }, joins[0].token);
  assert(duplicate.ok && duplicate.duplicate);
  const rejoin = await post('/v1/match/join', { invite_code: codes[0],
    player_id: 'player0001', ...SkirmishVersions.public() });
  assert(rejoin.ok && rejoin.side === 0 && rejoin.token !== joins[0].token);
  assert.equal((await state(joins[0].token)).ok, false);
  assert((await state(rejoin.token)).ok);
  await Promise.all([0, 1].map(async side => {
    const native = spawn(godotBin, ['--headless', '--path', resolve('game'),
      '--script', 'res://tests/multiplayer_client_online_test.gd'], { env: { ...process.env,
      AOMX_TEST_MATCH_ENDPOINT: origin, AOMX_TEST_MATCH_CODE: codes[side],
      AOMX_TEST_MATCH_PLAYER: `player000${side + 1}`, AOMX_TEST_EXPECT_SIDE: String(side) },
    stdio: ['ignore', 'pipe', 'pipe'] });
    let nativeOutput = '';
    native.stdout.on('data', chunk => { nativeOutput += chunk; });
    native.stderr.on('data', chunk => { nativeOutput += chunk; });
    const [nativeCode] = await once(native, 'exit');
    assert.equal(nativeCode, 0, nativeOutput);
    assert.match(nativeOutput, /AOMX_CLIENT_PASS/);
  }));
  process.stdout.write(JSON.stringify({ ok: true, match_id: joins[0].match_id,
    tick: left.tick, accepted_sequence: accepted.sequence, fog_redacted: true,
    native_client: true }) + '\n');
} finally {
  server.close();
  session.close();
}
