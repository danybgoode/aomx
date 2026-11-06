#!/usr/bin/env node
// Verifies a public release the same way every time and writes a JSON report.
//
//   node scripts/public-verify.mjs                     after upload: checks what players download
//   node scripts/public-verify.mjs --before-upload     before upload: checks the local packages
//   options: --build public-<sha> (default: the commit at HEAD), --skip-host, --skip-pages
//
// Needs the manifest and ZIPs from `npm run public:export` in dist/public/. Uses BUTLER_BIN
// (default `butler`, then ~/.local/share/butler/butler) and AOMX_PUBLIC_MATCH_URL (default: the
// origin recorded in the manifest). Exits 1 if any check fails. See docs/release/public-release-runbook.md.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { pathToFileURL } from 'node:url';

const root = path.resolve(import.meta.dirname, '..');
const GAME = 'danybgoode/battle-for-la-roma-play';
const CHANNELS = { web: 'html5-public', macos: 'mac-public' };
const WEB_ORIGIN = 'https://html-classic.itch.zone';
const PAGES = ['https://danybgoode.itch.io/battle-for-la-roma-play', 'https://battle-for-la-roma.pages.dev/', 'https://battle-for-la-roma.pages.dev/en/'];

/** SHA-256 of every file under dir, keyed by relative path. itch's own bookkeeping files are ignored. */
export function fileHashes(dir) {
  const out = {};
  const walk = (d) => {
    for (const name of fs.readdirSync(d)) {
      const p = path.join(d, name);
      const rel = path.relative(dir, p);
      if (rel.split(path.sep)[0].startsWith('.itch')) continue;
      const stat = fs.lstatSync(p);
      if (stat.isDirectory()) walk(p);
      else if (stat.isFile()) out[rel] = createHash('sha256').update(fs.readFileSync(p)).digest('hex');
    }
  };
  walk(dir);
  return out;
}

/** Differences between two trees of files: missing, extra and changed paths. */
export function compareTrees(expected, actual) {
  const missing = Object.keys(expected).filter((k) => !(k in actual));
  const extra = Object.keys(actual).filter((k) => !(k in expected));
  const changed = Object.keys(expected).filter((k) => k in actual && expected[k] !== actual[k]);
  return { ok: !missing.length && !extra.length && !changed.length, files: Object.keys(expected).length, missing, extra, changed };
}

