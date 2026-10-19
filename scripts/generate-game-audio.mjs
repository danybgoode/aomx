// Reproducible original UI cue. No samples, recordings, or third-party sounds.
import fs from 'node:fs';
import path from 'node:path';

const sampleRate = 22050;
const duration = 0.22;
const count = Math.round(sampleRate * duration);
const pcm = Buffer.alloc(count * 2);
for (let i = 0; i < count; i++) {
  const t = i / sampleRate;
  const rise = Math.min(1, t / 0.012);
  const tail = Math.pow(1 - t / duration, 2);
  const tone = Math.sin(2 * Math.PI * 587.33 * t) * 0.72 + Math.sin(2 * Math.PI * 880 * t) * 0.28;
  pcm.writeInt16LE(Math.round(11000 * rise * tail * tone), i * 2);
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
const target = path.resolve(import.meta.dirname, '../game/assets/audio/order-confirm.wav');
fs.mkdirSync(path.dirname(target), { recursive: true });
fs.writeFileSync(target, wav);
process.stdout.write(`${target}\n`);
