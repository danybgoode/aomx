#!/usr/bin/env node
// Collects player-facing strings from the Godot game into game/i18n/messages.pot.
//
// Plain literals assigned to Control text are translated by Godot's auto-translate, so the
// extractor only needs to find them; text built at runtime must be wrapped in tr() by hand.
// Usage: node scripts/i18n-extract.mjs [--list | --check]
//   --list prints a review table; --check fails if messages.pot is stale (used by npm test).
import { readFileSync, writeFileSync, readdirSync, statSync, mkdirSync } from 'node:fs';
import { join, relative, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const game = join(root, 'game');
const i18n = join(game, 'i18n');

// Scripts that never show text to players (simulation, probes, networking internals, tests).
const SKIP_FILES = new Set([
  'tests', 'art_pilot.gd', 'large_map_performance_probe.gd', 'large_map_render_probe.gd',
  'warfare_performance_probe.gd', 'warfare_render_probe.gd', 'multiplayer_worker.gd',
  'simulation.gd', 'rules_content.gd', 'main.gd',
]);
// Calls whose string arguments are diagnostics, keys or paths rather than player text.
const NON_UI_CALL = /\b(print|printerr|push_error|push_warning|assert|get_node|has_node|load|preload|has|get|erase|connect|emit_signal|add_theme_[a-z_]+|set_meta|get_meta|has_meta|ProjectSettings\.[a-z_]+|Input\.[a-z_]+|InputMap\.[a-z_]+|OS\.[a-z_]+|JavaScriptBridge\.[a-z_]+|texture|art\.[a-z_]+|Color|StringName|NodePath)\s*\(\s*$/;

const ignore = new Set(readFileSync(join(i18n, 'ignore.txt'), 'utf8')
  .split('\n').filter((l) => l && !l.startsWith('#')).map((l) => l.replace(/\\n/g, '\n')));

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (SKIP_FILES.has(name) || name.startsWith('.')) continue;
    const p = join(dir, name);
    if (statSync(p).isDirectory()) walk(p, out);
    else if (name.endsWith('.gd')) out.push(p);
  }
  return out;
}

// Tokenize GDScript just enough to find string literals outside comments.
function literals(src) {
  const found = [];
  let line = 1;
  for (let i = 0; i < src.length; i++) {
    const c = src[i];
    if (c === '\n') { line++; continue; }
    if (c === '#') { while (i < src.length && src[i] !== '\n') i++; i--; continue; }
    if (c !== '"' && c !== "'") continue;
    const prefix = src[i - 1];
    const triple = src.startsWith(c.repeat(3), i);
    const quote = triple ? c.repeat(3) : c;
    let j = i + quote.length;
    let value = '';
    const startLine = line;
    while (j < src.length && !src.startsWith(quote, j)) {
      if (src[j] === '\\') {
        const n = src[j + 1];
        value += n === 'n' ? '\n' : n === 't' ? '\t' : n;
        j += 2;
        continue;
      }
      if (src[j] === '\n') line++;
      value += src[j++];
    }
    const lineStart = src.lastIndexOf('\n', i) + 1;
    found.push({ value, line: startLine, before: src.slice(lineStart, i), after: src.slice(j + quote.length, j + quote.length + 2), stringName: prefix === '&' || prefix === '^' });
    i = j + quote.length - 1;
  }
  return found;
}

// Prose: has a letter, isn't an id/path/colour, and either contains a space, a capital or an
// accented letter. Lower-case single words ("gather", "la_roma") are identifiers.
const isProse = (s) => /\p{L}/u.test(s)
  && !/^(res|user|uid|https?):\/\//.test(s)
  && !/^#?[0-9a-fA-F]{6,8}$/.test(s)
  && !/^[a-z0-9_.\/:%-]+$/.test(s)
  && !/^[a-z]+(_[a-z0-9]+)+$/i.test(s)
  && (/\s/.test(s) || /[A-Z]/.test(s) || /[^\x00-\x7F]/.test(s));

