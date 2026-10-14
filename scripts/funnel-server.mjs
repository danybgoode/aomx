import { AuditStore } from '../src/funnel/store.mjs';
import { Ingest } from '../src/funnel/ingest.mjs';
import { serve } from '../src/funnel/http.mjs';
import { createFlagProvider } from '@golden-frijoles/sdk';

const filename = process.env.FUNNEL_AUDIT_PATH ?? '.funnel-local/audit.jsonl';
const environment = process.env.GOLDEN_FRIJOLES_ENVIRONMENT ?? 'development';
const provider = process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY ? createFlagProvider({
  baseUrl: process.env.GOLDEN_FRIJOLES_URL,
  flagReadKey: process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY,
  environment
}) : null;
if (provider) {
  const result = await provider.initialize();
  if (!result.ok) process.stderr.write(`Flag provider unavailable: ${result.errorCode}; defaulting off\n`);
}
const resolveFlag = playerId => provider ? {
  ...provider.resolveBooleanEvaluation('telemetry.play_funnel_enabled', false, { targetingKey: playerId }),
  snapshotVersion: provider.getStatus().snapshotVersion, environment
} : { value: false, reason: 'provider_not_configured', environment };
const server = serve(new Ingest(new AuditStore(filename), { resolveFlag }), { port: Number(process.env.FUNNEL_PORT ?? 8787) });
server.on('listening', () => process.stdout.write(`Local funnel ingest: http://127.0.0.1:${server.address().port}\nAudit: ${filename}\n`));
process.on('SIGINT', () => { provider?.shutdown(); server.close(); });
