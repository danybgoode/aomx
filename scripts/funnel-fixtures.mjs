import { AuditStore } from '../src/funnel/store.mjs';
import { Ingest } from '../src/funnel/ingest.mjs';

const filename = process.env.FUNNEL_AUDIT_PATH ?? '.funnel-local/fixture-audit.jsonl';
const now = new Date('2026-01-01T12:00:00.000Z');
const at = offset => new Date(now.getTime() + offset).toISOString();
const base = { schema_version: 1, player_id: 'fixture_player_01', game_version: 'fixture-1', content_version: 'fixture-1',
  mode: 'solo', faction: 'neutral', test_account: true, bot: false };
const events = [
  { ...base, type: 'game_opened', event_id: 'fixture_open_01', claimed_at: at(-3600_000), local_sequence: 1 },
  { ...base, type: 'match_started', event_id: 'fixture_start_01', match_id: 'fixture_match_01', claimed_at: at(-3000_000), local_sequence: 2 },
  { ...base, type: 'match_completed', event_id: 'fixture_finish_01', match_id: 'fixture_match_01', claimed_at: at(-2400_000), local_sequence: 3, result: 'win' },
  { ...base, type: 'match_started', event_id: 'fixture_abandoned_01', match_id: 'fixture_match_02', claimed_at: at(-1800_000), local_sequence: 4 },
];
const ingest = new Ingest(new AuditStore(filename));
for (const [name, event] of [...events.map((e, i) => [`event_${i + 1}`, e]), ['retry_finish', events[2]],
  ['same_match_second_finish', { ...events[2], event_id: 'fixture_finish_02', local_sequence: 5 }],
  ['malformed', { ...events[2], event_id: 'fixture_invalid_01', schema_version: 999 }]]) {
  process.stdout.write(`${name}: ${JSON.stringify(ingest.accept(event))}\n`);
}
process.stdout.write(`Audit: ${filename}\n`);
