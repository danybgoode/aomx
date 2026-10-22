import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const assets = path.join(root, "game/assets");
const output = path.join(assets, "render/cdmx");
fs.mkdirSync(output, { recursive: true });
const sha = file => crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
const records = [];

function add(id, category, source, canvas, pivot, footprint, command, args) {
  const sourceFile = path.join(assets, source);
  const outputFile = path.join(output, `${id}.png`);
  execFileSync("magick", [path.join(assets, command), ...args, `PNG32:${outputFile}`]);
  records.push({
    id, category, path: `res://assets/render/cdmx/${id}.png`,
    source: `res://assets/${source}`, canvas, pivot, footprint,
    anchor: category === "terrain" ? "tile_center" : "ground_center",
    states: ["static"], directions: category === "terrain" ? [] : ["se"], frame_ms: 0,
    rights: "project-original-ai-assisted", runtime_use: "match",
    source_sha256: sha(sourceFile), export_sha256: sha(outputFile),
    export_recipe: `scripts/export-cdmx-art.mjs:${id}`
  });
}

for (const kind of ["grass", "sidewalk", "asphalt", "plaza"]) {
  for (let variant = 0; variant < 4; variant++) {
    const id = `terrain_cdmx_${kind}_${variant}`;
    const base = `render/terrain_${kind}_${variant}.png`;
    add(id, "terrain", "source/terrain_atlas.png", [48, 27], [24, 12], [1, 1], base,
      ["-modulate", kind === "grass" ? "102,91,100" : kind === "asphalt" ? "105,85,100" : "105,90,100",
        "-strip"]);
  }
}

for (const kind of ["roma_command_post", "barracks", "depot", "housing", "registry"]) {
  const id = `building_cdmx_${kind}`;
  add(id, "building", `source/cdmx/${kind}.png`, [96, 80], [48, 79], [2, 2], `source/cdmx/${kind}.png`,
    ["-trim", "+repage", "-filter", "Lanczos", "-resize", "92x76", "-background", "none",
      "-gravity", "south", "-extent", "96x80", "-strip"]);
}
for (const kind of ["worker", "melee", "ranged", "armored", "siege"]) {
  const id = `unit_cdmx_${kind}`;
  add(id, "unit", `source/cdmx/${kind}.png`, [40, 56], [20, 55], [1, 1], `source/cdmx/${kind}.png`,
    ["-trim", "+repage", "-filter", "Lanczos", "-resize", "36x54", "-background", "none",
      "-gravity", "south", "-extent", "40x56", "-strip"]);
}
add("prop_cdmx_cibeles", "prop", "source/cdmx/cibeles.png", [96, 80], [48, 79], [2, 2], "source/cdmx/cibeles.png",
  ["-trim", "+repage", "-filter", "Lanczos", "-resize", "92x76", "-background", "none",
    "-gravity", "south", "-extent", "96x80", "-strip"]);

const manifest = {
  schema_version: 1,
  pack: "la-roma-cdmx-art-v1",
  tile_ground_size: [48, 24],
  simulation_grid: [28, 28],
  source_policy: "Project original AI-assisted transparent sources; prompts and reference mapping in docs/art/cdmx-art-source.md.",
  assets: records
};
fs.writeFileSync(path.join(assets, "cdmx-pack.json"), JSON.stringify(manifest, null, 2) + "\n");
console.log(`Exported ${records.length} CDMX RGBA textures and manifest`);
