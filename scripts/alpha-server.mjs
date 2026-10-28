import { createFlagProvider, createGrowthEngineClient } from '@golden-frijoles/sdk';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { serve } from '../src/funnel/http.mjs';
import { supportedVersions } from '../src/alpha/versions.mjs';
import { campaignDecision } from '../src/alpha/campaign-flags.mjs';
import { verifiedCampaignGrowthKey } from '../src/alpha/key-attestation.mjs';

if (!process.env.AOMX_DATABASE_URL) throw new Error('AOMX_DATABASE_URL is required');
if (!['preview', 'production'].includes(process.env.GOLDEN_FRIJOLES_ENVIRONMENT)) {
  throw new Error('GOLDEN_FRIJOLES_ENVIRONMENT must be preview or production');
}
const environment = process.env.GOLDEN_FRIJOLES_ENVIRONMENT;
const provider = process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY ? createFlagProvider({
  baseUrl: process.env.GOLDEN_FRIJOLES_URL,
  flagReadKey: process.env.GOLDEN_FRIJOLES_FLAG_READ_KEY,
  environment
}) : null;
if (provider) {
  const result = await provider.initialize();
  if (!result.ok) process.stderr.write(`Flag provider unavailable: ${result.errorCode}; serving off\n`);
}
const resolveFlag = playerId => provider ? {
  ...provider.resolveBooleanEvaluation('telemetry.play_funnel_enabled', false, { targetingKey: playerId }),
  snapshotVersion: provider.getStatus().snapshotVersion, environment
} : { value: false, reason: 'provider_not_configured', environment };
const resolveCampaignFlag = playerId => provider ? {
  ...provider.resolveBooleanEvaluation('campaign.chapter_enabled', false, { targetingKey: playerId }),
  snapshotVersion: provider.getStatus().snapshotVersion, environment
} : { value: false, reason: 'provider_not_configured', environment };
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL, { resolveFlag, resolveCampaignFlag,
  requireInvite: true,
  forceExcludeReason: environment === 'preview' ? 'preview_environment' : null,
  supportedVersions });
await funnel.health();
const growthKey = process.env.AOMX_GROWTH_ENGINE_API_KEY;
const growthKeyVerified = verifiedCampaignGrowthKey(growthKey,
  process.env.AOMX_VERIFIED_CAMPAIGN_KEY_SCRYPT, process.env.AOMX_VERIFIED_PROJECT);
const growthForPlayer = growthKeyVerified ? playerId => createGrowthEngineClient({
  apiKey: process.env.AOMX_GROWTH_ENGINE_API_KEY, userId: playerId,
  ...(process.env.GOLDEN_FRIJOLES_URL ? { baseUrl: process.env.GOLDEN_FRIJOLES_URL } : {}),
  fetchImpl: (url, options) => fetch(url, { ...options, signal: AbortSignal.timeout(2000) })
}) : null;
const server = serve(funnel, { host: '0.0.0.0', port: Number(process.env.AOMX_PORT ?? 8787), publicMode: true,
  campaignDecision: campaignDecision({ provider, growthForPlayer, environment }) });
server.on('listening', () => process.stdout.write(`aomx ingest listening on ${server.address().port}\n`));
async function stop() { server.close(); provider?.shutdown(); await funnel.close(); }
process.once('SIGINT', stop);
process.once('SIGTERM', stop);