/** Reads `butler status` table rows: channel → { build, processed, version }. */
export function parseButlerStatus(text) {
  const rows = {};
  for (const line of text.split('\n')) {
    const cells = line.split('|').map((c) => c.trim());
    if (cells.length < 6 || !cells[1] || cells[1] === 'CHANNEL') continue;
    const build = cells[3].match(/#(\d+)/);
    rows[cells[1]] = { build: build ? Number(build[1]) : null, processed: cells[3].startsWith('✓'), version: cells[4] };
  }
  return rows;
}

function run(cmd, args, opts = {}) {
  const r = spawnSync(cmd, args, { encoding: 'utf8', maxBuffer: 1 << 28, ...opts });
  return { ok: r.status === 0, status: r.status, out: `${r.stdout ?? ''}${r.stderr ?? ''}`.trim(), error: r.error };
}

function butlerBin() {
  if (process.env.BUTLER_BIN) return process.env.BUTLER_BIN;
  if (run('butler', ['-V']).ok) return 'butler';
  const local = path.join(os.homedir(), '.local/share/butler/butler');
  if (fs.existsSync(local)) return local;
  throw new Error('butler not found: install it (see the runbook) or set BUTLER_BIN');
}

async function http(url, init = {}, tries = 4) {
  for (let i = 0; ; i++) {
    const res = await fetch(url, { redirect: 'follow', signal: AbortSignal.timeout(20000), ...init,
      headers: { 'user-agent': 'Mozilla/5.0 (Macintosh) AppleWebKit/537.36 Chrome/130 Safari/537.36', ...(init.headers ?? {}) } });
    if (res.status !== 429 || i + 1 >= tries) return res;
    await new Promise((r) => setTimeout(r, 3000 * (i + 1)));
  }
}

function checkMacApp(dir) {
  const app = fs.readdirSync(dir).find((n) => n.endsWith('.app'));
  if (!app) return { ok: false, detail: 'no .app in package' };
  if (process.platform !== 'darwin') return { ok: true, skipped: true, detail: `${app}: codesign and launch need macOS` };
  const appPath = path.join(dir, app);
  const sign = run('codesign', ['--verify', '--deep', '--strict', appPath]);
  if (!sign.ok) return { ok: false, detail: `codesign failed: ${sign.out}` };
  const exe = run('plutil', ['-extract', 'CFBundleExecutable', 'raw', path.join(appPath, 'Contents/Info.plist')]).out;
  const start = run(path.join(appPath, 'Contents/MacOS', exe), ['--headless', '--quit-after', '120'], { timeout: 180000 });
  return { ok: start.ok, detail: start.ok ? `${app}: codesign ok, headless start exited 0` : `headless start failed (${start.status ?? start.error?.code})` };
}

async function main() {
  const args = process.argv.slice(2);
  const opt = (name) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : undefined; };
  const before = args.includes('--before-upload');
  const sha = run('git', ['rev-parse', '--short=12', 'HEAD'], { cwd: root }).out;
  const buildId = opt('--build') ?? `public-${sha}`;
  const dist = path.join(root, 'dist', 'public');
  const manifestPath = path.join(dist, `${buildId}.json`);
  if (!fs.existsSync(manifestPath)) throw new Error(`${path.relative(root, manifestPath)} not found: run npm run public:export first`);
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const work = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-verify-'));
  const checks = [];
  const record = (name, result) => {
    checks.push({ name, ...result });
    console.log(`${result.skipped ? 'skip' : result.ok ? 'ok  ' : 'FAIL'}  ${name}${result.detail ? ` — ${result.detail}` : ''}`);
  };

  try {
    // Local packages: the ZIPs on disk are the ones the manifest names.
    const local = {};
    for (const kind of ['web', 'macos']) {
      const zip = path.join(dist, manifest[kind].file);
      const hash = fs.existsSync(zip) ? createHash('sha256').update(fs.readFileSync(zip)).digest('hex') : null;
      record(`${kind} package matches manifest`, { ok: hash === manifest[kind].sha256, detail: hash ? manifest[kind].file : 'ZIP missing' });
      local[kind] = path.join(work, `local-${kind}`);
      fs.mkdirSync(local[kind]);
      if (hash) run('unzip', ['-q', zip, '-d', local[kind]]);
    }
    record('manifest is from a clean tree', { ok: manifest.source_clean !== false, detail: manifest.source_clean === undefined ? 'older manifest without source_clean' : `source_clean: ${manifest.source_clean}` });
    if (before) record('local macOS app', checkMacApp(local.macos));

    // Match host: healthy, and it admits the itch Web origin but no other.
    if (!args.includes('--skip-host')) {
      const host = process.env.AOMX_PUBLIC_MATCH_URL ?? manifest.match_endpoint;
      if (!host) record('match host', { ok: false, detail: 'no AOMX_PUBLIC_MATCH_URL and none in the manifest' });
      else {
        const health = await http(`${host}/healthz`).then(async (r) => ({ status: r.status, body: await r.text() }), (e) => ({ status: 0, body: e.message }));
        record('match host health', { ok: health.status === 200 && /"ok":\s*true/.test(health.body), detail: `${host} → ${health.status}` });
        for (const [origin, want] of [[WEB_ORIGIN, 204], ['https://example.com', 403]]) {
          const pre = await http(`${host}/v1/match/create`, { method: 'OPTIONS', headers: { origin, 'access-control-request-method': 'POST', 'access-control-request-headers': 'content-type' } }).then((r) => r.status, () => 0);
          record(`host preflight from ${origin}`, { ok: pre === want, detail: `${pre} (want ${want})` });
        }
      }
    }

    if (!before) {
      const butler = butlerBin();
      const status = run(butler, ['status', GAME]);
      const rows = parseButlerStatus(status.out);
      for (const [kind, channel] of Object.entries(CHANNELS)) {
        const row = rows[channel];
        record(`${channel} serves ${buildId}`, { ok: !!row && row.processed && row.version === buildId, detail: row ? `build #${row.build}, ${row.processed ? 'processed' : 'processing'}, ${row.version}` : 'channel not listed' });
        const fetched = path.join(work, `fetched-${kind}`);
        const f = run(butler, ['fetch', `${GAME}:${channel}`, fetched]);
        if (!f.ok) { record(`${channel} download matches package`, { ok: false, detail: `butler fetch failed: ${f.out.slice(-200)}` }); continue; }
        const diff = compareTrees(fileHashes(local[kind]), fileHashes(fetched));
        record(`${channel} download matches package`, { ok: diff.ok, detail: diff.ok ? `${diff.files} files identical` : JSON.stringify({ missing: diff.missing, extra: diff.extra, changed: diff.changed }) });
        if (kind === 'macos') record('downloaded macOS app', checkMacApp(fetched));
      }
    }

    if (!args.includes('--skip-pages')) {
      for (const url of PAGES) {
        const code = await http(url).then((r) => r.status, () => 0);
        record(`page ${url}`, { ok: code === 200, detail: String(code) });
      }
    }
  } finally {
    fs.rmSync(work, { recursive: true, force: true });
  }

  const failed = checks.filter((c) => !c.ok);
  const report = { build_id: buildId, mode: before ? 'before-upload' : 'after-upload', checked_at: new Date().toISOString(), ok: !failed.length, checks,
    not_checked: ['a full match played by a person', 'a two-person online room', 'the itch-served Web page in a browser session', 'physical phones'] };
  const reportPath = path.join(dist, `${buildId}-verify-${report.mode}.json`);
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n');
  console.log(`\n${failed.length ? `${failed.length} check(s) failed` : `all ${checks.length} checks passed`} · report: ${path.relative(root, reportPath)}`);
  process.exit(failed.length ? 1 : 0);
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((e) => { console.error(e.message); process.exit(1); });
}
