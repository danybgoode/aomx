import assert from 'node:assert/strict';
import { resolve } from 'node:path';
import { once } from 'node:events';
import { spawn } from 'node:child_process';
import { MemoryMatchStore } from '../src/multiplayer/store.mjs';
import { MatchSession } from '../src/multiplayer/session.mjs';
import { PublicRoomHub } from '../src/multiplayer/rooms.mjs';
import { GodotMatchWorker } from '../src/multiplayer/worker.mjs';
import { serveMatch } from '../src/multiplayer/http.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';

const godotBin = process.env.GODOT_BIN;
if (!godotBin) throw new Error('GODOT_BIN is required');
const store = new MemoryMatchStore();
const workerFactory = () => new GodotMatchWorker({ godotBin, gamePath: resolve('game') }).start();
const legacySession = new MatchSession({ store, evaluateAdmission: () => false, workerFactory });
const hub = new PublicRoomHub({ legacySession, records: store, workerFactory, tickMs: 1000 });
const server = serveMatch(hub, { port: 0, allowedWebOrigin: 'https://html-classic.itch.zone' });
await once(server, 'listening');
const origin = `http://127.0.0.1:${server.address().port}`;
const post = async (path, body) => {
  const response = await fetch(origin + path, { method: 'POST', headers: {
    origin: 'https://html-classic.itch.zone', 'content-type': 'application/json' },
  body: JSON.stringify(body) });
  return response.json();
};
try {
  const first = await post('/v1/match/create', {
    player_id: 'player0001', ...SkirmishVersions.public() });
  assert(first.ok, JSON.stringify(first));
  const second = await post('/v1/match/join', { invite_code: first.room_code,
    player_id: 'player0002', ...SkirmishVersions.public() });
  assert(second.ok, JSON.stringify(second));
  assert.equal(first.match_id, second.match_id);
  assert.deepEqual([first.side, second.side], [0, 1]);
  const state = await fetch(origin + '/v1/match/state', { headers: {
    'x-aomx-match-token': first.token } }).then(response => response.json());
  assert(state.ok && state.state);
  assert.equal(state.state.balances[1].varos, 0);
  const clients = await Promise.all([0, 1].map(async side => {
    const child = spawn(godotBin, ['--headless', '--path', resolve('game'),
      '--script', 'res://tests/multiplayer_client_online_test.gd'], { env: { ...process.env,
      AOMX_TEST_MATCH_ENDPOINT: origin, AOMX_TEST_MATCH_CODE: first.room_code,
      AOMX_TEST_MATCH_PLAYER: `player000${side + 1}`, AOMX_TEST_EXPECT_SIDE: String(side) },
    stdio: ['ignore', 'pipe', 'pipe'] });
    let output = '';
    child.stdout.on('data', chunk => { output += chunk; });
    child.stderr.on('data', chunk => { output += chunk; });
    const [code] = await once(child, 'exit');
    assert.equal(code, 0, output);
    assert.match(output, /AOMX_CLIENT_PASS/);
    return true;
  }));
  assert(clients.every(Boolean));
  const creator = spawn(godotBin, ['--headless', '--path', resolve('game'),
    '--script', 'res://tests/public_room_client_online_test.gd'], { env: { ...process.env,
    AOMX_TEST_MATCH_ENDPOINT: origin }, stdio: ['ignore', 'pipe', 'pipe'] });
  let creatorOutput = '';
  creator.stdout.on('data', chunk => { creatorOutput += chunk; });
  creator.stderr.on('data', chunk => { creatorOutput += chunk; });
  const [creatorCode] = await once(creator, 'exit');
  assert.equal(creatorCode, 0, creatorOutput);
  assert.match(creatorOutput, /AOMX_ROOM_CREATED [A-Za-z0-9_-]{24}/);
  process.stdout.write(JSON.stringify({ ok: true, match_id: first.match_id,
    room_code_length: first.room_code.length, native_clients: 2,
    native_room_creation: true, fog_redacted: true }) + '\n');
} finally {
  hub.close();
  await new Promise(resolve => server.close(resolve));
}
