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

The six building/melee/ranged prompts also specified a hand-painted game-art treatment, warm afternoon light from upper left, crisp silhouette at 96×80 or 40×56 export, no text/scene/ground tile and transparent background. Generated output was inspected before source copies were tracked. The `source_sha256` fields in [the CDMX manifest](../../game/assets/cdmx-pack.json) identify the exact retained source bytes. No local reference JPEG is a build dependency.

## Deterministic export

Run `node scripts/export-cdmx-art.mjs`, then `node scripts/validate-art-manifest.mjs`. The exporter trims and sizes each retained original with ImageMagick, pins bottom ground contact, exports RGBA and writes source/export SHA-256 values and `export_recipe` for each ID. Its 16 ground variants are color-adjusted exports of the existing seam-tested terrain cells; the tracked original terrain atlas and existing render cells are their inputs. The additional eleven illustrations make **27** CDMX textures, 312,064 decoded RGBA bytes in the manifest. Four resource-site icons and faction/ownership marks are Godot draw primitives; they add no balance or pathing data. States are static frames with current movement bob/facing, construction, health, order and combat overlays driven by simulation state.

## Builder pilot and limits

The four [actual Godot captures](../screenshots/cdmx-art/README.md) show the source-matched scene at 100%, 125%, fit and a contested center. Builder decision: **revise then continue**. The first pass let the map title cross Cibeles and oversized faction badges crowd combat; the saved captures are after those fixes. The fountain, structure and fighter keep their ground anchors; worker alpha picking and resource sight selection pass the client check. These images are debug observations on an Apple M2 Max, not target-device performance or proof of uncoached comprehension. Owner style judgment, full downloaded match, and the planned familiar/unfamiliar read are still required.
