import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import pg from 'pg';
import { createHash } from 'node:crypto';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { serve } from '../src/funnel/http.mjs';

const url = process.env.AOMX_TEST_DATABASE_URL;
test('Postgres keeps a stable receipt across service restart and hides operator routes', { skip: !url }, async () => {
  const admin = new pg.Client({ connectionString: url, ssl: false });
  await admin.connect();
  await admin.query('drop schema if exists alpha_private cascade');
  await admin.query(`do $$ begin
    if not exists (select 1 from pg_roles where rolname='anon') then create role anon; end if;
    if not exists (select 1 from pg_roles where rolname='authenticated') then create role authenticated; end if;
    if not exists (select 1 from pg_roles where rolname='aomx_ingest') then create role aomx_ingest; end if;
  end $$`);
  await admin.query(fs.readFileSync(new URL('../db/001_alpha_audit.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/002_ingest_grants.sql', import.meta.url), 'utf8'));
  await admin.query(fs.readFileSync(new URL('../db/003_publication_reading_hash.sql', import.meta.url), 'utf8'));
  const grants = await admin.query(`select
    has_table_privilege('aomx_ingest','alpha_private.audit_events','INSERT') as audit_insert,
    has_table_privilege('aomx_ingest','alpha_private.report_history','SELECT') as report_select,
    has_table_privilege('aomx_ingest','alpha_private.publication_days','INSERT') as publish_insert`);
  assert.deepEqual(grants.rows[0], { audit_insert: true, report_select: false, publish_insert: false });
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