const entries = new Map();
function add(msgid, ref, explicit, line = 0) {
  if (!msgid.trim() || ignore.has(msgid)) return;
  const e = entries.get(msgid) ?? { refs: new Set(), explicit: false };
  e.refs.add(ref);
  e.line ??= line;
  e.explicit ||= explicit;
  entries.set(msgid, e);
}

for (const file of walk(game)) {
  const rel = relative(game, file);
  for (const lit of literals(readFileSync(file, 'utf8'))) {
    if (lit.stringName) continue;
    const explicit = /\btr(_n)?\(\s*$/.test(lit.before);
    if (!explicit) {
      if (NON_UI_CALL.test(lit.before)) continue;
      if (/\.name\s*=\s*$/.test(lit.before)) continue; // node names
      if (/^\s*(const\s+[A-Z_]+\s*:?=\s*)?$/.test(lit.before) && lit.after.startsWith(':')) continue; // dictionary key
      if (/\[\s*$/.test(lit.before) && lit.after.startsWith(']')) continue; // subscript
      if (!isProse(lit.value)) continue;
    }
    // File only, no line numbers: unrelated edits must not make the catalog look stale.
    add(lit.value, rel, explicit, lit.line);
  }
}

// Player-facing fields in content files (read only; the simulation content is never edited here).
const CONTENT_FIELDS = new Set(['title', 'description', 'label', 'name', 'briefing', 'wins', 'summary', 'hint', 'subtitle', 'goal', 'tagline']);
function collectJson(file) {
  const rel = relative(game, file);
  const visit = (v, key) => {
    if (Array.isArray(v)) v.forEach((x) => visit(x, key));
    else if (v && typeof v === 'object') for (const [k, x] of Object.entries(v)) visit(x, k);
    else if (typeof v === 'string' && CONTENT_FIELDS.has(key) && /\p{L}/u.test(v) && /\s/.test(v)) add(v, `${rel} (${key})`, false);
  };
  visit(JSON.parse(readFileSync(file, 'utf8')));
}
for (const f of ['content/campaign.v1.json', 'content/wonder.v1.json', 'content/skirmish.v1.json', 'content/geography/cdmx.v1.json']) collectJson(join(game, f));
for (const f of readdirSync(join(game, 'content/maps'))) collectJson(join(game, 'content/maps', f));

const sorted = [...entries.entries()].sort((a, b) => [...a[1].refs][0].localeCompare([...b[1].refs][0], 'en') || a[0].localeCompare(b[0], 'en'));
if (process.argv.includes('--list')) {
  for (const [id, e] of sorted) console.log(`${`${[...e.refs][0]}:${e.line}`.padEnd(28)} ${e.explicit ? 'tr ' : '   '} ${JSON.stringify(id)}`);
  console.error(`${sorted.length} strings`);
  process.exit(0);
}

const esc = (s) => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t');
let pot = 'msgid ""\nmsgstr ""\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Content-Transfer-Encoding: 8bit\\n"\n"X-Generator: scripts/i18n-extract.mjs\\n"\n';
for (const [id, e] of sorted) {
  pot += `\n#: ${[...e.refs].slice(0, 4).join(' ')}\n`;
  if (/%[-+0 #]*\d*(\.\d+)?[sdfcxXo]/.test(id)) pot += '#, c-format\n';
  pot += `msgid "${esc(id)}"\nmsgstr ""\n`;
}
const potPath = join(i18n, 'messages.pot');
if (process.argv.includes('--check')) {
  const current = readFileSync(potPath, 'utf8');
  if (current !== pot) {
    console.error('game/i18n/messages.pot is out of date: run node scripts/i18n-extract.mjs, then node scripts/i18n-sync.mjs and translate any new strings');
    process.exit(1);
  }
  console.log(`ok    messages.pot is current (${sorted.length} strings)`);
  process.exit(0);
}
mkdirSync(i18n, { recursive: true });
writeFileSync(potPath, pot);
console.log(`wrote game/i18n/messages.pot (${sorted.length} strings)`);
