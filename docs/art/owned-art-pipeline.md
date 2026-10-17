# Owned art production pipeline · epic #9

The owner confirmed commercial game rights to `references/isometric tileset/`, `references/critters/` and `references/newArtWork/` on 2026-10-16. These ignored local files are audit references, never build inputs. Selected sources are copied to `game/assets/source/owned/`; `scripts/export-owned-art.sh` creates runtime PNGs in `game/assets/render/owned/`. `game/assets/manifest.v0.1.json` records per-asset source and export SHA-256, rights, dimensions, pivot, 1×1 or 2×2 footprint, direction/state, recipe and `runtime_use`. The validator rejects stale hashes, canvas drift, unexpected roles and a 1 MiB raw RGBA budget breach.

| Set | Selected source and export | Ground contact | Runtime role |
| --- | --- | --- | --- |
| Isometric tileset | `tile_000`, `tile_022` resized 32×32 → 48×48 with point sampling | (24,12) on the 48×24 top diamond | Scale pilot only; raised sidewalls do not seam with flat v0.1 terrain. |
| Isometric tileset | `tile_044` at native 32×32 | (16,26) | Decorative flower prop in two match locations; no obstacle or target. |
| Critters | Boar NE/NW/SE/SW idle, seven 46×32 frames each | (23,29) feet; seven frames/s | Pilot only by owner choice. The dark silhouette needs contrast work before match use. |
| New artwork direction | Isolated transparent command post generated from `BUILDINGS.jpg` as a visual reference, then resized 1330×1183 → 96×85 | (48,83) on the current 2×2 ground footprint | Pilot only. The source is AI-assisted raster art, not a crop of the flattened board. No board labels or proposed gameplay enter the match. |

The isolated source prompt was: “Create one isolated 2×2 isometric neighborhood command post inspired by the warm masonry and blue-banner architecture of the supplied `BUILDINGS.jpg` concept board; full building, crisp pixel-art legibility at about 96×90 pixels, genuine transparent background, no ground tile, signs, text, people, logos or proposed mechanics.” The built-in image generation tool produced `game/assets/source/owned/concept_command_post_blue.png`. The board supplied style reference only. All final selected files and rights labels are in the tracked manifest.

## Reproduce and inspect

```sh
scripts/export-owned-art.sh
node scripts/validate-art-manifest.mjs
export GODOT_BIN=/path/to/Godot
"$GODOT_BIN" --headless --path game --import
"$GODOT_BIN" --headless --path game --script res://tests/art_pipeline_test.gd
"$GODOT_BIN" --path game res://art_pilot.tscn
```

The pilot shows 100% and 125% scales. Left/Right changes boar direction; `S` saves a screenshot to `user://owned-art-pilot.png`; `P` prints the current FPS. [Captured comparison](../screenshots/owned-art-pilot/scale-comparison.png) was rendered in Godot 4.7.2 on the development Apple M2 Max Mac at 1280×800. A single debug sample was 119 FPS; this is a pilot observation, not a target-device benchmark. The 32 new PNGs total 220,032 bytes as decoded RGBA. The match catalog loads only the 32×32 flower export (4,096 decoded bytes); pilot-only textures are skipped. GPU allocation and mobile device behavior remain unmeasured.

## Review result

Builder visual check: the source tiles read as raised blocks and do not join the flat match terrain cleanly. The boar has a dark, very small silhouette against the current board palette. The isolated command post is legible at both scales but has more fine detail than the v0.1 post. The owner reviewed the scale comparison and chose to keep all three as pilot candidates; none is an approved match replacement. The flower prop is visible near existing decorative trees in the match; a friendly command post was selected by clicking its visible body after integration. Rules, collision, picking and objectives remain governed by the simulation.

The signed Restricted macOS preview `preview-0d2b90f67f91` (Butler build `#2146053`) was fetched and launched. Its menu reports the expected build ID, and the match displays the flower props at normal zoom. The fetched app matched the source archive and passed strict code-signature verification. A full downloaded-build playthrough to both victory routes as both factions remains open. No first-match-completion or retention lift can be inferred before an eligible cohort exists.
