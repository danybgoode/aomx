const KEYS = ['new_players', 'first_match_completion', 'return_to_match', 'match_completion'];

export function covered(reading, observedDays) {
  const observed = new Set(observedDays);
  const span = ['first_match_completion', 'return_to_match'].includes(reading.key) ? 8 :
    reading.key === 'match_completion' ? 2 : 1;
  const start = Date.parse(`${reading.day}T00:00:00.000Z`);
  return Array.from({ length: span }, (_, index) => new Date(start + index * 86_400_000).toISOString().slice(0, 10))
    .every(day => observed.has(day));
}

export function publishPlan(report, { requireCoverage = false } = {}) {
  return KEYS.map(key => ({ key, values: report.readings.filter(r => r.key === key && r.status === 'final' &&
    (!requireCoverage || covered(r, report.observed_days ?? [])))
    .map(r => ({ occurredOn: r.day, value: r.value })) }));
}

export async function publish(report, client, project) {
  if (project !== 'aomx') throw new Error('wrong_project');
  const results = [];
  for (const { key, values } of publishPlan(report)) {
    if (!values.length) continue;
    const result = await client.pushInputValues(key, values);
    results.push(result);
    if (!result.ok || result.mismatchedDuplicates?.length) {
      throw Object.assign(new Error(`push_failed_or_needs_backfill:${key}`), { results });
    }
  }
  return results;
}
