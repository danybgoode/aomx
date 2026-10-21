import { randomBytes, createHash } from 'node:crypto';
import { SkirmishVersions } from './versions.mjs';

const accessToken = () => randomBytes(32).toString('base64url');
const MATCH_ID = /^online_[0-9a-f]{32}$/;
const COMMAND_KINDS = new Set(['move', 'gather', 'attack_move', 'build', 'attack', 'assist',
  'repair', 'cancel', 'train', 'research', 'advance', 'stop', 'hold']);

export class MatchSession {
  constructor({ store, workerFactory, evaluateAdmission, now = () => Date.now(),
    reconnectMs = 60000, tickMs = 100, maxTicks = 100000 } = {}) {
    if (!store || !workerFactory || !evaluateAdmission) throw new Error('match dependencies missing');
    this.store = store;
    this.workerFactory = workerFactory;
    this.evaluateAdmission = evaluateAdmission;
    this.now = now;
    this.reconnectMs = reconnectMs;
    this.tickMs = tickMs;
    this.maxTicks = maxTicks;
    this.matchId = 'online_' + randomBytes(16).toString('hex');
    this.status = 'waiting';
    this.slots = [null, null];
    this.lastState = null;
    this.acceptedCommands = [];
    this.checkpoints = [];
    this.terminal = null;
    this.busyTick = false;
    this.orderQueue = Promise.resolve();
    this.joinQueue = Promise.resolve();
    this.replayStreams = new Map();
  }

  join(request = {}) {
    const result = this.joinQueue.then(() => this.#join(request));
    this.joinQueue = result.catch(() => {});
    return result;
  }

  async #join({ invite_code: code, player_id: playerId, ...versions } = {}) {
    if (!SkirmishVersions.matches(versions)) return { ok: false, reason: 'version_mismatch', statusCode: 409 };
    const sameSlot = typeof code === 'string' && this.slots.some(slot => slot?.playerId === playerId &&
      slot.codeHash === createHash('sha256').update(code).digest('hex'));
    if ((this.status === 'complete' || this.status === 'no_result') && !sameSlot) return { ok: false, reason: 'match_closed', statusCode: 409 };
    if (!sameSlot && this.slots.every(Boolean)) return { ok: false, reason: 'match_full', statusCode: 409 };
    if (!sameSlot && !this.evaluateAdmission(playerId)) return { ok: false, reason: 'match_disabled', statusCode: 403 };
    const claimed = await this.store.claimInvite(code, playerId);
    if (!claimed.ok) return { ...claimed, statusCode: 401 };
    let side = this.slots.findIndex(slot => slot?.codeHash === claimed.codeHash && slot.playerId === playerId);
    if (side < 0) side = this.slots.findIndex(slot => slot === null);
    if (side < 0) return { ok: false, reason: 'match_full', statusCode: 409 };
    const current = this.slots[side];
    if (current && this.status === 'playing' && this.now() - current.lastSeen > this.reconnectMs) {
      await this.#expire();
    }
    const token = accessToken();
    this.slots[side] = { codeHash: claimed.codeHash, playerId, token, lastSeen: this.now(),
      nextSequence: current?.nextSequence ?? 1, lastOrder: current?.lastOrder ?? null };
    if (this.slots.every(Boolean) && this.status === 'waiting') await this.#start();
    return { ok: true, match_id: this.matchId, side, team_id: side, token,
      status: this.status, next_sequence: this.slots[side].nextSequence,
      reconnect_seconds: this.reconnectMs / 1000, terminal: this.terminal,
      ...SkirmishVersions.public() };
  }

