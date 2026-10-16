# Asset manifest v0.1

The machine-readable source of truth is game/assets/manifest.v0.1.json. Every integrated PNG has an ID, category, Godot resource path, retained source atlas, canvas size, pivot, logical footprint and provenance. scripts/export-art.sh reproduces the exports. An ID must resolve before the renderer requests it; missing assets are an error during development, not a silent production primitive.

## Current-match priority

| Priority | Inventory | Simulation relationship |
| --- | --- | --- |
| P0 | Four grass, sidewalk, asphalt and plaza variants each | Visual classes on the fixed 20×20 map; every tile remains governed by the existing wall/district logic. |
| P0 | Blue/red command post and barracks | Skins for the existing command_post and barracks kinds; both retain 2×2 footprints. |
| P0 | Blue/red worker, melee and ranged | Skins for the existing unit kinds; each occupies one tile. |
| P0 | Two resource sources, blocked-tile marking and La Roma state treatment | Current gameplay feedback. They may be procedural overlays rather than separate sprites; document that choice in the manifest. |
| P1 | Jacaranda, bench, lamp, food cart and other nonblocking decorations | Add only after crowded-map visibility is checked. They never create a collision or resource. |
| Later | Taquería, depot, motorcycle, additional resources, age art and full HUD | No corresponding present gameplay kind or interaction. Requires separate product work. |

A damaged building state can use view-only tint/crack overlay driven by existing HP. A construction state can use the existing complete/progress fields. Dedicated destroyed animation frames are not required for v0.1 because most dead entities are removed immediately; the 0-HP command post stays for the terminal view.

## Naming and dimensions

Use lowercase snake_case IDs and files. The existing game calls the two sides human/computer, but art IDs use blue/red visual roles; the view maps faction/side at runtime. Terrain exports are 48×27 with ground diamond 48×24 and pivot (24,12). Unit exports are 40×56 with foot pivot (20,55). Command posts are 96×80 and barracks 96×60 with south-footprint pivots at (48,79) and (48,59). Distinguish these visible canvases from logical 1×1 or 2×2 footprints.

The retained source atlases are not runtime resources. The versioned manifest and small PNG exports ship with the game. Artwork is original AI-assisted raster production for this project; no downloaded Scrabling pixels are in the exports. Check future external props or sounds per-file for rights and attribution.
