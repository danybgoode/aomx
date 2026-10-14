import fs from 'node:fs';
import { randomBytes, createHash } from 'node:crypto';
import pg from 'pg';

const label = process.argv[2];
const output = process.env.AOMX_INVITE_OUTPUT_PATH;
const url = process.env.AOMX_DATABASE_URL;
if (!label || !/^[a-zA-Z0-9_-]{3,80}$/.test(label) || !output || !url) {
  throw new Error('Usage: AOMX_DATABASE_URL=... AOMX_INVITE_OUTPUT_PATH=/private/path npm run alpha:invite -- <label>');
}
const token = randomBytes(24).toString('base64url');
const hash = createHash('sha256').update(token).digest('hex');
const client = new pg.Client({ connectionString: url, ssl: ['localhost', '127.0.0.1'].includes(new URL(url).hostname) ? false : { rejectUnauthorized: true } });
await client.connect();
try {
  await client.query('insert into alpha_private.invite_tokens(token_hash,label) values ($1,$2)', [hash, label]);
  fs.writeFileSync(output, JSON.stringify({ label, token, created_at: new Date().toISOString() }) + '\n', { flag: 'wx', mode: 0o600 });
  process.stdout.write(`Invite ${label} created; code saved to the private output path.\n`);
} finally { await client.end(); }
