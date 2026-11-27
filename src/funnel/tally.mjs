import { timingSafeEqual } from 'node:crypto';

// tally's members view (tally.goldenfrijoles.com, the owner's analytics app): GET /v1/tally/{summary|members|log}.
// Daniel asked for it on 2026-11-27 ("members lists have to be available in all projects"). Off unless
// AOMX_TALLY_KEY is set; any request without that exact bearer key is the same 404 as an unknown path. Read-only,
// over the ingest role's existing SELECT grants (audit_events, invite_tokens). Players stay pseudonymous: the
// installation ID is shortened, the invite label is the operator's own name for the key, nothing else is shown.

export function tallyAuthorized(header, key) {
  if (typeof key !== 'string' || key.length < 32 || typeof header !== 'string' || !header.startsWith('Bearer ')) return false;
  const given = Buffer.from(header.slice(7).trim());
  const expected = Buffer.from(key);
  return given.length === expected.length && timingSafeEqual(given, expected);
}

const int = (v, d, lo, hi) => Math.min(hi, Math.max(lo, Number.parseInt(v ?? '', 10) || d));
const SORT = { player: 'player', label: 'label', claimed_at: 'claimed_at', first_seen: 'first_seen', last_seen: 'last_seen',
  events: 'events', matches: 'matches', missions: 'missions', status: 'status' };
const PLAYERS = `
  with p as (
    select player_id, min(received_at) first_seen, max(received_at) last_seen,
           count(*) filter (where status in ('accepted', 'excluded')) events,
           count(*) filter (where status in ('accepted', 'excluded') and event_type in ('match_completed', 'wonder_match_completed')) matches,
           count(*) filter (where status in ('accepted', 'excluded') and event_type = 'campaign_mission_completed') missions
    from alpha_private.audit_events where player_id is not null group by player_id
  )
  select left(coalesce(p.player_id, i.player_id), 8) player, coalesce(i.label, '—') label, i.claimed_at,
         p.first_seen, p.last_seen, coalesce(p.events, 0)::int events, coalesce(p.matches, 0)::int matches,
         coalesce(p.missions, 0)::int missions,
         case when i.revoked then 'revoked' when i.player_id is null and p.player_id is null then 'unclaimed'
              when i.token_hash is null then 'no invite' else 'active' end status
  from p full join alpha_private.invite_tokens i on i.player_id = p.player_id`;

export async function tallyAnswer(pool, what, params) {
  const size = int(params.get('size'), 25, 5, 200);
  const offset = (int(params.get('page'), 1, 1, 100000) - 1) * size;
  const q = (params.get('q') ?? '').trim();
  if (what === 'members') {
    const col = SORT[params.get('sort')] ?? 'last_seen';
    const dir = params.get('dir') === 'asc' ? 'asc' : 'desc';
    const where = `where $1 = '' or label ilike '%' || $1 || '%' or player ilike $1 || '%'`;
    const total = await pool.query(`select count(*)::int n from (${PLAYERS}) m ${where}`, [q]);
    const { rows } = await pool.query(`select * from (${PLAYERS}) m ${where} order by ${col} ${dir} nulls last, player limit $2 offset $3`,
      [q, size, offset]);
    return { total: total.rows[0].n, rows, columns: [
      { key: 'player', label: 'Player', sort: true }, { key: 'label', label: 'Invite', sort: true },
      { key: 'status', label: 'Status', sort: true }, { key: 'events', label: 'Events', type: 'number', sort: true },
      { key: 'matches', label: 'Matches', type: 'number', sort: true }, { key: 'missions', label: 'Missions', type: 'number', sort: true },
      { key: 'claimed_at', label: 'Claimed', type: 'date', sort: true }, { key: 'first_seen', label: 'First seen', type: 'date', sort: true },
      { key: 'last_seen', label: 'Last seen', type: 'date', sort: true }] };
  }
  if (what === 'summary') {
    const days = int(params.get('days'), 30, 1, 400);
    const { rows: [s] } = await pool.query(`
      select (select count(*) from alpha_private.invite_tokens where not revoked)::int invites,
             (select count(*) from alpha_private.invite_tokens where not revoked and player_id is not null)::int claimed,
             (select count(distinct player_id) from alpha_private.audit_events where status in ('accepted', 'excluded'))::int players,
             (select count(distinct player_id) from alpha_private.audit_events
               where status in ('accepted', 'excluded') and received_at >= now() - make_interval(days => $1))::int active,
             (select count(*) from alpha_private.audit_events
               where status in ('accepted', 'excluded') and received_at >= now() - make_interval(days => $1))::int events,
             (select count(*) from alpha_private.audit_events where event_type = 'match_started' and status in ('accepted', 'excluded'))::int started,
             (select count(*) from alpha_private.audit_events
               where event_type in ('match_completed', 'wonder_match_completed') and status in ('accepted', 'excluded'))::int completed,
             (select count(*) from alpha_private.audit_events where event_type = 'campaign_mission_completed' and status in ('accepted', 'excluded'))::int missions,
             (select count(*) from alpha_private.audit_events where status in ('rejected', 'quarantined'))::int rejected`, [days]);
    const { rows: daily } = await pool.query(`
      select to_char(received_at at time zone 'UTC', 'YYYY-MM-DD') d, count(distinct player_id)::int n
      from alpha_private.audit_events where status in ('accepted', 'excluded') and received_at >= now() - make_interval(days => $1)
      group by 1 order by 1`, [days]);
    const pct = (a, b) => b ? `${Math.round(a / b * 100)}%` : '—';
    return {
      tiles: [
        { label: 'Players', value: s.players, sub: `${s.active} played in range` },
        { label: 'Invites claimed', value: s.claimed, sub: `of ${s.invites} active invites` },
        { label: 'Matches finished', value: s.completed, sub: `${pct(s.completed, s.started)} of ${s.started} started` },
        { label: 'Campaign missions', value: s.missions, sub: 'completed' },
        { label: 'Events in range', value: s.events, sub: `${s.rejected} rejected or quarantined, all time` }],
      sections: [{ title: 'Alpha', kind: 'kv', rows: [['Active invites', s.invites], ['Claimed', s.claimed], ['Players seen', s.players],
        ['Played in range', s.active], ['Matches started', s.started], ['Matches finished', s.completed], ['Missions completed', s.missions]] }],
      daily, daily_label: 'Players per day' };
  }
  if (what === 'log') {
    const total = await pool.query(`select count(*)::int n from alpha_private.audit_events where $1 = '' or event_type ilike '%' || $1 || '%'`, [q]);
    const { rows } = await pool.query(`
      select received_at at, coalesce(event_type, '—') name, left(coalesce(player_id, '—'), 8) player, status
      from alpha_private.audit_events where $1 = '' or event_type ilike '%' || $1 || '%'
      order by id desc limit $2 offset $3`, [q, size, offset]);
    return { total: total.rows[0].n, rows, columns: [{ key: 'at', label: 'When', type: 'date' }, { key: 'name', label: 'Event' },
      { key: 'player', label: 'Player' }, { key: 'status', label: 'Outcome' }] };
  }
  return null;
}
