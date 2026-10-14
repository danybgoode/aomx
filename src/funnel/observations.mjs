import fs from 'node:fs';

export function loadObservedDays(filename) {
  if (!fs.existsSync(filename)) return [];
  const days = JSON.parse(fs.readFileSync(filename, 'utf8'));
  if (!Array.isArray(days) || days.some(day => !validDay(day))) throw new Error('invalid_observed_days');
  return [...new Set(days)].sort();
}

export function validDay(day) {
  if (typeof day !== 'string' || !/^\d{4}-\d\d-\d\d$/.test(day)) return false;
  const parsed = new Date(`${day}T00:00:00.000Z`);
  return Number.isFinite(parsed.getTime()) && parsed.toISOString().slice(0, 10) === day;
}