  async #start() {
    try {
      this.worker = await this.workerFactory();
      const init = await this.worker.request({ type: 'init', map_id: 'la_roma',
        factions: ['regios', 'poblanos'], seed: 1 });
      if (!init.ok || init.content_hash !== SkirmishVersions.contentHash ||
        init.game_version !== SkirmishVersions.game) throw new Error('match_init_version_mismatch');
      this.lastState = init;
      this.checkpoints.push({ tick: 0, hash: init.hash });
      this.status = 'playing';
      this.interval = setInterval(() => this.tick().catch(() => this.#expire('worker_unavailable')), this.tickMs);
      this.interval.unref?.();
    } catch (error) {
      this.worker?.close();
      this.worker = null;
      this.status = 'no_result';
      this.terminal = { reason: error.message === 'match_init_version_mismatch'
        ? 'host_version_mismatch' : 'host_unavailable', tick: 0, results: [null, null] };
    }
  }

  #slot(token) {
    if (typeof token !== 'string' || token.length < 32) return null;
    const side = this.slots.findIndex(slot => slot?.token === token);
    return side < 0 ? null : { side, slot: this.slots[side] };
  }

  async state(token) {
    const access = this.#slot(token);
    if (!access) return { ok: false, reason: 'unauthorized', statusCode: 401 };
    if (await this.store.isDeleted(access.slot.playerId)) {
      await this.#expire('participant_withdrew');
      return { ok: false, reason: 'unauthorized', statusCode: 401 };
    }
    if (this.status === 'playing') {
      if (this.now() - access.slot.lastSeen > this.reconnectMs) {
        await this.#expire();
      } else access.slot.lastSeen = this.now();
    }
    return { ok: true, status: this.status, match_id: this.matchId, side: access.side,
      tick: this.lastState?.tick ?? 0, hash: this.lastState?.hash ?? null,
      state: this.lastState?.views?.[access.side] ?? null, terminal: this.terminal };
  }

  order(token, order = {}) {
    const result = this.orderQueue.then(() => this.#order(token, order));
    this.orderQueue = result.catch(() => {});
    return result;
  }

  async #order(token, order) {
    const access = this.#slot(token);
    if (!access) return { ok: false, reason: 'unauthorized', statusCode: 401 };
    if (await this.store.isDeleted(access.slot.playerId)) {
      await this.#expire('participant_withdrew');
      return { ok: false, reason: 'unauthorized', statusCode: 401 };
    }
    if (this.status !== 'playing') return { ok: false, reason: 'match_not_playing', statusCode: 409 };
    if (this.now() - access.slot.lastSeen > this.reconnectMs) {
      await this.#expire();
      return { ok: false, reason: 'reconnect_expired', statusCode: 409 };
    }
    const { match_id: matchId, side, expected_tick: expectedTick,
      sequence, kind, actor_id: actorId, target } = order;
    if (matchId !== this.matchId || side !== access.side) {
      return { ok: false, reason: 'wrong_match_or_slot', statusCode: 403 };
    }
    if (!Number.isSafeInteger(sequence) || sequence < 1 || !Number.isSafeInteger(expectedTick) ||
      expectedTick < 0 || !COMMAND_KINDS.has(kind) ||
      !Number.isSafeInteger(actorId) || actorId < 1 || target === undefined) {
      return { ok: false, reason: 'invalid_order', statusCode: 400 };
    }
    const payload = JSON.stringify({ kind, actorId, target, expectedTick });
    if (sequence === access.slot.nextSequence - 1 && access.slot.lastOrder?.payload === payload) {
      return { ...access.slot.lastOrder.response, duplicate: true };
    }
    if (sequence !== access.slot.nextSequence) return { ok: false, reason: 'sequence_mismatch', statusCode: 409 };
    if (expectedTick > this.lastState.tick || this.lastState.tick - expectedTick > 30) {
      return { ok: false, reason: 'stale_order', statusCode: 409 };
    }
    const response = await this.worker.request({ type: 'order', side: access.side,
      kind, actor_id: actorId, target });
    const answer = { ok: Boolean(response.ok), reason: response.reason,
      sequence, tick: response.tick, hash: response.hash };
    access.slot.nextSequence++;
    access.slot.lastOrder = { payload, response: answer };
    access.slot.lastSeen = this.now();
    if (response.ok) this.acceptedCommands.push({ schema_version: SkirmishVersions.commandSchema,
      issued_tick: response.tick, sequence: response.sequence, side: access.side,
      kind, actor_id: actorId, target });
    return answer;
  }

