import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import pg from 'pg';
import { alertDecision } from '../src/funnel/alert-state.mjs';

const url = process.env.AOMX_DATABASE_URL;
const bucket = process.env.AOMX_BACKUP_BUCKET;
const endpoint = process.env.AOMX_PUBLIC_HEALTH_URL;
if (!url || !bucket || !endpoint) throw new Error('AOMX_DATABASE_URL, AOMX_BACKUP_BUCKET and AOMX_PUBLIC_HEALTH_URL are required');
const issues = [];
const output = { checked_at: new Date().toISOString(), project: 'aomx' };
try {
  const db = new pg.Client({ connectionString: url,
    ssl: ['localhost', '127.0.0.1', 'postgres'].includes(new URL(url).hostname) ? false : { rejectUnauthorized: true },
    connectionTimeoutMillis: 5000 });
  try {
    await db.connect();
    const { rows } = await db.query('select pg_database_size(current_database()) as bytes');
    output.database_bytes = Number(rows[0].bytes);
    output.quota_percent = Math.round(output.database_bytes / 500_000_000 * 100);
    if (output.quota_percent >= 80) issues.push('quota_stop_invitations');
    else if (output.quota_percent >= 50) issues.push('quota_warning');
  } finally { await db.end().catch(() => {}); }
} catch { issues.push('database_unavailable'); }
try {
  if (process.env.AOMX_INGEST_DOCKER_CONTAINER) {
    const result = spawnSync('docker', ['exec', process.env.AOMX_INGEST_DOCKER_CONTAINER,
      'node', '-e', "fetch('http://127.0.0.1:8787/healthz').then(async r => process.exit(r.ok && (await r.json()).ok ? 0 : 1)).catch(() => process.exit(1))"],
    { encoding: 'utf8', timeout: 5000 });
    if (result.status !== 0) issues.push('ingest_unavailable');
  } else {
    const response = await fetch(endpoint, { signal: AbortSignal.timeout(5000) });
    if (!response.ok || !(await response.json()).ok) issues.push('ingest_unavailable');
  }
} catch { issues.push('ingest_unavailable'); }
try {
  const auth = process.env.AOMX_OCI_AUTH ?? 'instance_principal';
  const ns = process.env.AOMX_OCI_NAMESPACE;
  if (!ns) throw new Error('missing_namespace');
  const result = spawnSync('oci', ['os', 'object', 'list', '--auth', auth, '--namespace', ns,
    '--bucket-name', bucket, '--prefix', 'aomx/db/', '--all'], { encoding: 'utf8' });
  if (result.status !== 0) throw new Error('oci_list_failed');
  const objects = JSON.parse(result.stdout).data ?? [];
  const manifests = objects.filter(o => o.name?.endsWith('.dump.json'));
  const latest = manifests.sort((a, b) => Date.parse(b['time-created']) - Date.parse(a['time-created']))[0];
  output.last_backup_at = latest?.['time-created'] ?? null;
  if (!latest || Date.now() - Date.parse(latest['time-created']) > 36 * 3600_000) issues.push('backup_missing_or_old');
} catch { issues.push('backup_check_failed'); }
output.issues = issues;
process.stdout.write(`${JSON.stringify(output)}\n`);
const topic = process.env.AOMX_ALERT_TOPIC_ID;
const webhook = process.env.AOMX_ALERT_WEBHOOK_URL;
if (topic || webhook) {
  const statePath = process.env.AOMX_ALERT_STATE_PATH;
  if (!statePath) throw new Error('AOMX_ALERT_STATE_PATH is required with an alert destination');
  let prior = {};
  try { prior = JSON.parse(fs.readFileSync(statePath, 'utf8')); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  const { fingerprint, send, title } = alertDecision(issues, prior);
  if (send) {
    let delivered = false;
    if (topic) {
      const auth = process.env.AOMX_OCI_AUTH ?? 'instance_principal';
      const result = spawnSync('oci', ['ons', 'message', 'publish', '--auth', auth,
        '--topic-id', topic, '--title', title, '--body', JSON.stringify(output)],
      { encoding: 'utf8', timeout: 10000 });
      delivered = result.status === 0;
    } else {
      delivered = await fetch(webhook, { method: 'POST', headers: { 'content-type': 'application/json' },
        body: JSON.stringify(output), signal: AbortSignal.timeout(5000) })
        .then(response => response.ok).catch(() => false);
    }
    if (delivered) {
      const temporary = path.join(path.dirname(statePath), `.${path.basename(statePath)}.${process.pid}.tmp`);
      try {
        fs.writeFileSync(temporary, JSON.stringify({ fingerprint, sent_at: new Date().toISOString() }) + '\n',
          { mode: 0o600 });
        fs.renameSync(temporary, statePath);
      } finally { fs.rmSync(temporary, { force: true }); }
    } else {
      process.stderr.write('alpha health alert delivery failed\n');
      process.exitCode = 2;
    }
  }
}
if (issues.some(i => i !== 'quota_warning')) process.exitCode = 2;
