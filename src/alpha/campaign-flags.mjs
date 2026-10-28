import { experimentForResolution } from '@golden-frijoles/sdk';

export const CAMPAIGN_FLAG = 'campaign.chapter_enabled';

// The game receives a decision and version only. A missing provider or telemetry
// capability fails closed so a served exposure is never silently unmeasured.
export function campaignDecision({ provider, growthForPlayer, environment }) {
  return async playerId => {
    const growth = growthForPlayer?.(playerId);
    const resolution = provider?.resolveBooleanEvaluation(CAMPAIGN_FLAG, false, { targetingKey: playerId });
    const snapshotVersion = provider?.getStatus().snapshotVersion;
    if (!Number.isInteger(resolution?.flagVersion) || resolution.flagVersion < 0 || resolution.flagVersion > 2_147_483_647 ||
      !resolution?.variant || !Number.isInteger(snapshotVersion) || snapshotVersion < 0 || snapshotVersion > 2_147_483_647 || !growth) {
      return { enabled: false, flag_version: null, snapshot_version: null, environment };
    }
    const tracked = await growth.trackFlagEvaluation({
      flagKey: CAMPAIGN_FLAG, flagVersion: resolution.flagVersion,
      variant: resolution.variant, reason: resolution.reason,
      snapshotVersion, environment,
      subject: { type: 'user', id: playerId },
      experiment: experimentForResolution(resolution)
    });
    if (!tracked.ok) {
      return { enabled: false, flag_version: null, snapshot_version: null, environment };
    }
    return { enabled: resolution.value === true, flag_version: resolution.flagVersion,
      snapshot_version: snapshotVersion, environment };
  };
}
