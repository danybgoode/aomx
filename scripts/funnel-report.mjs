import fs from 'node:fs';
import { AuditStore } from '../src/funnel/store.mjs';
import { makeReport, corrections } from '../src/funnel/report.mjs';
import { loadObservedDays } from '../src/funnel/observations.mjs';

const filename = process.env.FUNNEL_AUDIT_PATH ?? '.funnel-local/audit.jsonl';
const snapshot = process.env.FUNNEL_REPORT_PATH ?? '.funnel-local/report.json';
const history = process.env.FUNNEL_REPORT_HISTORY_PATH ?? '.funnel-local/report-history.jsonl';
const previous = fs.existsSync(snapshot) ? JSON.parse(fs.readFileSync(snapshot, 'utf8')) : null;
const report = makeReport(new AuditStore(filename).rows, process.env.FUNNEL_AS_OF ?? new Date().toISOString(),
  { observedDays: loadObservedDays(process.env.FUNNEL_OBSERVED_DAYS_PATH ?? '.funnel-local/observed-days.json') });
const content = value => JSON.stringify({ status: value?.status, stages: value?.stages, readings: value?.readings,
  exclusions: value?.exclusions, accepted_events: value?.accepted_events, returning_commanders: value?.returning_commanders,
  observed_baseline: value?.observed_baseline, observed_days: value?.observed_days });
if (previous && content(previous) === content(report)) {
  process.stdout.write(`${JSON.stringify({ ...previous, unchanged: true }, null, 2)}\n`);
} else {
  report.revision = (previous?.revision ?? 0) + 1;
  report.corrections = corrections(previous, report);
  fs.writeFileSync(snapshot, JSON.stringify(report, null, 2));
  fs.appendFileSync(history, `${JSON.stringify(report)}\n`);
  process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
}
