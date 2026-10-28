import { scryptSync, timingSafeEqual } from 'node:crypto';

const SALT = 'aomx-growth-project-attestation-v1';

export function verifiedCampaignGrowthKey(key, expected, project) {
  if (typeof key !== 'string' || !key || typeof expected !== 'string' ||
    !/^[0-9a-f]{64}$/i.test(expected) || project !== 'aomx') return false;
  const derived = scryptSync(key, SALT, 32);
  return timingSafeEqual(derived, Buffer.from(expected, 'hex'));
}
