import { createHash } from 'node:crypto';
import pg from 'pg';

const tokenHash = token => createHash('sha256').update(token).digest('hex');
const validToken = token => typeof token === 'string' && /^[A-Za-z0-9_-]{24,80}$/.test(token);
const validPlayer = player => typeof player === 'string' && /^[A-Za-z0-9_-]{8,100}$/.test(player);

export class PostgresMatchStore {
  constructor(connectionString, { pool } = {}) {
    if (!connectionString && !pool) throw new Error('match database is required');
    const host = connectionString ? new URL(connectionString).hostname : '';
    this.pool = pool ?? new pg.Pool({ connectionString, max: 2, connectionTimeoutMillis: 5000,
      ssl: ['localhost', '127.0.0.1', 'postgres'].includes(host) ? false : { rejectUnauthorized: true } });
  }

  async claimInvite(token, playerId) {
    if (!validToken(token) || !validPlayer(playerId)) return { ok: false, reason: 'invite_invalid' };
    const client = await this.pool.connect();
    try {
      await client.query('begin');
      const result = await client.query(`select player_id, revoked from alpha_private.invite_tokens
        where token_hash=$1 for update`, [tokenHash(token)]);
      const row = result.rows[0];
      if (!row || row.revoked || row.player_id && row.player_id !== playerId) {
        await client.query('rollback');
        return { ok: false, reason: 'invite_invalid' };
      }
      if (!row.player_id) await client.query(`update alpha_private.invite_tokens
        set player_id=$1, claimed_at=now() where token_hash=$2`, [playerId, tokenHash(token)]);
      await client.query('commit');
      return { ok: true, codeHash: tokenHash(token), playerId };
    } catch (error) {
      await client.query('rollback');
      if (error.code === '23505') return { ok: false, reason: 'player_already_bound' };
      throw error;
    } finally { client.release(); }
  }

  async verifyInvite(token, playerId) {
    if (!validToken(token) || !validPlayer(playerId)) return { ok: false, reason: 'invite_invalid' };
    const { rows } = await this.pool.query(`select player_id, revoked from alpha_private.invite_tokens
      where token_hash=$1`, [tokenHash(token)]);
    const row = rows[0];
    return row && !row.revoked && row.player_id === playerId
      ? { ok: true, codeHash: tokenHash(token), playerId }
      : { ok: false, reason: 'invite_invalid' };
  }

  async saveRecord(record) {
    const hash = createHash('sha256').update(JSON.stringify(record)).digest('hex');
    await this.pool.query(`insert into alpha_private.match_records
      (match_id, players, terminal, replay, record_hash) values ($1,$2,$3,$4,$5)
      on conflict (match_id) do nothing`, [record.match_id, JSON.stringify(record.players),
      JSON.stringify(record.terminal), JSON.stringify(record.replay), hash]);
    return hash;
  }

  async getRecord(matchId) {
    const { rows } = await this.pool.query(`select match_id, players, terminal, replay, record_hash
      from alpha_private.match_records where match_id=$1`, [matchId]);
    return rows[0] ?? null;
  }

  async health() { await this.pool.query('select 1'); return { ok: true }; }
  async close() { await this.pool.end(); }
}

export class MemoryMatchStore {
  constructor() { this.invites = new Map(); this.records = new Map(); }
  addInvite(token) { if (!validToken(token)) throw new Error('invalid_test_invite'); this.invites.set(tokenHash(token), { playerId: null, revoked: false }); }
  revoke(token) { const row = this.invites.get(tokenHash(token)); if (row) row.revoked = true; }
  async claimInvite(token, playerId) {
    if (!validToken(token) || !validPlayer(playerId)) return { ok: false, reason: 'invite_invalid' };
    const hash = tokenHash(token);
    const row = this.invites.get(hash);
    if (!row || row.revoked || row.playerId && row.playerId !== playerId) return { ok: false, reason: 'invite_invalid' };
    if ([...this.invites.values()].some(other => other !== row && other.playerId === playerId)) return { ok: false, reason: 'player_already_bound' };
    row.playerId = playerId;
    return { ok: true, codeHash: hash, playerId };
  }
  async verifyInvite(token, playerId) {
    if (!validToken(token) || !validPlayer(playerId)) return { ok: false, reason: 'invite_invalid' };
    const row = this.invites.get(tokenHash(token));
    return row && !row.revoked && row.playerId === playerId
      ? { ok: true, codeHash: tokenHash(token), playerId }
      : { ok: false, reason: 'invite_invalid' };
  }
  async saveRecord(record) { if (!this.records.has(record.match_id)) this.records.set(record.match_id, record); }
  async getRecord(matchId) { return this.records.get(matchId) ?? null; }
  async health() { return { ok: true }; }
  async close() {}
}
