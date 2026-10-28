export function adoptionPlan(rows) {
  const seen = new Set();
  return rows.filter(row => row.receipt?.status === 'accepted' &&
    row.event?.type === 'campaign_mission_completed' && row.event?.result === 'win' &&
    !row.event?.test_account && !row.event?.bot).map(row => row.event).filter(event => {
    const key = `${event.player_id}|${event.match_id}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

export async function publishAdoptions(events, growthForPlayer) {
  let sent = 0;
  for (const event of events) {
    const growth = growthForPlayer(event.player_id);
    const result = await growth.track('campaign_mission_completed', {
      featureId: 'campaign.chapter',
      tags: { mission_id: event.mission_id, environment: event.environment ?? 'production' },
      context: { version: 1, subject: { type: 'user', id: event.player_id },
        idempotencyKey: `campaign_mission:${event.event_id}` }
    });
    if (!result.ok) throw new Error(`Campaign adoption publish failed for ${event.event_id}`);
    sent += 1;
  }
  return sent;
}
