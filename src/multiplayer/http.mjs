import http from 'node:http';
import { createHash } from 'node:crypto';
import { isIP } from 'node:net';

const MAX_BODY = 16384;

function send(res, status, body) {
  const bytes = Buffer.from(JSON.stringify(body));
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8',
    'content-length': bytes.length, 'cache-control': 'no-store',
    'x-content-type-options': 'nosniff' });
  res.end(bytes);
}

async function readJson(req) {
  if (!req.headers['content-type']?.startsWith('application/json')) throw Object.assign(new Error('json_required'), { statusCode: 415 });
  let text = '';
  for await (const chunk of req) {
    text += chunk;
    if (Buffer.byteLength(text) > MAX_BODY) throw Object.assign(new Error('body_too_large'), { statusCode: 413 });
  }
  try {
    const data = JSON.parse(text);
    if (!data || Array.isArray(data) || typeof data !== 'object') throw new Error();
    return data;
  } catch { throw Object.assign(new Error('invalid_json'), { statusCode: 400 }); }
}

export function serveMatch(session, { host = '127.0.0.1', port = 8790,
  trustProxyClientIp = false, allowedWebOrigin = '' } = {}) {
  if (allowedWebOrigin && (new URL(allowedWebOrigin).origin !== allowedWebOrigin ||
    !['http:', 'https:'].includes(new URL(allowedWebOrigin).protocol))) {
    throw new Error('allowedWebOrigin must be one exact HTTP(S) origin');
  }
  const hits = new Map();
  const server = http.createServer(async (req, res) => {
    const path = new URL(req.url ?? '/', 'http://local').pathname;
    const origin = req.headers.origin;
    res.setHeader('vary', 'Origin');
    if (origin !== undefined) {
      if (origin !== allowedWebOrigin || !allowedWebOrigin) {
        return send(res, 403, { ok: false, reason: 'origin_denied' });
      }
      res.setHeader('access-control-allow-origin', allowedWebOrigin);
      if (req.method === 'OPTIONS') {
        const requestedMethod = req.headers['access-control-request-method'];
        const allowedMethods = {
          '/v1/match/join': 'POST', '/v1/match/state': 'GET',
          '/v1/match/order': 'POST', '/v1/match/replay': 'POST',
          '/v1/match/replay/frame': 'POST',
        };
        const requestedHeaders = (req.headers['access-control-request-headers'] ?? '').toLowerCase()
          .split(',').map(header => header.trim()).filter(Boolean);
        if (requestedMethod !== allowedMethods[path] || requestedHeaders.some(header =>
          !['content-type', 'x-aomx-match-token', 'x-aomx-replay-token'].includes(header))) {
          return send(res, 403, { ok: false, reason: 'preflight_denied' });
        }
        res.writeHead(204, {
          'access-control-allow-methods': requestedMethod,
          'access-control-allow-headers': requestedHeaders.join(', '),
          'access-control-max-age': '600', 'cache-control': 'no-store',
        });
        return res.end();
      }
    }
    const now = Date.now();
    const minute = Math.floor(now / 60000);
    const bump = key => {
      const previous = hits.get(key);
      const count = previous?.minute === minute ? previous.count + 1 : 1;
      hits.set(key, { minute, count });
      return count;
    };
    const limited = (credential, limit) => {
      const identity = typeof credential === 'string' && /^[A-Za-z0-9_-]{24,100}$/.test(credential)
        ? `credential:${createHash('sha256').update(credential).digest('hex')}`
        : `invalid:${req.socket.remoteAddress ?? 'unknown'}`;
      return bump(`${path}|${identity}`) > limit;
    };
    const proxyIp = req.headers['x-aomx-client-ip'];
    const source = trustProxyClientIp && typeof proxyIp === 'string' && isIP(proxyIp)
      ? proxyIp : req.socket.remoteAddress ?? 'unknown';
    const limitedSource = limit => bump(`${path}|source:${source}`) > limit;
    if (bump('global') > 3000) return send(res, 429, { ok: false, reason: 'rate_limited' });
    if (hits.size > 10000) for (const [key, value] of hits) if (value.minute < minute) hits.delete(key);
    try {
      if (req.method === 'GET' && path === '/healthz') {
        return send(res, 200, { ok: true, service: 'aomx-match', status: session.status });
      }
      if (req.method === 'POST' && path === '/v1/match/join') {
        if (limitedSource(30)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const body = await readJson(req);
        if (limited(body.invite_code, 30)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const answer = await session.join(body);
        return send(res, answer.statusCode ?? (answer.ok ? 200 : 400), answer);
      }
      if (req.method === 'GET' && path === '/v1/match/state') {
        if (limitedSource(2400)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        if (limited(req.headers['x-aomx-match-token'], 2400)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const answer = await session.state(req.headers['x-aomx-match-token']);
        return send(res, answer.statusCode ?? (answer.ok ? 200 : 400), answer);
      }
      if (req.method === 'POST' && path === '/v1/match/order') {
        if (limitedSource(600)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        if (limited(req.headers['x-aomx-match-token'], 600)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const answer = await session.order(req.headers['x-aomx-match-token'], await readJson(req));
        return send(res, answer.statusCode ?? (answer.ok ? 200 : 400), answer);
      }
      if (req.method === 'POST' && path === '/v1/match/replay') {
        if (limitedSource(30)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const body = await readJson(req);
        if (limited(body.invite_code, 30)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const answer = await session.replay(body.invite_code, body.player_id, body.match_id);
        return send(res, answer.statusCode ?? (answer.ok ? 200 : 400), answer);
      }
      if (req.method === 'POST' && path === '/v1/match/replay/frame') {
        if (limitedSource(600)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const token = req.headers['x-aomx-replay-token'];
        if (limited(token, 600)) return send(res, 429, { ok: false, reason: 'rate_limited' });
        const body = await readJson(req);
        const answer = await session.replayFrame(token, body.frame_index);
        return send(res, answer.statusCode ?? (answer.ok ? 200 : 400), answer);
      }
      return send(res, 404, { ok: false, reason: 'not_found' });
    } catch (error) {
      if (error.statusCode) return send(res, error.statusCode, { ok: false, reason: error.message });
      if (process.env.AOMX_DEBUG_MATCH === '1') process.stderr.write(`${error.stack}\n`);
      process.stderr.write(`match request failed: ${error.code ?? error.name ?? 'error'}\n`);
      return send(res, 503, { ok: false, reason: 'service_unavailable' });
    }
  });
  server.listen(port, host);
  return server;
}
