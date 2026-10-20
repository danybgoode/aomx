import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import pg from 'pg';
import { createHash } from 'node:crypto';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { serve } from '../src/funnel/http.mjs';
import { retention } from '../src/alpha/retention.mjs';
import { PostgresMatchStore } from '../src/multiplayer/store.mjs';

const url = process.env.AOMX_TEST_DATABASE_URL;
test('Postgres preview policy excludes a client that claims public eligibility', async () => {
  const persisted = [];
  const client = {
    async query(sql, params) {
      if (sql.startsWith('select row from alpha_private.audit_events')) {
        return { rows: persisted.map(row => ({ row })) };
      }
      if (sql.startsWith('insert into alpha_private.audit_events')) persisted.push(params[7]);
      return { rows: [] };
    },
    release() {}
  };
  const pool = { async connect() { return client; }, async end() {} };
  const funnel = new PostgresFunnel(null, { pool, forceExcludeReason: 'preview_environment',
    resolveFlag: () => ({ value: true, environment: 'preview' }),
    now: () => new Date('2026-10-20T12:00:00.000Z') });
  const base = { schema_version: 1, player_id: 'player_preview_01',
    claimed_at: '2026-10-14T12:00:00.000Z', game_version: 'game-1',
    content_version: 'map-1', mode: 'solo', faction: 'regios', test_account: false, bot: false };
  const rows = [
    { ...base, type: 'game_opened', event_id: 'event_preview_open_01', local_sequence: 1 },
    { ...base, type: 'match_started', event_id: 'event_preview_start_01', match_id: 'match_preview_01', local_sequence: 2 },
    { ...base, type: 'match_completed', event_id: 'event_preview_finish_01', match_id: 'match_preview_01', local_sequence: 3, result: 'win' }
  ];
  for (const row of rows) {
    const receipt = await funnel.accept(row);
    assert.equal(receipt.status, 'excluded');
    assert.equal(receipt.reason, 'preview_environment');
  }
  assert.equal(persisted.length, 3);
  assert.ok(persisted.every(row => row.receipt.status === 'excluded'));
});

