import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { readFileSync, mkdtempSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

test('landing locales share keys and the template renders both languages', () => {
  const out = mkdtempSync(join(tmpdir(), 'landing-'));
  execFileSync(process.execPath, ['scripts/build-landing.mjs', '--out', out], { stdio: 'pipe' });
  const es = readFileSync(join(out, 'index.html'), 'utf8');
  const en = readFileSync(join(out, 'en', 'index.html'), 'utf8');
  assert.match(es, /<html lang="es-MX">/);
  assert.match(en, /<html lang="en">/);
  for (const html of [es, en]) {
    assert.doesNotMatch(html, /\{\{/);
    assert.match(html, /hreflang="en" href="https:\/\/battle-for-la-roma\.pages\.dev\/en\/"/);
    assert.match(html, /danybgoode\.itch\.io\/battle-for-la-roma-play/);
  }
});

test('Spanish copy follows the voice guide spelling rules', () => {
  const es = readFileSync('landing/i18n/es-MX.json', 'utf8');
  assert.doesNotMatch(es, /sólo/i, 'use "solo" without an accent');
  assert.doesNotMatch(es, /cóctel/i, 'use the Mexican spelling "coctel"');
  assert.doesNotMatch(es, /[“”]/, 'use « » quotes in Spanish copy');
});
