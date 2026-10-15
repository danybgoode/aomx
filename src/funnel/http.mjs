import http from 'node:http';
import { createHash } from 'node:crypto';
import { makeReport } from './report.mjs';

export function serve(ingest, { host = '127.0.0.1', port = 8787, publicMode = false,
  requestsPerMinute = 30, globalRequestsPerMinute = 300 } = {}) {
  const traffic = new Map();
  const server = http.createServer(async (req, res) => {
    res.setHeader('content-type', 'application/json');
    res.setHeader('cache-control', 'no-store');
    if (req.method === 'GET' && req.url === '/healthz') {
      try {
        if (typeof ingest.health === 'function') await ingest.health();
        res.end(JSON.stringify({ ok: true }));
      } catch {
        res.statusCode = 503;
        res.end(JSON.stringify({ ok: false }));
      }
      return;
    }
    if (req.method === 'POST' && req.url === '/v1/events') {
      try {
        if (publicMode) {
          const ip = req.socket.remoteAddress ?? 'unknown';
          const invite = req.headers['x-aomx-invite-code'];
          const key = typeof invite === 'string' && /^[A-Za-z0-9_-]{24,80}$/.test(invite) ?
            `invite:${createHash('sha256').update(invite).digest('hex')}` : `ip:${ip}`;
          const minute = Math.floor(Date.now() / 60_000);
          const bump = k => {
            const bucket = traffic.get(k);
            const count = bucket?.minute === minute ? bucket.count + 1 : 1;
            traffic.set(k, { minute, count });
            return count;
          };
          const count = bump(key);
          const globalCount = bump('global');
          if (traffic.size > 10000) for (const [key, value] of traffic) if (value.minute < minute) traffic.delete(key);
          if (count > requestsPerMinute || globalCount > globalRequestsPerMinute) {
            res.statusCode = 429;
            res.end(JSON.stringify({ error: 'rate_limited' }));
            return;
          }
        }
        const chunks = [];
        let size = 0;
        for await (const chunk of req) {
          size += chunk.length;
          if (size > 16_384) throw new Error('payload_too_large');
          chunks.push(chunk);
        }
        const receipt = await ingest.accept(JSON.parse(Buffer.concat(chunks).toString('utf8')),
          { inviteToken: req.headers['x-aomx-invite-code'] });
        res.statusCode = receipt.status === 'rejected' ? 422 : 200;
        res.end(JSON.stringify(receipt));
      } catch (error) {
        res.statusCode = error.statusCode ?? (error.message === 'payload_too_large' ? 413 : error instanceof SyntaxError ? 400 : 503);
        res.end(JSON.stringify({ error: error.statusCode === 401 ? error.message :
          error.message === 'payload_too_large' ? error.message : error instanceof SyntaxError ? 'invalid_json' : 'service_unavailable' }));
      }
    } else if (!publicMode && req.method === 'GET' && req.url === '/v1/audit') {
      res.end(JSON.stringify(ingest.store.rows));
    } else if (!publicMode && req.method === 'GET' && req.url === '/v1/report') {
      res.end(JSON.stringify(makeReport(ingest.store.rows)));
    } else {
      res.statusCode = 404;
      res.end(JSON.stringify({ error: 'not_found' }));
    }
  });
  server.listen(port, host);
  return server;
}
