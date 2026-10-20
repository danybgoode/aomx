import { performance } from 'node:perf_hooks';
import { execFileSync } from 'node:child_process';
import os from 'node:os';
import { resolve } from 'node:path';
import { GodotMatchWorker } from '../src/multiplayer/worker.mjs';

const godotBin = process.env.GODOT_BIN;
if (!godotBin) throw new Error('GODOT_BIN is required');
const worker = await new GodotMatchWorker({ godotBin, gamePath: resolve('game') }).start();
const timings = [];
const ticks = 1000;
const percentile = (values, proportion) => {
  const ordered = [...values].sort((a, b) => a - b);
  return ordered[Math.min(ordered.length - 1, Math.ceil(ordered.length * proportion) - 1)];
};
try {
  const initialized = await worker.request({ type: 'init', map_id: 'la_roma',
    factions: ['regios', 'poblanos'], seed: 1 });
  if (!initialized.ok) throw new Error(`initialization failed: ${initialized.reason}`);
  let state = initialized;
  for (let i = 0; i < ticks; i++) {
    const start = performance.now();
    state = await worker.request({ type: 'tick' });
    timings.push(performance.now() - start);
    if (!state.ok) throw new Error(`tick failed: ${state.reason}`);
  }
  let rssKb = null;
  try { rssKb = Number(execFileSync('ps', ['-o', 'rss=', '-p', String(worker.child.pid)],
    { encoding: 'utf8' }).trim()); } catch {}
  const report = { os: os.platform(), arch: os.arch(), node: process.version,
    godot: '4.7.2.stable.official', map_id: 'la_roma', factions: ['regios', 'poblanos'],
    initial_seed: 1, entities: state.state.entities.length, fog: true,
    resources: ['comida', 'materiales', 'varos', 'terrenos'], ticks,
    tick_request_mean_ms: Number((timings.reduce((sum, ms) => sum + ms, 0) / ticks).toFixed(3)),
    tick_request_p95_ms: Number(percentile(timings, 0.95).toFixed(3)),
    tick_request_max_ms: Number(Math.max(...timings).toFixed(3)),
    worker_rss_kib: rssKb, canonical_state_bytes: Buffer.byteLength(JSON.stringify(state.state)),
    side_view_bytes: state.views.map(view => Buffer.byteLength(JSON.stringify(view))),
    final_hash: state.hash };
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
} finally { worker.close(); }
