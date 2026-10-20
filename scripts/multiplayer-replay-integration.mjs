import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { spawn, spawnSync } from 'node:child_process';
import { once } from 'node:events';
import { mkdtempSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { MemoryMatchStore } from '../src/multiplayer/store.mjs';
import { MatchSession } from '../src/multiplayer/session.mjs';
import { GodotMatchWorker } from '../src/multiplayer/worker.mjs';
import { serveMatch } from '../src/multiplayer/http.mjs';

const godotBin = process.env.GODOT_BIN;
if (!godotBin) throw new Error('GODOT_BIN is required');
const dir = mkdtempSync(join(tmpdir(), 'aomx-replay-'));
const file = join(dir, 'recording.json');
let session;
let server;
try {
  const made = spawnSync(godotBin, ['--headless', '--path', resolve('game'),
    '--script', 'res://tests/multiplayer_replay_test.gd'], {
    env: { ...process.env, AOMX_TEST_REPLAY_OUTPUT: file }, encoding: 'utf8' });
  assert.equal(made.status, 0, made.stdout + made.stderr);
  const replay = JSON.parse(readFileSync(file, 'utf8'));
  const store = new MemoryMatchStore();
  const codes = ['c'.repeat(32), 'd'.repeat(32)];
  const players = ['replay_player_one', 'replay_player_two'];
  for (let side = 0; side < 2; side++) {
    store.addInvite(codes[side]);
    assert((await store.claimInvite(codes[side], players[side])).ok);
  }
  await store.saveRecord({ match_id: replay.match_id, terminal: replay.terminal,
    replay, players: codes.map((code, side) => ({ side, player_id: players[side],
      code_hash: createHash('sha256').update(code).digest('hex') })) });
  session = new MatchSession({ store, evaluateAdmission: () => false,
    workerFactory: () => new GodotMatchWorker({ godotBin, gamePath: resolve('game') }).start() });
  server = serveMatch(session, { port: 0 });
  await once(server, 'listening');
  const origin = `http://127.0.0.1:${server.address().port}`;
  const post = async (path, body, token = '') => {
    const response = await fetch(origin + path, { method: 'POST', headers: {
      'content-type': 'application/json', ...(token ? { 'x-aomx-replay-token': token } : {}) },
    body: JSON.stringify(body) });
    return response.json();
  };
  const streams = [];
  for (let side = 0; side < 2; side++) {
    const opened = await post('/v1/match/replay', { invite_code: codes[side],
      player_id: players[side], match_id: replay.match_id });
    assert(opened.ok, JSON.stringify(opened));
    assert.equal(opened.side, side);
    assert.equal('replay' in opened, false);
    assert.equal('commands' in opened, false);
    streams.push(opened);
  }
  const denied = await post('/v1/match/replay', { invite_code: codes[0],
    player_id: players[1], match_id: replay.match_id });
  assert.equal(denied.ok, false);
  for (const stream of streams) {
    let last;
    for (let frame_index = 0; frame_index < stream.frame_count; frame_index++) {
      const frame = await post('/v1/match/replay/frame', { frame_index }, stream.replay_token);
      assert(frame.ok, JSON.stringify(frame));
      assert.equal(frame.side, stream.side);
      assert.equal('commands' in frame, false);
      assert.equal('replay' in frame, false);
      assert.deepEqual(frame.state.explored[1 - stream.side], []);
      assert.deepEqual(frame.state.last_seen[1 - stream.side], []);
      assert.deepEqual(frame.state.researched[1 - stream.side], []);
      assert(Object.values(frame.state.balances[1 - stream.side]).every(value => value === 0));
      last = frame;
    }
    assert.equal(last.tick, replay.end_tick);
    assert.deepEqual(last.terminal.results, replay.terminal.results);
  }
  for (let side = 0; side < 2; side++) {
    const native = spawn(godotBin, ['--headless', '--path', resolve('game'),
      '--script', 'res://tests/multiplayer_replay_client_test.gd'], {
      env: { ...process.env, AOMX_TEST_MATCH_ENDPOINT: origin,
        AOMX_TEST_MATCH_CODE: codes[side], AOMX_TEST_MATCH_PLAYER: players[side],
        AOMX_TEST_MATCH_ID: replay.match_id, AOMX_TEST_EXPECT_SIDE: String(side) },
      stdio: ['ignore', 'pipe', 'pipe'] });
    let output = '';
    native.stdout.on('data', chunk => { output += chunk; });
    native.stderr.on('data', chunk => { output += chunk; });
    const [code] = await once(native, 'exit');
    assert.equal(code, 0, output);
    assert.match(output, /AOMX_REPLAY_CLIENT_PASS/);
  }
  process.stdout.write(JSON.stringify({ ok: true, frame_count: streams[0].frame_count,
    end_tick: replay.end_tick, participant_views: 2, native_replay_clients: 2 }) + '\n');
} finally {
  if (server) await new Promise(resolve => server.close(resolve));
  session?.close();
  rmSync(dir, { recursive: true, force: true });
}
