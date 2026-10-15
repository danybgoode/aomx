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
function databaseTool(tool, uri, args, { inputFile, outputFile } = {}) {
  const connection = pgArgs(uri);
  const container = process.env.AOMX_PG_DOCKER_CONTAINER;
  const parsed = new URL(uri);
  if (container && !['localhost', '127.0.0.1'].includes(parsed.hostname)) {
    throw new Error('Docker database tools require a loopback operator URL');
  }
  const command = container ? 'docker' : tool;
  const toolArgs = container ? ['exec', ...(inputFile ? ['-i'] : []), container, tool,
    '-U', decodeURIComponent(parsed.username), '-d', decodeURIComponent(parsed.pathname.slice(1)), ...args] :
    [...connection.args, ...args];
  const input = inputFile ? fs.openSync(inputFile, 'r') : 'ignore';
  const output = outputFile ? fs.openSync(outputFile, 'w', 0o600) : 'pipe';
  try {
    const result = spawnSync(command, toolArgs, { env: connection.env,
      stdio: [input, output, 'pipe'], maxBuffer: 1024 * 1024 });
    if (result.status !== 0) throw new Error(`${tool} failed: ${result.stderr?.toString().trim().slice(0, 500)}`);
  } finally {
    if (typeof input === 'number') fs.closeSync(input);
    if (typeof output === 'number') fs.closeSync(output);
  }
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
  const before = await counts(source);
  databaseTool('pg_dump', source, ['--format=custom', '--schema=alpha_private', '--no-owner', '--no-acl'], { outputFile: filename });
  const after = await counts(source);
  if (fs.statSync(filename).size < 1024) throw new Error('backup_too_small');
  const checksum = createHash('sha256').update(fs.readFileSync(filename)).digest('hex');
  const name = `aomx/db/${path.basename(filename)}`;
  const auth = process.env.AOMX_OCI_AUTH ?? 'instance_principal';
  const namespace = process.env.AOMX_OCI_NAMESPACE ?? run('oci', ['os', 'ns', 'get', '--auth', auth, '--query', 'data', '--raw-output'], process.env);
  run('oci', ['os', 'object', 'put', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', name, '--file', filename, '--force'], process.env);
  run('oci', ['os', 'object', 'head', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', name], process.env);
  const sourceStable = JSON.stringify(before) === JSON.stringify(after);
  const manifest = { object: name, sha256: checksum, bytes: fs.statSync(filename).size,
    created_at: new Date().toISOString(), source_stable: sourceStable,
    source_counts_before: before, source_counts_after: after,
    counts: sourceStable ? after : null };
  const manifestPath = path.join(dir, 'manifest.json');
  if (restore) {
    const downloaded = path.join(dir, 'downloaded.dump');
    run('oci', ['os', 'object', 'get', '--auth', auth, '--namespace', namespace,
      '--bucket-name', bucket, '--name', name, '--file', downloaded], process.env);
    if (createHash('sha256').update(fs.readFileSync(downloaded)).digest('hex') !== checksum) {
      throw new Error('downloaded_backup_checksum_mismatch');
    }
    databaseTool('pg_restore', target, ['--no-owner', '--no-acl', '--exit-on-error'], { inputFile: downloaded });
    const actual = await counts(target);
    if (sourceStable && JSON.stringify(actual) !== JSON.stringify(manifest.counts)) throw new Error('restore_counts_mismatch');
    manifest.restored_counts = actual;
    manifest.restore_verified = true;
  }
  fs.writeFileSync(manifestPath, JSON.stringify(manifest));
  run('oci', ['os', 'object', 'put', '--auth', auth, '--namespace', namespace,
    '--bucket-name', bucket, '--name', `${name}.json`, '--file', manifestPath, '--force'], process.env);
  process.stdout.write(`${JSON.stringify(manifest)}\n`);
} finally { fs.rmSync(dir, { recursive: true, force: true }); }
