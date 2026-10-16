# Art pipeline specification v0.1

This contract applies to the existing 20×20 Godot solo skirmish. Requirements are facts that art must meet for the current scene; recommendations are quality choices that can change after rendered review.

## Production path

1. Retain original source atlases in game/assets/source with their generation prompt and provenance. Scrabling art is a visual reference only; no third-party pixels enter the production PNGs.
2. Run scripts/export-art.sh (ImageMagick) to reproduce game/assets/render transparent PNG exports. The export script fixes measured atlas crops, final canvas dimensions and hard alpha edge.
3. Keep game/assets/manifest.v0.1.json current. Each ID names the exported path, source atlas, canvas, ground anchor, logical footprint, state convention and provenance. The Godot view reads the manifest once when the scene starts, then caches textures.
4. Import PNGs into Godot as lossless 2D textures, with nearest texture filtering on the art view. Avoid lossy compression and per-frame resource loads. Keep UI font and Control rendering independent of pixel sprite filter.
5. Inspect one asset of each category at 100%, 110% and 125% board zoom in the running game before expanding a source atlas. Re-export after source edits; do not hand-edit generated PNGs.

The source atlas PNGs are editable raster source for v0.1, but they do not contain layered Aseprite data. If hand animation or repainting begins, introduce layered source files without changing the manifest contract.

## Visual rules

- Fixed 2:1 isometric projection and upper-left daylight. Bright top planes, darker lower/right walls.
- Warm masonry, restrained grass and street tones, blue/red faction accents on banners and clothing. Icon shape, labels and placement also indicate role and ownership.
- Transparent sprite backgrounds. No painted full-scene backdrop or flattened HUD.
- Unit silhouettes must be distinguishable at the default 110% zoom before adding tiny details. A role remains understandable in both blue and red skins.
- Faction names and motifs are fictional gameplay presentation; regional stereotypes are not factual unit abilities.
- Terrain variants use deterministic coordinate hashing in the view, not random calls that alter simulation/replay.
- All additions are view-only. No sprite alpha, decoration or source image supplies walkability, attack range, selection or win state.
- Tall jacarandas, carts and barricades draw below actor sprites in v0.1 so units and their tile selection remain visible in crowded areas. A unit can visually cross in front of a nearer prop; this is an explicit readability tradeoff for the current tile-picking rules.

## Imports and runtime

The current project uses GL Compatibility and desktop macOS preview. Godot 4.7.2 accepts the exported RGBA PNGs. Set the world art CanvasItem texture filter to nearest; do not change global UI text filtering to make sprites crisp. Keep each exported source small (terrain 48×27, units 40×56, buildings at most 96×80). The current map is 400 tiles, so a cached set of small textures is sufficient; an atlas is a later optimization if draw-call measurement warrants it. The retained large source atlases are not loaded at runtime.

WebGL 2.0, mobile GPU memory and hundreds of units remain target risks, not verified claims. If later targets are authorized, test an actual export and device with its native texture limits, batching and memory numbers. Do not redesign the renderer from a desktop debug frame alone.

## Rights and asset records

Each manifest entry carries source and rights. Locally produced PNGs use original generated artwork for this project; the Scrabling download remains in untracked references. The provider page labels it CC BY 4.0 while also stating custom attribution and redistribution terms; direct incorporation needs a separate provenance decision. Freesound is not a uniform open-source library: choose and record each sound's license in a later audio milestone, favoring CC0 or correctly attributed CC BY for commercial use.
