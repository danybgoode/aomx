import { randomUUID, createHash } from 'node:crypto';

const TYPES = new Set(['game_opened', 'match_started', 'match_completed']);
const MODES = new Set(['solo', 'multiplayer', 'tutorial']);
const RESULTS = new Set(['win', 'loss', 'draw']);
const ID = /^[a-zA-Z0-9][a-zA-Z0-9_-]{7,127}$/;
const UTC = /^\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d{1,3})?Z$/;
const FIELDS = new Set(['schema_version', 'type', 'event_id', 'player_id', 'match_id', 'claimed_at',
  'local_sequence', 'game_version', 'content_version', 'mode', 'faction', 'test_account', 'bot', 'result']);
function canonical(value) {
  if (Array.isArray(value)) return value.map(canonical);
  if (value && typeof value === 'object') return Object.fromEntries(Object.keys(value).sort().map(k => [k, canonical(value[k])]));
  return value;
}
const fingerprint = value => createHash('sha256').update(JSON.stringify(canonical(value)) ?? 'undefined').digest('hex');
function rejectedEvent(event) {
  if (!event || typeof event !== 'object' || Array.isArray(event)) return null;
  const safe = {};
  if (ID.test(event.event_id ?? '')) safe.event_id = event.event_id;
  if (ID.test(event.player_id ?? '')) safe.player_id = event.player_id;
  if (ID.test(event.match_id ?? '')) safe.match_id = event.match_id;
  if (TYPES.has(event.type)) safe.type = event.type;
  if (Number.isSafeInteger(event.schema_version)) safe.schema_version = event.schema_version;
  return safe;
}

function validTime(value) {
  if (typeof value !== 'string' || !UTC.test(value)) return false;
  const parsed = new Date(value);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 19) === value.slice(0, 19);
}

export function validate(event) {
  if (!event || typeof event !== 'object' || Array.isArray(event)) return 'malformed_event';
  if (Object.keys(event).some(k => !FIELDS.has(k))) return 'unknown_field';
  if (event.schema_version !== 1) return 'unsupported_version';
  if (!TYPES.has(event.type)) return 'unknown_event_type';
  if (!ID.test(event.event_id ?? '') || !ID.test(event.player_id ?? '')) return 'invalid_identity';
  if (event.type !== 'game_opened' && !ID.test(event.match_id ?? '')) return 'invalid_match_id';
  if (event.type === 'game_opened' && event.match_id != null) return 'unexpected_match_id';
  if (!validTime(event.claimed_at)) return 'invalid_claimed_time';
  if (!Number.isSafeInteger(event.local_sequence) || event.local_sequence < 1) return 'invalid_sequence';
  if (typeof event.game_version !== 'string' || !event.game_version.trim() || event.game_version.length > 80) return 'invalid_game_version';
  if (typeof event.content_version !== 'string' || !event.content_version.trim() || event.content_version.length > 80) return 'invalid_content_version';
  if (!MODES.has(event.mode) || typeof event.faction !== 'string' || !event.faction.trim() || event.faction.length > 80) return 'invalid_context';
  if (typeof event.test_account !== 'boolean' || typeof event.bot !== 'boolean') return 'invalid_actor_marker';
  if (event.type === 'match_completed' && !RESULTS.has(event.result)) return 'invalid_result';
  if (event.type !== 'match_completed' && event.result != null) return 'unexpected_result';
  return null;
}

const key = e => e.type === 'game_opened' ? null : `${e.player_id}|${e.match_id}|${e.type}`;
const exclusion = e => e.test_account ? 'test_account' : e.bot ? 'bot' : e.mode === 'tutorial' ? 'tutorial' : null;

export class Ingest {
  constructor(store, { now = () => new Date(), maxFutureMs = 5 * 60_000,
    resolveFlag = () => ({ value: false, reason: 'provider_not_ready' }) } = {}) {
    this.store = store;
    this.now = now;
    this.maxFutureMs = maxFutureMs;
    this.resolveFlag = resolveFlag;
  }

