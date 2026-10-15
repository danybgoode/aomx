export function alertDecision(issues, prior = {}, now = Date.now()) {
  const fingerprint = [...issues].sort().join(',');
  const lastSent = Date.parse(prior.sent_at ?? '') || 0;
  const changed = fingerprint !== (prior.fingerprint ?? '');
  return {
    fingerprint,
    send: Boolean(fingerprint || prior.fingerprint) &&
      (changed || now - lastSent >= 24 * 3600_000),
    title: fingerprint ? 'aomx alpha health alert' : 'aomx alpha health recovered',
  };
}
