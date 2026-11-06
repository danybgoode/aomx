#!/usr/bin/env node
// Keeps game/i18n/{es,en}.po in step with game/i18n/messages.pot.
//
//   node scripts/i18n-sync.mjs          merge new strings into each .po (existing translations kept,
//                                        strings no longer in the game are dropped)
//   node scripts/i18n-sync.mjs --check  fail if any string is untranslated, a placeholder (%d, %s…)
//                                        differs from its source, or a .po is out of date
//
// Every message id needs a translation in BOTH files: the game's source text mixes English and
// Spanish, so en.po also carries entries (often identical to the source).
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const dir = join(root, 'game', 'i18n');
const LOCALES = { es: 'es', en: 'en' };
const check = process.argv.includes('--check');

const unq = (s) => JSON.parse(s.replace(/\\t/g, '\\t'));
function parsePo(text) {
  const entries = [];
  let cur = null;
  let field = null;
  const flush = () => { if (cur && cur.msgid !== undefined) entries.push(cur); };
  for (const raw of text.split('\n')) {
    const line = raw.trim();
    if (!line) { flush(); cur = null; field = null; continue; }
    cur ??= { comments: [], flags: [] };
    if (line.startsWith('#,')) cur.flags.push(...line.slice(2).split(',').map((f) => f.trim()));
    else if (line.startsWith('#')) cur.comments.push(raw);
    else if (line.startsWith('msgid ')) { field = 'msgid'; cur.msgid = unq(line.slice(6)); }
    else if (line.startsWith('msgstr ')) { field = 'msgstr'; cur.msgstr = unq(line.slice(7)); }
    else if (line.startsWith('"') && field) cur[field] += unq(line);
  }
  flush();
  return entries;
}

const esc = (s) => s.replace(/\\/g, '\\\\').replace(/"/g, '\\"').replace(/\n/g, '\\n').replace(/\t/g, '\\t');
const placeholders = (s) => (s.match(/%[-+0 #]*\d*(\.\d+)?[sdfcxXo%]/g) ?? []).filter((p) => p !== '%%').join(' '); // order matters: Godot fills placeholders positionally

const pot = parsePo(readFileSync(join(dir, 'messages.pot'), 'utf8')).filter((e) => e.msgid !== '');
const problems = [];

for (const [file, lang] of Object.entries(LOCALES)) {
  const path = join(dir, `${file}.po`);
  const existing = existsSync(path) ? parsePo(readFileSync(path, 'utf8')).filter((e) => e.msgid !== '') : [];
  const byId = new Map(existing.map((e) => [e.msgid, e]));
  let out = `msgid ""\nmsgstr ""\n"Language: ${lang}\\n"\n"Content-Type: text/plain; charset=UTF-8\\n"\n"Content-Transfer-Encoding: 8bit\\n"\n`;
  let added = 0;
  for (const p of pot) {
    const prior = byId.get(p.msgid);
    const msgstr = prior?.msgstr ?? '';
    if (!prior) added++;
    if (!msgstr) problems.push(`${file}.po: untranslated ${JSON.stringify(p.msgid)}`);
    else if (p.flags.includes('c-format') && placeholders(msgstr) !== placeholders(p.msgid)) problems.push(`${file}.po: placeholders differ for ${JSON.stringify(p.msgid)} → ${JSON.stringify(msgstr)}`);
    out += `\n${p.comments.join('\n')}\n`;
    if (p.flags.length) out += `#, ${p.flags.join(', ')}\n`;
    out += `msgid "${esc(p.msgid)}"\nmsgstr "${esc(msgstr)}"\n`;
  }
  const removed = existing.filter((e) => !pot.some((p) => p.msgid === e.msgid)).length;
  const current = existsSync(path) ? readFileSync(path, 'utf8') : '';
  if (check) {
    if (current !== out) problems.push(`${file}.po is out of date with messages.pot: run node scripts/i18n-sync.mjs`);
  } else {
    writeFileSync(path, out);
    console.log(`${file}.po: ${pot.length} strings (${added} new, ${removed} removed)`);
  }
}

if (check) {
  for (const p of problems) console.error(p);
  if (problems.length) process.exit(1);
  console.log(`ok    es.po and en.po translate all ${pot.length} strings`);
} else if (problems.length) {
  console.log(`${problems.length} entries still need a translation (run with --check to list them)`);
}
