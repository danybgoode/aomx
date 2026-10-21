import test from 'node:test';
import assert from 'node:assert/strict';
import { MatchSession } from '../src/multiplayer/session.mjs';
import { MemoryMatchStore } from '../src/multiplayer/store.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';
import { readFileSync } from 'node:fs';

const CODE_A = 'invite_A_abcdefghijklmnopqrstuvwxyz';
const CODE_B = 'invite_B_abcdefghijklmnopqrstuvwxyz';
const PLAYER_A = 'player_alpha_001';
const PLAYER_B = 'player_bravo_002';

class FakeWorker {
  constructor() { this.tick = 0; this.orders = []; this.closed = false; }
  async request(message) {
    if (message.type === 'init') return this.state();
    if (message.type === 'tick') { this.tick++; return this.state(); }
    if (message.type === 'order') {
      this.orders.push(message);
      return { ok: true, reason: 'moving', tick: this.tick, sequence: this.orders.length,
        hash: `hash-${this.tick}` };
    }
    throw new Error('unknown_fake_request');
  }
  state() { return { ok: true, tick: this.tick, hash: `hash-${this.tick}`,
    content_hash: SkirmishVersions.contentHash, game_version: SkirmishVersions.game,
    state: { result: this.tick >= 2 ? 'win' : '',
      result_reason: this.tick >= 2 ? 'conquest' : '', entities: [] } }; }
  close() { this.closed = true; }
}

function setup({ enabled = true, reconnectMs = 60000 } = {}) {
  const store = new MemoryMatchStore();
  store.addInvite(CODE_A);
  store.addInvite(CODE_B);
  let time = 1000;
  const worker = new FakeWorker();
  const gate = { enabled };
  const session = new MatchSession({ store, workerFactory: async () => worker,
    evaluateAdmission: () => gate.enabled, now: () => time, reconnectMs, tickMs: 1e9 });
  const join = (code, playerId, versions = {}) => session.join({ invite_code: code,
    player_id: playerId, ...SkirmishVersions.public(), ...versions });
  return { store, worker, session, join, gate, setTime: value => { time = value; } };
}

test('two individual codes bind opposing slots and versions before match start', async () => {
  const { session, join, store } = setup();
  assert.equal((await join(CODE_A, PLAYER_A, { game_version: 'wrong' })).reason, 'version_mismatch');
  assert.equal((await join(CODE_A, PLAYER_A, { content_hash: 'old-content' })).reason, 'version_mismatch');
  assert.equal((await join(CODE_A, PLAYER_A, { simulation_hash: 'old-sim' })).reason, 'version_mismatch');
  assert.equal((await join(CODE_A, PLAYER_A)).side, 0);
  assert.equal(session.status, 'waiting');
  assert.equal((await join(CODE_A, PLAYER_B)).reason, 'invite_invalid');
  const second = await join(CODE_B, PLAYER_B);
  assert.equal(second.side, 1);
  assert.equal(session.status, 'playing');
  const extra = 'invite_C_abcdefghijklmnopqrstuvwxyz';
  store.addInvite(extra);
  assert.equal((await join(extra, 'player_charlie_003')).reason, 'match_full');
  assert.equal([...store.invites.values()].filter(row => row.playerId === null).length, 1);
  assert.equal((await join(CODE_B, PLAYER_A)).reason, 'invite_invalid');
  store.revoke(CODE_B);
  assert.equal((await join(CODE_B, PLAYER_B)).reason, 'invite_invalid');
  session.close();
});

test('checkout client and server advertise the same simulation hash', () => {
  assert(readFileSync(new URL('../game/alpha_config.gd', import.meta.url), 'utf8')
    .includes(`const SIMULATION_HASH := "${SkirmishVersions.simulationHash}"`));
});

test('a revoked code preserves its binding while the player claims a replacement', async () => {
  const store = new MemoryMatchStore();
  const replacement = 'invite_C_abcdefghijklmnopqrstuvwxyz';
  store.addInvite(CODE_A);
  store.addInvite(CODE_B);
  store.addInvite(replacement);
  assert.equal((await store.claimInvite(CODE_A, PLAYER_A)).ok, true);
  assert.equal((await store.claimInvite(CODE_B, PLAYER_A)).reason, 'player_already_bound');
  store.revoke(CODE_A);
  assert.equal((await store.verifyInvite(CODE_A, PLAYER_A)).reason, 'invite_invalid');
  assert.equal((await store.claimInvite(CODE_B, PLAYER_A)).ok, true);
  assert.equal((await store.claimInvite(replacement, PLAYER_A)).reason, 'player_already_bound');
  assert.equal((await store.claimInvite(CODE_A, PLAYER_A)).reason, 'invite_invalid');
  assert.equal((await store.claimInvite(CODE_B, PLAYER_B)).reason, 'invite_invalid');
});

