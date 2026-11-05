import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { PublicRoomHub } from '../src/multiplayer/rooms.mjs';
import { MemoryMatchStore } from '../src/multiplayer/store.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';
import { serveMatch } from '../src/multiplayer/http.mjs';

test('players create isolated private rooms with a shared code and scoped tokens', async () => {
  const records = new MemoryMatchStore();
  const legacySession = { status: 'waiting', async join() { return { ok: false, reason: 'invite_invalid' }; },
    async state() { return { ok: false, reason: 'unauthorized' }; },
    async order() { return { ok: false, reason: 'unauthorized' }; }, close() {} };
  const workerFactory = async () => ({
    async request(message) {
      if (message.type === 'init') return { ok: true, content_hash: SkirmishVersions.contentHash,
        game_version: SkirmishVersions.game, tick: 0, hash: 'init', views: [{ side: 0 }, { side: 1 }] };
      return { ok: false };
    }, close() {},
  });
  const hub = new PublicRoomHub({ legacySession, records, workerFactory, tickMs: 60_000,
    maxRooms: 2, maxPlaying: 2 });
  const server = serveMatch(hub, { port: 0, allowedWebOrigin: 'https://html-classic.itch.zone' });
  await once(server, 'listening');
  const base = `http://127.0.0.1:${server.address().port}`;
  const post = async (path, body) => {
    const res = await fetch(base + path, { method: 'POST', headers: {
      origin: 'https://html-classic.itch.zone', 'content-type': 'application/json' },
    body: JSON.stringify(body) });
    return { status: res.status, data: await res.json() };
  };
  try {
    const preflight = await fetch(base + '/v1/match/create', { method: 'OPTIONS', headers: {
      origin: 'https://html-classic.itch.zone', 'access-control-request-method': 'POST',
      'access-control-request-headers': 'content-type' } });
    assert.equal(preflight.status, 204);
    const a = await post('/v1/match/create', { player_id: 'player0001', ...SkirmishVersions.public() });
    const b = await post('/v1/match/create', { player_id: 'player0003', ...SkirmishVersions.public() });
    assert.equal(a.status, 200);
    assert.equal(b.status, 200);
    assert.notEqual(a.data.room_code, b.data.room_code);
    assert.match(a.data.room_code, /^[A-Za-z0-9_-]{24}$/);
    const joined = await post('/v1/match/join', { invite_code: a.data.room_code,
      player_id: 'player0002', ...SkirmishVersions.public() });
    assert.equal(joined.status, 200);
    assert.equal(joined.data.match_id, a.data.match_id);
    assert.equal(joined.data.side, 1);
    const third = await post('/v1/match/join', { invite_code: a.data.room_code,
      player_id: 'player0004', ...SkirmishVersions.public() });
    assert.equal(third.status, 409);
    assert.equal(third.data.reason, 'match_full');
    const state = await fetch(base + '/v1/match/state', { headers: {
      'x-aomx-match-token': a.data.token } }).then(res => res.json());
    assert.equal(state.match_id, a.data.match_id);
    assert.equal(state.state.side, 0);
    assert.notEqual(state.match_id, b.data.match_id);
    const invalid = await post('/v1/match/create', { player_id: 'player0005', ...SkirmishVersions.public() });
    assert.equal(invalid.status, 429);
    assert.equal(invalid.data.reason, 'rooms_busy');
  } finally {
    hub.close();
    await new Promise(resolve => server.close(resolve));
  }
});
