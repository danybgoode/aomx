import test from 'node:test';
import assert from 'node:assert/strict';
import { once } from 'node:events';
import { serveMatch } from '../src/multiplayer/http.mjs';

test('private match invite quotas are independent behind a shared proxy', async () => {
  const calls = [];
  const session = { status: 'waiting', async join(body) {
    calls.push(body.invite_code);
    return { ok: false, reason: 'invite_invalid', statusCode: 401 };
  } };
  const server = serveMatch(session, { port: 0, trustProxyClientIp: true });
  await once(server, 'listening');
  try {
    const origin = `http://127.0.0.1:${server.address().port}`;
    const join = (code, ip = '203.0.113.10') => fetch(origin + '/v1/match/join', { method: 'POST',
      headers: { 'content-type': 'application/json', 'x-aomx-client-ip': ip },
      body: JSON.stringify({ invite_code: code }) });
    for (let i = 0; i < 30; i++) assert.equal((await join('a'.repeat(32))).status, 401);
    assert.equal((await join('a'.repeat(32))).status, 429);
    assert.equal((await join('b'.repeat(32))).status, 429);
    assert.equal((await join('b'.repeat(32), '203.0.113.11')).status, 401);
    assert.equal(calls.length, 31);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
