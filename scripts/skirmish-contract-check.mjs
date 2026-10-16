import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { AuditStore } from '../src/funnel/store.mjs';
import { Ingest } from '../src/funnel/ingest.mjs';
import { makeReport } from '../src/funnel/report.mjs';
import { gameVersion, currentContentVersion, supportedVersions } from '../src/alpha/versions.mjs';

const godot = process.env.GODOT_BIN;
if (!godot) throw new Error('Set GODOT_BIN to the Godot 4.7.2 executable');
const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'aomx-skirmish-contract-'));
try {
  const outboxFile = path.join(dir, 'godot-outbox.json');
  const run = spawnSync(godot, ['--headless', '--path', 'game', '--script', 'res://tests/emit_skirmish_events.gd'], {
    env: { ...process.env, SKIRMISH_FIXTURE_PATH: outboxFile }, encoding: 'utf8', timeout: 30_000
  });
  assert.equal(run.status, 0, `${run.stdout}\n${run.stderr}`);
  assert.match(run.stdout, /Skirmish client fixture saved/);
  assert.doesNotMatch(run.stdout + run.stderr, /SCRIPT ERROR|Parse Error|ERROR:/);
  const events = JSON.parse(fs.readFileSync(outboxFile, 'utf8')).events.map(item => item.event);
  assert.deepEqual(events.map(event => event.type), ['game_opened', 'match_started', 'match_completed']);
  assert.equal(events[1].match_id, events[2].match_id);
  assert.equal(events[2].result, 'win');
  assert.equal(events[1].game_version, gameVersion);
  assert.equal(events[2].content_version, currentContentVersion);
  assert.ok(supportedVersions.some(version => version.game === events[2].game_version && version.content === events[2].content_version));
  assert.equal(events[0].faction, 'neutral');
  assert.equal(events[1].faction, 'regios');
  assert.equal(events[2].faction, events[1].faction);
  assert.ok(events.every(event => event.test_account && !event.bot));
  const store = new AuditStore(path.join(dir, 'audit.jsonl'));
  const ingest = new Ingest(store, { supportedVersions });
  const receipts = events.map(event => ingest.accept(event));
  assert.deepEqual(receipts.map(receipt => receipt.status), ['excluded', 'excluded', 'excluded']);
  assert.ok(receipts.every(receipt => receipt.reason === 'test_account'));
  assert.deepEqual(ingest.accept(events[2]), receipts[2]);
  assert.equal(store.rows.length, 3);
  const legacy = new Ingest(new AuditStore(path.join(dir, 'legacy-audit.jsonl')), { supportedVersions });
  const legacyReceipt = legacy.accept({ ...events[0], content_version: 'original-skirmish-map-1' });
  assert.equal(legacyReceipt.status, 'excluded');
  assert.equal(legacyReceipt.reason, 'test_account');
  const report = makeReport(store.rows);
  assert.equal(report.accepted_events, 0);
  assert.equal(report.observed_baseline, null);
  process.stdout.write('Godot-to-ingest contract passed: one test-tagged start/result, stable retry, zero public events\n');
} finally {
  fs.rmSync(dir, { recursive: true, force: true });
}
