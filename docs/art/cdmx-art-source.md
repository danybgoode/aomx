# La Roma CDMX art pack — source and export record

Status: builder-integrated on 2026-10-22 for epic #15. Owner visual acceptance and downloaded-match QA remain open.

## Scope and authority

The live 28×28 La Roma match uses 48×24 tile tops, 96×80 buildings, 40×56 unit canvases displayed at 75%, and a 96×80 Cibeles underlay. The existing simulation owns every tile, resource amount, building footprint, faction choice, objective state and result. Cibeles denotes the **existing** district at (10,10); #16 will verify real-world placement. The other maps keep their previous art. The source files are project-original AI-assisted illustrations generated for this pack; the twelve local JPEG boards are visual references only and are not redistributed or used as runtime textures. Neither their depicted powers nor stereotyped regional traits become rules.

| Tracked source | Reference direction and generation instruction | Export ID |
| --- | --- | --- |
| `source/cdmx/cibeles.png` | `roma-norte.jpg`: isolated transparent Cibeles-style fountain, southeast isometric view, warm upper-left light, readable at game scale; no surrounding street or text. | `prop_cdmx_cibeles` |
| `source/cdmx/roma_command_post.png` | `BUILDINGS.jpg`: isolated neutral Roma command post, cream/terracotta/teal palette, southeast view and bottom ground anchor; no faction text. | `building_cdmx_roma_command_post` |
| `source/cdmx/barracks.png` | Isolated Roma Norte Art Deco workshop/barracks with ochre plaster, dark teal trim, distinct roof and defensive supplies; southeast view, transparent background. | `building_cdmx_barracks` |
| `source/cdmx/depot.png` | Isolated covered warehouse/market depot with cream plaster, terracotta roof, teal doors and crates; southeast view, transparent background. | `building_cdmx_depot` |
| `source/cdmx/housing.png` | Isolated narrow three-story Roma residence with balconies, plants and turquoise frames; southeast view, transparent background. | `building_cdmx_housing` |
| `source/cdmx/registry.png` | Isolated compact civic office with pale stone, an arched door and clock medallion; southeast view, transparent background. | `building_cdmx_registry` |
| `source/cdmx/worker.png` | `regional-factions.jpg`: neutral worker, full body, practical civilian outfit and clear tool/supply silhouette, southeast view; no real faction mark. | `unit_cdmx_worker` |
| `source/cdmx/melee.png` | Neutral defensive fighter with shield and short practice baton, practical blue/ochre protective gear, full body and bottom-center feet; no real-world faction mark. | `unit_cdmx_melee` |
| `source/cdmx/ranged.png` | Neutral ranged fighter with a fictional compact device, coral/teal protective gear, full body and bottom-center feet; no real-world faction mark. | `unit_cdmx_ranged` |
| `source/cdmx/armored.png` | Existing `unit_atlas.png` style direction: neutral armored role, full body and broad protected silhouette; no real-world faction mark. | `unit_cdmx_armored` |
| `source/cdmx/siege.png` | Existing `unit_atlas.png` style direction: neutral compact siege cart, clear wheeled silhouette and bottom-center contact; no real-world faction mark. | `unit_cdmx_siege` |
| `source/cdmx/resource_comida.png` | `economy.jpg`: isolated produce and street-food stall with red and cream awning, fruit and vegetables; transparent background and readable at 48×48. | `prop_cdmx_resource_comida` |
| `source/cdmx/resource_materiales.png` | `economy.jpg`: isolated compact yard of lumber, brick and aggregate with teal tools; transparent background and readable at 48×48. | `prop_cdmx_resource_materiales` |
| `source/cdmx/resource_varos.png` | `economy.jpg`: isolated small commerce stall with cash box and coins, distinct from the food stall; transparent background and readable at 48×48. | `prop_cdmx_resource_varos` |
| `source/cdmx/resource_terrenos.png` | `economy.jpg`: isolated surveyed vacant lot with low boundary, papers and survey marker; transparent background and readable at 48×48. | `prop_cdmx_resource_terrenos` |

The six building/melee/ranged prompts also specified a hand-painted game-art treatment, warm afternoon light from upper left, crisp silhouette at 96×80 or 40×56 export, no text/scene/ground tile and transparent background. Generated output was inspected before source copies were tracked. The `source_sha256` fields in [the CDMX manifest](../../game/assets/cdmx-pack.json) identify the exact retained source bytes. No local reference JPEG is a build dependency.

## Deterministic export

Run `node scripts/export-cdmx-art.mjs`, then `node scripts/validate-art-manifest.mjs`. The exporter trims and sizes each retained original with ImageMagick, pins bottom ground contact, exports RGBA and writes source/export SHA-256 values and `export_recipe` for each ID. Its 16 ground variants are color-adjusted exports of the existing seam-tested terrain cells; the tracked original terrain atlas and existing render cells are their inputs. The additional fifteen illustrations make **31** CDMX textures, 348,928 decoded RGBA bytes in the manifest. Four resource-site sprites replace the generic icon primitives; the simulation still owns their amount, visibility, position, passability and gathering rules. Faction/ownership marks remain Godot draw primitives. States are static frames with current movement bob/facing, construction, health, order and combat overlays driven by simulation state.

## QA follow-up art

`source/bicitaxi/blue.png` and `source/bicitaxi/red.png` are project-original AI-assisted transparent illustrations derived from the `props.jpg` concept direction and the shipped CDMX worker palette. The prompt asked for a compact pedal-powered passenger tricycle, one matching blue canopy and one red canopy, southeast view and bottom-ground contact. `node scripts/export-bicitaxi-art.mjs` produces the two 64×56 sprites and updates their source/export SHA-256 values in [the main art manifest](../../game/assets/manifest.v0.1.json). This replaces the earlier out-of-style silhouettes without changing scout mechanics.

`assets/menu/roma-home-background.png` is an AI-assisted original generated from `references/homescreenart/homescreen.jpg` as a visual direction. The prompt specified a wide painterly Roma Norte street and café with jacarandas, warm dusk light, open space for live setup controls, and no baked text or UI. The retained 1672×941 bitmap has SHA-256 `fff5180cd21bf3db71ff77983be739d9d896d45b615821b2aa51df90ccfba04b`; faction and match controls remain live Godot widgets. The reference JPEG is neither copied into the build nor required at runtime.

## Builder pilot and limits

The four [actual Godot captures](../screenshots/cdmx-art/README.md) show the source-matched scene at 100%, 125%, fit and a contested center. Builder decision: **revise then continue**. The first pass let the map title cross Cibeles and oversized faction badges crowd combat; the saved captures are after those fixes. The fountain, structure and fighter keep their ground anchors; worker alpha picking and resource sight selection pass the client check. These images are debug observations on an Apple M2 Max, not target-device performance or proof of uncoached comprehension. Owner style judgment, full downloaded match, and the planned familiar/unfamiliar read are still required.
