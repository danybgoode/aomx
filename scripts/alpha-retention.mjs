import pg from 'pg';
import { retention } from '../src/alpha/retention.mjs';

const url = process.env.AOMX_DATABASE_URL;
if (!url) throw new Error('AOMX_DATABASE_URL is required');
const args = process.argv.slice(2);
const apply = args.includes('--apply');
const playerIndex = args.indexOf('--delete-player');
if (args.some((arg, index) => !['--apply', '--delete-player'].includes(arg) && index !== playerIndex + 1) ||
  playerIndex >= 0 && !args[playerIndex + 1]) {
  throw new Error('Usage: alpha-retention [--apply] [--delete-player PLAYER_ID]');
}
const playerId = playerIndex >= 0 ? args[playerIndex + 1] : null;
const host = new URL(url).hostname;
const client = new pg.Client({ connectionString: url,
  ssl: ['localhost', '127.0.0.1'].includes(host) ? false : { rejectUnauthorized: true } });
await client.connect();
try {
  process.stdout.write(JSON.stringify(await retention(client, { playerId, apply })) + '\n');
} finally { await client.end(); }