  async tick() {
    if (this.status !== 'playing' || this.busyTick) return;
    for (const slot of this.slots) {
      if (await this.store.isDeleted(slot.playerId)) return this.#expire('participant_withdrew');
    }
    if (this.slots.some(slot => this.now() - slot.lastSeen > this.reconnectMs)) return this.#expire();
    if (this.lastState?.tick >= this.maxTicks) return this.#expire('match_time_limit');
    this.busyTick = true;
    try {
      const state = await this.worker.request({ type: 'tick' });
      if (!state.ok) throw new Error('worker_tick_failed');
      this.lastState = state;
      if (state.tick % 100 === 0) this.checkpoints.push({ tick: state.tick, hash: state.hash });
      if (state.state.result) await this.#complete(state);
    } finally { this.busyTick = false; }
  }

  async #complete(state) {
    if (this.status !== 'playing') return;
    clearInterval(this.interval);
    const result0 = state.state.result;
    const result1 = result0 === 'win' ? 'loss' : result0 === 'loss' ? 'win' : 'draw';
    this.terminal = { tick: state.tick, reason: state.state.result_reason,
      results: [result0, result1], hash: state.hash };
    const replay = { format: 'battle-for-la-roma-multiplayer-replay', replay_schema_version: 1,
      match_id: this.matchId, game_version: SkirmishVersions.game,
      content_version: SkirmishVersions.content, content_hash: state.content_hash,
      map_id: 'la_roma', factions: ['regios', 'poblanos'], initial_seed: 1,
      end_tick: state.tick, commands: this.acceptedCommands, checkpoints: this.checkpoints,
      expected_hash: state.hash, terminal: this.terminal };
    try {
      await this.store.saveRecord({ match_id: this.matchId,
        players: this.slots.map((slot, side) => ({ player_id: slot.playerId,
          code_hash: slot.codeHash, side })), terminal: this.terminal, replay });
      this.status = 'complete';
    } catch {
      this.status = 'no_result';
      this.terminal = { reason: 'record_unavailable', tick: state.tick, results: [null, null] };
    }
    this.worker?.close();
  }

  async #expire(reason = 'reconnect_expired') {
    if (this.status !== 'playing') return;
    clearInterval(this.interval);
    this.status = 'no_result';
    this.terminal = { reason, tick: this.lastState?.tick ?? 0,
      results: [null, null] };
    this.worker?.close();
  }

  async replay(code, playerId, matchId) {
    if (!MATCH_ID.test(matchId ?? '')) return { ok: false, reason: 'invalid_match_id', statusCode: 400 };
    const claim = await this.store.verifyInvite(code, playerId);
    if (!claim.ok) return { ...claim, statusCode: 401 };
    const record = await this.store.getRecord(matchId);
    // A newly issued active code can read this installation's retained matches;
    // verifyInvite above requires that code to be bound to this same player.
    if (!record || !record.players.some(player => player.player_id === playerId)) {
      return { ok: false, reason: 'replay_unavailable', statusCode: 404 };
    }
    const side = record.players.find(player => player.player_id === playerId).side;
    if (Buffer.byteLength(JSON.stringify(record.replay)) > 16 * 1024 * 1024) {
      return { ok: false, reason: 'replay_too_large', statusCode: 413 };
    }
    for (const [key, stream] of this.replayStreams) {
      if (stream.playerId === playerId && stream.matchId === matchId ||
        this.now() - stream.lastAccess > 15 * 60_000) {
        stream.worker?.close();
        this.replayStreams.delete(key);
      }
    }
    if (this.replayStreams.size >= 2) return { ok: false, reason: 'replay_busy', statusCode: 429 };
    const replayToken = accessToken();
    this.replayStreams.set(replayToken, { record, side, playerId, matchId,
      worker: null, lastIndex: -1, lastFrame: null, lastAccess: this.now(),
      queue: Promise.resolve() });
    return { ok: true, match_id: matchId, side, replay_token: replayToken,
      frame_stride: 10, frame_count: Math.ceil(record.replay.end_tick / 10) + 1,
      end_tick: record.replay.end_tick, terminal: record.terminal };
  }

  replayFrame(token, frameIndex) {
    const stream = this.replayStreams.get(token);
    if (!stream) return Promise.resolve({ ok: false, reason: 'unauthorized', statusCode: 401 });
    const result = stream.queue.then(() => this.#replayFrame(stream, frameIndex));
    stream.queue = result.catch(() => {});
    return result;
  }

  async #replayFrame(stream, frameIndex) {
    if (!await this.#replayAvailable(stream)) return this.#closeReplay(stream);
    if (this.now() - stream.lastAccess > 15 * 60_000) {
      stream.worker?.close();
      for (const [key, value] of this.replayStreams) if (value === stream) this.replayStreams.delete(key);
      return { ok: false, reason: 'replay_expired', statusCode: 401 };
    }
    const endTick = stream.record.replay.end_tick;
    const maxIndex = Math.ceil(endTick / 10);
    if (!Number.isSafeInteger(frameIndex) || frameIndex < 0 || frameIndex > maxIndex) {
      return { ok: false, reason: 'replay_frame_invalid', statusCode: 400 };
    }
    stream.lastAccess = this.now();
    if (frameIndex === stream.lastIndex) return stream.lastFrame;
    if (frameIndex !== stream.lastIndex + 1) {
      return { ok: false, reason: 'replay_frame_out_of_order', statusCode: 409 };
    }
    try {
      if (!stream.worker) {
        stream.worker = await this.workerFactory();
        const opened = await stream.worker.request({ type: 'replay_init',
          recording: stream.record.replay });
        if (!opened.ok) return { ok: false, reason: opened.reason,
          first_divergent_tick: opened.first_divergent_tick, statusCode: 409 };
        stream.lastState = opened;
      } else {
        const targetTick = Math.min(endTick, frameIndex * 10);
        const advanced = await stream.worker.request({ type: 'replay_step', target_tick: targetTick });
        if (!advanced.ok) return { ok: false, reason: advanced.reason,
          first_divergent_tick: advanced.first_divergent_tick, statusCode: 409 };
        stream.lastState = advanced;
      }
      const frame = { ok: true, match_id: stream.matchId, side: stream.side,
        frame_index: frameIndex, tick: stream.lastState.tick,
        state: stream.lastState.views[stream.side],
        terminal: frameIndex === maxIndex ? stream.record.terminal : null };
      stream.lastIndex = frameIndex;
      stream.lastFrame = frame;
      if (!await this.#replayAvailable(stream)) return this.#closeReplay(stream);
      if (frameIndex === maxIndex) { stream.worker.close(); stream.worker = null; }
      return frame;
    } catch {
      stream.worker?.close();
      stream.worker = null;
      return { ok: false, reason: 'replay_unavailable', statusCode: 503 };
    }
  }

  async #replayAvailable(stream) {
    if (!await this.store.getRecord(stream.matchId)) return false;
    for (const player of stream.record.players) {
      if (await this.store.isDeleted(player.player_id)) return false;
    }
    return true;
  }

  #closeReplay(stream) {
    stream.worker?.close();
    for (const [key, value] of this.replayStreams) if (value === stream) this.replayStreams.delete(key);
    return { ok: false, reason: 'replay_unavailable', statusCode: 404 };
  }

  close() {
    clearInterval(this.interval);
    this.worker?.close();
    for (const stream of this.replayStreams.values()) stream.worker?.close();
    this.replayStreams.clear();
  }
}
