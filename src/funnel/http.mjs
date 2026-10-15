import http from 'node:http';
import { makeReport } from './report.mjs';

export function serve(ingest, { host = '127.0.0.1', port = 8787 } = {}) {
  const server = http.createServer(async (req, res) => {
    res.setHeader('content-type', 'application/json');
    if (req.method === 'POST' && req.url === '/v1/events') {
      try {
        let body = '';
        for await (const chunk of req) {
          body += chunk;
          if (body.length > 16_384) throw new Error('payload_too_large');
        }
        const receipt = ingest.accept(JSON.parse(body));
        res.statusCode = receipt.status === 'rejected' ? 422 : 200;
        res.end(JSON.stringify(receipt));
      } catch (error) {
        res.statusCode = 400;
        res.end(JSON.stringify({ status: 'rejected', reason: error.message === 'payload_too_large' ? error.message : 'invalid_json' }));
      }
    } else if (req.method === 'GET' && req.url === '/v1/audit') {
      res.end(JSON.stringify(ingest.store.rows));
    } else if (req.method === 'GET' && req.url === '/v1/report') {
      res.end(JSON.stringify(makeReport(ingest.store.rows)));
    } else {
      res.statusCode = 404;
      res.end(JSON.stringify({ error: 'not_found' }));
    }
  });
  server.listen(port, host);
  return server;
}
