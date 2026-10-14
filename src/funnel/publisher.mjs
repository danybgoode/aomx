const KEYS = ['new_players', 'first_match_completion', 'return_to_match', 'match_completion'];

export function publishPlan(report) {
  return KEYS.map(key => ({ key, values: report.readings.filter(r => r.key === key && r.status === 'final')
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
