import { createHash } from 'node:crypto';

const DAYS = 30;
const PLAYER = /^[A-Za-z0-9_-]{8,100}$/;

export async function retention(client, { now = new Date(), playerId = null, apply = false } = {}) {
  if (!(now instanceof Date) || Number.isNaN(now.valueOf())) throw new Error('invalid_retention_clock');
  if (playerId !== null && !PLAYER.test(playerId)) throw new Error('invalid_player_id');
  const cutoff = new Date(now.getTime() - DAYS * 86400_000);
  const matchFilter = playerId === null ? 'created_at < $1' : 'players @> $1::jsonb';
  const auditFilter = playerId === null ? 'received_at < $1' : 'player_id = $1';
  const parameter = playerId === null ? cutoff : playerId;
  const matchParameter = playerId === null ? cutoff : JSON.stringify([{ player_id: playerId }]);
  const count = async (table, where, value) => Number((await client.query(
    `select count(*)::int as count from alpha_private.${table} where ${where}`, [value])).rows[0].count);
  const planned = {
    match_records: await count('match_records', matchFilter, matchParameter),
    audit_events: await count('audit_events', auditFilter, parameter),
    invite_tokens: await count('invite_tokens', playerId === null ? 'created_at < $1' : 'player_id = $1', parameter),
    player_deletions: playerId === null ? await count('player_deletions', 'deleted_at < $1', cutoff) : 0
  };
  if (!apply) return { ok: true, applied: false, cutoff: cutoff.toISOString(), planned };
  await client.query('begin');
  try {
    await client.query('select pg_advisory_xact_lock(601103, 1)');
    if (playerId !== null) {
      // Match save and funnel acceptance use this lock too. The marker is kept
      // for 30 days, longer than the maximum live match and replay lifetime.
      const playerHash = createHash('sha256').update(playerId).digest('hex');
      await client.query(`insert into alpha_private.player_deletions(player_hash, deleted_at)
        values ($1,$2) on conflict (player_hash) do update set deleted_at=excluded.deleted_at`,
      [playerHash, now]);
    }
    const deleted = {
      match_records: (await client.query(`delete from alpha_private.match_records where ${matchFilter}`, [matchParameter])).rowCount,
      audit_events: (await client.query(`delete from alpha_private.audit_events where ${auditFilter}`, [parameter])).rowCount,
      invite_tokens: (await client.query(`delete from alpha_private.invite_tokens where ${playerId === null ? 'created_at < $1' : 'player_id = $1'}`, [parameter])).rowCount,
      player_deletions: playerId === null ? (await client.query(
        'delete from alpha_private.player_deletions where deleted_at < $1', [cutoff])).rowCount : 0
    };
    await client.query('commit');
    return { ok: true, applied: true, cutoff: cutoff.toISOString(), deleted };
  } catch (error) {
    await client.query('rollback');
    throw error;
  }
}
