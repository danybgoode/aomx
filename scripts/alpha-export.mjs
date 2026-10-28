import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { gameVersion, currentContentVersion } from '../src/alpha/versions.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';

const root = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN ?? 'godot';
const channel = process.env.AOMX_BUILD_CHANNEL ?? 'preview';
const userDataDir = process.env.AOMX_USER_DIR ?? 'BattleForLaRomaAlpha';
const endpoint = process.env.AOMX_INGEST_URL;
const matchEndpoint = process.env.AOMX_MATCH_URL ?? (endpoint ? new URL(endpoint).origin : '');
if (!['preview', 'production'].includes(channel)) throw new Error('AOMX_BUILD_CHANNEL must be preview or production');
if (!/^BattleForLaRoma[A-Za-z0-9]{1,48}$/.test(userDataDir)) throw new Error('AOMX_USER_DIR must be a BattleForLaRoma-prefixed simple directory name');
if (channel === 'production' && userDataDir !== 'BattleForLaRomaAlpha') throw new Error('Production builds must use the standard user data directory');
if (!endpoint || !endpoint.startsWith('https://') || new URL(endpoint).pathname !== '/v1/events') {
  throw new Error('AOMX_INGEST_URL must be an HTTPS /v1/events endpoint');
}
if (!matchEndpoint || !matchEndpoint.startsWith('https://') || new URL(matchEndpoint).pathname !== '/') {
  throw new Error('AOMX_MATCH_URL must be an HTTPS origin');
}
const run = (command, args, options = {}) => {
  const result = spawnSync(command, args, { stdio: 'inherit', ...options });
  if (result.status !== 0) throw new Error(`${command} exited ${result.status ?? result.error?.message}`);
};
const sha = spawnSync('git', ['rev-parse', '--short=12', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
const buildId = `${channel}-${sha}`;
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-export-'));
const game = path.join(work, 'game');
const out = path.join(root, 'dist', 'alpha');
try {
  run('node', ['scripts/validate-art-manifest.mjs'], { cwd: root });
  run('npm', ['test'], { cwd: root });
  // Fresh checkouts need Godot's imported art cache before scene-based tests run.
  run(godot, ['--headless', '--path', path.join(root, 'game'), '--import']);
  for (const test of ['simulation_test.gd', 'outbox_test.gd', 'skirmish_test.gd', 'faction_test.gd', 'district_test.gd', 'skirmish_client_test.gd', 'campaign_missions_test.gd', 'campaign_progress_test.gd', 'campaign_flag_cache_test.gd', 'campaign_client_test.gd', 'large_map_client_test.gd', 'large_map_layout_test.gd', 'presentation_cues_test.gd',
    'rules_content_test.gd', 'strategic_economy_test.gd', 'strategic_progression_test.gd', 'strategic_ai_test.gd',
    'skirmish_persistence_test.gd', 'skirmish_replay_test.gd', 'multiplayer_replay_test.gd', 'world_expansion_test.gd', 'geography_test.gd', 'cross_platform_hash_test.gd', 'skirmish_save_client_test.gd',
    'skirmish_scale_benchmark.gd', 'art_pipeline_test.gd', 'warfare_test.gd',
    'strategic_opponent_test.gd', 'opponent_scenario_report.gd']) {
    run(godot, ['--headless', '--path', path.join(root, 'game'), '--script', `res://tests/${test}`]);
  }
  run(godot, ['--headless', '--path', path.join(root, 'game'), '--script', 'res://warfare_performance_probe.gd']);
  run(godot, ['--headless', '--path', path.join(root, 'game'), '--script', 'res://large_map_performance_probe.gd']);
  run('npm', ['run', 'skirmish:contract'], { cwd: root, env: { ...process.env, GODOT_BIN: godot } });
  run('npm', ['run', 'multiplayer:integration'], { cwd: root, env: { ...process.env, GODOT_BIN: godot } });
  run('npm', ['run', 'multiplayer:replay-integration'], { cwd: root, env: { ...process.env, GODOT_BIN: godot } });
  fs.cpSync(path.join(root, 'game'), game, { recursive: true, filter: source => !source.includes(`${path.sep}.godot`) && !source.includes(`${path.sep}tests`) });
  const projectFile = path.join(game, 'project.godot');
  fs.writeFileSync(projectFile, fs.readFileSync(projectFile, 'utf8')
    .replace('config/name="Battle for La Roma — RTS Prototype"', 'config/name="Battle for La Roma Alpha"')
    .replace('config/custom_user_dir_name="BattleForLaRomaPrototype"', `config/custom_user_dir_name="${userDataDir}"`));
  fs.writeFileSync(path.join(game, 'alpha_config.gd'), `extends RefCounted\nconst ENDPOINT := ${JSON.stringify(endpoint)}\nconst MATCH_ENDPOINT := ${JSON.stringify(matchEndpoint)}\nconst TEST_ACCOUNT := ${channel === 'preview'}\nconst CHANNEL := ${JSON.stringify(channel)}\nconst BUILD_ID := ${JSON.stringify(buildId)}\nconst SIMULATION_HASH := ${JSON.stringify(SkirmishVersions.simulationHash)}\n`);
  fs.mkdirSync(out, { recursive: true });
  const archive = path.join(out, `battle-for-la-roma-${buildId}-macos.zip`);
  run(godot, ['--headless', '--path', game, '--import']);
  run(godot, ['--headless', '--path', game, '--export-release', 'macOS', archive]);
  if (process.platform === 'darwin') {
    const extracted = path.join(work, 'signed-export');
    fs.mkdirSync(extracted);
    run('ditto', ['-x', '-k', archive, extracted]);
    const apps = fs.readdirSync(extracted).filter(name => name.endsWith('.app'));
    if (apps.length !== 1) throw new Error(`Expected one macOS app in export, found ${apps.length}`);
    run('codesign', ['--verify', '--deep', '--strict', '--verbose=2', path.join(extracted, apps[0])]);
  }
  const checksum = createHash('sha256').update(fs.readFileSync(archive)).digest('hex');
  const manifest = { build_id: buildId, channel, commit: sha, godot: '4.7.2', user_data_dir: userDataDir,
    game_version: gameVersion, content_version: currentContentVersion,
    endpoint, match_endpoint: matchEndpoint, archive: path.basename(archive), sha256: checksum };
  fs.writeFileSync(path.join(out, `${buildId}.json`), JSON.stringify(manifest, null, 2) + '\n');
  process.stdout.write(`${JSON.stringify(manifest, null, 2)}\n`);
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
