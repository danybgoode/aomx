import { createHash, randomBytes } from 'node:crypto';
import { MatchSession } from './session.mjs';
import { SkirmishVersions } from './versions.mjs';

const hash = value => createHash('sha256').update(value).digest('hex');
const validPlayer = value => typeof value === 'string' && /^[A-Za-z0-9_-]{8,100}$/.test(value);

class SharedRoomStore {
  constructor(code, records) {
    this.code = code;
    this.codeHash = hash(code);
    this.players = new Set();
    this.records = records;
  }

  async claimInvite(code, playerId) {
    if (code !== this.code || !validPlayer(playerId) ||
      (!this.players.has(playerId) && this.players.size >= 2) ||
      await this.records.isDeleted(playerId)) return { ok: false, reason: 'room_invalid' };
    this.players.add(playerId);
    return { ok: true, codeHash: this.codeHash, playerId };
  }

  async verifyInvite(code, playerId) {
    return code === this.code && this.players.has(playerId) && !await this.records.isDeleted(playerId)
      ? { ok: true, codeHash: this.codeHash, playerId }
      : { ok: false, reason: 'room_invalid' };
  }

  async saveRecord(record) { return this.records.savePublicRecord(record); }
  async getRecord(matchId) { return this.records.getRecord(matchId); }
  async isDeleted(playerId) { return this.records.isDeleted(playerId); }
}

// Public rooms share only a high-entropy code. Each room has its own authoritative
// simulation and slot state; a process restart ends active rooms without a result.
export class PublicRoomHub {
  constructor({ legacySession, records, workerFactory, now = () => Date.now(),
    maxRooms = 8, maxPlaying = 2, waitingTtlMs = 15 * 60_000,
    finishedTtlMs = 30 * 60_000, tickMs = 100 } = {}) {
    if (!legacySession || !records || !workerFactory) throw new Error('room dependencies missing');
    this.legacySession = legacySession;
    this.records = records;
    this.workerFactory = workerFactory;
    this.now = now;
    this.maxRooms = maxRooms;
    this.maxPlaying = maxPlaying;
    this.waitingTtlMs = waitingTtlMs;
    this.finishedTtlMs = finishedTtlMs;
    this.tickMs = tickMs;
    this.rooms = new Map();
    this.tokens = new Map();
    this.replayTokens = new Map();
    this.status = 'ready';
  }

  #prune() {
    for (const [code, room] of this.rooms) {
      if (room.session.status === 'playing') continue;
      const waiting = room.session.status === 'waiting';
      if (!waiting && !room.finishedAt) room.finishedAt = this.now();
      const ttl = waiting ? this.waitingTtlMs : this.finishedTtlMs;
      if (this.now() - (waiting ? room.createdAt : room.finishedAt) < ttl) continue;
      room.session.close();
      this.rooms.delete(code);
      for (const [token, owner] of this.tokens) if (owner === room) this.tokens.delete(token);
      for (const [token, owner] of this.replayTokens) if (owner === room) this.replayTokens.delete(token);
    }
  }

  async create(request = {}) {
    this.#prune();
    if (!SkirmishVersions.matches(request)) return { ok: false, reason: 'version_mismatch', statusCode: 409 };
    if (!validPlayer(request.player_id) || await this.records.isDeleted(request.player_id)) {
      return { ok: false, reason: 'player_invalid', statusCode: 400 };
    }
    if (this.rooms.size >= this.maxRooms) return { ok: false, reason: 'rooms_busy', statusCode: 429 };
    const code = randomBytes(18).toString('base64url');
    const store = new SharedRoomStore(code, this.records);
    const room = { createdAt: this.now(), session: new MatchSession({ store,
      evaluateAdmission: () => true, workerFactory: this.workerFactory, now: this.now,
      tickMs: this.tickMs }) };
    this.rooms.set(code, room);
    const joined = await room.session.join({ ...request, invite_code: code });
    if (!joined.ok) { room.session.close(); this.rooms.delete(code); return joined; }
    this.tokens.set(joined.token, room);
    return { ...joined, room_code: code };
  }

  async join(request = {}) {
    this.#prune();
    const room = this.rooms.get(request.invite_code);
    if (!room) {
      if (typeof request.invite_code === 'string' && /^[A-Za-z0-9_-]{24}$/.test(request.invite_code)) {
        return { ok: false, reason: 'room_not_found', statusCode: 404 };
      }
      return this.legacySession.join(request);
    }
    if (room.session.status === 'waiting' && room.session.slots.filter(Boolean).length === 1 &&
      !room.session.slots.some(slot => slot?.playerId === request.player_id) &&
      [...this.rooms.values()].filter(entry => entry.session.status === 'playing').length >= this.maxPlaying) {
      return { ok: false, reason: 'rooms_busy', statusCode: 429 };
    }
    const joined = await room.session.join(request);
    if (joined.ok) this.tokens.set(joined.token, room);
    return joined;
  }

  state(token) { return (this.tokens.get(token)?.session ?? this.legacySession).state(token); }
  order(token, order) { return (this.tokens.get(token)?.session ?? this.legacySession).order(token, order); }

  async replay(code, playerId, matchId) {
    const room = this.rooms.get(code);
    const answer = await (room?.session ?? this.legacySession).replay(code, playerId, matchId);
    if (room && answer.ok) this.replayTokens.set(answer.replay_token, room);
    return answer;
  }

  replayFrame(token, index) {
    return (this.replayTokens.get(token)?.session ?? this.legacySession).replayFrame(token, index);
  }

  close() {
    for (const room of this.rooms.values()) room.session.close();
    this.rooms.clear();
    this.tokens.clear();
    this.replayTokens.clear();
    this.legacySession.close();
  }
}
