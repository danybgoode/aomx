import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const manifestPath = path.join(root, "game/assets/manifest.v0.1.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const errors = [];
const ids = new Set();

if (manifest.schema_version !== 1) errors.push("unsupported schema_version");
if (manifest.tile_ground_size?.join("x") !== "48x24") errors.push("tile ground geometry mismatch");
if (manifest.simulation_grid?.join("x") !== "20x20") errors.push("simulation grid mismatch");

for (const asset of manifest.assets ?? []) {
  if (ids.has(asset.id)) errors.push("duplicate ID " + asset.id);
  ids.add(asset.id);
  const expectedPrefix = asset.category + "_";
  if (!asset.id?.startsWith(expectedPrefix)) errors.push("bad ID/category " + asset.id);
  for (const key of ["path", "source"]) {
    const value = asset[key];
    if (typeof value !== "string" || !value.startsWith("res://assets/")) {
      errors.push(asset.id + ": bad " + key);
      continue;
    }
    const local = path.join(root, "game", value.slice("res://".length));
    if (!fs.existsSync(local)) {
      errors.push(asset.id + ": missing " + key + " " + value);
      continue;
    }
    if (key === "path") {
      const png = fs.readFileSync(local);
      if (png.subarray(0, 8).toString("hex") !== "89504e470d0a1a0a") {
        errors.push(asset.id + ": not a PNG");
        continue;
      }
      const dimensions = [png.readUInt32BE(16), png.readUInt32BE(20)];
      if (dimensions.join("x") !== asset.canvas?.join("x")) {
        errors.push(asset.id + ": canvas does not match PNG " + dimensions.join("x"));
      }
      if (png[25] !== 6) errors.push(asset.id + ": expected RGBA PNG");
    }
  }
  if (!Array.isArray(asset.pivot) || asset.pivot.length !== 2 ||
      asset.pivot.some((v, i) => !Number.isInteger(v) || v < 0 || v >= asset.canvas[i])) {
    errors.push(asset.id + ": invalid pivot");
  }
  if (asset.rights !== "project-original-ai-assisted") errors.push(asset.id + ": rights missing");
}

const expected = [
  ...["grass", "sidewalk", "asphalt", "plaza"].flatMap(
    kind => Array.from({ length: 4 }, (_, i) => "terrain_" + kind + "_" + i)
  ),
  ...["blue", "red"].flatMap(color => [
    "building_command_post_" + color, "building_barracks_" + color,
    "unit_worker_" + color, "unit_melee_" + color, "unit_ranged_" + color
  ]),
  "prop_gold_cart", "prop_jacaranda", "prop_barricade", "prop_plaza_medallion"
];
for (const id of expected) if (!ids.has(id)) errors.push("required asset missing: " + id);

if (errors.length) {
  console.error(errors.join("\n"));
  process.exit(1);
}
console.log("Art manifest OK: " + ids.size + " RGBA textures, " + (manifest.procedural?.length ?? 0) + " procedural cues.");
