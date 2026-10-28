import { experimentForResolution } from '@golden-frijoles/sdk';
import { signWonderExposure } from './wonder-exposure.mjs';

export const WONDER_FLAG = 'modes.wonder_enabled';

export function wonderDecision({ provider, growthForPlayer, environment, signingKey }) {
  return async playerId => {
    const growth = growthForPlayer?.(playerId);
    const resolution = provider?.resolveBooleanEvaluation(WONDER_FLAG, false, { targetingKey: playerId });
    const snapshotVersion = provider?.getStatus().snapshotVersion;
    if (!Number.isInteger(resolution?.flagVersion) || resolution.flagVersion < 0 || resolution.flagVersion > 2_147_483_647 ||
      !resolution?.variant || !Number.isInteger(snapshotVersion) || snapshotVersion < 0 || snapshotVersion > 2_147_483_647 || !growth) {
      return { enabled: false, flag_version: null, snapshot_version: null, environment };
    }
    const tracked = await growth.trackFlagEvaluation({
      flagKey: WONDER_FLAG, flagVersion: resolution.flagVersion,
      variant: resolution.variant, reason: resolution.reason,
      snapshotVersion, environment,
      subject: { type: 'user', id: playerId },
      experiment: experimentForResolution(resolution)
    });
    if (!tracked.ok) return { enabled: false, flag_version: null, snapshot_version: null, environment };
    const exposureProof = signWonderExposure(signingKey, { playerId, environment, flagVersion: resolution.flagVersion });
    if (!exposureProof) return { enabled: false, flag_version: null, snapshot_version: null, environment };
    return { enabled: resolution.value === true, flag_version: resolution.flagVersion,
      snapshot_version: snapshotVersion, environment, exposure_proof: exposureProof };
  };
}
