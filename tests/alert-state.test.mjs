import test from 'node:test';
import assert from 'node:assert/strict';
import { alertDecision } from '../src/funnel/alert-state.mjs';

test('alpha alerts send on change, suppress repeated checks and announce recovery', () => {
  const now = Date.parse('2026-10-15T00:00:00Z');
  assert.equal(alertDecision([], {}, now).send, false);
  const first = alertDecision(['backup_missing_or_old', 'ingest_unavailable'], {}, now);
  assert.equal(first.send, true);
  assert.equal(first.fingerprint, 'backup_missing_or_old,ingest_unavailable');
  const prior = { fingerprint: first.fingerprint, sent_at: new Date(now).toISOString() };
  assert.equal(alertDecision(['ingest_unavailable', 'backup_missing_or_old'], prior, now + 15 * 60_000).send, false);
  assert.equal(alertDecision(['backup_missing_or_old'], prior, now + 15 * 60_000).send, true);
  assert.equal(alertDecision(['ingest_unavailable', 'backup_missing_or_old'], prior, now + 24 * 3600_000).send, true);
  const recovered = alertDecision([], prior, now + 15 * 60_000);
  assert.equal(recovered.send, true);
  assert.equal(recovered.title, 'aomx alpha health recovered');
  assert.equal(alertDecision([], { fingerprint: '', sent_at: new Date(now).toISOString() }, now + 30 * 60_000).send, false);
});
