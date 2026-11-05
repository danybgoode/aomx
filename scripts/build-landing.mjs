#!/usr/bin/env node
// Builds the bilingual landing page from one template and one JSON copy file per locale.
// Usage: node scripts/build-landing.mjs [--out dist/landing] [--check]
//   --check validates the locales and template without writing output.
import { readFileSync, writeFileSync, mkdirSync, rmSync, cpSync, readdirSync } from 'node:fs';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const landing = join(root, 'landing');
const args = process.argv.slice(2);
const checkOnly = args.includes('--check');
const outIndex = args.indexOf('--out');
const outDir = resolve(root, outIndex >= 0 ? args[outIndex + 1] : 'dist/landing');

const template = readFileSync(join(landing, 'src', 'index.html'), 'utf8');
const locales = readdirSync(join(landing, 'i18n'))
  .filter((f) => f.endsWith('.json'))
  .map((f) => ({ file: f, data: JSON.parse(readFileSync(join(landing, 'i18n', f), 'utf8')) }));

const errors = [];
const warnings = [];

// Flatten nested copy into "a.b.0.c" paths so locales can be compared key by key.
function flatten(value, prefix = '', out = {}) {
  if (Array.isArray(value)) value.forEach((v, i) => flatten(v, prefix ? `${prefix}.${i}` : String(i), out));
  else if (value && typeof value === 'object') for (const [k, v] of Object.entries(value)) flatten(v, prefix ? `${prefix}.${k}` : k, out);
  else out[prefix] = value;
  return out;
}

function lookup(data, path) {
  return path.split('.').reduce((v, k) => (v == null ? undefined : v[k]), data);
}

// Counts the characters a reader sees, skipping inline markup such as <strong>.
// Used only to compare copy lengths; nothing it returns is written to the page.
function visibleLength(text) {
  let count = 0;
  let inTag = false;
  for (const ch of text) {
    if (ch === '<') inTag = true;
    else if (ch === '>') inTag = false;
    else if (!inTag) count += 1;
  }
  return count;
}

// 1. Every locale must carry exactly the same keys (arrays must have the same length).
const flat = locales.map((l) => ({ ...l, flat: flatten(l.data) }));
const [base, ...others] = flat;
for (const other of others) {
  for (const key of Object.keys(base.flat)) if (!(key in other.flat)) errors.push(`${other.file} is missing "${key}"`);
  for (const key of Object.keys(other.flat)) if (!(key in base.flat)) errors.push(`${base.file} is missing "${key}"`);
  // 2. Flag strings that grew a lot between languages; long copy breaks card layouts.
  for (const [key, a] of Object.entries(base.flat)) {
    const b = other.flat[key];
    if (typeof a !== 'string' || typeof b !== 'string') continue;
    const la = visibleLength(a);
    const lb = visibleLength(b);
    if (Math.min(la, lb) >= 24 && Math.max(la, lb) / Math.min(la, lb) > 1.4) {
      warnings.push(`length differs >40% at "${key}" (${base.file} ${la}, ${other.file} ${lb})`);
    }
  }
}

// 3. Attribute values (meta tags, alt text, aria labels) must be plain text.
for (const l of flat) {
  for (const [key, v] of Object.entries(l.flat)) {
    if (typeof v === 'string' && /(^|\.)(meta|alt|aria)(\.|$)/.test(key) && /[<>"]/.test(v)) {
      errors.push(`${l.file} "${key}" is used in an attribute and must not contain < > or "`);
    }
  }
}

// Minimal template language: {{path}}, {{json:path}}, and {{#each path}}…{{@field}}…{{/each}}.
function render(tpl, data, used) {
  tpl = tpl.replace(/\{\{#each ([\w.]+)\}\}([\s\S]*?)\{\{\/each\}\}/g, (_, path, body) => {
    const list = lookup(data, path);
    if (!Array.isArray(list)) { errors.push(`template: "${path}" is not a list`); return ''; }
    return list.map((item, i) => body
      .replace(/\{\{@index\}\}/g, String(i))
      .replace(/\{\{@\}\}/g, () => { used.add(`${path}.${i}`); return String(item); })
      .replace(/\{\{@([\w.]+)\}\}/g, (m, field) => {
        used.add(`${path}.${i}.${field}`);
        const v = lookup(item, field);
        if (v === undefined) { errors.push(`template: "${path}.${i}.${field}" is undefined`); return ''; }
        return String(v);
      })).join('');
  });
  tpl = tpl.replace(/\{\{json:([\w.]+)\}\}/g, (_, path) => {
    const v = lookup(data, path);
    for (const k of Object.keys(flatten(v, path))) used.add(k);
    return JSON.stringify(v).replace(/</g, '\\u003c');
  });
  return tpl.replace(/\{\{([\w.]+)\}\}/g, (_, path) => {
    const v = lookup(data, path);
    if (v === undefined || typeof v === 'object') { errors.push(`template: "${path}" is not a string`); return ''; }
    used.add(path);
    return String(v);
  });
}

const pages = flat.map((l) => {
  const used = new Set();
  const html = render(template, l.data, used);
  if (html.includes('{{')) errors.push(`${l.file}: unrendered template tag remains`);
  for (const key of Object.keys(l.flat)) {
    if (key !== "meta.path" && !used.has(key) && ![...used].some((u) => key.startsWith(`${u}.`))) warnings.push(`${l.file}: unused key "${key}"`);
  }
  return { path: l.data.meta.path, html };
});

for (const w of [...new Set(warnings)]) console.warn(`warn  ${w}`);
if (errors.length) {
  for (const e of [...new Set(errors)]) console.error(`error ${e}`);
  process.exit(1);
}
if (checkOnly) { console.log(`ok    ${flat.length} locales, ${Object.keys(base.flat).length} keys each`); process.exit(0); }

rmSync(outDir, { recursive: true, force: true });
for (const page of pages) {
  const dir = join(outDir, page.path);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, 'index.html'), page.html);
}
cpSync(join(landing, 'assets'), join(outDir, 'assets'), { recursive: true });
cpSync(join(landing, 'static'), outDir, { recursive: true });
console.log(`built ${pages.map((p) => "/" + (p.path ? p.path + "/" : "")).join(", ")} → ${outDir}`);