test('Postgres keeps a stable receipt across service restart and hides operator routes', { skip: !url }, async () => {
  const admin = new pg.Client({ connectionString: url, ssl: false });
  await admin.connect();
  await admin.query('drop schema if exists alpha_private cascade');
  await admin.query(`do $$ begin
    if not exists (select 1 from pg_roles where rolname='anon') then create role anon; end if;
    if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
    if not exists (select 1 from pg_roles where rolname='aomx_ingest') then create role aomx_ingest; end if;
    if not exists (select 1 from pg_roles where rolname='aomx_match') then create role aomx_match; end if;
    if not exists (select 1 from pg_roles where rolname='aomx_retention') then create role aomx_retention; end if;
  end $$`);
  await admin.query(fs.readFileSync(new URL('../db/001_alpha_audit.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/002_ingest_grants.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/003_publication_reading_hash.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/004_private_matches.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/005_retention.sql', import.meta.url), 'utf8'));
  const grants = await admin.query(`select
    has_table_privilege('aomx_ingest','alpha_private.audit_events','INSERT') as audit_insert,
    has_table_privilege('aomx_ingest','alpha_private.report_history','SELECT') as report_select,
    has_table_privilege('aomx_ingest','alpha_private.publication_days','INSERT') as publish_insert`);
  assert.deepEqual(grants.rows[0], { audit_insert: true, report_select: false, publish_insert: false });
  const matchGrants = await admin.query(`select
    has_table_privilege('aomx_match','alpha_private.invite_tokens','SELECT') as invite_select,
    has_column_privilege('aomx_match','alpha_private.invite_tokens','player_id','UPDATE') as invite_bind,
    has_table_privilege('aomx_match','alpha_private.match_records','INSERT') as record_insert,
    has_table_privilege('aomx_match','alpha_private.audit_events','SELECT') as audit_select,
    has_table_privilege('aomx_match','alpha_private.audit_events','INSERT') as audit_insert`);
  assert.deepEqual(matchGrants.rows[0], { invite_select: true, invite_bind: true,
    record_insert: true, audit_select: false, audit_insert: false });
  const retentionGrants = await admin.query(`select
    has_table_privilege('aomx_retention','alpha_private.audit_events','DELETE') as audit_delete,
    has_table_privilege('aomx_retention','alpha_private.match_records','DELETE') as match_delete,
    has_table_privilege('aomx_retention','alpha_private.invite_tokens','DELETE') as invite_delete,
    has_table_privilege('aomx_retention','alpha_private.report_history','DELETE') as report_delete,
    has_table_privilege('aomx_retention','alpha_private.publication_days','INSERT') as publication_insert`);
  assert.deepEqual(retentionGrants.rows[0], { audit_delete: true, match_delete: true,
    invite_delete: true, report_delete: false, publication_insert: false });
  await admin.end();
  const options = { resolveFlag: () => ({ value: true, environment: 'preview' }),
    now: () => new Date('2026-10-20T12:00:00.000Z'),
    supportedVersions: [{ game: 'game-1', content: 'map-1' }] };
  const funnel = new PostgresFunnel(url, options);
  try {
  const base = { schema_version: 1, player_id: 'player_alpha_01', claimed_at: '2026-10-14T12:00:00.000Z',
    game_version: 'game-1', content_version: 'map-1', mode: 'solo', faction: 'neutral', test_account: false, bot: false };
  const open = { ...base, type: 'game_opened', event_id: 'event_open_01', local_sequence: 1 };
  const start = { ...base, type: 'match_started', event_id: 'event_start_01', match_id: 'match_one_01', local_sequence: 2 };
  const finish = { ...base, type: 'match_completed', event_id: 'event_finish_01', match_id: 'match_one_01', local_sequence: 3, result: 'win' };
  assert.equal((await funnel.accept(open)).status, 'accepted');
  assert.equal((await funnel.accept(start)).status, 'accepted');
  const receipt = await funnel.accept(finish);
  assert.equal(receipt.status, 'accepted');
  await funnel.close();
  const restarted = new PostgresFunnel(url, options);
  assert.deepEqual(await restarted.accept(finish), receipt);
  assert.equal((await restarted.accept({ ...finish, event_id: 'event_finish_02', local_sequence: 4 })).reason, 'duplicate_match_event');
  assert.equal((await restarted.accept({ ...finish, event_id: 'event_bad_01', game_version: 'unknown', local_sequence: 5 })).reason, 'unsupported_game_version');
  assert.equal((await restarted.report('2026-10-24T12:00:00.000Z')).accepted_events, 3);
  const code = 'alpha_private_test_code_123456';
  const hash = createHash('sha256').update(code).digest('hex');
  await restarted.pool.query(`insert into alpha_private.invite_tokens(token_hash,label)
    values ($1,'integration test')`, [hash]);
  const invited = new PostgresFunnel(url, { ...options, requireInvite: true });
  const secondOpen = { ...open, player_id: 'player_beta_0001', event_id: 'event_beta_open_01' };
  await assert.rejects(invited.accept(secondOpen), { message: 'invite_required' });
  const badOpen = { ...secondOpen, event_id: 'event_beta_bad_01', schema_version: 99 };
  assert.equal((await invited.accept(badOpen, { inviteToken: code })).status, 'rejected');
  assert.equal((await restarted.pool.query(`select player_id from alpha_private.invite_tokens where token_hash=$1`, [hash])).rows[0].player_id, null);
  const unsupportedOpen = { ...secondOpen, event_id: 'event_beta_bad_02', game_version: 'unknown' };
  assert.equal((await invited.accept(unsupportedOpen, { inviteToken: code })).reason, 'unsupported_game_version');
  assert.equal((await restarted.pool.query(`select player_id from alpha_private.invite_tokens where token_hash=$1`, [hash])).rows[0].player_id, null);
  const futureOpen = { ...secondOpen, event_id: 'event_beta_bad_03', claimed_at: '2026-10-21T12:00:00.000Z' };
  assert.equal((await invited.accept(futureOpen, { inviteToken: code })).reason, 'clock_ahead');
  assert.equal((await restarted.pool.query(`select player_id from alpha_private.invite_tokens where token_hash=$1`, [hash])).rows[0].player_id, null);
  assert.equal((await invited.accept(secondOpen, { inviteToken: code })).status, 'accepted');
  assert.equal((await restarted.pool.query(`select player_id from alpha_private.invite_tokens where token_hash=$1`, [hash])).rows[0].player_id, secondOpen.player_id);
  await assert.rejects(invited.accept({ ...secondOpen, player_id: 'player_gamma_01' }, { inviteToken: code }), { message: 'invite_invalid' });
  await invited.close();
  const server = serve(restarted, { port: 0, publicMode: true });
  await new Promise(resolve => server.on('listening', resolve));
  const origin = `http://127.0.0.1:${server.address().port}`;
  assert.equal((await fetch(`${origin}/healthz`)).status, 200);
  assert.equal((await fetch(`${origin}/v1/audit`)).status, 404);
  assert.equal((await fetch(`${origin}/v1/report`)).status, 404);
  await new Promise(resolve => server.close(resolve));
  await restarted.close();
  } finally {
    if (!funnel.pool.ending) await funnel.close();
  }
});

