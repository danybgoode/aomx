import fs from 'node:fs';
import path from 'node:path';
import { createGrowthEngineClient } from '@golden-frijoles/sdk';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { adoptionPlan, publishAdoptions } from '../src/alpha/campaign-adoption.mjs';
import { verifiedCampaignGrowthKey } from '../src/alpha/key-attestation.mjs';

if (!process.env.AOMX_DATABASE_URL) throw new Error('AOMX_DATABASE_URL is required');
const send = process.argv.includes('--send');
const cursorPath = process.env.AOMX_CAMPAIGN_CURSOR_PATH;
if (send && (!cursorPath || !path.isAbsolute(cursorPath))) {
  throw new Error('AOMX_CAMPAIGN_CURSOR_PATH must be an absolute operator-only path');
}
const cursor = cursorPath && fs.existsSync(cursorPath) ? JSON.parse(fs.readFileSync(cursorPath, 'utf8')) : { last_id: 0 };
if (!Number.isSafeInteger(cursor.last_id) || cursor.last_id < 0) throw new Error('Campaign cursor is invalid');
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL);
try {
  // A bounded read outside the ingest advisory lock. Retention may delete old
  // rows, so the cursor is the monotonically increasing audit ID, not an offset.
  const { rows } = await funnel.pool.query(`select id, row from alpha_private.audit_events
    where id > $1 and event_type = 'campaign_mission_completed'
    order by id limit 100`, [cursor.last_id]);
  const pending = adoptionPlan(rows.map(item => item.row));
  const nextId = Number(rows.at(-1)?.id ?? cursor.last_id);
  if (!Number.isSafeInteger(nextId) || nextId < cursor.last_id) throw new Error('Campaign audit cursor is invalid');
  process.stdout.write(`${JSON.stringify({ dry_run: !send, examined: rows.length,
    accepted_adoptions: pending.length, last_id: cursor.last_id, next_id: nextId,
    more_may_remain: rows.length === 100 })}\n`);
  if (send) {
    const key = process.env.AOMX_GROWTH_ENGINE_API_KEY;
    if (!verifiedCampaignGrowthKey(key, process.env.AOMX_VERIFIED_CAMPAIGN_KEY_SCRYPT,
      process.env.AOMX_VERIFIED_PROJECT)) throw new Error('A verified aomx campaign growth key is required');
    const growthForPlayer = playerId => createGrowthEngineClient({ apiKey: key, userId: playerId,
      baseUrl: process.env.GOLDEN_FRIJOLES_URL,
      fetchImpl: (url, options) => fetch(url, { ...options, signal: AbortSignal.timeout(5000) }) });
    await publishAdoptions(pending, growthForPlayer);
    const temporary = cursorPath + '.tmp';
    fs.writeFileSync(temporary, JSON.stringify({ last_id: nextId }) + '\n', { mode: 0o600 });
    fs.chmodSync(temporary, 0o600);
    fs.renameSync(temporary, cursorPath);
  }
} finally {
  await funnel.close();
}
