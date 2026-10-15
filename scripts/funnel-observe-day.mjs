import fs from 'node:fs';
import path from 'node:path';
import { loadObservedDays, validDay } from '../src/funnel/observations.mjs';

const day = process.argv[process.argv.indexOf('--day') + 1];
if (!process.argv.includes('--complete') || !validDay(day) || day >= new Date().toISOString().slice(0, 10)) {
  throw new Error('Usage: npm run funnel:observe-day -- --day YYYY-MM-DD --complete (closed UTC day with verified full ingest coverage)');
}
const filename = process.env.FUNNEL_OBSERVED_DAYS_PATH ?? '.funnel-local/observed-days.json';
const days = [...new Set([...loadObservedDays(filename), day])].sort();
fs.mkdirSync(path.dirname(filename), { recursive: true });
const temp = `${filename}.${process.pid}.tmp`;
fs.writeFileSync(temp, JSON.stringify(days, null, 2));
fs.renameSync(temp, filename);
process.stdout.write(`${JSON.stringify({ observed_days: days })}\n`);
