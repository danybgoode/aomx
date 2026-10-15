import { AuditStore } from '../src/funnel/store.mjs';

const rows = new AuditStore(process.env.FUNNEL_AUDIT_PATH ?? '.funnel-local/audit.jsonl').rows;
const inputs = rows.filter(r => r.receipt.flag?.flag_version && r.receipt.flag?.snapshot_version &&
  r.receipt.flag?.variant && ['development', 'preview', 'production'].includes(r.receipt.flag?.environment) &&
  r.event?.player_id).map(r => ({
  flagKey: r.receipt.flag.key, flagVersion: r.receipt.flag.flag_version,
  variant: r.receipt.flag.variant, reason: r.receipt.flag.reason,
  snapshotVersion: r.receipt.flag.snapshot_version, environment: r.receipt.flag.environment,
  subject: { type: 'player', id: r.event.player_id }
}));
if (!process.argv.includes('--send')) {
  process.stdout.write(`${JSON.stringify({ project: 'aomx', dry_run: true, evaluations: inputs.length }, null, 2)}\n`);
} else {
  throw new Error('Live send is disabled until the API key can be verified as belonging to aomx');
}
