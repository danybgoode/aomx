# Source art and provenance

These four transparent PNG atlases were generated for Battle for La Roma on 2026-10-16 with the built-in OpenAI image generation tool. The source files are retained so scripts/export-art.sh can reproduce the small in-game exports. No pixels from references/isometric tileset, references/critters, Age of Empires or the supplied concept JPGs were used as direct image inputs. The references informed the verbal visual brief. The source atlases are original AI-assisted raster art for this project; they are not layered hand-painted source files.

- terrain_atlas.png: 4×4 separate 2:1 isometric diamonds: warm urban grass, stone sidewalk, dark asphalt and plaza paving, each with four variants; crisp retro pixel clusters, upper-left daylight, transparent gutters, no subjects or labels.
- building_atlas.png: 2×2 separate CDMX-inspired warm masonry structures with the same isometric view: blue/red two-story command headquarters with water tanks and banners, and blue/red one-story recruitment outposts; transparent gutters, no text.
- unit_atlas.png: 3×2 separate adult human miniatures in a common three-quarter isometric view and foot baseline: blue worker/melee/ranged above matching red roles, practical clothing, clear silhouettes and no caricature.

- environment_atlas.png: 2×2 separate gold street cart, purple jacaranda, low metal street barricade and bronze plaza medallion, isolated on transparent gutters in the same isometric daylight. The cart represents an existing source; jacarandas are decorative; barricades mark blocked tiles; the medallion marks the existing district.

The final generation prompts also required genuine transparency, restrained blue/red accents, no logos, no watermark and readability after downsampling to the target sprite sizes. Crops, target dimensions and hard alpha threshold are declared in scripts/export-art.sh. The source atlases are never loaded by the Godot runtime.

The Scrabling pack listed at https://scrabling.itch.io/pixel-isometric-tiles remains a style reference outside the game tree. Its page currently has an ambiguous combination of CC BY 4.0 and custom attribution/redistribution wording; direct use would need a separate rights record.
