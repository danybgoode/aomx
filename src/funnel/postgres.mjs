import pg from 'pg';
import { createHash } from 'node:crypto';
import { Ingest, validate } from './ingest.mjs';
import { makeReport } from './report.mjs';

// A transaction-wide lock serializes policy decisions across service instances.
// Each decision uses the same pure Ingest policy as the local JSONL prototype.
export class PostgresFunnel {
  constructor(connectionString, { resolveFlag, now, pool, supportedVersions, requireInvite = false } = {}) {
    const hostname = connectionString ? new URL(connectionString).hostname : '';
    const privateHost = ['localhost', '127.0.0.1', 'postgres'].includes(hostname);
    this.pool = pool ?? new pg.Pool({ connectionString, max: 4, connectionTimeoutMillis: 5000,
      idleTimeoutMillis: 30000, ssl: privateHost ? false : { rejectUnauthorized: true } });
    this.resolveFlag = resolveFlag;
    this.now = now;
    this.supportedVersions = supportedVersions;
    this.requireInvite = requireInvite;
  }

  async accept(event, { inviteToken } = {}) {
    const client = await this.pool.connect();
    try {
      await client.query('begin');
      await client.query('select pg_advisory_xact_lock(601103, 1)');
      if (this.requireInvite) {
        if (typeof inviteToken !== 'string' || !/^[A-Za-z0-9_-]{24,80}$/.test(inviteToken)) {
          throw Object.assign(new Error('invite_required'), { statusCode: 401 });
        }
        const hash = createHash('sha256').update(inviteToken).digest('hex');
        const invite = await client.query(`select player_id, revoked from alpha_private.invite_tokens
          where token_hash=$1 for update`, [hash]);
        if (!invite.rows.length || invite.rows[0].revoked ||
          invite.rows[0].player_id && invite.rows[0].player_id !== event?.player_id) {
          throw Object.assign(new Error('invite_invalid'), { statusCode: 401 });
        }
        if (!invite.rows[0].player_id && event?.type !== 'game_opened') {
          throw Object.assign(new Error('invite_must_start_with_open'), { statusCode: 401 });
        }
        if (!invite.rows[0].player_id && !validate(event)) {
          await client.query(`update alpha_private.invite_tokens set player_id=$1, claimed_at=now()
            where token_hash=$2`, [event.player_id, hash]);
        }
      }
      const { rows } = await client.query('select row from alpha_private.audit_events order by id');
      let appended;
      const store = { rows: rows.map(r => r.row), append(row) { appended = row; this.rows.push(row); } };
      const receipt = new Ingest(store, { resolveFlag: this.resolveFlag, now: this.now,
        supportedVersions: this.supportedVersions }).accept(event);
      if (appended) await client.query(`insert into alpha_private.audit_events
        (receipt_id, event_id, player_id, match_id, event_type, status, payload_hash, row, received_at)
        values ($1,$2,$3,$4,$5,$6,$7,$8,$9)`, [receipt.receipt_id, appended.event?.event_id ?? null,
        appended.event?.player_id ?? null, appended.event?.match_id ?? null,
        appended.event?.type ?? null, receipt.status, appended.payload_hash, appended, receipt.received_at]);
      await client.query('commit');
      return receipt;
    } catch (error) {
      await client.query('rollback');
      throw error;
    } finally {
      client.release();
    }
  }

  async health() { await this.pool.query('select 1'); return { ok: true }; }
  async rows() { const { rows } = await this.pool.query('select row from alpha_private.audit_events order by id'); return rows.map(r => r.row); }
  async report(asOf = new Date().toISOString()) {
    const [events, observed] = await Promise.all([this.rows(), this.pool.query('select day from alpha_private.observed_days where complete order by day')]);
    return makeReport(events, asOf, { observedDays: observed.rows.map(r => new Date(r.day).toISOString().slice(0, 10)) });
  }
  async close() { await this.pool.end(); }
}
