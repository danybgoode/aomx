import test from 'node:test';
import assert from 'node:assert/strict';
import { serve } from '../src/funnel/http.mjs';
import { tallyAnswer, tallyAuthorized } from '../src/funnel/tally.mjs';

const KEY = '0123456789abcdef0123456789abcdef';

test('tally: only the exact bearer key, never an unset or short key', () => {
  assert.equal(tallyAuthorized(`Bearer ${KEY}`, KEY), true);
  assert.equal(tallyAuthorized(`Bearer ${KEY}x`, KEY), false);
  assert.equal(tallyAuthorized(`Basic ${KEY}`, KEY), false);
  assert.equal(tallyAuthorized(undefined, KEY), false);
  assert.equal(tallyAuthorized('Bearer short', 'short'), false);
  assert.equal(tallyAuthorized(`Bearer ${KEY}`, null), false);
});

test('tally: a sort outside the whitelist falls back, so no request text reaches the SQL', async () => {
  const seen = [];
  const pool = { query: async (sql, args) => { seen.push({ sql, args }); return { rows: [{ n: 0 }] }; } };
  await tallyAnswer(pool, 'members', new URLSearchParams({ sort: 'player; drop table x', dir: 'up', q: "o'hara" }));
  assert.match(seen[1].sql, /order by last_seen desc nulls last/);
  assert.ok(!seen.some(s => s.sql.includes('drop table')));
  assert.equal(seen[1].args[0], "o'hara");
  assert.equal(await tallyAnswer(pool, 'nope', new URLSearchParams()), null);
});

test('tally: without the key the route is the same 404 as any unknown path', async () => {
  const ingest = { pool: { query: async () => ({ rows: [{ n: 0 }] }) }, health: async () => {} };
  const server = serve(ingest, { port: 0, publicMode: true, tallyKey: KEY });
  await new Promise(r => server.once('listening', r));
  const base = `http://127.0.0.1:${server.address().port}`;
  try {
    assert.equal((await fetch(`${base}/v1/tally/members`)).status, 404);
    assert.equal((await fetch(`${base}/v1/tally/members`, { headers: { authorization: 'Bearer wrong' } })).status, 404);
    const ok = await fetch(`${base}/v1/tally/members`, { headers: { authorization: `Bearer ${KEY}` } });
    assert.equal(ok.status, 200);
    assert.equal((await ok.json()).total, 0);
  } finally { server.close(); }
});
