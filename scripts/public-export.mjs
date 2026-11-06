import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { gameVersion, currentContentVersion } from '../src/alpha/versions.mjs';
import { SkirmishVersions } from '../src/multiplayer/versions.mjs';

const root = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN ?? 'godot';
const matchEndpoint = process.env.AOMX_PUBLIC_MATCH_URL ?? '';
if (!matchEndpoint || new URL(matchEndpoint).origin !== matchEndpoint ||
  new URL(matchEndpoint).protocol !== 'https:') {
  throw new Error('AOMX_PUBLIC_MATCH_URL must be one exact HTTPS origin for public rooms');
}
const run = (command, args, options = {}) => {
  const result = spawnSync(command, args, { stdio: 'inherit', ...options });
  if (result.status !== 0) throw new Error(`${command} exited ${result.status ?? result.error?.message}`);
};
const sha = spawnSync('git', ['rev-parse', '--short=12', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
// The build ID names a commit, so the exported files must be exactly that commit. Untracked
// files count too: everything under game/ is copied into the export. Godot regenerates .uid
// files on import and many are not tracked here, so they are not treated as changes.
const dirty = spawnSync('git', ['status', '--porcelain', '--', 'game', 'src', ':(exclude)game/tests', ':(exclude,glob)**/*.uid'], { cwd: root, encoding: 'utf8' }).stdout.trim();
if (dirty && process.env.AOMX_ALLOW_DIRTY !== '1') {
  throw new Error(`Refusing to export ${sha} with uncommitted game or source changes:\n${dirty}\nCommit them, or set AOMX_ALLOW_DIRTY=1 for a throwaway local build.`);
}
const buildId = `public-${sha}${dirty ? '-dirty' : ''}`;
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-public-'));
const game = path.join(work, 'game');
const output = path.join(root, 'dist', 'public');
try {
  fs.cpSync(path.join(root, 'game'), game, {
    recursive: true,
    filter: source => !source.includes(`${path.sep}.godot`) && !source.includes(`${path.sep}tests`),
  });
  const project = path.join(game, 'project.godot');
  fs.writeFileSync(project, fs.readFileSync(project, 'utf8')
    .replace('config/name="Battle for La Roma — RTS Prototype"', 'config/name="Battle for La Roma"')
    .replace('config/custom_user_dir_name="BattleForLaRomaPrototype"', 'config/custom_user_dir_name="BattleForLaRomaPublicExportQA"'));
  fs.writeFileSync(path.join(game, 'alpha_config.gd'), `extends RefCounted\nconst ENDPOINT := ""\nconst MATCH_ENDPOINT := ${JSON.stringify(matchEndpoint)}\nconst TEST_ACCOUNT := true\nconst CHANNEL := "public"\nconst BUILD_ID := ${JSON.stringify(buildId)}\nconst SIMULATION_HASH := ${JSON.stringify(SkirmishVersions.simulationHash)}\n`);
  fs.mkdirSync(output, { recursive: true });
  run(godot, ['--headless', '--path', game, '--import']);
  const smokePath = path.join(game, 'public_channel_smoke.gd');
  fs.writeFileSync(smokePath, `extends SceneTree
func _initialize() -> void:
  call_deferred("verify")
func verify() -> void:
  var scene = load("res://skirmish_main.tscn").instantiate()
  root.add_child(scene)
  await process_frame
  assert(scene._campaign_allowed(), "Public campaign must be available")
  assert(scene._wonder_allowed(), "Public Wonder must be available")
  assert(not scene.setup_mode.is_item_disabled(1), "Campaign choice must be enabled")
  assert(not scene.setup_objective.is_item_disabled(2), "Wonder choice must be enabled")
  assert(scene.setup_online_code.visible, "Public room code entry must be visible")
  assert(scene.setup_online_create.visible, "Public room creation must be visible")
  assert(scene.setup_map.get_item_count() == 5, "Public setup must include all five solo maps")
  assert(not scene.setup_mode.is_item_disabled(2), "Public team skirmish must be available")
  assert(scene.setup_online_button.visible, "Public room join must be visible")
  TranslationServer.set_locale("es")
  assert(scene.tr("Worker") == "Obrero", "Spanish translation must load")
  TranslationServer.set_locale("en")
  assert(scene.tr("PARTIDA RÁPIDA") == "QUICK MATCH", "English translation must load")
  var has_multiplayer := false
  for button in scene.setup_navigation.get_children():
    if button.text == "MULTIJUGADOR":
      has_multiplayer = true
  assert(has_multiplayer, "Public navigation must include multiplayer")
  scene._choose_map(3)
  scene._choose_objective(2)
  assert(scene.selected_objective == "wonder", "Medium map Wonder must remain available")
  scene._choose_mode(2)
  assert(scene.team_mode, "Public team skirmish must start from setup")
  print("Public channel setup checks passed")
  quit()
`);
  run(godot, ['--headless', '--path', game, '--script', 'res://public_channel_smoke.gd']);
  fs.rmSync(smokePath);
  fs.writeFileSync(project, fs.readFileSync(project, 'utf8')
    .replace('config/custom_user_dir_name="BattleForLaRomaPublicExportQA"', 'config/custom_user_dir_name="BattleForLaRomaPublic"'));
  const macZip = path.join(output, `battle-for-la-roma-${buildId}-macos.zip`);
  run(godot, ['--headless', '--path', game, '--export-release', 'macOS', macZip]);
  const web = path.join(work, 'web');
  fs.mkdirSync(web);
  run(godot, ['--headless', '--path', game, '--export-release', 'Web', path.join(web, 'index.html')]);
  const webZip = path.join(output, `battle-for-la-roma-${buildId}-web.zip`);
  run('zip', ['-X', '-q', '-r', webZip, '.'], { cwd: web });
  // Both packages must carry the translation catalogs, not just the source checkout.
  const packHas = (zip, pattern, text) => {
    const pack = spawnSync('unzip', ['-p', zip, pattern], { maxBuffer: 1 << 30 });
    if (pack.status !== 0 || !pack.stdout.includes(Buffer.from(text))) throw new Error(`${path.basename(zip)} is missing the "${text}" translation`);
  };
  for (const zip of [macZip, webZip]) {
    const pattern = zip === macZip ? '*.app/Contents/Resources/*.pck' : 'index.pck';
    packHas(zip, pattern, 'Obrero');
    packHas(zip, pattern, 'QUICK MATCH');
  }
  const manifest = {
    build_id: buildId,
    commit: sha,
    channel: 'public',
    game_version: gameVersion,
    content_version: currentContentVersion,
    scope: 'five solo maps, campaign, Wonder, solo 2v2, player-created private online rooms',
    locales: ['es', 'en'],
    simulation_hash: SkirmishVersions.simulationHash,
    source_clean: !dirty,
    match_endpoint: matchEndpoint,
    macos: { file: path.basename(macZip), sha256: createHash('sha256').update(fs.readFileSync(macZip)).digest('hex') },
    web: { file: path.basename(webZip), sha256: createHash('sha256').update(fs.readFileSync(webZip)).digest('hex') },
  };
  fs.writeFileSync(path.join(output, `${buildId}.json`), JSON.stringify(manifest, null, 2) + '\n');
  process.stdout.write(JSON.stringify(manifest, null, 2) + '\n');
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
