import { createHash } from 'node:crypto';
import { PostgresFunnel } from '../src/funnel/postgres.mjs';

if (!process.env.AOMX_DATABASE_URL) throw new Error('AOMX_DATABASE_URL is required');
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL);
try {
  const report = await funnel.report();
  const hash = createHash('sha256').update(JSON.stringify(report)).digest('hex');
  const previous = await funnel.pool.query('select report from alpha_private.report_history order by id desc limit 1');
  const before = new Map((previous.rows[0]?.report?.readings ?? []).map(r => [`${r.key}:${r.day}`, r]));
  const corrections = report.readings.filter(r => {
    const old = before.get(`${r.key}:${r.day}`);
    return old && (old.value !== r.value || old.status !== r.status);
  }).map(r => ({ key: r.key, day: r.day, before: before.get(`${r.key}:${r.day}`), after: r }));
  if (process.argv.includes('--record')) {
    await funnel.pool.query(`insert into alpha_private.report_history(report,report_hash) values ($1,$2)
      on conflict (report_hash) do nothing`, [report, hash]);
  }
  process.stdout.write(`${JSON.stringify({ report, hash, corrections,
    recorded: process.argv.includes('--record') }, null, 2)}\n`);
} finally { await funnel.close(); }