test('30-day retention and verified player deletion remove only matching live records', { skip: !url }, async () => {
  const client = new pg.Client({ connectionString: url, ssl: false });
  await client.connect();
  try {
    const players = id => JSON.stringify([{ side: 0, player_id: id },
      { side: 1, player_id: 'other_player_001' }]);
    await client.query(`insert into alpha_private.match_records
      (match_id, created_at, players, terminal, replay, record_hash)
      values ($1,$2,$3,'{}','{}','test'),($4,$5,$6,'{}','{}','test'),($7,$5,$8,'{}','{}','test')`,
    ['old_match', '2026-09-01T00:00:00Z', players('old_player_001'),
      'recent_match', '2026-10-19T00:00:00Z', players('recent_player_001'),
      'deletion_match', players('player_beta_0001')]);
    await client.query(`update alpha_private.audit_events set received_at=$1 where event_id=$2`,
      ['2026-09-01T00:00:00Z', 'event_open_01']);
    await client.query(`insert into alpha_private.invite_tokens(token_hash,label,created_at)
      values ('old_invite_hash','old invitation','2026-09-01T00:00:00Z')`);
    const now = new Date('2026-10-20T12:00:00Z');
    const preview = await retention(client, { now });
    assert.deepEqual(preview.planned, { match_records: 1, audit_events: 1,
      invite_tokens: 1, player_deletions: 0 });
    assert.equal((await client.query(`select count(*)::int as n from alpha_private.match_records`)).rows[0].n, 3);
    assert.deepEqual((await retention(client, { now, apply: true })).deleted,
      { match_records: 1, audit_events: 1, invite_tokens: 1, player_deletions: 0 });
    const removal = await retention(client, { now, playerId: 'player_beta_0001', apply: true });
    assert.deepEqual(removal.deleted, { match_records: 1, audit_events: 4,
      invite_tokens: 1, player_deletions: 0 });
    assert.deepEqual((await client.query(`select match_id from alpha_private.match_records`)).rows,
      [{ match_id: 'recent_match' }]);
    const store = new PostgresMatchStore(url);
    const deletedCode = 'alpha_private_test_code_123456';
    assert.equal((await store.claimInvite(deletedCode, 'player_beta_0001')).reason, 'invite_invalid');
    assert.equal(await store.isDeleted('player_beta_0001'), true);
    await assert.rejects(store.saveRecord({ match_id: 'late_match',
      players: [{ player_id: 'player_beta_0001', code_hash: createHash('sha256').update(deletedCode).digest('hex') },
        { player_id: 'other_player_001', code_hash: 'none' }], terminal: {}, replay: {} }),
    { message: 'participant_withdrew' });
    assert.equal((await store.getRecord('late_match')), null);
    await store.close();
  } finally { await client.end(); }
});