  accept(event) {
    const receivedAt = this.now().toISOString();
    const payloadHash = fingerprint(event);
    const prior = this.store.rows.find(r => r.event?.event_id === event?.event_id && r.event?.player_id === event?.player_id && r.payload_hash === payloadHash);
    if (prior) return prior.receipt;

    let reason = validate(event);
    let status = 'accepted';
    let flag = null;
    if (reason) status = 'rejected';
    else {
      const accepted = this.store.rows.filter(r => ['accepted', 'excluded'].includes(r.receipt.status)).map(r => r.event);
      const eligibleRows = this.store.rows.filter(r => r.receipt.status === 'accepted');
      const sameId = this.store.rows.find(r => r.event?.event_id === event.event_id);
      const duplicate = key(event) && accepted.find(e => key(e) === key(event));
      const player = accepted.filter(e => e.player_id === event.player_id);
      const match = player.filter(e => e.match_id === event.match_id);
      const firstOpen = player.find(e => e.type === 'game_opened');
      const start = match.find(e => e.type === 'match_started');
      const eligibleOpen = eligibleRows.find(r => r.event.player_id === event.player_id && r.event.type === 'game_opened');
      const eligibleStart = eligibleRows.find(r => r.event.player_id === event.player_id &&
        r.event.match_id === event.match_id && r.event.type === 'match_started');
      const latestSequence = Math.max(0, ...player.map(e => e.local_sequence));
      if (sameId) reason = 'event_id_collision';
      else if (duplicate) reason = 'duplicate_match_event';
      else if (event.type === 'match_started' && !firstOpen) reason = 'missing_first_open';
      else if (event.type === 'match_completed' && !start) reason = 'missing_match_start';
      else if (event.type === 'match_completed' && event.local_sequence <= start.local_sequence) reason = 'invalid_transition_sequence';
      else if (event.type === 'match_started' && event.local_sequence <= firstOpen.local_sequence) reason = 'invalid_transition_sequence';
      else if (event.type === 'match_completed' && Date.parse(event.claimed_at) < Date.parse(start.claimed_at)) reason = 'invalid_transition_time';
      else if (event.type === 'match_started' && Date.parse(event.claimed_at) < Date.parse(firstOpen.claimed_at)) reason = 'invalid_transition_time';
      else if (player.some(e => e.local_sequence === event.local_sequence)) reason = 'sequence_collision';
      else if (event.local_sequence < latestSequence) reason = 'out_of_order_sequence';
      else if (event.type !== 'game_opened' && start && (event.mode !== start.mode || event.faction !== start.faction || event.test_account !== start.test_account || event.bot !== start.bot)) reason = 'match_context_mismatch';
      if (reason) status = 'rejected';
      else if (Date.parse(event.claimed_at) > Date.parse(receivedAt) + this.maxFutureMs) {
        status = 'quarantined'; reason = 'clock_ahead';
      } else if (player.some(e => Date.parse(e.claimed_at) > Date.parse(event.claimed_at))) {
        status = 'quarantined'; reason = 'clock_reversal';
      } else if (exclusion(event)) {
        status = 'excluded'; reason = exclusion(event);
      } else {
        flag = this.resolveFlag(event.player_id);
        if (!flag?.value) { status = 'excluded'; reason = 'flag_off'; }
        else if (event.type === 'match_started' && !eligibleOpen ||
          event.type === 'match_completed' && (!eligibleOpen || !eligibleStart)) {
          status = 'excluded'; reason = 'prior_event_excluded';
        }
      }
    }
    const receipt = { receipt_id: randomUUID(), event_id: ID.test(event?.event_id ?? '') ? event.event_id : null,
      status, reason, received_at: receivedAt,
      trust: status === 'accepted' || status === 'excluded' ? 'client_reported' : null,
      ...(flag ? { flag: { key: 'telemetry.play_funnel_enabled', value: !!flag.value,
        variant: flag.variant ?? null, reason: flag.reason ?? null, flag_version: flag.flagVersion ?? null,
        snapshot_version: flag.snapshotVersion ?? null, environment: flag.environment ?? null } } : {}) };
    this.store.append({ receipt, event: status === 'rejected' ? rejectedEvent(event) : event, payload_hash: payloadHash });
    return receipt;
  }
}
