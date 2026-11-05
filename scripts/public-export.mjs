import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const root = path.resolve(import.meta.dirname, '..');
const godot = process.env.GODOT_BIN ?? 'godot';
const run = (command, args, options = {}) => {
  const result = spawnSync(command, args, { stdio: 'inherit', ...options });
  if (result.status !== 0) throw new Error(`${command} exited ${result.status ?? result.error?.message}`);
};
const sha = spawnSync('git', ['rev-parse', '--short=12', 'HEAD'], { cwd: root, encoding: 'utf8' }).stdout.trim();
const buildId = `public-${sha}`;
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
    .replace('config/custom_user_dir_name="BattleForLaRomaPrototype"', 'config/custom_user_dir_name="BattleForLaRomaPublic"'));
  fs.writeFileSync(path.join(game, 'alpha_config.gd'), `extends RefCounted\nconst ENDPOINT := ""\nconst MATCH_ENDPOINT := ""\nconst TEST_ACCOUNT := true\nconst CHANNEL := "public"\nconst BUILD_ID := ${JSON.stringify(buildId)}\nconst SIMULATION_HASH := ""\n`);
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
  assert(not scene.setup_online_code.visible, "Private invite entry must be hidden")
  assert(scene.setup_nav.get_child_count() == 4, "Public navigation must omit private matches")
  print("Public channel setup checks passed")
  quit()
`);
  run(godot, ['--headless', '--path', game, '--script', 'res://public_channel_smoke.gd']);
  fs.rmSync(smokePath);
  const macZip = path.join(output, `battle-for-la-roma-${buildId}-macos.zip`);
  run(godot, ['--headless', '--path', game, '--export-release', 'macOS', macZip]);
  const web = path.join(work, 'web');
  fs.mkdirSync(web);
  run(godot, ['--headless', '--path', game, '--export-release', 'Web', path.join(web, 'index.html')]);
  const webZip = path.join(output, `battle-for-la-roma-${buildId}-web.zip`);
  run('zip', ['-X', '-q', '-r', webZip, '.'], { cwd: web });
  const manifest = {
    build_id: buildId,
    commit: sha,
    channel: 'public',
    scope: 'offline solo; campaign and Wonder available; private multiplayer excluded',
    macos: { file: path.basename(macZip), sha256: createHash('sha256').update(fs.readFileSync(macZip)).digest('hex') },
    web: { file: path.basename(webZip), sha256: createHash('sha256').update(fs.readFileSync(webZip)).digest('hex') },
  };
  fs.writeFileSync(path.join(output, `${buildId}.json`), JSON.stringify(manifest, null, 2) + '\n');
  process.stdout.write(JSON.stringify(manifest, null, 2) + '\n');
} finally {
  fs.rmSync(work, { recursive: true, force: true });
}
