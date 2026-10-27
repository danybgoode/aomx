import { createHash } from 'node:crypto';
import { createGrowthEngineClient } from '@golden-frijoles/sdk';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { publishPlan } from '../src/funnel/publisher.mjs';
import { adoptionPlan, publishAdoptions } from '../src/alpha/campaign-adoption.mjs';

if (!process.env.AOMX_DATABASE_URL) throw new Error('AOMX_DATABASE_URL is required');
const send = process.argv.includes('--send');
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL);
const lock = await funnel.pool.connect();
try {
  // Ingest and coverage attestation take the same advisory lock. Hold it
  // through the remote append-only write so the reading cannot change mid-push.
  await lock.query('select pg_advisory_lock(601103, 1)');
  const report = await funnel.report();
  const auditRows = await funnel.rows();
  const adoptions = adoptionPlan(auditRows);
  const reportHash = createHash('sha256').update(JSON.stringify(report)).digest('hex');
  const plan = publishPlan(report, { requireCoverage: true });
  const readings = new Map(report.readings.map(r => [`${r.key}:${r.day}`, r]));
  const current = await lock.query(`select metric_key, day, value, numerator, denominator, reading_hash
    from alpha_private.publication_days`);
  const published = new Map(current.rows.map(r => [`${r.metric_key}:${new Date(r.day).toISOString().slice(0, 10)}`, r]));
  const pending = [];
  const conflicts = [];
  for (const { key, values } of plan) for (const entry of values) {
    const reading = readings.get(`${key}:${entry.occurredOn}`);
    const readingHash = createHash('sha256').update(JSON.stringify({ key, day: entry.occurredOn,
      numerator: reading.numerator, denominator: reading.denominator, status: reading.status,
      value: entry.value })).digest('hex');
    const item = { key, ...entry, numerator: reading.numerator, denominator: reading.denominator,
      reading_hash: readingHash };
    const before = published.get(`${key}:${entry.occurredOn}`);
    if (before === undefined) pending.push(item);
    else if (before.reading_hash !== readingHash || Number(before.value) !== entry.value ||
      before.numerator !== reading.numerator || before.denominator !== reading.denominator) {
      conflicts.push({ ...item, published: before });
    }
  }
  process.stdout.write(`${JSON.stringify({ project: 'aomx', dry_run: !send, report_hash: reportHash,
    pending, conflicts, campaign_adoptions: adoptions.length, observed_days: report.observed_days }, null, 2)}\n`);
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
    // One deadline bounds the entire batch while the ingest lock is held.
    const deadline = AbortSignal.timeout(20_000);
    const client = createGrowthEngineClient({ apiKey: key, baseUrl: process.env.GOLDEN_FRIJOLES_URL,
      fetchImpl: (url, options) => fetch(url, { ...options, signal: deadline }) });
    for (const item of pending) {
      const result = await client.pushInputValues(item.key, [{ occurredOn: item.occurredOn, value: item.value }]);
      if (!result.ok || result.mismatchedDuplicates?.length) throw new Error(`Publish conflict for ${item.key}:${item.occurredOn}`);
      await lock.query(`insert into alpha_private.publication_days
        (metric_key,day,value,report_hash,numerator,denominator,reading_hash)
        values ($1,$2,$3,$4,$5,$6,$7)`, [item.key, item.occurredOn, item.value, reportHash,
        item.numerator, item.denominator, item.reading_hash]);
    }
    const growthForPlayer = playerId => createGrowthEngineClient({ apiKey: key, userId: playerId,
      baseUrl: process.env.GOLDEN_FRIJOLES_URL,
      fetchImpl: (url, options) => fetch(url, { ...options, signal: deadline }) });
    await publishAdoptions(adoptions, growthForPlayer);
    await funnel.pool.query(`insert into alpha_private.report_history(report,report_hash) values ($1,$2)
      on conflict do nothing`, [report, reportHash]);
  }
} finally {
  await lock.query('select pg_advisory_unlock(601103, 1)').catch(() => {});
  lock.release();
  await funnel.close();
}
