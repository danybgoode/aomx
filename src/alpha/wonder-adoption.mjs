export function wonderAdoptionPlan(rows) {
  const seen = new Set();
  return rows.filter(row => row.receipt?.status === 'accepted' &&
    row.event?.type === 'wonder_match_completed' && row.event?.objective_id === 'wonder' &&
    !row.event?.test_account && !row.event?.bot).map(row => row.event).filter(event => {
    const key = `${event.player_id}|${event.match_id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export async function publishWonderAdoptions(events, growthForPlayer) {
  let sent = 0;
  for (const event of events) {
    const growth = growthForPlayer(event.player_id);
    const result = await growth.track('wonder_match_completed', {
      featureId: 'add-more-ways-to-play',
      tags: { objective_id: 'wonder', result: event.result, environment: event.environment ?? 'production' },
      context: { version: 1, subject: { type: 'user', id: event.player_id },
        idempotencyKey: `wonder_match:${event.event_id}` }
    });
    if (!result.ok) throw new Error(`Wonder adoption publish failed for ${event.event_id}`);
    sent += 1;
  }
  return sent;
}
