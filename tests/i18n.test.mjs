import { test } from 'node:test';
import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';

const run = (script, ...args) => execFileSync(process.execPath, [script, ...args], { encoding: 'utf8', stdio: 'pipe' });

test('game message catalog matches the source code', () => {
  assert.match(run('scripts/i18n-extract.mjs', '--check'), /messages\.pot is current/);
});

test('Spanish and English catalogs translate every game string with matching placeholders', () => {
  assert.match(run('scripts/i18n-sync.mjs', '--check'), /translate all \d+ strings/);
});
