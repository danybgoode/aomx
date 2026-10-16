# Isometric geometry — current skirmish

Status: confirmed from game/skirmish_main.gd and game/skirmish.gd on 2026-10-16. This document describes the implemented default scene, not the older worker prototype or the concept paintings.

## Coordinates

The simulation stores integer Vector2i tiles in a 20×20 grid. There is no elevation or fractional world position. A move advances a whole tile on a fixed 0.1-second tick; the renderer currently receives no interpolation fraction. Game paths, wall blocking, resource sources and the central district use these tile coordinates.

The Node2D view converts a tile (x,y) to the center of its screen diamond:

- screen_x = 640 + 24 × (x − y)
- screen_y = 65 + 12 × (x + y)

The visible ground diamond centered there has corners (0,−12), (24,0), (0,12), (−24,0), so its ground footprint is exactly 48×24 screen pixels before zoom. Positive tile X goes down-right; positive tile Y goes down-left. Tile centers span x 184–1096 and y 65–521. Including diamond tips, the unzoomed board extrema are x 160–1120 and y 53–533.

Input first reverses board zoom, then solves the two projection equations and rounds each coordinate to the nearest integer tile. Selection calls the simulation's entity_at(tile), not a sprite mask or physics collider. A unit occupies one tile. Both command_post and barracks use a 2×2 logical footprint beginning at entity.pos; the union of those four ground diamonds is 96×48 pixels. Its ground center is 12 pixels below the first tile center and its southern tip is 36 pixels below that center.

## Zoom and layers

The board is not a Camera2D. Node2D._draw applies a transform around (640,305): draw_set_transform(BOARD_CENTER × (1−zoom), 0, (zoom,zoom)). Initial zoom is 1.1; controls clamp it to 1.0–1.25. The CanvasLayer HUD is outside this transform. The project uses a 1280×800 viewport with canvas_items stretch. Fractional zoom can unevenly enlarge pixel clusters; judge art at 1.0, 1.1 and 1.25 instead of promising pixel-perfect integer scaling.

The pre-art draw order was all terrain by map row/column, then two sources, then all buildings by entity ID, then all units by entity ID, then placement and order feedback. That did not depth-sort tall sprites. The art view should sort actors by projected ground Y plus stable entity ID, while selection and collision remain tile based. Draw underlay terrain and district marks before entities; draw health, selection, placement and order feedback after entities.

## Anchors and canvas

Requirements:

- Terrain export: 48×27 RGBA. The top 24 pixels align to one 48×24 ground diamond; at most three pixels of relief extend below it. Draw origin is tile center minus (24,12).
- Unit export: 40×56 RGBA. Feet/ground anchor is (20,55), placed at the tile center. Transparent canvas and artwork overhang do not affect occupancy.
- Command-post export: 96×80 RGBA. Southern footprint tip is anchor (48,79), placed at tile_to_screen(entity.pos) + (0,36).
- Barracks export: 96×60 RGBA. Southern footprint tip is anchor (48,59), at the same world point.
- Image alpha is genuine transparency; selection and HP overlays remain independent of the image.

Recommendations to review after a rendered pilot: whether any unit silhouettes need a larger canvas; whether roofs need a per-sprite foreground pass to prevent hidden units; whether zoom needs an integer-scale mode in a later usability task. No such change is required to import this pack.
