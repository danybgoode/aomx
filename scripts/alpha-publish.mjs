import { createHash } from 'node:crypto';
import { createGrowthEngineClient } from '@golden-frijoles/sdk';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { publishPlan } from '../src/funnel/publisher.mjs';

if (!process.env.AOMX_DATABASE_URL) throw new Error('AOMX_DATABASE_URL is required');
const send = process.argv.includes('--send');
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL);
try {
  const report = await funnel.report();
  const reportHash = createHash('sha256').update(JSON.stringify(report)).digest('hex');
  const plan = publishPlan(report, { requireCoverage: true });
  const current = await funnel.pool.query('select metric_key, day, value from alpha_private.publication_days');
  const published = new Map(current.rows.map(r => [`${r.metric_key}:${new Date(r.day).toISOString().slice(0, 10)}`, Number(r.value)]));
  const pending = [];
  const conflicts = [];
  for (const { key, values } of plan) for (const entry of values) {
    const before = published.get(`${key}:${entry.occurredOn}`);
    if (before === undefined) pending.push({ key, ...entry });
    else if (before !== entry.value) conflicts.push({ key, ...entry, published: before });
  }
  process.stdout.write(`${JSON.stringify({ project: 'aomx', dry_run: !send, report_hash: reportHash,
    pending, conflicts, observed_days: report.observed_days }, null, 2)}\n`);
  if (conflicts.length) throw new Error('Published values changed; stop and review a backfill');
  if (!send) process.exitCode = 0;
  else {
    const key = process.env.AOMX_GROWTH_ENGINE_API_KEY;
    const expected = process.env.AOMX_VERIFIED_KEY_SHA256;
    if (!key || !expected || createHash('sha256').update(key).digest('hex') !== expected ||
      process.env.AOMX_VERIFIED_PROJECT !== 'aomx') {
      throw new Error('A separately verified aomx key fingerprint and project attestation are required');
    }
    // The operator records the key fingerprint from the aomx project in a
    // different channel before enabling send; SDK writes do not identify project.
    const client = createGrowthEngineClient({ apiKey: key, baseUrl: process.env.GOLDEN_FRIJOLES_URL });
    for (const item of pending) {
      const result = await client.pushInputValues(item.key, [{ occurredOn: item.occurredOn, value: item.value }]);
      if (!result.ok || result.mismatchedDuplicates?.length) throw new Error(`Publish conflict for ${item.key}:${item.occurredOn}`);
      await funnel.pool.query(`insert into alpha_private.publication_days(metric_key,day,value,report_hash)
        values ($1,$2,$3,$4) on conflict do nothing`, [item.key, item.occurredOn, item.value, reportHash]);
    }
    await funnel.pool.query(`insert into alpha_private.report_history(report,report_hash) values ($1,$2)
      on conflict do nothing`, [report, reportHash]);
  }
} finally {
  await funnel.close();
}
