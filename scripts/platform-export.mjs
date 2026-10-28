import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { gameVersion, currentContentVersion } from '../src/alpha/versions.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';

const root = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN ?? '/Applications/Godot.app/Contents/MacOS/Godot';
const targets = {
  web: { preset: 'Web', filename: 'index.html' },
  macos: { preset: 'macOS', filename: 'battle-for-la-roma-macos.zip' },
  windows: { preset: 'Windows Desktop', filename: 'battle-for-la-roma.exe' },
  linux: { preset: 'Linux', filename: 'battle-for-la-roma.x86_64' },
  android: { preset: 'Android', filename: 'battle-for-la-roma.apk' },
};
const targetName = process.argv[2];
if (!Object.hasOwn(targets, targetName)) {
  throw new Error(`Usage: node scripts/platform-export.mjs <${Object.keys(targets).join('|')}>`);
}
const target = targets[targetName];
const ingest = process.env.AOMX_PLATFORM_INGEST_URL ?? 'http://127.0.0.1:8787/v1/events';
const match = process.env.AOMX_PLATFORM_MATCH_URL ?? 'http://127.0.0.1:8790';
for (const [name, value, pathname] of [['ingest', ingest, '/v1/events'], ['match', match, '/']]) {
  const parsed = new URL(value);
  if (!['http:', 'https:'].includes(parsed.protocol) || parsed.username || parsed.password || parsed.pathname !== pathname) {
    throw new Error(`${name} must be an HTTP(S) URL with no credentials and path ${pathname}`);
  }
}
const run = (cmd, args, options = {}) => {
  const result = spawnSync(cmd, args, { encoding: 'utf8', ...options });
  if (result.status !== 0) throw new Error(`${cmd} ${args.join(' ')} failed: ${result.stderr || result.stdout || result.error?.message}`);
  return result.stdout.trim();
};
const commit = run('git', ['rev-parse', 'HEAD'], { cwd: root });
const dirty = run('git', ['status', '--porcelain'], { cwd: root }).length > 0;
const godotVersion = run(godot, ['--version']);
if (!godotVersion.startsWith('4.7.2.')) throw new Error(`Expected pinned Godot 4.7.2, got ${godotVersion}`);
const buildId = `platform-${commit.slice(0, 12)}${dirty ? '-dirty' : ''}`;
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-platform-'));
const game = path.join(work, 'game');
const out = path.join(root, 'dist', 'platform', buildId, targetName);
const hash = file => createHash('sha256').update(fs.readFileSync(file)).digest('hex');

try {
  fs.cpSync(path.join(root, 'game'), game, { recursive: true, filter: source =>
    !source.includes(`${path.sep}.godot`) && !source.includes(`${path.sep}tests`) });
  const project = path.join(game, 'project.godot');
  fs.writeFileSync(project, fs.readFileSync(project, 'utf8')
    .replace('config/name="Battle for La Roma — RTS Prototype"', 'config/name="Battle for La Roma Platform Pilot"')
    .replace('config/custom_user_dir_name="BattleForLaRomaPrototype"', 'config/custom_user_dir_name="BattleForLaRomaPlatformPilot"'));
  fs.writeFileSync(path.join(game, 'alpha_config.gd'), `extends RefCounted\nconst ENDPOINT := ${JSON.stringify(ingest)}\nconst MATCH_ENDPOINT := ${JSON.stringify(match)}\nconst TEST_ACCOUNT := true\nconst CHANNEL := "preview"\nconst BUILD_ID := ${JSON.stringify(buildId)}\nconst SIMULATION_HASH := ${JSON.stringify(SkirmishVersions.simulationHash)}\n`);
  fs.mkdirSync(out, { recursive: true });
  run(godot, ['--headless', '--path', game, '--import']);
  const artifact = path.join(out, target.filename);
  run(godot, ['--headless', '--path', game, '--export-release', target.preset, artifact]);
  const files = fs.readdirSync(out).filter(name => name !== 'manifest.json').map(name => ({
    name, bytes: fs.statSync(path.join(out, name)).size, sha256: hash(path.join(out, name)),
  }));
  const manifest = { build_id: buildId, target: targetName, channel: 'preview', test_account: true,
    commit, dirty, godot: godotVersion, game_version: gameVersion,
    content_version: currentContentVersion, user_data_dir: 'BattleForLaRomaPlatformPilot',
    ingest, match, files, support_claim: false };
  fs.writeFileSync(path.join(out, 'manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);
  process.stdout.write(`${JSON.stringify(manifest, null, 2)}\n`);
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
