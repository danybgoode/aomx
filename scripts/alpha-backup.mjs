import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import pg from 'pg';

const source = process.env.AOMX_BACKUP_DATABASE_URL;
const bucket = process.env.AOMX_BACKUP_BUCKET;
if (!source || !bucket) throw new Error('AOMX_BACKUP_DATABASE_URL and AOMX_BACKUP_BUCKET are required');
const restore = process.argv.includes('--restore-test');
const target = process.env.AOMX_RESTORE_DATABASE_URL;
if (restore && (!target || target === source)) throw new Error('A distinct disposable AOMX_RESTORE_DATABASE_URL is required');
const run = (command, args, env) => {
  const result = spawnSync(command, args, { env, encoding: 'utf8', maxBuffer: 1024 * 1024 });
  if (result.status !== 0) throw new Error(`${command} failed: ${result.stderr.trim().slice(0, 500)}`);
  return result.stdout.trim();
};
function pgArgs(uri) {
  const u = new URL(uri);
  if (!['postgres:', 'postgresql:'].includes(u.protocol)) throw new Error('invalid_postgres_url');
  return { args: ['-h', u.hostname, '-p', u.port || '5432', '-U', decodeURIComponent(u.username), '-d', decodeURIComponent(u.pathname.slice(1))],
    env: { ...process.env, PGPASSWORD: decodeURIComponent(u.password), PGSSLMODE: ['localhost', '127.0.0.1', 'postgres'].includes(u.hostname) ? 'disable' : 'verify-full',
      ...(process.env.AOMX_PG_SSL_ROOT_CERT ? { PGSSLROOTCERT: process.env.AOMX_PG_SSL_ROOT_CERT } : {}) } };
}
async function counts(uri) {
  const client = new pg.Client({ connectionString: uri, ssl: /(?:localhost|127\.0\.0\.1)/.test(uri) ? false : { rejectUnauthorized: true } });
  await client.connect();
  try {
    const result = await client.query(`select
      (select count(*) from alpha_private.audit_events) as events,
      (select count(*) from alpha_private.observed_days) as observed,
      (select count(*) from alpha_private.report_history) as reports,
      (select count(*) from alpha_private.publication_days) as publications`);
    return result.rows[0];
  } finally { await client.end(); }
}
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-backup-'));
const stamp = new Date().toISOString().replaceAll(':', '-');
const filename = path.join(dir, `aomx-${stamp}.dump`);
try {
  const src = pgArgs(source);
  run('pg_dump', [...src.args, '--format=custom', '--schema=alpha_private', '--no-owner', '--no-acl', '--file', filename], src.env);
  if (fs.statSync(filename).size < 1024) throw new Error('backup_too_small');
  const checksum = createHash('sha256').update(fs.readFileSync(filename)).digest('hex');
  const name = `aomx/db/${path.basename(filename)}`;
  const auth = process.env.AOMX_OCI_AUTH ?? 'instance_principal';
  const namespace = process.env.AOMX_OCI_NAMESPACE ?? run('oci', ['os', 'ns', 'get', '--auth', auth, '--query', 'data', '--raw-output'], process.env);
  run('oci', ['os', 'object', 'put', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', name, '--file', filename, '--force'], process.env);
  run('oci', ['os', 'object', 'head', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', name], process.env);
  const manifest = { object: name, sha256: checksum, bytes: fs.statSync(filename).size, created_at: new Date().toISOString(), counts: await counts(source) };
  const manifestPath = path.join(dir, 'manifest.json');
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  run('oci', ['os', 'object', 'put', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', `${name}.json`, '--file', manifestPath, '--force'], process.env);
  if (restore) {
    const dst = pgArgs(target);
    run('pg_restore', [...dst.args, '--no-owner', '--no-acl', '--exit-on-error', filename], dst.env);
    const actual = await counts(target);
    if (JSON.stringify(actual) !== JSON.stringify(manifest.counts)) throw new Error('restore_counts_mismatch');
    manifest.restore_verified = true;
  }
  process.stdout.write(`${JSON.stringify(manifest)}\n`);
} finally { fs.rmSync(dir, { recursive: true, force: true }); }
