const DAY = 86_400_000;
const date = value => value.slice(0, 10);
const dayStart = value => Date.parse(`${value}T00:00:00.000Z`);
const within = (later, earlier, window) => Date.parse(later) >= Date.parse(earlier) && Date.parse(later) <= Date.parse(earlier) + window;
const laterDay = (later, earlier) => date(later) > date(earlier);
const pct = (n, d) => Math.round(n * 10_000 / d) / 100;
export const STAGES = [
  { name: 'First open', signal: 'game_opened' },
  { name: 'First match start', signal: 'match_started' },
  { name: 'First match finish', signal: 'match_completed and first_match_completed' },
  { name: 'Later-day return', signal: 'game_opened' },
  { name: 'Later-day match start', signal: 'match_started' },
  { name: 'Later-day match finish', signal: 'match_completed and later_day_match_completed' }
];

function reading(key, day, numerator, denominator, mature) {
  return { key, day, numerator, denominator, status: !mature ? 'pending' : denominator === 0 && key !== 'new_players' ? 'no_data' : 'final',
    value: !mature || denominator === 0 && key !== 'new_players' ? null : key === 'new_players' ? numerator : pct(numerator, denominator) };
}

export function makeReport(rows, asOf = new Date().toISOString(), { observedDays = [] } = {}) {
  const accepted = rows.filter(r => r.receipt.status === 'accepted').map(r => r.event);
  const excluded = rows.reduce((counts, r) => {
    if (r.receipt.status !== 'accepted') {
      const k = `${r.receipt.status}:${r.receipt.reason}`;
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts;
  }, {});
  const byPlayer = Map.groupBy(accepted, e => e.player_id);
  const players = [];
  for (const [playerId, events] of byPlayer) {
    const ordered = [...events].sort((a, b) => Date.parse(a.claimed_at) - Date.parse(b.claimed_at));
    const opens = ordered.filter(e => e.type === 'game_opened');
    if (!opens.length) continue;
    const firstOpen = opens[0];
    const starts = ordered.filter(e => e.type === 'match_started');
    const finishes = ordered.filter(e => e.type === 'match_completed');
    const firstStart = starts.find(e => within(e.claimed_at, firstOpen.claimed_at, 7 * DAY));
    const firstFinish = finishes.find(e => within(e.claimed_at, firstOpen.claimed_at, 7 * DAY));
    const firstCompletion = finishes[0];
    const after = firstFinish ? {
      open: opens.find(e => laterDay(e.claimed_at, firstFinish.claimed_at) && within(e.claimed_at, firstFinish.claimed_at, 7 * DAY)),
      start: starts.find(e => laterDay(e.claimed_at, firstFinish.claimed_at) && within(e.claimed_at, firstFinish.claimed_at, 7 * DAY)),
      finish: finishes.find(e => laterDay(e.claimed_at, firstFinish.claimed_at) && within(e.claimed_at, firstFinish.claimed_at, 7 * DAY))
    } : {};
    const laterCompletion = firstCompletion && finishes.find(e => laterDay(e.claimed_at, firstCompletion.claimed_at) &&
      within(e.claimed_at, firstCompletion.claimed_at, 7 * DAY));
    const returning = finishes.some((e, i) => finishes.slice(i + 1).some(f => laterDay(f.claimed_at, e.claimed_at) && within(f.claimed_at, e.claimed_at, 7 * DAY)));
    players.push({ player_id: playerId, firstOpen, firstStart, firstFinish, firstCompletion, laterCompletion,
      ...after, starts, finishes, returning });
  }
  const firstOpenDays = [...new Set([...players.map(p => date(p.firstOpen.claimed_at)), ...observedDays])].sort();
  const finishDays = [...new Set(players.filter(p => p.firstCompletion).map(p => date(p.firstCompletion.claimed_at)))].sort();
  const startDays = [...new Set(players.flatMap(p => p.starts.map(e => date(e.claimed_at))))].sort();
  const stages = firstOpenDays.map(day => {
    const cohort = players.filter(p => date(p.firstOpen.claimed_at) === day);
    const counts = [cohort.length, cohort.filter(p => p.firstStart).length, cohort.filter(p => p.firstFinish).length,
      cohort.filter(p => p.open).length, cohort.filter(p => p.start).length, cohort.filter(p => p.finish).length];
    const mature = Date.parse(asOf) >= dayStart(day) + 8 * DAY;
    return { day, status: !mature ? 'pending' : counts[0] ? 'final' : 'no_data', counts,
      denominator: counts[0], rates_from_first_open: mature && counts[0] ? counts.slice(1).map(n => pct(n, counts[0])) : [null, null, null, null, null] };
  });
  const readings = [];
  for (const day of firstOpenDays) {
    const cohort = players.filter(p => date(p.firstOpen.claimed_at) === day);
    readings.push(reading('new_players', day, cohort.length, cohort.length, Date.parse(asOf) >= dayStart(day) + DAY));
    readings.push(reading('first_match_completion', day, cohort.filter(p => p.firstFinish).length, cohort.length, Date.parse(asOf) >= dayStart(day) + 8 * DAY));
  }
  for (const day of finishDays) {
    const cohort = players.filter(p => p.firstCompletion && date(p.firstCompletion.claimed_at) === day);
    readings.push(reading('return_to_match', day, cohort.filter(p => p.laterCompletion).length, cohort.length, Date.parse(asOf) >= dayStart(day) + 8 * DAY));
  }
  for (const day of startDays) {
    const starts = players.flatMap(p => p.starts.filter(e => date(e.claimed_at) === day).map(e => ({ player: p, event: e })));
    const done = starts.filter(({player, event}) => player.finishes.some(f => f.match_id === event.match_id && within(f.claimed_at, event.claimed_at, DAY)));
    readings.push(reading('match_completion', day, done.length, starts.length, Date.parse(asOf) >= dayStart(day) + 2 * DAY));
  }
  const observedBaseline = finishDays.filter(d => Date.parse(asOf) >= dayStart(d) + 8 * DAY).length ? {
    numerator: players.filter(p => p.firstCompletion && Date.parse(asOf) >= dayStart(date(p.firstCompletion.claimed_at)) + 8 * DAY && p.laterCompletion).length,
    denominator: players.filter(p => p.firstCompletion && Date.parse(asOf) >= dayStart(date(p.firstCompletion.claimed_at)) + 8 * DAY).length
  } : null;
  if (observedBaseline) observedBaseline.rate = pct(observedBaseline.numerator, observedBaseline.denominator);
  return { as_of: asOf, status: players.length || observedDays.length ? 'data' : 'no_data',
    observed_days: [...observedDays].sort(), stages_definition: STAGES,
    trust: 'client_reported', identity: 'pseudonymous_installation_proxy',
    accepted_events: accepted.length, exclusions: excluded, returning_commanders: players.filter(p => p.returning).length,
    stages, readings: readings.sort((a, b) => a.day.localeCompare(b.day) || a.key.localeCompare(b.key)),
    observed_baseline: observedBaseline };
}

export function corrections(previous, current) {
  if (!previous) return [];
  const old = new Map((previous?.readings ?? []).map(r => [`${r.key}:${r.day}`, r]));
  return current.readings.filter(r => {
    const before = old.get(`${r.key}:${r.day}`);
    return r.status === 'final' && (!before || before.status === 'final' &&
      (before.value !== r.value || before.numerator !== r.numerator || before.denominator !== r.denominator));
  }).map(r => ({ key: r.key, day: r.day, previous: old.get(`${r.key}:${r.day}`) ?? null, current: r }));
}
