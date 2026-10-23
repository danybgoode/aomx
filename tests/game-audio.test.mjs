import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

const root = path.resolve(import.meta.dirname, '..');
const manifestPath = path.join(root, 'game/assets/audio/cues.manifest.json');
const sha256 = (bytes) => createHash('sha256').update(bytes).digest('hex');

test('original match cues have traceable, valid PCM exports', () => {
  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  assert.equal(manifest.schema, 1);
  assert.equal(manifest.generator_sha256, sha256(fs.readFileSync(path.join(root, 'scripts/generate-game-audio.mjs'))));
  const ids = new Set(manifest.assets.map((asset) => asset.id));
  for (const required of ['order-confirm', 'order-reject', 'economy', 'construction',
    'threat', 'destruction', 'objective', 'result-win', 'result-loss', 'result-draw']) {
    assert.ok(ids.has(required), `missing ${required}`);
  }
  assert.equal(ids.size, manifest.assets.length);
  for (const asset of manifest.assets) {
    assert.equal(asset.source, 'scripts/generate-game-audio.mjs');
    assert.match(asset.rights, /Project-original/);
    assert.match(asset.path, /^res:\/\/assets\/audio\/[a-z-]+\.wav$/);
    const wav = fs.readFileSync(path.join(root, 'game', asset.path.slice('res://'.length)));
    assert.equal(sha256(wav), asset.sha256, `hash mismatch: ${asset.id}`);
    assert.equal(wav.toString('ascii', 0, 4), 'RIFF');
    assert.equal(wav.toString('ascii', 8, 16), 'WAVEfmt ');
    assert.equal(wav.readUInt16LE(20), 1, 'PCM format');
    assert.equal(wav.readUInt16LE(22), 1, 'mono');
    assert.equal(wav.readUInt32LE(24), 22050);
    assert.equal(wav.readUInt16LE(34), 16, '16-bit samples');
    assert.equal(wav.readUInt32LE(40), wav.length - 44);
    assert.ok(asset.duration_ms <= 500, 'short cue');
  }
});
