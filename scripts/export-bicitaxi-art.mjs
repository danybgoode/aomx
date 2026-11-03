import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const assets = path.join(root, "game/assets");
const manifestPath = path.join(assets, "manifest.v0.1.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const sha = file => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");

for (const color of ["blue", "red"]) {
  const id = `unit_bicitaxi_${color}`;
  const source = `source/bicitaxi/${color}.png`;
  const output = `render/${id}.png`;
  execFileSync("magick", [path.join(assets, source), "-trim", "+repage", "-filter", "Lanczos",
    "-resize", "62x54", "-background", "none", "-gravity", "south", "-extent", "64x56",
    "-strip", `PNG32:${path.join(assets, output)}`]);
  const record = manifest.assets.find(asset => asset.id === id);
  if (!record) throw new Error(`Missing art manifest record: ${id}`);
  record.source = `res://assets/${source}`;
  record.source_sha256 = sha(path.join(assets, source));
  record.export_sha256 = sha(path.join(assets, output));
  record.export_recipe = `scripts/export-bicitaxi-art.mjs:${id}`;
}

fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2) + "\n");
console.log("Exported two faction bicitaxi sprites and source hashes");
