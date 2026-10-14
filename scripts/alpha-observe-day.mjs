import { PostgresFunnel } from '../src/funnel/postgres.mjs';
import { validDay } from '../src/funnel/observations.mjs';

const day = process.argv.at(-1);
if (!validDay(day) || !process.argv.includes('--complete')) {
  throw new Error('Usage: npm run alpha:observe-day -- --complete YYYY-MM-DD');
}
if (Date.parse(`${day}T00:00:00.000Z`) + 86_400_000 > Date.now()) throw new Error('day_not_closed');
if (!process.env.AOMX_DATABASE_URL || !process.env.AOMX_COVERAGE_NOTE?.trim()) {
  throw new Error('AOMX_DATABASE_URL and AOMX_COVERAGE_NOTE are required');
}
const funnel = new PostgresFunnel(process.env.AOMX_DATABASE_URL);
try {
  await funnel.pool.query(`insert into alpha_private.observed_days(day,complete,note)
    values ($1,true,$2) on conflict(day) do update set complete=true,note=excluded.note,attested_at=now()`,
  [day, process.env.AOMX_COVERAGE_NOTE]);
  process.stdout.write(`Coverage attested for ${day}; report remains subject to late-upload reconciliation.\n`);
} finally { await funnel.close(); }
