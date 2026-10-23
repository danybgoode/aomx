// Deterministic project-original cue synthesis. No recordings, samples, or third-party music.
import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';

const sampleRate = 22050;
const outputDir = path.resolve(import.meta.dirname, '../game/assets/audio');
const source = 'scripts/generate-game-audio.mjs';
const rights = 'Project-original procedural synthesis; no external samples or recordings.';
const specs = [
  { id: 'order-confirm', duration: 0.22, notes: [[587.33, 0, 0.22], [880, 0, 0.22]], noise: 0 },
  { id: 'order-reject', duration: 0.24, notes: [[392, 0, 0.13], [261.63, 0.10, 0.14]], noise: 0 },
  { id: 'economy', duration: 0.18, notes: [[440, 0, 0.09], [659.25, 0.08, 0.10]], noise: 0 },
  { id: 'construction', duration: 0.30, notes: [[329.63, 0, 0.13], [493.88, 0.10, 0.13], [659.25, 0.20, 0.10]], noise: 0 },
  { id: 'threat', duration: 0.30, notes: [[196, 0, 0.14], [146.83, 0.12, 0.18]], noise: 0.12 },
  { id: 'destruction', duration: 0.32, notes: [[164.81, 0, 0.17], [110, 0.13, 0.19]], noise: 0.20 },
  { id: 'objective', duration: 0.34, notes: [[523.25, 0, 0.16], [783.99, 0.13, 0.21]], noise: 0 },
  { id: 'result-win', duration: 0.46, notes: [[392, 0, 0.16], [523.25, 0.13, 0.16], [783.99, 0.27, 0.19]], noise: 0 },
  { id: 'result-loss', duration: 0.46, notes: [[392, 0, 0.16], [293.66, 0.13, 0.16], [196, 0.27, 0.19]], noise: 0 },
  { id: 'result-draw', duration: 0.42, notes: [[329.63, 0, 0.20], [329.63, 0.22, 0.20]], noise: 0 },
];

function render(spec) {
  const count = Math.round(sampleRate * spec.duration);
  const pcm = Buffer.alloc(count * 2);
  let random = 0xacc07;
  for (let i = 0; i < count; i++) {
    const t = i / sampleRate;
    let value = 0;
    for (const [frequency, start, length] of spec.notes) {
      const local = t - start;
      if (local < 0 || local >= length) continue;
      const attack = Math.min(1, local / 0.012);
      const release = Math.pow(1 - local / length, 2);
      const tone = Math.sin(2 * Math.PI * frequency * local) * 0.78
        + Math.sin(2 * Math.PI * frequency * 2 * local) * 0.22;
      value += attack * release * tone / spec.notes.length;
    }
    if (spec.noise) {
      random = (Math.imul(1664525, random) + 1013904223) >>> 0;
      value += ((random / 0xffffffff) * 2 - 1) * spec.noise * Math.pow(1 - t / spec.duration, 3);
    }
    pcm.writeInt16LE(Math.max(-32768, Math.min(32767, Math.round(value * 15000))), i * 2);
  }
  const wav = Buffer.alloc(44 + pcm.length);
  wav.write('RIFF', 0);
  wav.writeUInt32LE(wav.length - 8, 4);
  wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16);
  wav.writeUInt16LE(1, 20);
  wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(sampleRate, 24);
  wav.writeUInt32LE(sampleRate * 2, 28);
  wav.writeUInt16LE(2, 32);
  wav.writeUInt16LE(16, 34);
  wav.write('data', 36);
  wav.writeUInt32LE(pcm.length, 40);
  pcm.copy(wav, 44);
  return wav;
}

fs.mkdirSync(outputDir, { recursive: true });
const assets = specs.map((spec) => {
  const data = render(spec);
  const filename = `${spec.id}.wav`;
  fs.writeFileSync(path.join(outputDir, filename), data);
  return {
    id: spec.id,
    path: `res://assets/audio/${filename}`,
    sha256: createHash('sha256').update(data).digest('hex'),
    source,
    rights,
    sample_rate: sampleRate,
    duration_ms: Math.round(spec.duration * 1000),
  };
});
const manifest = {
  schema: 1,
  generator_sha256: createHash('sha256').update(fs.readFileSync(import.meta.filename)).digest('hex'),
  assets,
};
fs.writeFileSync(path.join(outputDir, 'cues.manifest.json'), JSON.stringify(manifest, null, 2) + '\n');
process.stdout.write(`Generated ${assets.length} original cues and cues.manifest.json\n`);