test('rotating a code reclaims the same slot and invalidates its old access token', async () => {
  const { session, join, store } = setup();
  const a = await join(CODE_A, PLAYER_A);
  const replacement = 'invite_C_abcdefghijklmnopqrstuvwxyz';
  store.addInvite(replacement);
  store.revoke(CODE_A);
  const rotated = await join(replacement, PLAYER_A);
  assert.equal(rotated.ok, true);
  assert.equal(rotated.side, 0);
  assert.equal(session.slots[1], null);
  assert.equal((await session.state(a.token)).reason, 'unauthorized');
  assert.equal((await join(CODE_B, PLAYER_B)).side, 1);
  assert.deepEqual(session.slots.map(slot => slot.playerId), [PLAYER_A, PLAYER_B]);
  session.close();
});

test('commands are serialized, idempotent and bound to the slot', async () => {
  const { session, join, worker } = setup();
  const a = await join(CODE_A, PLAYER_A);
  const b = await join(CODE_B, PLAYER_B);
  const order = { match_id: a.match_id, side: 0, expected_tick: 0,
    sequence: 1, kind: 'move', actor_id: 2, target: [5, 5] };
  const first = await session.order(a.token, order);
  assert.equal(first.ok, true);
  assert.equal((await session.order(a.token, order)).duplicate, true);
  assert.equal((await session.order(a.token, { ...order, target: [6, 6] })).reason, 'sequence_mismatch');
  assert.equal((await session.order('bad', order)).reason, 'unauthorized');
  assert.equal((await session.order(b.token, order)).reason, 'wrong_match_or_slot');
  assert.equal((await session.order(b.token, { ...order, side: 1 })).ok, true);
  assert.deepEqual(worker.orders.map(row => row.side), [0, 1]);
  session.close();
});

test('one terminal record per slot is retained for participants only', async () => {
  const { session, join, store } = setup();
  const a = await join(CODE_A, PLAYER_A);
  await join(CODE_B, PLAYER_B);
  await session.tick();
  await session.tick();
  assert.equal(session.status, 'complete');
  assert.deepEqual((await session.state(a.token)).terminal.results, ['win', 'loss']);
  assert.equal(store.records.size, 1);
  const replay = await session.replay(CODE_A, PLAYER_A, a.match_id);
  assert.equal(replay.ok, true);
  assert.equal(replay.side, 0);
  assert.equal(typeof replay.replay_token, 'string');
  assert.equal('replay' in replay, false);
  assert.equal((await session.replay(CODE_A, PLAYER_B, a.match_id)).reason, 'invite_invalid');
  session.close();
});

test('a replacement code opens only its bound installation’s retained replay', async () => {
  const { session, join, store } = setup();
  const a = await join(CODE_A, PLAYER_A);
  await join(CODE_B, PLAYER_B);
  await session.tick();
  await session.tick();
  const replacement = 'invite_C_abcdefghijklmnopqrstuvwxyz';
  store.addInvite(replacement);
  assert.equal((await session.replay(replacement, PLAYER_A, a.match_id)).reason, 'invite_invalid');
  store.revoke(CODE_A);
  assert.equal((await store.claimInvite(replacement, PLAYER_A)).ok, true);
  assert.equal((await session.replay(CODE_A, PLAYER_A, a.match_id)).reason, 'invite_invalid');
  assert.equal((await session.replay(replacement, PLAYER_B, a.match_id)).reason, 'invite_invalid');
  const replay = await session.replay(replacement, PLAYER_A, a.match_id);
  assert.equal(replay.ok, true);
  assert.equal(replay.side, 0);
  session.close();
});

test('withdrawal ends an active match and invalidates an already issued replay token', async () => {
  const { session, join, store } = setup();
  const a = await join(CODE_A, PLAYER_A);
  await join(CODE_B, PLAYER_B);
  store.deletePlayer(PLAYER_A);
  await session.tick();
  assert.equal(session.status, 'no_result');
  assert.equal((await session.state(a.token)).reason, 'unauthorized');
  session.close();

  const completed = setup();
  const participant = await completed.join(CODE_A, PLAYER_A);
  await completed.join(CODE_B, PLAYER_B);
  await completed.session.tick();
  await completed.session.tick();
  const replay = await completed.session.replay(CODE_B, PLAYER_B, participant.match_id);
  assert.equal(replay.ok, true);
  completed.store.deletePlayer(PLAYER_A);
  assert.equal((await completed.session.replayFrame(replay.replay_token, 0)).reason, 'replay_unavailable');
  completed.session.close();
});

