import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileHashes, compareTrees, parseButlerStatus } from '../scripts/public-verify.mjs';

function tree(files) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'verify-test-'));
  for (const [rel, body] of Object.entries(files)) {
    fs.mkdirSync(path.dirname(path.join(dir, rel)), { recursive: true });
    fs.writeFileSync(path.join(dir, rel), body);
  }
  return dir;
}

test('identical trees match and itch bookkeeping is ignored', () => {
  const a = fileHashes(tree({ 'index.html': 'x', 'App.app/Contents/MacOS/game': 'bin' }));
  const b = fileHashes(tree({ 'index.html': 'x', 'App.app/Contents/MacOS/game': 'bin', '.itch/receipt.json.gz': 'r' }));
  assert.deepEqual(compareTrees(a, b), { ok: true, files: 2, missing: [], extra: [], changed: [] });
});

test('missing, extra and changed files are reported', () => {
  const diff = compareTrees(fileHashes(tree({ a: '1', b: '2' })), fileHashes(tree({ a: 'changed', c: '3' })));
  assert.equal(diff.ok, false);
  assert.deepEqual([diff.missing, diff.extra, diff.changed], [['b'], ['c'], ['a']]);
});

test('butler status rows parse into build, processing state and version', () => {
  const rows = parseButlerStatus(`
+--------------+-----------+----------------------------+---------------------+
|   CHANNEL    |  UPLOAD   |           BUILD            |       VERSION       |
+--------------+-----------+----------------------------+---------------------+
| html5-public | #20300765 | ✓ #2310032 (from #2309749) | public-36868ff112ac |
| mac-public   | #20300766 | • #2310040 (from #2310033) | public-abc123def456 |
+--------------+-----------+----------------------------+---------------------+`);
  assert.deepEqual(rows['html5-public'], { build: 2310032, processed: true, version: 'public-36868ff112ac' });
  assert.deepEqual(rows['mac-public'], { build: 2310040, processed: false, version: 'public-abc123def456' });
});
