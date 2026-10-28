import { createHmac, timingSafeEqual } from 'node:crypto';

const PROOF = /^[a-f0-9]{64}$/;

// Issued only after Golden Frijoles records a user-level evaluation. The
// domain prefix prevents reuse as a signature for another backend purpose.
export function signWonderExposure(key, { playerId, environment, flagVersion }) {
  if (typeof key !== 'string' || !key || typeof playerId !== 'string' || !playerId ||
    typeof environment !== 'string' || !environment || !Number.isInteger(flagVersion) || flagVersion < 0) return null;
  return createHmac('sha256', key).update(`aomx-wonder-exposure-v1\0${playerId}\0${environment}\0${flagVersion}`).digest('hex');
}

export function verifyWonderExposure(key, event, environment) {
  if (!PROOF.test(event?.wonder_exposure_proof ?? '')) return false;
  const expected = signWonderExposure(key, { playerId: event.player_id, environment,
    flagVersion: event.wonder_flag_version });
  return !!expected && timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(event.wonder_exposure_proof, 'hex'));
}