test('60-second expiry gives no result to a returning participant', async () => {
  const { session, join, setTime, store } = setup();
  const a = await join(CODE_A, PLAYER_A);
  await join(CODE_B, PLAYER_B);
  setTime(61001);
  const state = await session.state(a.token);
  assert.equal(state.status, 'no_result');
  assert.deepEqual(state.terminal.results, [null, null]);
  const rejoined = await join(CODE_A, PLAYER_A);
  assert.equal(rejoined.status, 'no_result');
  assert.equal(rejoined.terminal.reason, 'reconnect_expired');
  assert.equal((await session.state(rejoined.token)).status, 'no_result');
  assert.equal(store.records.size, 0);
  session.close();
});

test('a long wait for the second invite does not consume the in-play reconnect window', async () => {
  const { session, join, setTime, store } = setup();
  const first = await join(CODE_A, PLAYER_A);
  setTime(121001);
  const second = await join(CODE_B, PLAYER_B);
  assert.equal(first.status, 'waiting');
  assert.equal(second.status, 'playing');
  await session.tick();
  assert.equal(session.status, 'playing');
  assert.equal((await session.state(first.token)).status, 'playing');
  setTime(181002);
  await session.tick();
  assert.equal(session.status, 'no_result');
  assert.equal(session.terminal.reason, 'reconnect_expired');
  assert.equal(store.records.size, 0);
  session.close();
});

test('admission flag closes new sessions without claiming codes', async () => {
  const { join, store, session } = setup({ enabled: false });
  assert.equal((await join(CODE_A, PLAYER_A)).reason, 'match_disabled');
  assert.equal(store.invites.size, 2);
  assert.equal([...store.invites.values()].every(row => row.playerId === null), true);
  session.close();
});

test('disabling admission preserves live reconnect but closes new slots', async () => {
  const { join, gate, session } = setup();
  const first = await join(CODE_A, PLAYER_A);
  gate.enabled = false;
  assert.equal((await join(CODE_B, PLAYER_B)).reason, 'match_disabled');
  const rejoined = await join(CODE_A, PLAYER_A);
  assert.equal(rejoined.side, 0);
  assert.notEqual(rejoined.token, first.token);
  assert.equal((await session.state(first.token)).reason, 'unauthorized');
  session.close();
});

test('simultaneous joins cannot claim the same slot', async () => {
  const { join, session } = setup();
  const admitted = await Promise.all([join(CODE_A, PLAYER_A), join(CODE_B, PLAYER_B)]);
  assert.deepEqual(admitted.map(row => row.side), [0, 1]);
  session.close();
});

test('stale tick and wrong match are rejected before mutation', async () => {
  const { join, session, worker } = setup();
  const a = await join(CODE_A, PLAYER_A);
  await join(CODE_B, PLAYER_B);
  const order = { match_id: a.match_id, side: 0, expected_tick: 0,
    sequence: 1, kind: 'stop', actor_id: 2, target: '' };
  assert.equal((await session.order(a.token, { ...order, match_id: 'other' })).reason, 'wrong_match_or_slot');
  session.lastState.tick = 31;
  assert.equal((await session.order(a.token, order)).reason, 'stale_order');
  assert.equal(worker.orders.length, 0);
  session.close();
});

test('replay lookup cannot consume an unused invitation', async () => {
  const { session, store, gate, join } = setup({ enabled: false });
  assert.equal((await session.replay(CODE_A, PLAYER_A, session.matchId)).reason, 'invite_invalid');
  assert.equal([...store.invites.values()].every(row => row.playerId === null), true);
  gate.enabled = true;
  assert.equal((await join(CODE_A, PLAYER_A)).side, 0);
  session.close();
});

test('failed worker init closes the process and gives both participants no result', async () => {
  const { session, join, worker } = setup();
  worker.state = () => ({ ok: true, content_hash: 'wrong', game_version: SkirmishVersions.game });
  const first = await join(CODE_A, PLAYER_A);
  const second = await join(CODE_B, PLAYER_B);
  assert.equal(second.status, 'no_result');
  assert.equal(second.terminal.reason, 'host_version_mismatch');
  assert.equal(worker.closed, true);
  assert.equal((await session.state(first.token)).status, 'no_result');
  session.close();
});
