import { AuditStore } from '../src/funnel/store.mjs';
import { makeReport } from '../src/funnel/report.mjs';
import { publishPlan } from '../src/funnel/publisher.mjs';
import { loadObservedDays } from '../src/funnel/observations.mjs';

const filename = process.env.FUNNEL_AUDIT_PATH ?? '.funnel-local/audit.jsonl';
const report = makeReport(new AuditStore(filename).rows, new Date().toISOString(),
  { observedDays: loadObservedDays(process.env.FUNNEL_OBSERVED_DAYS_PATH ?? '.funnel-local/observed-days.json') });
const plan = publishPlan(report);
if (!process.argv.includes('--send')) {
  process.stdout.write(`${JSON.stringify({ project: 'aomx', dry_run: true, plan }, null, 2)}\n`);
} else {
  throw new Error('Live send is disabled until the API key can be verified as belonging to aomx');
}
