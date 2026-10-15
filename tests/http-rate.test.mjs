import test from 'node:test';
import assert from 'node:assert/strict';
import { serve } from '../src/funnel/http.mjs';

test('private invite rate limits stay separate behind one reverse proxy address', async () => {
  const ingest = { async accept() { return { status: 'accepted', receipt_id: 'receipt-test' }; } };
  const server = serve(ingest, { port: 0, publicMode: true, requestsPerMinute: 1,
    globalRequestsPerMinute: 4 });
  await new Promise(resolve => server.on('listening', resolve));
  try {
    const origin = `http://127.0.0.1:${server.address().port}`;
    const post = code => fetch(`${origin}/v1/events`, { method: 'POST',
      headers: { 'x-aomx-invite-code': code, 'content-type': 'application/json' },
      body: '{}' });
    assert.equal((await post('invited_player_one_123456789')).status, 200);
    assert.equal((await post('invited_player_one_123456789')).status, 429);
    assert.equal((await post('invited_player_two_123456789')).status, 200);
    assert.equal((await post('invited_player_three_123456789')).status, 200);
    assert.equal((await post('invited_player_four_123456789')).status, 429);
  } finally { await new Promise(resolve => server.close(resolve)); }
});
