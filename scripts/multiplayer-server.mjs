import { createFlagProvider } from '@golden-frijoles/sdk';
import { resolve } from 'node:path';
import { GodotMatchWorker } from '../src/multiplayer/worker.mjs';
import { PostgresMatchStore } from '../src/multiplayer/store.mjs';
import { MatchSession } from '../src/multiplayer/session.mjs';
import { serveMatch } from '../src/multiplayer/http.mjs';

const databaseUrl = process.env.AOMX_MATCH_DATABASE_URL;
const godotBin = process.env.AOMX_GODOT_BIN;
const gamePath = resolve(process.env.AOMX_GAME_PATH ?? 'game');
const environment = process.env.GOLDEN_FRIJOLES_ENVIRONMENT;
if (!databaseUrl || !godotBin || !['preview', 'production'].includes(environment)) {
  throw new Error('AOMX_MATCH_DATABASE_URL, AOMX_GODOT_BIN and preview/production environment are required');
}
const store = new PostgresMatchStore(databaseUrl);
await store.health();
const provider = process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY ? createFlagProvider({
  baseUrl: process.env.GOLDEN_FRIJOLES_URL,
  flagReadKey: process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY,
  environment
}) : null;
if (provider) {
  const status = await provider.initialize();
  if (!status.ok) process.stderr.write(`match flag provider unavailable: ${status.errorCode}; admission closed\n`);
}
const evaluateAdmission = playerId => Boolean(provider?.resolveBooleanEvaluation(
  'multiplayer.private_match_enabled', false, { targetingKey: playerId }).value);
const session = new MatchSession({ store, evaluateAdmission,
  workerFactory: () => new GodotMatchWorker({ godotBin, gamePath }).start() });
const server = serveMatch(session, { host: '0.0.0.0', port: Number(process.env.AOMX_MATCH_PORT ?? 8790),
  trustProxyClientIp: process.env.AOMX_TRUST_PROXY_CLIENT_IP === '1',
  allowedWebOrigin: process.env.AOMX_MATCH_WEB_ORIGIN ?? '' });
server.on('listening', () => process.stdout.write(`aomx match listening on ${server.address().port}\n`));
async function stop() { server.close(); session.close(); provider?.shutdown(); await store.close(); }
process.once('SIGINT', stop);
process.once('SIGTERM', stop);
